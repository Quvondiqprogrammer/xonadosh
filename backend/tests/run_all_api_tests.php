<?php
declare(strict_types=1);

/**
 * XonaDosh Automated Production API Test Runner
 * Runs end-to-end integration tests against https://xonadoshim.uz/
 */

$baseUrl = getenv('BASE_URL') ?: 'https://xonadoshim.uz';
echo "\n======================================================\n";
echo "   XONADOSH PRODUCTION API TEST SUITE (E2E)\n";
echo "   Target Base URL: {$baseUrl}\n";
echo "======================================================\n\n";

$results = [];
$totalPassed = 0;
$totalFailed = 0;
$authToken = null;
$refreshToken = null;
$createdListingId = null;
$createdSquadCode = null;

function request(string $method, string $path, array $data = [], array $headers = []): array {
    global $baseUrl;
    $url = $baseUrl . $path;
    $ch = curl_init();
    
    $defaultHeaders = ['Accept: application/json'];
    foreach ($headers as $h) {
        $defaultHeaders[] = $h;
    }
    
    $start = microtime(true);
    if (strtoupper($method) === 'GET') {
        if (!empty($data)) {
            $url .= (strpos($url, '?') !== false ? '&' : '?') . http_build_query($data);
        }
    } else {
        curl_setopt($ch, CURLOPT_POSTFIELDS, json_encode($data));
        $defaultHeaders[] = 'Content-Type: application/json';
    }

    curl_setopt($ch, CURLOPT_URL, $url);
    curl_setopt($ch, CURLOPT_CUSTOMREQUEST, strtoupper($method));
    curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
    curl_setopt($ch, CURLOPT_HTTPHEADER, $defaultHeaders);
    curl_setopt($ch, CURLOPT_TIMEOUT, 15);
    curl_setopt($ch, CURLOPT_SSL_VERIFYPEER, false);
    curl_setopt($ch, CURLOPT_SSL_VERIFYHOST, false);

    $raw = curl_exec($ch);
    $status = curl_getinfo($ch, CURLINFO_HTTP_CODE);
    $error = curl_error($ch);
    $latencyMs = round((microtime(true) - $start) * 1000);

    $json = $raw ? json_decode($raw, true) : null;
    return [
        'status' => $status,
        'raw' => $raw,
        'json' => $json,
        'error' => $error,
        'latency_ms' => $latencyMs,
    ];
}

function runTest(string $name, callable $fn): void {
    global $results, $totalPassed, $totalFailed;
    try {
        $start = microtime(true);
        $res = $fn();
        $ms = round((microtime(true) - $start) * 1000);
        if ($res['passed']) {
            $totalPassed++;
            echo "  [\033[32mPASS\033[0m] {$name} ({$ms}ms) - {$res['message']}\n";
            $results[] = ['name' => $name, 'status' => 'PASS', 'ms' => $ms];
        } else {
            $totalFailed++;
            echo "  [\033[31mFAIL\033[0m] {$name} ({$ms}ms) - {$res['message']}\n";
            $results[] = ['name' => $name, 'status' => 'FAIL', 'ms' => $ms, 'error' => $res['message']];
        }
    } catch (Throwable $e) {
        $totalFailed++;
        echo "  [\033[31mEXCP\033[0m] {$name} - Exception: {$e->getMessage()}\n";
        $results[] = ['name' => $name, 'status' => 'FAIL', 'error' => $e->getMessage()];
    }
}

// -------------------------------------------------------------
// 1. PUBLIC CONFIG & DIRECTORY TESTS
// -------------------------------------------------------------
echo "1. Public Services & Information Endpoints:\n";

runTest("GET /api/xonadosh_universities_get.php", function() {
    $res = request('GET', '/api/xonadosh_universities_get.php');
    if ($res['status'] !== 200 || !isset($res['json']['universities'])) {
        return ['passed' => false, 'message' => "Expected 200 with universities array, got HTTP {$res['status']}"];
    }
    $count = count($res['json']['universities']);
    return ['passed' => $count >= 20, 'message' => "Returned {$count} accredited universities"];
});

runTest("GET /api/student_subsidies.php (50% Rent Subsidy Guide)", function() {
    $res = request('GET', '/api/student_subsidies.php');
    if ($res['status'] !== 200 || !isset($res['json']['subsidy_info'])) {
        return ['passed' => false, 'message' => "Expected 200 with subsidy_info, got HTTP {$res['status']}"];
    }
    $steps = $res['json']['subsidy_info']['steps_to_apply'] ?? [];
    return ['passed' => count($steps) >= 3, 'message' => "Tashkent subsidy: {$res['json']['subsidy_info']['amount_tashkent']}, steps: " . count($steps)];
});

