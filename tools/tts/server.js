const http = require('node:http');
const { spawn } = require('node:child_process');
const { mkdtemp, readFile, rm } = require('node:fs/promises');
const { tmpdir } = require('node:os');
const { join } = require('node:path');
const { timingSafeEqual } = require('node:crypto');

const port = Number(process.env.PORT || 5000);
const host = process.env.HOST || '0.0.0.0';
const token = process.env.TTS_HTTP_TOKEN || '';
const maxJobs = 8;
let activeJobs = 0;
let voices = [];
let voiceFiles = new Map();
let closing = false;

function run(command, args, input) {
  return new Promise((resolve, reject) => {
    const child = spawn(command, args, { stdio: ['pipe', 'pipe', 'pipe'] });
    const stdout = [];
    const stderr = [];
    let timedOut = false;
    const timer = setTimeout(() => {
      timedOut = true;
      child.kill('SIGKILL');
    }, 6000);
    child.stdout.on('data', (chunk) => stdout.push(chunk));
    child.stderr.on('data', (chunk) => stderr.push(chunk));
    child.stdin.on('error', () => {});
    child.once('error', (error) => {
      clearTimeout(timer);
      reject(error);
    });
    child.once('close', (code) => {
      clearTimeout(timer);
      if (code !== 0 || timedOut) {
        reject(new Error(`${command} failed${timedOut ? ' (timeout)' : ''}: ${Buffer.concat(stderr).toString().slice(0, 300)}`));
      } else {
        resolve(Buffer.concat(stdout).toString());
      }
    });
    child.stdin.end(input || '');
  });
}

function json(response, status, body) {
  response.writeHead(status, { 'Content-Type': 'application/json' });
  response.end(JSON.stringify(body));
}

function authorized(request) {
  if (!token) return true;
  const supplied = Buffer.from(request.headers.authorization || '');
  const expected = Buffer.from(token);
  return supplied.length === expected.length && timingSafeEqual(supplied, expected);
}

async function readBody(request) {
  const chunks = [];
  let size = 0;
  for await (const chunk of request) {
    size += chunk.length;
    if (size > 4096) throw new Error('Request body exceeds 4096 bytes');
    chunks.push(chunk);
  }
  return JSON.parse(Buffer.concat(chunks).toString());
}

async function synthesize(request, response, url) {
  const voice = url.searchParams.get('voice');
  const pitch = Number(url.searchParams.get('pitch') || 0);
  const filter = url.searchParams.get('filter') || '';
  if (!voices.includes(voice) || !Number.isFinite(pitch) || pitch < -4 || pitch > 4) {
    json(response, 400, { error: 'Invalid voice or pitch' });
    return;
  }
  if (!['', 'silicon', 'radio'].includes(filter) || url.searchParams.get('special_filters')) {
    json(response, 400, { error: 'Unsupported audio filter' });
    return;
  }
  let body;
  try {
    body = await readBody(request);
  } catch {
    json(response, 400, { error: 'Expected a JSON body containing text' });
    return;
  }
  if (!body || typeof body.text !== 'string' || !body.text.trim() || body.text.length > 299) {
    json(response, 400, { error: 'Text must contain 1 to 299 characters' });
    return;
  }
  const gender = body.gender === undefined ? 'neuter' : body.gender;
  const age = body.age === undefined ? 30 : body.age;
  if (!['male', 'female', 'neuter', 'plural'].includes(gender) || typeof age !== 'number' || !Number.isFinite(age) || age < 0 || age > 120) {
    json(response, 400, { error: 'Invalid character gender or age' });
    return;
  }
  const voiceVariant = gender === 'female' ? '+f2' : gender === 'male' ? '+m2' : '';
  const agePitch = age < 25 ? (25 - age) * 0.5 : age > 60 ? -(age - 60) * 0.15 : 0;
  const speechPitch = Math.max(0, Math.min(99, Math.round(50 + pitch * 5 + agePitch)));
  const speechRate = Math.round(age < 25 ? 165 + (25 - age) * 0.5 : age > 60 ? Math.max(140, 165 - (age - 60) * 0.5) : 165);
  if (activeJobs >= maxJobs || closing) {
    json(response, 503, { error: 'Speech service busy' });
    return;
  }
  activeJobs++;
  let directory;
  try {
    directory = await mkdtemp(join(tmpdir(), 'interpost-tts-'));
    const wav = join(directory, 'speech.wav');
    const ogg = join(directory, 'speech.ogg');
    await run('espeak-ng', ['--stdin', '-v', voiceFiles.get(voice) + voiceVariant, '-p', String(speechPitch), '-s', String(speechRate), '-w', wav], body.text);
    const duration = Number((await run('ffprobe', ['-v', 'error', '-show_entries', 'format=duration', '-of', 'default=noprint_wrappers=1:nokey=1', wav])).trim());
    if (!Number.isFinite(duration) || duration <= 0 || duration > 60) throw new Error('Invalid synthesized audio duration');
    const args = ['-hide_banner', '-loglevel', 'error', '-nostdin', '-y'];
    if (url.pathname === '/tts-blips') {
      const genderFrequency = gender === 'female' ? 80 : gender === 'male' ? -40 : 0;
      const frequency = Math.max(180, 440 + genderFrequency + pitch * 20 + agePitch * 4);
      args.push('-f', 'lavfi', '-i', `sine=frequency=${frequency}:sample_rate=22050:duration=${duration}`, '-af', "volume='if(lt(mod(t,0.14),0.06),0.8,0)':eval=frame");
    } else {
      args.push('-i', wav);
      if (filter === 'silicon') args.push('-af', 'highpass=f=250,lowpass=f=3000,aecho=0.8:0.7:25:0.4');
      if (filter === 'radio') args.push('-af', 'highpass=f=500,lowpass=f=2500');
    }
    args.push('-ac', '1', '-ar', '22050', '-c:a', 'libvorbis', '-q:a', '3', ogg);
    await run('ffmpeg', args);
    const audio = await readFile(ogg);
    response.writeHead(200, { 'Content-Type': 'audio/ogg', 'Content-Length': audio.length, 'audio-length': String(duration), 'Cache-Control': 'no-store' });
    response.end(audio);
  } catch (error) {
    console.error(`Speech generation failed: ${error.message}`);
    if (!response.headersSent) json(response, 500, { error: 'Speech generation failed' });
  } finally {
    activeJobs--;
    if (directory) await rm(directory, { recursive: true, force: true });
  }
}

