// Render the production NanoUI templates with the shipped engine and helpers.
const fs = require('fs');
const path = require('path');
const vm = require('vm');
const assert = require('assert');
const root = path.resolve(__dirname, '../..');
const read = p => fs.readFileSync(path.join(root, p), 'utf8');
const dot = require(path.join(root, 'nano/js/libraries/doT.js'));
let helper;
vm.runInNewContext(read('nano/js/nano_base_helpers.js') + '\nNanoBaseHelpers.addHelpers();', {
  NanoTemplate: { addHelpers(h) { helper = h; } },
  NanoUtility: { generateHref(p) { return '?' + new URLSearchParams(p); } }
});
const render = (name, data) => dot.template(read('nano/templates/' + name + '.tmpl'))(data, {}, helper);
const power = {
  demand: 310, generated: 345.6, stored: 45, capacity: 100, age: 2,
  working: 48, panels: 56, solar_output: 345.6, retracted: 0, can_control: true,
  areas: [{ name: 'Engineering', load: 25, offline: false }, { name: 'Research', load: 30, offline: true }]
};
let html = render('engineering_power', power);
assert(html.includes('345.6 kW') && html.includes('Engineering') && html.includes('Power cut'));
assert(html.includes('deploy=1') && html.includes('deploy=0'));
power.can_control = false;
assert(!render('engineering_power', power).includes('deploy=1'));
const shield = {
  offline_for: 0, running: 2, overloaded: false, current_energy: 10, max_energy: 20,
  mitigation_em: 0, mitigation_physical: 0, mitigation_heat: 0, mitigation_max: 50,
  upkeep_power_usage: 30, power_usage: 50, input_cap_kw: 100,
  functional_segments: 20, total_segments: 20, field_radius: 10,
  coverage: 'North sector (90 degrees)', modes: [], hacked: false
};
const shields = render('shieldgen', shield);
for (const direction of [0, 1, 2, 4, 8]) assert(shields.includes('direction=' + direction));
assert(shields.includes('North sector (90 degrees)'));
const crew = render('crew_monitor', { isAI: false, crewmembers: [
  { name: 'Missing Engineer', assignment: 'Engineer', sensor_type: 0, missing: true },
  { name: 'Online Engineer', assignment: 'Engineer', sensor_type: 3, pulse: 80, span: 'good', pressure: 'Normal', bodytemp: 37, area: 'Engineering', x: 62, y: 80, z: 3, radiation: 42 }
] });
assert(crew.includes('NOT RESPONDING') && crew.includes('RAD: 42') && crew.includes('report=1'));
const out = path.join(root, 'tmp/engineer-video-check');
fs.mkdirSync(out, { recursive: true });
const css = ['shared.css', 'icons.css', 'layout_default.css'].map(f => read('nano/css/' + f)).join('\n');
const page = (title, content) => '<!doctype html><html><head><meta charset="utf-8"><title>' + title + '</title><style>' + css + '\nbody{padding:18px;max-width:580px;margin:auto}td,th{padding:5px;text-align:left}</style></head><body>' + content + '</body></html>';
fs.writeFileSync(path.join(out, 'power.html'), page('Station power', html));
fs.writeFileSync(path.join(out, 'shields.html'), page('Directional shields', shields));
fs.writeFileSync(path.join(out, 'crew.html'), page('Crew signals', crew));
const atmos = {
  can_control: true, tank: true, reserve: 2026.5, supply_status: 'online',
  enabled: true, limit: 1000, lockdown_pressure: 60,
  areas: [{ name: 'Engineering', ref: 'area1', locked: false }],
  selected: 'area1', area_name: 'Engineering', locked: false,
  manual: false, automatic: true, controller_online: true,
  vents: [{ name: 'Engineering Vent 1', ref: 'vent1', pressure: 101.3, mode: 'FILTER', status: 'filtering' },
    { name: 'Engineering Vent 2', ref: 'vent2', pressure: 45.5, mode: 'STOP', status: 'vent switched off' }]
};
const atmosphere = render('engineering_atmos', atmos);
assert(atmosphere.includes('60 kPa at 20 C') && atmosphere.includes('101.3 kPa'));
for (const mode of ['REFILL', 'STOP', 'FILTER']) assert(atmosphere.includes('vent_mode=' + mode));
assert(atmosphere.includes('vent=all') && atmosphere.includes('vent=vent1'));
assert(atmosphere.includes('lockdown=1') && atmosphere.includes('automatic=1'));
atmos.can_control = false;
const readOnly = render('engineering_atmos', atmos);
assert(!readOnly.includes('vent_mode=') && !readOnly.includes('gas_action=') && !readOnly.includes('lockdown=1'));
assert(readOnly.includes('101.3 kPa'));
atmos.can_control = true;
atmos.controller_online = false;
assert(!render('engineering_atmos', atmos).includes('vent_mode='));
atmos.vents = [];
assert(render('engineering_atmos', atmos).includes('No vents in this area.'));
assert(render('engineering_atmos', { areas: [], vents: [], can_control: false, tank: false }).includes('No area controllers connected.'));
fs.writeFileSync(path.join(out, 'atmosphere.html'), page('Atmospherics Control Console', atmosphere));
console.log('PASS: atmosphere readings, vent controls, lockdown actions, access restrictions and offline/empty states render.');
console.log('PASS: power readout, access-dependent deployment controls, area status and all shield directions render.');
console.log('Preview fixtures: ' + out);