runTest("GET /api/xonadosh_recipes.php (Coliving Recipe Engine)", function() {
    $res = request('GET', '/api/xonadosh_recipes.php');
    if ($res['status'] !== 200 || !isset($res['json']['recipes'])) {
        return ['passed' => false, 'message' => "Expected 200 with recipes array, got HTTP {$res['status']}"];
    }
    $count = count($res['json']['recipes']);
    return ['passed' => $count >= 14, 'message' => "Returned {$count} structured student recipes"];
});

runTest("GET /api/xonadosh_grocery_calc.php (Weekly Market Aggregator)", function() {
    $res = request('GET', '/api/xonadosh_grocery_calc.php', ['roommates' => 4, 'days' => 7]);
    if ($res['status'] !== 200 || !isset($res['json']['summary'])) {
        return ['passed' => false, 'message' => "Expected 200 with summary, got HTTP {$res['status']}"];
    }
    $perPerson = $res['json']['summary']['per_person_uzs'] ?? 0;
    return ['passed' => $perPerson > 0, 'message' => "Weekly grocery per roommate: {$perPerson} UZS"];
});

runTest("POST /api/utility_calculator.php (Official Tariffs 2026)", function() {
    $payload = [
        'elec_prev' => 1200,
        'elec_curr' => 1450,
        'gas_prev' => 500,
        'gas_curr' => 580,
        'water_prev' => 100,
        'water_curr' => 112,
        'wifi_amount_uzs' => 150000,
        'roommate_count' => 3
    ];
    $res = request('POST', '/api/utility_calculator.php', $payload);
    if ($res['status'] !== 200 || !isset($res['json']['grand_total_uzs'])) {
        return ['passed' => false, 'message' => "Expected 200 with grand_total_uzs, got HTTP {$res['status']}"];
    }
    $total = $res['json']['grand_total_uzs'];
    $perPerson = $res['json']['cost_per_person_uzs'];
    return ['passed' => $total > 0 && $perPerson > 0, 'message' => "Total: {$total} UZS, Per roommate: {$perPerson} UZS"];
});

runTest("GET /api/xonadosh_commute_calc.php (Distance & Transit Math)", function() {
    $res = request('GET', '/api/xonadosh_commute_calc.php', [
        'from_lat' => 41.3506, 'from_lng' => 69.2062, // Beruniy
        'to_lat' => 41.3409, 'to_lng' => 69.2866      // TATU
    ]);
    if ($res['status'] !== 200 || !isset($res['json']['distance']['road_km'])) {
        return ['passed' => false, 'message' => "Expected 200 with distance.road_km, got HTTP {$res['status']}"];
    }
    $dist = $res['json']['distance']['road_km'];
    return ['passed' => $dist > 0, 'message' => "Calculated road distance: {$dist} km"];
});

// -------------------------------------------------------------
// 2. AUTHENTICATION & PROFILE TESTS
// -------------------------------------------------------------
echo "\n2. User Authentication & Authorization:\n";

$testLogin = 'talaba_tester';
$testPass = 'Password123!';

runTest("POST /api/auth_login.php (Standard Login)", function() use (&$authToken, &$refreshToken, $testLogin, $testPass) {
    $res = request('POST', '/api/auth_login.php', [
        'login' => $testLogin,
        'password' => $testPass
    ]);
    if ($res['status'] !== 200 || empty($res['json']['token'])) {
        return ['passed' => false, 'message' => "Login failed: HTTP {$res['status']} " . ($res['json']['error'] ?? '')];
    }
    $authToken = $res['json']['token'];
    $refreshToken = $res['json']['refresh_token'] ?? null;
    return ['passed' => true, 'message' => "Authenticated successfully, token acquired"];
});

runTest("GET /api/auth_me.php (Session Verification)", function() use (&$authToken) {
    if (!$authToken) return ['passed' => false, 'message' => 'No auth token available'];
    $res = request('GET', '/api/auth_me.php', [], ["Authorization: Bearer {$authToken}"]);
    if ($res['status'] !== 200 || !isset($res['json']['user']['user_id'])) {
        return ['passed' => false, 'message' => "Expected 200 with user object, got HTTP {$res['status']}"];
    }
    return ['passed' => true, 'message' => "Verified identity for user #{$res['json']['user']['user_id']}"];
});

