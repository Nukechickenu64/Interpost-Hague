// Exercise the production window transport without opening a BYOND client.
const assert = require('node:assert/strict');
const fs = require('node:fs');
const vm = require('node:vm');
const path = require('node:path');
class Node {
  constructor() { this.children = []; this.events = {}; this.style = {}; this.className = ''; }
  get firstChild() { return this.children[0]; }
  appendChild(node) {
    if (node.parent) node.parent.children.splice(node.parent.children.indexOf(node), 1);
    node.parent = this;
    this.children.push(node);
  }
  set innerHTML(html) {
    this.nodes = {};
    for (const match of html.matchAll(/id="([^"]+)"/g)) this.nodes['#' + match[1]] = new Node();
  }
  querySelector(selector) { return this.nodes[selector]; }
  getBoundingClientRect() { return { left: 2, top: 2, width: 596, height: 396 }; }
  addEventListener(name, fn) { this.events[name] = fn; }
  removeEventListener(name, fn) { if (this.events[name] === fn) delete this.events[name]; }
  dispatch(name, props = {}) {
    if (this.events[name]) this.events[name]({ type: name, button: 0, buttons: 1, screenX: 100, screenY: 200, currentTarget: this, preventDefault() {}, ...props });
  }
}
const body = new Node(), originalForm = new Node();
body.appendChild(originalForm);
const document = new Node();
document.body = body;
document.documentElement = new Node();
document.readyState = 'complete';
document.createElement = () => new Node();
document.querySelector = () => ({ content: JSON.stringify({ window: 'device [1]', name: 'Test console', kind: 'console', closeCommand: '.deviceclose device ref' }) });
const window = new Node();
Object.assign(window, { screenLeft: -1600, screenTop: 70, innerWidth: 600, innerHeight: 400 });
const requests = [], callbacks = new Map();
window.location = { set href(value) { requests.push(value); } };
let timer = 0;
window.setTimeout = fn => { callbacks.set(++timer, fn); return timer; };
window.clearTimeout = id => callbacks.delete(id);
const flush = () => { for (const [id, fn] of callbacks) { callbacks.delete(id); fn(); } };
const query = () => new URLSearchParams(requests.at(-1).split('?')[1]);
vm.runInNewContext(fs.readFileSync(path.join(__dirname, '../../html/device-ui.js'), 'utf8'), { window, document, Math, JSON, encodeURIComponent });
const frame = body.firstChild, drag = frame.querySelector('#device-drag'), resize = frame.querySelector('#device-resize');
assert.equal(window.DeviceUI.content().firstChild, originalForm, 'Existing controls must retain their DOM identity');
window.DeviceUI.mount();
assert.equal(body.children.length, 1, 'Refreshes must not nest frames');
drag.dispatch('mousedown');
document.dispatch('mousemove', { screenX: 160, screenY: 230 });
flush();
assert.equal(query().get('device [1].pos'), '-1540,100', 'Negative monitor coordinates must be supported');
window.screenLeft = -1540;
document.dispatch('mousemove', { screenX: 170, screenY: 240 });
flush();
assert.equal(query().get('device [1].pos'), '-1530,110', 'Moving the native window must not feed back into drag deltas');
document.dispatch('mouseup', { screenX: 170, screenY: 240 });
const afterRelease = requests.length;
document.dispatch('mousemove', { screenX: 500 });
drag.dispatch('mousedown', { button: 2 });
document.dispatch('mousemove');
flush();
assert.equal(requests.length, afterRelease, 'Release and right clicks must not move the window');
resize.dispatch('mousedown');
document.dispatch('mousemove', { screenX: 180, screenY: 260 });
flush();
assert.equal(query().get('device [1].size'), '680,460');
document.dispatch('mouseup', { screenX: -1000, screenY: -1000 });
assert.equal(query().get('device [1].size'), '320,240', 'Resizing must retain a usable minimum');
drag.dispatch('mousedown');
document.dispatch('mousemove', { screenX: 140 });
window.dispatch('blur');
const afterBlur = requests.length;
document.dispatch('mousemove');
flush();
assert.equal(requests.length, afterBlur, 'Lost focus must release native capture');
frame.querySelector('#device-close').dispatch('click');
assert.equal(query().get('command'), '.deviceclose device ref', 'Close must invoke the supplied framework cleanup');
console.log('PASS: DOM preservation, single frame, negative monitor drag, stable deltas, release, right click, resize limits, blur and close routing.');