const server = http.createServer((request, response) => {
  const url = new URL(request.url, 'http://localhost');
  if (request.method !== 'GET') {
    response.setHeader('Allow', 'GET');
    json(response, 405, { error: 'Only GET is supported' });
    return;
  }
  if (url.pathname === '/healthz') {
    json(response, closing ? 503 : 200, { ready: !closing && voices.length > 0 });
    return;
  }
  if (!authorized(request)) {
    json(response, 401, { error: 'Unauthorized' });
    return;
  }
  if (url.pathname === '/tts-voices') {
    json(response, 200, voices);
  } else if (url.pathname === '/pitch-available') {
    json(response, 200, true);
  } else if (url.pathname === '/speech-profile-available') {
    json(response, 200, true);
  } else if (url.pathname === '/tts' || url.pathname === '/tts-blips') {
    synthesize(request, response, url).catch((error) => {
      console.error(`Speech request failed: ${error.message}`);
      if (!response.headersSent) json(response, 500, { error: 'Speech request failed' });
      else response.destroy();
    });
  } else {
    json(response, 404, { error: 'Unknown endpoint' });
  }
});

server.requestTimeout = 10000;
server.headersTimeout = 10000;

async function main() {
  const output = await run('espeak-ng', ['--voices=en']);
  const rows = output.trim().split(/\r?\n/).slice(1).map((line) => line.trim().split(/\s+/));
  const englishVoices = rows.filter((row) => /^en(?:-|$)/.test(row[1]) && row[4] && !row[4].startsWith('mb/') && /^[a-zA-Z0-9/_-]+$/.test(row[4]));
  voiceFiles = new Map(englishVoices.map((row) => [row[1], row[4]]));
  voices = [...voiceFiles.keys()];
  if (!voices.length) throw new Error('No English eSpeak NG voices installed');
  await run('ffmpeg', ['-version']);
  await run('ffprobe', ['-version']);
  server.listen(port, host, () => console.log(`TTS listening on ${host}:${port}; ${voices.length} voices available`));
}

server.on('error', (error) => {
  console.error(error.message);
  process.exitCode = 1;
});

for (const signal of ['SIGINT', 'SIGTERM']) {
  process.on(signal, () => {
    closing = true;
    server.close();
    server.closeIdleConnections();
  });
}

main().catch((error) => {
  console.error(`TTS startup failed: ${error.message}`);
  process.exitCode = 1;
});