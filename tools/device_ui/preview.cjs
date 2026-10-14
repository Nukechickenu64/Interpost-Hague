// Build browser fixtures from real BYOND-generated themes and existing UI assets.
// Run check.py + the generated DM regression first. Optional argument: output folder.
const fs = require('fs');
const path = require('path');
const vm = require('vm');
const root = path.resolve(__dirname, '../..');
const fixtures = path.join(root, 'tmp/device-ui-check');
const out = path.resolve(process.argv[2] || fixtures);
fs.mkdirSync(out, { recursive: true });
const read = p => fs.readFileSync(path.join(root, p), 'utf8');
for (const file of ['device-ui.css', 'device-ui.js', 'cyberdeck.css']) fs.copyFileSync(path.join(root, 'html', file), path.join(out, file));
const profiles = JSON.parse(fs.readFileSync(path.join(fixtures, 'profiles.json'), 'utf8'));
const fixture = i => fs.readFileSync(path.join(fixtures, 'fixture-' + i + '.html'), 'utf8');
const themeHead = i => fixture(i).match(/<meta name='device-screen'[\s\S]*?<\/head>/)[0].replace(/<\/head>$/, '');
for (let i = 1; i <= profiles.length; i++) fs.writeFileSync(path.join(out, 'device-' + i + '.html'), fixture(i));

// These states are rendered by the production DM cyberdeck renderer.
const cyberStates = ['ready', 'standby', 'booting', 'active', 'recorded'];
for (const state of cyberStates) {
  fs.copyFileSync(path.join(fixtures, 'cyberdeck-' + state + '.html'), path.join(out, 'cyberdeck-' + state + '.html'));
}
const cyberProfile = profiles.find(p => p.state === 'os13_rdcomp');
const cyberWidth = Math.floor(Math.sqrt(600 * 620 * cyberProfile.ratio)) + 48;
const cyberHeight = Math.floor((cyberWidth - 48) / cyberProfile.ratio) + 76;
fs.writeFileSync(path.join(out, 'cyberdeck-preview.html'), '<!doctype html><html><head><meta charset="utf-8"><title>Cyberdeck screen preview</title><style>body{margin:24px;background:#171b1d;color:#c4e0ec;font:13px Verdana}h1{font-size:20px;margin:0 0 8px}p{color:#a0b4bf}nav{display:flex;flex-wrap:wrap;gap:8px;margin:20px 0}a{color:#b6dced;border:1px solid #536672;padding:7px 12px;text-decoration:none}a:hover,a:focus{background:#304654}iframe{display:block;border:0;width:' + cyberWidth + 'px;max-width:100%;height:' + cyberHeight + 'px}</style></head><body><h1>Cyberdeck research console</h1><p>Sprite-matched hardware and glass. Preview the in-game screen states below; game actions require a running game.</p><nav>' + cyberStates.map(s => '<a href="cyberdeck-' + s + '.html" target="cyberdeck-screen">' + s[0].toUpperCase() + s.slice(1) + '</a>').join('') + '</nav><iframe name="cyberdeck-screen" title="Cyberdeck screen" src="cyberdeck-ready.html"></iframe></body></html>');

// NanoUI's actual air-alarm template and layout, including semantic warning colors.
const dot = require(path.join(root, 'nano/js/libraries/doT.js'));
let helpers;
const sandbox = { NanoTemplate: { addHelpers(h) { helpers = h; } }, NanoUtility: { generateHref(p) { return '?' + new URLSearchParams(p); } } };
vm.runInNewContext(read('nano/js/nano_base_helpers.js') + '\nNanoBaseHelpers.addHelpers();', sandbox);
const data = { has_environment: true, environment: [{ name: 'Pressure', value: 101.3, unit: 'kPa', danger_level: 0 }, { name: 'Oxygen', value: 21, unit: '%', danger_level: 0 }, { name: 'Temperature', value: 293, unit: 'K', danger_level: 0 }], total_danger: 0, rcon: 2, target_temperature: '293 K', screen: 1, mode: 1, remote_connection: false, locked: false, atmos_alarm: false, fire_alarm: false };
const config = { title: 'Air alarm', mapName: 'alpha', mapZLevel: 1 };
const render = dot.template(read('nano/templates/air_alarm.tmpl'));
const layout = dot.template(read('nano/templates/layout_default.tmpl'));
let css = ['shared.css', 'icons.css', 'layout_default.css'].map(f => read('nano/css/' + f)).join('\n');
css = css.replace(/url\(['"]?([^)'"\s]+)['"]?\)/g, (m, name) => {
  const file = path.join(root, 'nano/images', name);
  return fs.existsSync(file) ? 'url(data:image/png;base64,' + fs.readFileSync(file).toString('base64') + ')' : m;
});
const content = layout(data, config, helpers).replace("<div id='uiLoadingNotice'>Initiating...</div>", render(data, config, helpers));
fs.writeFileSync(path.join(out, 'device-nano.html'), '<!doctype html><html><head><meta charset="utf-8"><style>' + css + '</style>' + themeHead(8) + '</head><body><div id="uiLayout">' + content + '</div><script>setInterval(function(){document.getElementById("uiContent").innerHTML=' + JSON.stringify(render(data, config, helpers)) + ';},3000);</script></body></html>');