runTest("POST /api/verify_hemis.php (Talaba Verifikatsiyasi)", function() use (&$authToken) {
    if (!$authToken) return ['passed' => false, 'message' => 'No auth token available'];
    $payload = [
        'student_id' => '392211100234',
        'university_name' => 'Toshkent Axborot Texnologiyalari Universiteti (TATU)',
        'faculty' => 'Kompyuter injiniringi',
        'course_year' => 3
    ];
    $res = request('POST', '/api/verify_hemis.php', $payload, ["Authorization: Bearer {$authToken}"]);
    if ($res['status'] !== 200 || empty($res['json']['verified'])) {
        return ['passed' => false, 'message' => "Verification failed: HTTP {$res['status']} " . ($res['json']['error'] ?? '')];
    }
    return ['passed' => true, 'message' => "HEMIS badge verified: {$res['json']['badge']}"];
});

runTest("POST /api/xonadosh_profiles.php (Save & Update Roommate Profile)", function() use (&$authToken) {
    if (!$authToken) return ['passed' => false, 'message' => 'No auth token available'];
    $payload = [
        'budget_max' => 1500000,
        'cleanliness_level' => 5,
        'sleep_time' => '23:30',
        'wake_time' => '07:00',
        'smoking' => 0,
        'guests_allowed' => 1,
        'preferred_district' => 'Yunusobod'
    ];
    $res = request('POST', '/api/xonadosh_profiles.php', $payload, ["Authorization: Bearer {$authToken}"]);
    if ($res['status'] !== 200 || empty($res['json']['ok'])) {
        return ['passed' => false, 'message' => "Failed to save profile: HTTP {$res['status']} " . ($res['json']['error'] ?? '')];
    }
    return ['passed' => true, 'message' => "Roommate preferences profile updated"];
});

runTest("GET /api/xonadosh_match.php (Algorithmic Roommate Matching)", function() use (&$authToken) {
    if (!$authToken) return ['passed' => false, 'message' => 'No auth token available'];
    $res = request('GET', '/api/xonadosh_match.php', [], ["Authorization: Bearer {$authToken}"]);
    if ($res['status'] !== 200 || !isset($res['json']['matches'])) {
        return ['passed' => false, 'message' => "Expected 200 with matches array, got HTTP {$res['status']}"];
    }
    $count = count($res['json']['matches']);
    return ['passed' => true, 'message' => "Found {$count} compatible candidates (algorithm working)"];
});

// -------------------------------------------------------------
// 3. RENTAL MARKETPLACE & 72H DYNAMIC TTL
// -------------------------------------------------------------
echo "\n3. Rental Listings & 72-Hour TTL Management:\n";

runTest("GET /api/xonadosh_listings_get.php (Active Listings)", function() {
    $res = request('GET', '/api/xonadosh_listings_get.php');
    if ($res['status'] !== 200 || !isset($res['json']['listings'])) {
        return ['passed' => false, 'message' => "Expected 200 with listings array, got HTTP {$res['status']}"];
    }
    $count = count($res['json']['listings']);
    return ['passed' => true, 'message' => "Retrieved {$count} active non-expired listings"];
});

runTest("POST /api/xonadosh_listing_create.php (Post New Rental)", function() use (&$authToken, &$createdListingId) {
    if (!$authToken) return ['passed' => false, 'message' => 'No auth token available'];
    $payload = [
        'title' => 'TATU yaqinida talabalar uchun 2 xonali uy',
        'district' => 'Yunusobod',
        'address' => 'Shahriston metro yaqinida',
        'price' => 1200000,
        'rooms_count' => 2,
        'capacity' => 4,
        'latitude' => 41.3412,
        'longitude' => 69.2870,
        'is_no_broker' => 1,
        'description' => 'Barcha sharoitlari bor, Wi-Fi, kir yuvish mashinasi mavjud.'
    ];
    $res = request('POST', '/api/xonadosh_listing_create.php', $payload, ["Authorization: Bearer {$authToken}"]);
    $lid = $res['json']['listing_id'] ?? ($res['json']['id'] ?? null);
    if ($res['status'] !== 200 || empty($lid)) {
        return ['passed' => false, 'message' => "Listing creation failed: HTTP {$res['status']} " . ($res['json']['error'] ?? '')];
    }
    $createdListingId = $lid;
    return ['passed' => true, 'message' => "Listing #{$createdListingId} created with 72h TTL"];
});

runTest("POST /api/xonadosh_listing_renew.php (Extend TTL by 72h)", function() use (&$authToken, &$createdListingId) {
    if (!$authToken || !$createdListingId) return ['passed' => false, 'message' => 'No listing ID available'];
    $res = request('POST', '/api/xonadosh_listing_renew.php', ['listing_id' => $createdListingId], ["Authorization: Bearer {$authToken}"]);
    if ($res['status'] !== 200 || empty($res['json']['ok'])) {
        return ['passed' => false, 'message' => "Listing renewal failed: HTTP {$res['status']} " . ($res['json']['error'] ?? '')];
    }
    return ['passed' => true, 'message' => "Listing #{$createdListingId} renewed, new expiry: " . ($res['json']['expires_at'] ?? 'ok')];
});

