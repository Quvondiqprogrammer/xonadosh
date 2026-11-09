const { chromium } = require('playwright');
const path = require('path');
const OUT_DIR = path.resolve(__dirname, '../screenshots');
const sleep = (ms) => new Promise((resolve) => setTimeout(resolve, ms));

async function run() {
  const browser = await chromium.launch({
    executablePath: '/Applications/Google Chrome.app/Contents/MacOS/Google Chrome',
    headless: true,
    args: ['--disable-web-security']
  });

  const page = await browser.newPage({
    viewport: { width: 412, height: 915 },
    deviceScaleFactor: 2
  });

  console.log('Navigating to https://honadosh.uz/app/ ...');
  await page.goto('https://honadosh.uz/app/', { waitUntil: 'domcontentloaded' });
  await page.waitForFunction(() => !document.getElementById('xd-boot'), { timeout: 25000 });
  await sleep(4000);

  // Skip onboarding
  await page.mouse.click(206, 865);
  await sleep(3500);

  // Click 3rd Tab: XonaDoshlar at bottom bar (approx x: 350, y: 875)
  console.log('Clicking XonaDoshlar tab...');
  await page.mouse.click(350, 875);
  await sleep(4000);

  // 1. Capture Navbatchilik (Tab 0)
  await page.screenshot({ path: path.join(OUT_DIR, 'xonadoshlar_01_navbatchilik.png') });
  console.log('✓ Saved xonadoshlar_01_navbatchilik.png');

  // 2. Click Subtab 1: Umumiy Kassa (approx x: 206, y: 55)
  console.log('Clicking Umumiy Kassa subtab...');
  await page.mouse.click(206, 55);
  await sleep(3000);
  await page.screenshot({ path: path.join(OUT_DIR, 'xonadoshlar_02_umumiy_kassa.png') });
  console.log('✓ Saved xonadoshlar_02_umumiy_kassa.png');

  // 3. Click Subtab 2: Oshxona & Bozor (approx x: 330, y: 55)
  console.log('Clicking Oshxona & Bozor subtab...');
  await page.mouse.click(330, 55);
  await sleep(3000);
  await page.screenshot({ path: path.join(OUT_DIR, 'xonadoshlar_03_oshxona_bozor.png') });
  console.log('✓ Saved xonadoshlar_03_oshxona_bozor.png');

  // 4. Click Quick Tool: Tezkor qo'shish (approx x: 340, y: 92)
  console.log('Clicking Tezkor qo‘shish pill...');
  await page.mouse.click(340, 92);
  await sleep(2500);
  await page.screenshot({ path: path.join(OUT_DIR, 'xonadoshlar_04_quick_add_sheet.png') });
  console.log('✓ Saved xonadoshlar_04_quick_add_sheet.png');

  await browser.close();
  console.log('All XonaDoshlar screens captured successfully!');
}

run().catch(err => {
  console.error(err);
  process.exit(1);
});