// Use the shipped TGUI bundle; the device shell is outside its Ractive root.
for (const file of ['tgui.css', 'tgui.js']) fs.copyFileSync(path.join(root, 'tgui/assets', file), path.join(out, file));
const tguiData = { config: { title: 'Cell timer', status: 2, interface: 'brig_timer', style: 'nanotrasen', fancy: true, locked: false, window: 'preview', ref: 'preview', titlebar: false }, data: { timetoset: 3000, timing: false, timeleft: 300, flashes: [] } };
let tgui = read('tgui/tgui.html').replace('>{}</script>', '>' + JSON.stringify(tguiData) + '</script>').replace('[style]', 'nanotrasen').replace('[ref]', 'preview').replace('</head>', themeHead(3) + '</head>').replace('</body>', '<script>if(window.DeviceUI){window.DeviceUI.mount();}</script></body>');
fs.writeFileSync(path.join(out, 'device-tgui.html'), tgui);

// Exercise the HTML-interface update path with its real refresh functions.
fs.copyFileSync(path.join(root, 'nano/js/libraries/1-jquery.js'), path.join(out, 'jquery.min.js'));
fs.copyFileSync(path.join(root, 'code/modules/html_interface/html_interface.js'), path.join(out, 'html_interface.js'));
const liveLayout = JSON.stringify('<h2>Research diagnostics</h2><p>Live layout refresh</p><input aria-label="Test input" value="Preserved controls"><p>Updated successfully</p>');
fs.writeFileSync(path.join(out, 'device-html.html'), '<!doctype html><html><head><script src="jquery.min.js"></script><script>var hSrc="preview";</script><script src="html_interface.js"></script>' + themeHead(4) + '</head><body><script>setInterval(function(){updateLayout(' + liveLayout + ');},3000);</script></body></html>');

const cards = profiles.map((p, i) => '<article><div class="caption">' + p.name + '</div><iframe title="' + p.name + '" src="device-' + (i + 1) + '.html" style="height:' + Math.round(330 / p.ratio + 76) + 'px"></iframe></article>').join('');
const extras = [['NanoUI air alarm', 'device-nano.html'], ['TGUI cell timer', 'device-tgui.html'], ['HTML interface live refresh', 'device-html.html']].map(([name, url]) => '<article><div class="caption">' + name + '</div><iframe title="' + name + '" src="' + url + '" style="height:560px"></iframe></article>').join('');
fs.writeFileSync(path.join(out, 'device-preview.html'), '<!doctype html><html><head><meta charset="utf-8"><title>Device screen preview</title><style>body{background:#171b1d;color:#d3dcd7;font:13px Verdana;margin:28px}h1{font-size:22px;margin-bottom:8px}p{color:#87958f;margin-bottom:24px}a{color:#b6dced}.grid{display:grid;grid-template-columns:repeat(auto-fit,minmax(340px,1fr));gap:24px;align-items:start}iframe{display:block;width:100%;border:0}.caption{padding:8px 2px;color:#a8b8b0;font-size:11px;text-transform:uppercase;letter-spacing:.08em}h2{font-size:16px;margin-top:32px}</style></head><body><h1>Device screens</h1><p>Sprite-derived casing, display colors and proportions. Sample controls below are a visual preview.</p><p><a href="cyberdeck-preview.html">Open the cyberdeck research screen and its five states</a></p><div class="grid">' + cards + '</div><h2>Existing UI systems</h2><div class="grid">' + extras + '</div></body></html>');
console.log('Generated nine sprite themes, five cyberdeck states and NanoUI, TGUI and HTML-interface fixtures in ' + out);
