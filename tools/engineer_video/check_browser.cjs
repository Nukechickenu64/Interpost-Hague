// Requires Playwright (the Codex bundled runtime can supply it through NODE_PATH).
const { chromium } = require('playwright');
const { pathToFileURL } = require('url');
const path = require('path');
const assert = require('assert');
(async () => {
  const browser = await chromium.launch({ headless: true, channel: 'msedge' });
  try {
    const page = await browser.newPage();
    for (const [name, width] of [['power', 580], ['shields', 500], ['crew', 1000], ['atmosphere', 650]]) {
      await page.setViewportSize({ width, height: 900 });
      await page.goto(pathToFileURL(path.resolve(__dirname, '../../tmp/engineer-video-check/' + name + '.html')).href);
      const state = await page.evaluate(() => ({ width: document.documentElement.scrollWidth, viewport: innerWidth, missing: document.body.innerText.includes('undefined') }));
      assert(state.width <= state.viewport && !state.missing, name + ': ' + JSON.stringify(state));
      await page.screenshot({ path: path.resolve(__dirname, '../../tmp/engineer-video-check/' + name + '.png'), fullPage: true });
    }
    console.log('PASS: Edge renders power, shield, crew and atmosphere fixtures without overflow or undefined text.');
  } finally {
    await browser.close();
  }
})().catch(error => { console.error(error); process.exitCode = 1; });
