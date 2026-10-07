const fs = require('node:fs');
const path = require('node:path');
const childProcess = require('node:child_process');

const revision = '0d38999d5f9f987a944493f11c456537f39ac2f6';
const upstream = process.argv[2];
const checkOnly = process.argv.includes('--check');
const root = path.resolve(__dirname, '../..');
if (!upstream || childProcess.execFileSync('git', ['-C', upstream, 'rev-parse', 'HEAD'], {encoding: 'utf8'}).trim() !== revision) {
  throw new Error(`Provide a Civ13 checkout at ${revision}.`);
}

function read(relative) {
  return fs.readFileSync(path.join(upstream, relative), 'utf8').replace(/\r\n/g, '\n');
}

function blocks(source) {
  const declarations = [...source.matchAll(/^\/obj\/[^\n]+/gm)];
  return declarations.map((declaration, index) => ({
    type: declaration[0].replace(/\s*\/\/.*$/, '').trim(),
    body: source.slice(declaration.index + declaration[0].length, declarations[index + 1]?.index ?? source.length),
  }));
}

function properties(body, allowed) {
  const output = new Map();
  for (const line of body.split('\n')) {
    if (/^\t(?:New|Destroy|\w+)\(/.test(line)) break;
    const assignment = line.match(/^\t(?:var\/(?:list\/)?)?([a-z_]+)\s*=\s*(.+)$/);
    if (assignment && allowed.has(assignment[1])) output.set(assignment[1], assignment[2]);
  }
  return output;
}

function balanced(source, start) {
  let depth = 0;
  let quote = null;
  for (let index = start; index < source.length; index++) {
    const character = source[index];
    if (quote) {
      if (character === '\\') index++;
      else if (character === quote) quote = null;
    } else if (character === '"' || character === "'") quote = character;
    else if (character === '(') depth++;
    else if (character === ')' && --depth === 0) return source.slice(start + 1, index);
  }
  throw new Error('Unbalanced upstream data expression.');
}

function walk(directory) {
  return fs.readdirSync(directory, {withFileTypes: true}).flatMap(entry => {
    const filename = path.join(directory, entry.name);
    return entry.isDirectory() ? walk(filename) : filename.endsWith('.dm') ? [filename] : [];
  });
}

const sourceFiles = [
  ...walk(path.join(upstream, 'code/modules/1713/machinery')),
  ...walk(path.join(upstream, 'code/modules/1713/siege')),
  ...walk(path.join(upstream, 'code/modules/1713/weapons/guns/mg')),
  path.join(upstream, 'code/modules/1713/_mags1904.dm'),
  path.join(upstream, 'code/modules/1713/_mags1939.dm'),
  path.join(upstream, 'code/modules/1713/_magsmodern.dm'),
  path.join(upstream, 'code/modules/projectiles/ammunition.dm'),
  ...walk(path.join(upstream, 'code/modules/projectiles/projectile')),
];
const allBlocks = sourceFiles.flatMap(filename => blocks(fs.readFileSync(filename, 'utf8').replace(/\r\n/g, '\n')));
const records = new Map();
const definitions = new Map();
for (const block of allBlocks) {
  if (block.type.endsWith('/New()')) {
    const type = block.type.slice(0, -6);
    records.set(type, (records.get(type) ?? '') + block.body);
    continue;
  }
  if (!/^\/obj(?:\/[a-zA-Z0-9_]+)*$/.test(block.type)) continue;
  const data = definitions.get(block.type) ?? new Map();
  for (const [key, value] of properties(block.body, new Set([
    'name', 'desc', 'icon', 'icon_state', 'caliber', 'ammotype', 'atype', 'damage', 'heavy_armor_penetration',
    'maxrange', 'minrange', 'firedelay', 'autoloader', 'turret_icon', 'turret_x', 'turret_y', 'turret_color',
    'rotation_speed', 'magazine_type', 'good_mags', 'maxpower', 'enginesize', 'fuelefficiency', 'speeds', 'speedlist',
    'vehicle_type', 'reg_number', 'turntimer', 'color', 'pixel_x', 'pixel_y',
    'max_ammo', 'initial_ammo', 'ammo_type', 'projectile_type', 'btype',
    'gunner_x', 'gunner_y', 'loader_x', 'loader_y', 'commander_x', 'commander_y',
  ]))) data.set(key, value);
  definitions.set(block.type, data);
  records.set(block.type, (records.get(block.type) ?? '') + block.body);
}

function inherited(type) {
  const data = new Map();
  let prefix = '';
  for (const part of type.split('/').filter(Boolean)) {
    prefix += `/${part}`;
    for (const [key, value] of definitions.get(prefix) ?? []) data.set(key, value);
  }
  return data;
}

const aliases = new Map();
const skippedProps = new Set();
function convertType(type) {
  let converted;
  if (type.startsWith('/obj/structure/vehicleparts/license_plate')) {
    aliases.set(type, type);
    return type;
  }
  if (type.startsWith('/obj/structure/vehicleparts/')) return type;
  if (type.startsWith('/obj/structure/bed/chair/drivers')) converted = type.replace('/obj/structure/bed/chair/drivers', '/obj/structure/bed/chair/civ13/driver');
  else if (type.startsWith('/obj/structure/bed/chair/')) converted = type.replace('/obj/structure/bed/chair', '/obj/structure/bed/chair/civ13/passenger');
  else if (type.startsWith('/obj/structure/engine/')) converted = type.replace('/obj/structure/engine', '/obj/structure/vehicleparts/engine');
  else if (type.startsWith('/obj/item/weapon/reagent_containers/glass/barrel/fueltank')) converted = type.replace('/obj/item/weapon/reagent_containers/glass/barrel/fueltank', '/obj/structure/vehicleparts/fueltank');
  else if (type.startsWith('/obj/structure/turret')) converted = type.replace('/obj/structure/turret', '/obj/structure/vehicleparts/weapon/turret');
  else if (type.startsWith('/obj/structure/cannon/modern/tank')) converted = type.replace('/obj/structure/cannon/modern/tank', '/obj/structure/vehicleparts/weapon/cannon');
  else if (type.startsWith('/obj/item/weapon/gun/projectile/automatic/')) converted = type.replace('/obj/item/weapon/gun/projectile/automatic', '/obj/structure/vehicleparts/weapon/mg');
  else if (type.startsWith('/obj/item/cannon_ball/shell/tank')) converted = type.replace('/obj/item/cannon_ball/shell/tank', '/obj/item/civ13_shell');
  else if (type.startsWith('/obj/structure/shellrack')) converted = type.replace('/obj/structure/shellrack', '/obj/structure/vehicleparts/shellrack');
  else if (type.startsWith('/obj/item/ammo_magazine/')) converted = type.replace('/obj/item/ammo_magazine', '/obj/item/civ13_shell/magazine');
  else if (type.startsWith('/obj/structure/lamp/lamp_small/tank')) converted = '/obj/structure/vehicleparts/headlamp';
  else {
    skippedProps.add(type);
    return null;
  }
  aliases.set(type, converted);
  return converted;
}

const frames = new Map();
const frameProperties = new Set([
  'name', 'desc', 'icon', 'icon_state', 'normal_icon', 'broken_icon', 'pixel_x', 'pixel_y',
  'w_front', 'w_back', 'w_left', 'w_right', 'doorcode', 'override_roof_icon', 'override_frame_icon',
  'override_color', 'hasoverlay', 'noroof', 'removesroof', 'resistance',
]);
const frameSources = [
  'code/modules/1713/machinery/modular_vehicles/frame_parts.dm',
  'code/modules/1713/machinery/modular_vehicles/carparts/cars.dm',
  'code/modules/1713/machinery/modular_vehicles/carparts/tanks.dm',
  'code/modules/1713/machinery/modular_vehicles/carparts/apcs.dm',
];
for (const relative of frameSources) {
  for (const block of blocks(read(relative))) {
    if (!/^\/obj\/structure\/vehicleparts\/frame(?:\/[a-z0-9_]+)*$/.test(block.type)) continue;
    const merged = frames.get(block.type) ?? new Map();
    for (const [key, value] of properties(block.body, frameProperties)) merged.set(key, value);
    frames.set(block.type, merged);
  }
}

const output = [];
for (const [type, data] of frames) {
  output.push(type, ...[...data].map(([key, value]) => `\t${key} = ${value}`), '');
}

let chassisCount = 0;
for (const [type, data] of definitions) {
  if (!type.startsWith('/obj/structure/vehicleparts/axis/') || /\/(?:boat|ship|carriage)(?:\/|$)/.test(type)) continue;
  output.push(type);
  for (const [key, value] of data) {
    if (!new Set(['name', 'desc', 'icon', 'icon_state', 'speeds', 'speedlist', 'maxpower', 'vehicle_type', 'reg_number', 'turntimer', 'color']).has(key)) continue;
    output.push(`\t${key} = ${key === 'speedlist' ? value.replace(/alist\(/, 'list(').replace(/\d+\s*=/g, '') : value}`);
  }
  output.push('');
  chassisCount++;
}

const configurations = new Map();
const wheelSource = read('code/modules/1713/machinery/modular_vehicles/wheel_configs.dm');
for (const match of wheelSource.matchAll(/WHEEL_CONFIGS\["([^"]+)"\]\s*=\s*new \/datum\/wheel_config\(/g)) {
  const data = new Map([...balanced(wheelSource, match.index + match[0].length - 1).matchAll(/([a-z_]+)\s*=\s*("[^"]*"|'[^']*'|TRUE|FALSE|[\d.]+)/g)].map(assignment => [assignment[1], assignment[2]]));
  configurations.set(match[1], data);
}
const wheelTypes = new Map();
for (const relative of ['movement.dm', 'movement_compatibility.dm']) {
  for (const block of blocks(read(`code/modules/1713/machinery/modular_vehicles/${relative}`))) {
    const match = block.body.match(/get_wheel_config\("([^"]+)"\)/);
    const type = block.type.replace(/\/New\(\)$/, '');
    if (match && type.startsWith('/obj/structure/vehicleparts/movement') && !type.includes('/sail')) wheelTypes.set(type, configurations.get(match[1]));
  }
}
for (const [type, data] of wheelTypes) {
  if (!data) throw new Error(`Missing wheel configuration: ${type}`);
  output.push(type);
  for (const [key, value] of data) {
    const mappedKey = {name: 'name', icon: 'icon', icon_state: 'icon_state', type_name: 'ntype', base_icon_state: 'base_icon', movement_icon_state: 'movement_icon', is_reversed: 'reversed', side: 'side', position: 'position'}[key];
    if (mappedKey) output.push(`\t${mappedKey} = ${value}`);
  }
  output.push('');
}
for (const block of blocks(read('code/modules/1713/machinery/modular_vehicles/movement_compatibility.dm'))) {
  if (!/^\/obj\/structure\/vehicleparts\/movement(?:\/[a-z0-9_]+)*$/.test(block.type) || block.type.includes('/sail')) continue;
  const data = properties(block.body, new Set(['name', 'icon', 'icon_state', 'base_icon', 'movement_icon', 'ntype', 'reversed']));
  output.push(block.type, ...[...data].map(([key, value]) => `\t${key} = ${value}`), '');
}

const presetSource = read('code/modules/1713/machinery/modular_vehicles/carparts/premade.dm');
let presetCount = 0;
for (const block of blocks(presetSource)) {
  if (!/^\/obj\/effects\/premadevehicles(?:\/[a-z0-9_]+)+$/.test(block.type) || block.type.includes('/ship')) continue;
  const layoutStart = block.body.indexOf('tocreate = list(');
  if (layoutStart < 0) {
    const data = properties(block.body, new Set(['name', 'custom_color']));
    output.push(block.type.replace('/obj/effects/premadevehicles', '/obj/effect/civ13_vehicle'));
    output.push(...[...data].map(([key, value]) => `\t${key} = ${value}`), '');
    continue;
  }
  const layout = balanced(block.body, block.body.indexOf('(', layoutStart));
  const data = properties(block.body, new Set(['name', 'custom_color', 'axis', 'doorcode', 'reg_number']));
  output.push(block.type.replace('/obj/effects/premadevehicles', '/obj/effect/civ13_vehicle'));
  for (const [key, value] of data) output.push(`\t${key === 'axis' ? 'axis_type' : key} = ${value}`);
  output.push('\ttocreate = list(');
  let driverFound = false;
  let engineFound = false;
  for (const cell of layout.matchAll(/"(\d+,\d+)"\s*=\s*list\(/g)) {
    const contents = balanced(layout, cell.index + cell[0].length - 1);
    const originalTypes = [...contents.matchAll(/\/obj(?:\/[a-zA-Z0-9_]+)+/g)].map(match => match[0]);
    const types = originalTypes.map(convertType).filter(Boolean);
    if (!types.length) continue;
    if (!types.some(type => type.startsWith('/obj/structure/vehicleparts/frame/'))) throw new Error(`Missing frame at ${block.type} ${cell[1]}`);
    driverFound ||= types.some(type => type.startsWith('/obj/structure/bed/chair/civ13/driver'));
    engineFound ||= types.some(type => type.startsWith('/obj/structure/vehicleparts/engine/'));
    output.push(`\t\t"${cell[1]}" = list(${types.join(', ')}),`);
  }
  if (!driverFound || !engineFound) throw new Error(`Incomplete ground preset: ${block.type}`);
  output.push('\t)', '');
  presetCount++;
}

const caliberIds = new Map([
  ['762', 7.62], ['792', 7.92], ['127', 12.7], ['50', 12.7], ['50cal', 12.7], ['30cal', 7.62],
  ['3006', 7.62], ['303', 7.7], ['77', 7.7], ['8', 8], ['65', 6.5], ['556', 5.56], ['545', 5.45],
  ['20', 20], ['20mm', 20], ['25', 25], ['25mm', 25], ['30', 30], ['30mm', 30], ['35', 35], ['9', 9],
]);
const magazineCalibers = new Map();
for (const [type] of definitions) {
  if (!type.startsWith('/obj/item/weapon/gun/projectile/automatic/')) continue;
  const data = inherited(type);
  const token = (data.get('caliber') ?? '').replace(/"/g, '').replace(/^a/, '').split('x')[0].split('_')[0];
  const caliber = caliberIds.get(token);
  if (caliber && data.get('magazine_type')) magazineCalibers.set(data.get('magazine_type'), caliber);
  if (caliber && data.get('good_mags')) {
    for (const match of data.get('good_mags').matchAll(/\/obj\/item\/ammo_magazine(?:\/[a-zA-Z0-9_]+)+/g)) magazineCalibers.set(match[0], caliber);
  }
}

for (const type of definitions.keys()) {
  if (type.startsWith('/obj/item/cannon_ball/shell/tank/')) convertType(type);
}

for (const [original, converted] of aliases) {
  const data = inherited(original);
  output.push(converted);
  const common = new Set(['name', 'desc', 'icon', 'icon_state']);
  for (const [key, value] of data) if (common.has(key)) output.push(`\t${key} = ${value}`);
  if (converted.startsWith('/obj/structure/vehicleparts/engine/')) {
    const size = Number(data.get('enginesize') ?? 1000);
    output.push(`\tpower = ${Number(data.get('maxpower') ?? 50) * size / 1000}`);
    output.push(`\tfuel_use = ${Math.max(0.01, Number(data.get('fuelefficiency') ?? 0.1) * size / 1000)}`);
  } else if (converted.startsWith('/obj/structure/vehicleparts/fueltank')) {
    output.push('\tstart_fuel = 200');
  } else if (converted.startsWith('/obj/structure/vehicleparts/weapon/turret')) {
    if (data.get('turret_icon') && data.get('turret_icon') !== '""') {
      output.push("\ticon = 'icons/obj/vehicles/vehicles256x256.dmi'", '\ticon_state = ""');
    }
    for (const key of ['turret_icon', 'turret_x', 'turret_y', 'turret_color', 'rotation_speed', 'gunner_x', 'gunner_y', 'loader_x', 'loader_y', 'commander_x', 'commander_y']) if (data.has(key)) output.push(`\t${key} = ${data.get(key)}`);
    let weaponTypes;
    let prefix = original;
    while (prefix && !weaponTypes?.length) {
      weaponTypes = [...(records.get(prefix) ?? '').matchAll(/weapons\.Add\(new\s*(\/obj\/(?:structure\/cannon\/modern\/tank|item\/weapon\/gun\/projectile\/automatic)[^ (\n]*)/g)].map(match => match[1]);
      prefix = prefix.slice(0, prefix.lastIndexOf('/'));
    }
    if (weaponTypes?.length) output.push(`\tweapon_types = list(${weaponTypes.map(convertType).join(', ')})`);
    let crewSource;
    prefix = original;
    while (prefix && !crewSource) {
      if (/gunner_seat\s*=\s*new/.test(records.get(prefix) ?? '')) crewSource = records.get(prefix);
      prefix = prefix.slice(0, prefix.lastIndexOf('/'));
    }
    if (crewSource) {
      const roles = ['gunner', 'loader', 'commander'].filter(role => new RegExp(`${role}_seat\\s*=\\s*new`).test(crewSource));
      output.push(`\tcrew_roles = list(${roles.map(role => `"${role}"`).join(', ')})`);
    }
    if (original.includes('/course/')) output.push('\tfixed_mount = TRUE');
  } else if (converted.startsWith('/obj/structure/vehicleparts/weapon/cannon')) {
    for (const key of ['caliber', 'maxrange', 'minrange', 'firedelay', 'autoloader']) if (data.has(key)) output.push(`\t${key} = ${data.get(key)}`);
  } else if (converted.startsWith('/obj/structure/vehicleparts/weapon/mg')) {
    const token = (data.get('caliber') ?? 'a762').replace(/"/g, '').replace(/^a/, '').split('x')[0].split('_')[0];
    const caliber = caliberIds.get(token);
    if (!caliber) throw new Error(`Unknown mounted weapon caliber ${token}: ${original}`);
    output.push(`\tcaliber = ${caliber}`, '\tmachinegun = TRUE', '\tfiredelay = 0.2');
    const magazines = [...(data.get('good_mags') ?? data.get('magazine_type') ?? '').matchAll(/\/obj\/item\/ammo_magazine(?:\/[a-zA-Z0-9_]+)+/g)].map(match => convertType(match[0]));
    if (magazines.length) output.push(`\taccepted_ammo = list(${magazines.join(', ')})`);
  } else if (converted.startsWith('/obj/item/civ13_shell/magazine')) {
    let caliber;
    let prefix = original;
    while (prefix && !caliber) {
      caliber = magazineCalibers.get(prefix);
      prefix = prefix.slice(0, prefix.lastIndexOf('/'));
    }
    if (!caliber) throw new Error(`No mounted weapon found for magazine ${original}`);
    const capacity = parseFloat(data.get('max_ammo') ?? '50');
    if (!Number.isFinite(capacity) || capacity < 1) throw new Error(`Invalid magazine capacity: ${original}`);
    const casing = inherited(data.get('ammo_type') ?? '');
    const projectile = inherited(casing.get('projectile_type') ?? '');
    const damage = parseFloat(projectile.get('damage') ?? `${caliber >= 20 ? 80 : 35}`);
    const penetration = parseFloat(projectile.get('heavy_armor_penetration') ?? '15');
    const payload = projectile.get('atype') ?? (original.endsWith('_he') ? '"HE"' : '"AP"');
    output.push(`\tcaliber = ${caliber}`, `\trounds = ${capacity}`, `\tdamage = ${damage}`, `\theavy_armor_penetration = ${penetration}`, `\tatype = ${payload}`);
  } else if (converted.startsWith('/obj/structure/vehicleparts/shellrack')) {
    const caliber = original.match(/full(\d+)/)?.[1];
    if (caliber) {
      const shellType = `/obj/item/cannon_ball/shell/tank/AP${caliber}${original.includes('ww2') ? 'ww2' : ''}`;
      const alternative = [...definitions.keys()].find(type => type.startsWith('/obj/item/cannon_ball/shell/tank/AP') && Number(inherited(type).get('caliber')) === Number(caliber));
      const selected = definitions.has(shellType) ? shellType : alternative;
      if (!selected) throw new Error(`Missing rack ammunition ${original}`);
      output.push(`\tcaliber = ${caliber}`, '\tstart_shells = 6', `\tstart_shell_type = ${convertType(selected)}`);
    }
  } else if (converted.startsWith('/obj/item/civ13_shell')) {
    for (const key of ['caliber', 'atype', 'damage', 'heavy_armor_penetration']) if (data.has(key)) output.push(`\t${key} = ${data.get(key)}`);
  } else if (converted.includes('/passenger/mgunner/')) {
    const selected = records.get(original)?.match(/mg\s*=\s*new\s*(\/obj\/item\/weapon\/gun\/projectile\/automatic[^ (\n]*)/)?.[1];
    if (!selected) throw new Error(`Missing hull-gun seat weapon: ${original}`);
    output.push(`\tstation_weapon = ${convertType(selected)}`);
  }
  output.push('');
}
const assetDirectory = path.join(root, 'icons/obj/civ13');
if (!checkOnly) fs.mkdirSync(assetDirectory, {recursive: true});
const assetPaths = new Set([...output.join('\n').matchAll(/'([^']+\.dmi)'/g)].map(match => match[1]));
assetPaths.add('icons/obj/vehicles/vehicleparts.dmi');
assetPaths.add('icons/obj/vehicles/vehicleparts_damaged.dmi');
for (const relative of assetPaths) {
  const destination = path.join(assetDirectory, path.basename(relative));
  const source = path.join(upstream, relative);
  const data = fs.existsSync(source) ? fs.readFileSync(source) : childProcess.execFileSync('git', ['-C', upstream, 'show', `${revision}:${relative}`], {maxBuffer: 16 * 1024 * 1024});
  if (!data.subarray(0, 8).equals(Buffer.from([137, 80, 78, 71, 13, 10, 26, 10]))) throw new Error(`Invalid DMI/PNG asset: ${relative}`);
  if (checkOnly) {
    if (!fs.existsSync(destination) || !fs.readFileSync(destination).equals(data)) throw new Error(`Asset differs from upstream: ${relative}`);
  } else fs.writeFileSync(destination, data);
}
const dataFile = path.join(root, 'code/modules/vehicles/civ13/models.dm');
const remapped = output.join('\n').replace(/'([^']+\.dmi)'/g, (match, relative) => `'icons/obj/civ13/${path.basename(relative)}'`);
if (checkOnly) {
  if (fs.readFileSync(dataFile, 'utf8') !== remapped) throw new Error('Generated model data is not up to date.');
} else {
  fs.mkdirSync(path.dirname(dataFile), {recursive: true});
  fs.writeFileSync(dataFile, remapped);
}
const report = {revision, frames: frames.size, chassis: chassisCount, wheels: wheelTypes.size, presets: presetCount, assets: [...assetPaths].sort(), omittedProps: [...skippedProps].sort()};
if (!checkOnly) fs.writeFileSync(path.join(root, 'tools/civ13_port/import-report.json'), JSON.stringify(report, null, 2) + '\n');
console.log(`Imported ${frames.size} frames, ${chassisCount} chassis, ${wheelTypes.size} wheel types, ${presetCount} presets, and ${assetPaths.size} sprite files.`);
console.log(`Omitted ${skippedProps.size} non-vehicle prop types; see import-report.json.`);
if (checkOnly) console.log('Read-only verification passed: generated data and sprites match the pinned upstream revision.');