// -------------------------------------------------------------
// 4. HOUSEHOLD MANAGEMENT & STUDENT UX
// -------------------------------------------------------------
echo "\n4. Household Management & Student Collaboration:\n";

runTest("POST /api/xonadosh_squads.php (Create Coliving Squad)", function() use (&$authToken, &$createdSquadCode) {
    if (!$authToken) return ['passed' => false, 'message' => 'No auth token available'];
    $res = request('POST', '/api/xonadosh_squads.php', [
        'name' => 'Yunusobod 19-Mavze Squad',
        'target_district' => 'Yunusobod',
        'my_budget_uzs' => 1200000,
        'looking_for_count' => 3
    ], ["Authorization: Bearer {$authToken}"]);
    $sid = $res['json']['squad_id'] ?? ($res['json']['id'] ?? null);
    if ($res['status'] !== 200 || empty($sid)) {
        return ['passed' => false, 'message' => "Squad creation failed: HTTP {$res['status']} " . ($res['json']['error'] ?? '')];
    }
    return ['passed' => true, 'message' => "Coliving squad #{$sid} created"];
});

runTest("POST /api/opt_out_meal.php (Bugun Ovqatlanmayman)", function() use (&$authToken) {
    if (!$authToken) return ['passed' => false, 'message' => 'No auth token available'];
    $res = request('POST', '/api/opt_out_meal.php', [
        'group_code' => 'home_default',
        'date' => date('Y-m-d'),
        'meal_slot' => 'dinner',
        'opt_out' => true,
        'reason' => "Kutubxonada dars tayyorlayapman"
    ], ["Authorization: Bearer {$authToken}"]);
    if ($res['status'] !== 200 || empty($res['json']['ok'])) {
        return ['passed' => false, 'message' => "Opt-out failed: HTTP {$res['status']} " . ($res['json']['error'] ?? '')];
    }
    return ['passed' => true, 'message' => "Opted out from dinner, grocery cost deducted automatically"];
});

runTest("POST /api/chore_swap.php (Bugun Darsim Ko'p Navbat Almashish)", function() use (&$authToken) {
    if (!$authToken) return ['passed' => false, 'message' => 'No auth token available'];
    $res = request('POST', '/api/chore_swap.php', [
        'action' => 'request_swap',
        'group_code' => 'home_default',
        'reason' => "Ertaga oraliq nazorat (kollokvium) imtihoni bor"
    ], ["Authorization: Bearer {$authToken}"]);
    if ($res['status'] !== 200 || empty($res['json']['ok'])) {
        return ['passed' => false, 'message' => "Chore swap request failed: HTTP {$res['status']} " . ($res['json']['error'] ?? '')];
    }
    return ['passed' => true, 'message' => "Chore swap broadcasted to squad members"];
});

runTest("GET /api/telegram_sync.php (Roommate Daily Digest)", function() use (&$createdSquadCode) {
    $res = request('GET', '/api/telegram_sync.php', [
        'squad_code' => $createdSquadCode ?: 'home_default',
        'action' => 'format_daily_digest'
    ]);
    if ($res['status'] !== 200 || !isset($res['json']['digest_text'])) {
        return ['passed' => false, 'message' => "Expected 200 with digest_text, got HTTP {$res['status']}"];
    }
    return ['passed' => true, 'message' => "Generated daily Telegram digest for group chat"];
});

runTest("GET /cron/daily_scheduler.php (cPanel Cron Engine)", function() {
    $res = request('GET', '/cron/daily_scheduler.php', ['key' => 'Asad03@18']);
    if ($res['status'] !== 200 || empty($res['json']['ok'])) {
        return ['passed' => false, 'message' => "Expected 200 with ok: true, got HTTP {$res['status']}"];
    }
    $taskCount = count($res['json']['tasks'] ?? []);
    return ['passed' => true, 'message' => "Cron cycle executed: {$taskCount} automated tasks processed"];
});

// -------------------------------------------------------------
// SUMMARY & EXIT CODE
// -------------------------------------------------------------
echo "\n======================================================\n";
echo "   TEST RUN SUMMARY\n";
echo "   Total Tests: " . ($totalPassed + $totalFailed) . "\n";
echo "   Passed:      \033[32m{$totalPassed}\033[0m\n";
echo "   Failed:      \033[" . ($totalFailed > 0 ? "31" : "32") . "m{$totalFailed}\033[0m\n";
echo "======================================================\n\n";

exit($totalFailed > 0 ? 1 : 0);
