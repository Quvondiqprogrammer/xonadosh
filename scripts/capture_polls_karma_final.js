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

  // 1. Capture Polls Modal
  {
    const page = await browser.newPage({
      viewport: { width: 412, height: 915 },
      deviceScaleFactor: 2
    });
    console.log('--- 1. Capturing Polls Modal ---');
    await page.goto('https://honadosh.uz/app/', { waitUntil: 'domcontentloaded' });
    await page.waitForFunction(() => !document.getElementById('xd-boot'), { timeout: 20000 });
    await sleep(3500);

    // Skip onboarding
    await page.mouse.click(206, 865);
    await sleep(3500);

    // Tab 2: Bizning uy
    await page.mouse.click(350, 875);
    await sleep(4500);

    // Scroll down 1100px
    await page.mouse.move(206, 500);
    await page.mouse.wheel(0, 1100);
    await sleep(2500);

    // Click Polls button at (105, 718)
    console.log('Clicking Polls button at (105, 718)...');
    await page.mouse.click(105, 718);
    await sleep(4000);

    await page.screenshot({ path: path.join(OUT_DIR, '23_coliving_polls_modal.png') });
    console.log('✓ Saved 23_coliving_polls_modal.png');
    await page.close();
  }

  // 2. Capture Karma Leaderboard Modal
  {
    const page = await browser.newPage({
      viewport: { width: 412, height: 915 },
      deviceScaleFactor: 2
    });
    console.log('--- 2. Capturing Karma Modal ---');
    await page.goto('https://honadosh.uz/app/', { waitUntil: 'domcontentloaded' });
    await page.waitForFunction(() => !document.getElementById('xd-boot'), { timeout: 20000 });
    await sleep(3500);

    // Skip onboarding
    await page.mouse.click(206, 865);
    await sleep(3500);

    // Tab 2: Bizning uy
    await page.mouse.click(350, 875);
    await sleep(4500);

    // Scroll down 1100px
    await page.mouse.move(206, 500);
    await page.mouse.wheel(0, 1100);
    await sleep(2500);

    // Click Karma button at (305, 718)
    console.log('Clicking Karma button at (305, 718)...');
    await page.mouse.click(305, 718);
    await sleep(4000);

    await page.screenshot({ path: path.join(OUT_DIR, '24_coliving_karma_leaderboard.png') });
    console.log('✓ Saved 24_coliving_karma_leaderboard.png');
    await page.close();
  }

  await browser.close();
  console.log('All done!');
}

run().catch((err) => {
  console.error(err);
  process.exit(1);
});
