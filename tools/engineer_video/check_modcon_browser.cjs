// Render the report emitted by the actual DreamDaemon regression fixture.
const fs = require('fs');
const path = require('path');
const { pathToFileURL } = require('url');
const assert = require('assert');
const { chromium } = require('playwright');
const root = path.resolve(__dirname, '../..');
const out = path.join(root, 'tmp/engineer-video-check');
const fragment = fs.readFileSync(path.join(out, 'modcon-fragment.html'), 'utf8');
assert(fragment.includes('modcon=vent') && fragment.includes('vent=all'));
const css = pathToFileURL(path.join(root, 'code/modules/goonchat/browserassets/css/browserOutput.css')).href;
fs.writeFileSync(path.join(out, 'modcon.html'), '<!doctype html><html><head><meta charset="utf-8"><link rel="stylesheet" href="' + css + '"></head><body>' + fragment + '</body></html>');
(async () => {
  const browser = await chromium.launch({ headless: true, channel: 'msedge' });
  try {
    const page = await browser.newPage();
    for (const width of [360, 500]) {
      await page.setViewportSize({ width, height: 900 });
      await page.goto(pathToFileURL(path.join(out, 'modcon.html')).href);
      const state = await page.evaluate(() => ({
        width: document.documentElement.scrollWidth,
        viewport: innerWidth,
        text: document.body.innerText,
        commands: [...document.querySelectorAll('a')].map(a => a.getAttribute('href'))
      }));
      assert(state.width <= state.viewport, 'Report overflows at ' + width);
      assert(!state.text.includes('undefined') && state.text.includes('FILTER'));
      assert(state.commands.some(h => h.includes('modcon=lockdown')));
      assert(state.commands.filter(h => h.includes('modcon=vent')).length === 9);
      await page.screenshot({ path: path.join(out, 'modcon-' + width + '.png'), fullPage: true });
    }
    console.log('PASS: live modcon report renders all commands at 360/500px without overflow or missing values.');
  } finally {
    await browser.close();
  }
})().catch(error => { console.error(error); process.exitCode = 1; });
