// DriftLands review harness — load the web build, optionally send key/click
// input, screenshot the canvas, and report any page errors. This is the
// "second pair of eyes": it lets an agent SEE the running game.
//
// Usage: node shot.mjs <url> <outPng> <waitMs> [keys] [shots]
//   keys  : comma list of held keys, e.g. "KeyD,KeyD,Space" (pressed in sequence)
//   shots : number of screenshots over time (default 1) -> out-0.png, out-1.png...
import { chromium } from 'playwright';

const url = process.argv[2] || 'http://localhost:8099/';
const out = process.argv[3] || '.review/shot.png';
const waitMs = parseInt(process.argv[4] || '7000', 10);
const keys = (process.argv[5] || '').split(',').map(s => s.trim()).filter(Boolean);
const shots = parseInt(process.argv[6] || '1', 10);

const browser = await chromium.launch({ args: ['--use-gl=angle', '--ignore-gpu-blocklist'] });
const page = await browser.newPage({ viewport: { width: 960, height: 540 }, deviceScaleFactor: 1 });

const errors = [];
page.on('console', m => { if (m.type() === 'error') errors.push(m.text()); });
page.on('pageerror', e => errors.push('PAGEERROR ' + String(e)));

await page.goto(url, { waitUntil: 'load', timeout: 90000 });
await page.waitForSelector('canvas', { timeout: 90000 });
await page.waitForTimeout(waitMs);

// focus the canvas so Godot receives input
const canvas = await page.$('canvas');
await canvas.click({ position: { x: 480, y: 270 } }).catch(() => {});

const base = out.replace(/\.png$/, '');
for (let i = 0; i < shots; i++) {
  for (const k of keys) {
    await page.keyboard.down(k);
    await page.waitForTimeout(120);
    await page.keyboard.up(k);
  }
  await page.waitForTimeout(500);
  const path = shots > 1 ? `${base}-${i}.png` : out;
  await page.screenshot({ path });
  console.log('shot saved:', path);
}

if (errors.length) console.log('PAGE ERRORS:\n' + errors.slice(0, 30).join('\n'));
else console.log('no page errors');
await browser.close();
