const fs = require('node:fs');
const path = require('node:path');
const zlib = require('node:zlib');

const root = path.resolve(__dirname, '../..');
const spriteDirectory = 'icons/os13/turf/turf';
const floorSheets = new Set([
    'bridge', 'catwalk2', 'dirt', 'dirt2', 'ice', 'newmaintenance',
    'newrails', 'newrails2', 'platform', 'platform2', 'rails', 'snow',
    'stonefloor', 'stonenew', 'thermal',
]);
const wallSheets = new Set([
    'flesh', 'gwalls', 'lev', 'lev_mask', 'prisonwalls', 'prisonwalls2',
    'soulwall1', 'soulwall2', 'stonecave', 'stonewall', 'stonewall2',
    'stonewall3', 'stonewall3_mask', 'subwalls', 'wall', 'wallb', 'walls',
    'walls2', 'walls2_mask', 'walls3', 'walls3b', 'walls_details', 'wallw',
    'wooden3', 'wR', 'wwalls',
]);

function readStates(filename) {
    const data = fs.readFileSync(path.join(root, spriteDirectory, filename));
    let description = '';
    for (let offset = 8; offset < data.length;) {
        const size = data.readUInt32BE(offset);
        const kind = data.toString('ascii', offset + 4, offset + 8);
        const body = data.subarray(offset + 8, offset + 8 + size);
        if (kind === 'zTXt' && body.toString('ascii', 0, body.indexOf(0)) === 'Description') {
            description += zlib.inflateSync(body.subarray(body.indexOf(0) + 2)).toString('utf8');
        } else if (kind === 'tEXt' && body.toString('ascii', 0, body.indexOf(0)) === 'Description') {
            description += body.subarray(body.indexOf(0) + 1).toString('utf8');
        }
        offset += size + 12;
    }
    return [...new Set([...description.matchAll(/^state = "(.*)"\r?$/gm)].map(match => match[1]))];
}

function dmString(value) {
    return '"' + value.replace(/\\/g, '\\\\').replace(/"/g, '\\"')
        .replace(/\[/g, '\\[').replace(/\]/g, '\\]') + '"';
}

function identifier(value) {
    return value.toLowerCase().replace(/[^a-z0-9_]+/g, '_').replace(/^_+|_+$/g, '') || 'empty';
}

function classify(sheet, state) {
    if (/^(floors|floor_)/.test(sheet) || floorSheets.has(sheet)) {
        return 'floor';
    }
    if (sheet === 'hell') {
        if (state === 'floor') return 'floor';
        return /^(wall|W|straight|end|xwall)$/.test(state) ? 'wall' : null;
    }
    if (sheet === 'meat') {
        return /^(wall|xwall|W|A$)/.test(state) ? 'wall' : null;
    }
    if (sheet === 'shuttle') {
        return /wall/i.test(state) ? 'wall' : null;
    }
    if (sheet === 'train') {
        return state === 'floor' ? 'floor' : null;
    }
    if (sheet === 'cs') {
        return /^cybspace/.test(state) ? 'floor' : null;
    }
    if (/^caves_/.test(sheet) && sheet !== 'caves_new0crystals') {
        return 'wall';
    }
    if (wallSheets.has(sheet)) {
        return /floor|stonedamaged/i.test(state) ? 'floor' : 'wall';
    }
    return null;
}

const groups = { floor: new Map(), wall: new Map() };
for (const filename of fs.readdirSync(path.join(root, spriteDirectory)).sort()) {
    if (!filename.endsWith('.dmi')) continue;
    const sheet = filename.slice(0, -4);
    for (const state of readStates(filename)) {
        const kind = classify(sheet, state);
        if (!kind) continue;
        if (!groups[kind].has(sheet)) groups[kind].set(sheet, []);
        groups[kind].get(sheet).push(state);
    }
}

let outdated = false;
for (const [kind, sheets] of Object.entries(groups)) {
    const turfPath = kind === 'floor' ? '/turf/simulated/floor/fixed/os13' : '/turf/simulated/wall/os13';
    const filename = kind === 'floor' ? 'floor_static.dm' : 'wall_types.dm';
    const destination = path.join(root, 'code/game/turfs/simulated', filename);
    const current = fs.readFileSync(destination, 'utf8');
    const newline = current.includes('\r\n') ? '\r\n' : '\n';
    const generatedStart = new RegExp('^' + turfPath + '/[a-z0-9_]+\\r?$', 'm');
    const start = current.search(generatedStart);
    const prefix = (start < 0 ? current : current.slice(0, start)).trimEnd();
    const blocks = [];
    let count = 0;
    for (const [sheet, states] of sheets) {
        const sheetPath = turfPath + '/' + identifier(sheet);
        blocks.push(sheetPath + '\n\ticon = \'' + spriteDirectory + '/' + sheet + '.dmi\'\n\ticon_state = ' + dmString(states[0]));
        const usedNames = new Set();
        for (const state of states) {
            const base = 'state_' + identifier(state);
            let stateName = base;
            for (let suffix = 2; usedNames.has(stateName); suffix++) stateName = base + '_' + suffix;
            usedNames.add(stateName);
            blocks.push(sheetPath + '/' + stateName + '\n\ticon_state = ' + dmString(state));
            count++;
        }
    }
    const generated = prefix + newline + newline + blocks.join('\n\n').replace(/\n/g, newline) + newline;
    const changed = generated !== current;
    if (changed && process.argv.includes('--write')) fs.writeFileSync(destination, generated);
    if (changed && !process.argv.includes('--write')) outdated = true;
    console.log(kind + ': ' + count + ' sprite states across ' + sheets.size + ' sheets; ' +
        (changed ? (process.argv.includes('--write') ? 'updated' : 'needs regeneration') : 'up to date'));
}
if (outdated) {
    console.error('Run node tools/dmitool/import_os13_turfs.js --write to regenerate the turf catalogue.');
    process.exitCode = 1;
}