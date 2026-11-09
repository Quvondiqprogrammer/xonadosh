const { chromium } = require('playwright');
const path = require('path');
const fs = require('fs');

const OUT_DIR = path.resolve(__dirname, '../screenshots');
if (!fs.existsSync(OUT_DIR)) {
  fs.mkdirSync(OUT_DIR, { recursive: true });
}

const sleep = (ms) => new Promise((resolve) => setTimeout(resolve, ms));

async function main() {
  console.log('=== XonaDosh End-to-End Master Screenshot Capture ===');
  console.log('Target directory:', OUT_DIR);

  const browser = await chromium.launch({
    executablePath: '/Applications/Google Chrome.app/Contents/MacOS/Google Chrome',
    headless: true,
    args: ['--disable-web-security']
  });

  const context = await browser.newContext({
    viewport: { width: 412, height: 915 },
    deviceScaleFactor: 2,
    userAgent: 'Mozilla/5.0 (Linux; Android 14; Pixel 7 Pro) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Mobile Safari/537.36 XonaDoshApp/1.0'
  });

  const page = await context.newPage();

  // ==========================================
  // 1. WEB LANDING SCREENSHOTS
  // ==========================================
  console.log('\n--- 1. Web Landing Page ---');
  await page.goto('https://honadosh.uz/', { waitUntil: 'networkidle' });
  await sleep(2000);

  // 01: Hero
  await page.screenshot({ path: path.join(OUT_DIR, '01_web_landing_hero.png') });
  console.log('✓ 01_web_landing_hero.png');

  // 02: How it works (scroll 650px)
  await page.evaluate(() => window.scrollTo({ top: 680, behavior: 'instant' }));
  await sleep(1500);
  await page.screenshot({ path: path.join(OUT_DIR, '02_web_landing_how_it_works.png') });
  console.log('✓ 02_web_landing_how_it_works.png');

  // 03: Features & Stats (scroll 1450px)
  await page.evaluate(() => window.scrollTo({ top: 1450, behavior: 'instant' }));
  await sleep(1500);
  await page.screenshot({ path: path.join(OUT_DIR, '03_web_landing_features_stats.png') });
  console.log('✓ 03_web_landing_features_stats.png');

  // ==========================================
  // 2. FIRST-RUN ONBOARDING (APP)
  // ==========================================
  console.log('\n--- 2. App First-Run Onboarding ---');
  await page.goto('https://honadosh.uz/app/', { waitUntil: 'domcontentloaded' });
  await page.waitForFunction(() => !document.getElementById('xd-boot'), { timeout: 25000 });
  await sleep(3500);

  // 04: Onboarding Screen
  await page.screenshot({ path: path.join(OUT_DIR, '04_onboarding_otm_picker.png') });
  console.log('✓ 04_onboarding_otm_picker.png');

  // Click 'TATU' chip (x=115, y=345)
  console.log('Selecting TATU chip...');
  await page.mouse.click(115, 345);
  await sleep(800);

  // Click 'Uylarni ko\'rish →' button (x=206, y=865)
  console.log('Navigating into Shell...');
  await page.mouse.click(206, 865);
  await sleep(4000);

  // ==========================================
  // 3. HOUSING FEED & FILTERS
  // ==========================================
  console.log('\n--- 3. Housing Feed & Modals ---');
  // 05: Housing Feed Main
  await page.screenshot({ path: path.join(OUT_DIR, '05_housing_feed_main.png') });
  console.log('✓ 05_housing_feed_main.png');

  // 06: Smart chips active: Click Maklersiz (x=80, y=210) and Kommunal ichida (x=180, y=210)
  await page.mouse.click(80, 210);
  await sleep(600);
  await page.mouse.click(180, 210);
  await sleep(1500);
  await page.screenshot({ path: path.join(OUT_DIR, '06_housing_smart_chips_active.png') });
  console.log('✓ 06_housing_smart_chips_active.png');

  // 07: OTM Picker Sheet (click x=150, y=95)
  await page.mouse.click(150, 95);
  await sleep(2500);
  await page.screenshot({ path: path.join(OUT_DIR, '07_housing_otm_picker_sheet.png') });
  console.log('✓ 07_housing_otm_picker_sheet.png');
  // Dismiss sheet by tapping backdrop or close
  await page.mouse.click(206, 120);
  await sleep(1500);

  // 08: Housing Filter Sheet (click filter icon at x=380, y=155)
  await page.mouse.click(380, 155);
  await sleep(2500);
  await page.screenshot({ path: path.join(OUT_DIR, '08_housing_filter_sheet.png') });
  console.log('✓ 08_housing_filter_sheet.png');
  // Dismiss filter sheet
  await page.mouse.click(206, 120);
  await sleep(1500);

  // ==========================================
  // 4. LISTING DETAIL SCREEN
  // ==========================================
  console.log('\n--- 4. Listing Detail Screen ---');
  // Click first listing card (x=206, y=380)
  await page.mouse.click(206, 380);
  await sleep(3500);

  // 09: Listing detail hero & commute
  await page.screenshot({ path: path.join(OUT_DIR, '09_listing_detail_hero_commute.png') });
  console.log('✓ 09_listing_detail_hero_commute.png');

  // 10: Scroll down for amenities and host
  await page.mouse.move(206, 500);
  await page.mouse.wheel(0, 500);
  await sleep(2000);
  await page.screenshot({ path: path.join(OUT_DIR, '10_listing_detail_amenities_desc.png') });
  console.log('✓ 10_listing_detail_amenities_desc.png');

  // Go back to Shell (click back button at x=35, y=35)
  await page.mouse.click(35, 35);
  await sleep(2500);

  // ==========================================
  // 5. MAP SCREEN
  // ==========================================
  console.log('\n--- 5. Interactive Map Screen ---');
  // Click Xarita button (x=340, y=95)
  await page.mouse.click(340, 95);
  await sleep(4000);

  // 11: Interactive Map
  await page.screenshot({ path: path.join(OUT_DIR, '11_map_screen_interactive.png') });
  console.log('✓ 11_map_screen_interactive.png');

  // Go back to Shell (click back button at x=35, y=35)
  await page.mouse.click(35, 35);
  await sleep(2500);

  // ==========================================
  // 6. LAZY AUTH & REGISTRATION
  // ==========================================
  console.log('\n--- 6. Lazy Auth & Registration ---');
  // Click FAB to trigger Lazy Auth (x=330, y=805)
  await page.mouse.click(330, 805);
  await sleep(2500);

  // 25: Auth Login Modal
  await page.screenshot({ path: path.join(OUT_DIR, '25_auth_login_modal.png') });
  console.log('✓ 25_auth_login_modal.png');

  // Click "Ro'yxatdan o'tish" at bottom (x=200, y=690)
  await page.mouse.click(200, 690);
  await sleep(2500);

  // 26: Auth Register Screen
  await page.screenshot({ path: path.join(OUT_DIR, '26_auth_register_screen.png') });
  console.log('✓ 26_auth_register_screen.png');

  // Dismiss modal (click [X] at x=370, y=225)
  await page.mouse.click(370, 225);
  await sleep(1500);

  // ==========================================
  // 7. LOGIN & AUTHENTICATED ACTIONS
  // ==========================================
  console.log('\n--- 7. Logging in as real user ---');
  // Click Settings icon to open login modal (x=380, y=30)
  await page.mouse.click(380, 30);
  await sleep(2500);

  // Focus login at (200, 510) and type username
  await page.mouse.click(200, 510);
  await sleep(300);
  await page.keyboard.type('talaba_demo_2026');
  await sleep(300);

  // Focus password at (200, 570) and type password
  await page.mouse.click(200, 570);
  await sleep(300);
  await page.keyboard.type('DemoPassword2026!');
  await sleep(300);

  // Click Kirish button at (200, 630)
  await page.mouse.click(200, 630);
  await sleep(4000);

  // 27: Settings Screen (click Settings icon at x=380, y=30)
  console.log('Opening Settings Screen...');
  await page.mouse.click(380, 30);
  await sleep(3000);
  await page.screenshot({ path: path.join(OUT_DIR, '27_settings_screen.png') });
  console.log('✓ 27_settings_screen.png');

  // Go back to Shell (click back at x=35, y=35)
  await page.mouse.click(35, 35);
  await sleep(2500);

  // ==========================================
  // 8. CREATE LISTING (3 STEPS)
  // ==========================================
  console.log('\n--- 8. Create Listing Flow ---');
  // Click FAB (x=330, y=805)
  await page.mouse.click(330, 805);
  await sleep(3500);

  // 12: Step 1 (Location & Photos)
  await page.screenshot({ path: path.join(OUT_DIR, '12_create_listing_step1_location.png') });
  console.log('✓ 12_create_listing_step1_location.png');

  // Click "Davom etish →" button (at bottom: x=206, y=880)
  await page.mouse.click(206, 880);
  await sleep(2500);

  // 13: Step 2 (Pricing & Amenities)
  await page.screenshot({ path: path.join(OUT_DIR, '13_create_listing_step2_pricing.png') });
  console.log('✓ 13_create_listing_step2_pricing.png');

  // Click "Davom etish →" button
  await page.mouse.click(206, 880);
  await sleep(2500);

  // 14: Step 3 (Description & Publish)
  await page.screenshot({ path: path.join(OUT_DIR, '14_create_listing_step3_publish.png') });
  console.log('✓ 14_create_listing_step3_publish.png');

  // Go back to Shell (click back button at x=35, y=35)
  await page.mouse.click(35, 35);
  await sleep(1500);
  await page.mouse.click(35, 35);
  await sleep(1500);
  await page.mouse.click(35, 35);
  await sleep(2500);

  // ==========================================
  // 9. PROFILE & QUESTIONNAIRE
  // ==========================================
  console.log('\n--- 9. Profile & Questionnaire ---');
  // Click Profile Avatar at AppBar (x=340, y=30)
  await page.mouse.click(340, 30);
  await sleep(3500);

  // 17: Profile Edit Personal
  await page.screenshot({ path: path.join(OUT_DIR, '17_profile_edit_personal.png') });
  console.log('✓ 17_profile_edit_personal.png');

  // Click 'Odatlar' tab (x=240, y=95)
  await page.mouse.click(240, 95);
  await sleep(2500);

  // 18: Profile Edit Lifestyle Habits
  await page.screenshot({ path: path.join(OUT_DIR, '18_profile_edit_lifestyle_habits.png') });
  console.log('✓ 18_profile_edit_lifestyle_habits.png');

  // Go back to Shell (click back at x=35, y=35)
  await page.mouse.click(35, 35);
  await sleep(2500);

  // ==========================================
  // 10. ROOMMATE MATCHING (TAB 1)
  // ==========================================
  console.log('\n--- 10. Matching Tab ---');
  // Click Tab 1: Sherik topish (x=206, y=875)
  await page.mouse.click(206, 875);
  await sleep(3500);

  // 15: Matching candidates feed
  await page.screenshot({ path: path.join(OUT_DIR, '15_matching_tab_candidates.png') });
  console.log('✓ 15_matching_tab_candidates.png');

  // 16: Click Tanishish button on candidate card (x=280, y=860)
  await page.mouse.click(280, 860);
  await sleep(3000);
  await page.screenshot({ path: path.join(OUT_DIR, '16_matching_roommate_detail_sheet.png') });
  console.log('✓ 16_matching_roommate_detail_sheet.png');
  // Dismiss modal
  await page.mouse.click(206, 120);
  await sleep(1500);

  // ==========================================
  // 11. COLIVING HUB (TAB 2)
  // ==========================================
  console.log('\n--- 11. Coliving Hub ---');
  // Click Tab 2: Bizning uy (x=330, y=875)
  await page.mouse.click(330, 875);
  await sleep(3500);

  // 19: Duty & House (Segment 0)
  await page.screenshot({ path: path.join(OUT_DIR, '19_coliving_duty_house.png') });
  console.log('✓ 19_coliving_duty_house.png');

  // 23: Polls Modal (scroll down a bit, then click Polls button)
  await page.mouse.move(206, 500);
  await page.mouse.wheel(0, 300);
  await sleep(1500);
  // Click "Ovoz berish (Polls)" button
  await page.mouse.click(105, 540);
  await sleep(2500);
  await page.screenshot({ path: path.join(OUT_DIR, '23_coliving_polls_modal.png') });
  console.log('✓ 23_coliving_polls_modal.png');
  // Dismiss polls modal
  await page.mouse.click(206, 120);
  await sleep(1500);

  // 24: Karma Modal (click Xonadosh Karma button)
  await page.mouse.click(305, 540);
  await sleep(2500);
  await page.screenshot({ path: path.join(OUT_DIR, '24_coliving_karma_leaderboard.png') });
  console.log('✓ 24_coliving_karma_leaderboard.png');
  // Dismiss karma modal
  await page.mouse.click(206, 120);
  await sleep(1500);

  // Scroll back to top of tab
  await page.mouse.wheel(0, -500);
  await sleep(1000);

  // 20: Segment 1 (Umumiy Kassa / Splitwise) at x=210, y=235
  await page.mouse.click(210, 235);
  await sleep(3000);
  await page.screenshot({ path: path.join(OUT_DIR, '20_coliving_general_cash_splitwise.png') });
  console.log('✓ 20_coliving_general_cash_splitwise.png');

  // 21: Segment 2 (Oshxona & Bozor) at x=320, y=235
  await page.mouse.click(320, 235);
  await sleep(3000);
  await page.screenshot({ path: path.join(OUT_DIR, '21_coliving_kitchen_recipes.png') });
  console.log('✓ 21_coliving_kitchen_recipes.png');

  // 22: Scroll down in Oshxona & Bozor for grocery market prices
  await page.mouse.move(206, 500);
  await page.mouse.wheel(0, 500);
  await sleep(2000);
  await page.screenshot({ path: path.join(OUT_DIR, '22_coliving_grocery_bazaar.png') });
  console.log('✓ 22_coliving_grocery_bazaar.png');

  console.log('\n=== All 27 Screenshots Successfully Captured! ===');
  await browser.close();
}

main().catch((err) => {
  console.error('Fatal error during capture:', err);
  process.exit(1);
});
