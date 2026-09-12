<?php
declare(strict_types=1);

/**
 * API: AI Roommate Compatibility Matchmaker
 */

require_once dirname(__DIR__) . '/includes/bootstrap.php';
require_once dirname(__DIR__) . '/includes/db.php';
require_once dirname(__DIR__) . '/includes/auth_lib.php';

try {
    $pdo = db_connect($cfg);
} catch (Throwable $e) {
    json_response(['ok' => false, 'error' => 'Database connection failed'], 500);
}

$user = auth_require_token($pdo);
$myUsername = (string) $user['username'];
$uniFromGet = isset($_GET['university_id']) ? (int)$_GET['university_id'] : 0;
$myUniId = $uniFromGet > 0 ? $uniFromGet : null;

$genderRaw = isset($_GET['gender']) ? strtolower(trim((string)$_GET['gender'])) : '';
$genderAliases = [
    'boys' => 'male',
    'male' => 'male',
    'girls' => 'female',
    'female' => 'female',
];
$explicitGender = $genderAliases[$genderRaw] ?? null;
$wantAnyGender = ($genderRaw === '' || $genderRaw === 'any' || $genderRaw === 'all');
$myGender = $explicitGender ?? 'male';

$mySleep = isset($_GET['sleep_schedule']) ? trim($_GET['sleep_schedule']) : 'flexible';
$myClean = isset($_GET['cleanliness']) ? trim($_GET['cleanliness']) : 'strict';
$myStudy = isset($_GET['study_habit']) ? trim($_GET['study_habit']) : 'silent';
$myCook = isset($_GET['cooking_habit']) ? trim($_GET['cooking_habit']) : 'rotates';
$mySmoke = isset($_GET['smoking_habit']) ? trim($_GET['smoking_habit']) : 'no';
$myBudgetMin = isset($_GET['budget_min']) ? (float)$_GET['budget_min'] : 500000.0;
$myBudgetMax = isset($_GET['budget_max']) ? (float)$_GET['budget_max'] : 1200000.0;

$allowedLangs = ['uz', 'ru', 'en', 'kaa', 'kk', 'tg', 'tk'];
$lang = isset($_GET['lang']) ? strtolower(trim((string)$_GET['lang'])) : 'uz';
if (!in_array($lang, $allowedLangs, true)) {
    $lang = 'uz';
}

function get_match_reason($key, $lang = 'uz', $arg = '') {
    $dict = [
        'sleep_early' => [
            'uz' => 'Uyqu tartibi 100% mos (Erta turuvchilar)',
            'ru' => 'Режим сна 100% совпадает (Ранний подъем)',
            'en' => 'Sleep schedule 100% matches (Early birds)',
            'kaa' => 'Uyqı tártibi 100% sáykes (Erte turıwshılar)',
            'kk' => 'Ұйқы тәртібі 100% сәйкес (Ерте тұратындар)',
            'tg' => 'Реҷаи хоб 100% мувофиқат мекунад (Барвақтхезҳо)',
            'tk' => 'Uky tertibi 100% gabat gelýär (Ir turýanlar)',
        ],
        'sleep_night' => [
            'uz' => 'Uyqu tartibi 100% mos (Tungi ijodkorlar)',
            'ru' => 'Режим сна 100% совпадает (Ночная сова)',
            'en' => 'Sleep schedule 100% matches (Night owls)',
            'kaa' => 'Uyqı tártibi 100% sáykes (Túngiler)',
            'kk' => 'Ұйқы тәртібі 100% сәйкес (Түнгі)',
            'tg' => 'Реҷаи хоб 100% мувофиқат мекунад (Шабона)',
            'tk' => 'Uky tertibi 100% gabat gelýär (Gijeki)',
        ],
        'sleep_flex' => [
            'uz' => 'Uyqu tartibi 100% mos (Moslashuvchan)',
            'ru' => 'Режим сна 100% совпадает (Гибкий)',
            'en' => 'Sleep schedule 100% matches (Flexible)',
            'kaa' => 'Uyqı tártibi 100% sáykes (Beyimlesiwshi)',
            'kk' => 'Ұйқы тәртібі 100% сәйкес (Икемді)',
            'tg' => 'Реҷаи хоб 100% мувофиқат мекунад (Озод)',
            'tk' => 'Uky tertibi 100% gabat gelýär (Erkin)',
        ],
        'clean_strict' => [
            'uz' => 'Tozalik va tartib talabi bir xil (Yuqori tozalik)',
            'ru' => 'Требования к чистоте совпадают (Очень чистоплотный)',
            'en' => 'Cleanliness standards match (High neatness)',
            'kaa' => 'Tazalıq hám tártip talabı birdey (Joqarı tazalıq)',
            'kk' => 'Тазалық талабы бірдей (Өте ұқыпты)',
            'tg' => 'Талаботи тозагӣ якхела аст (Хеле ботартиб)',
            'tk' => 'Arassalyk talaplary bir meňzeş (Gaty tertipli)',
        ],
        'clean_mod' => [
            'uz' => 'Tozalik va tartib talabi bir xil (O‘rtacha)',
            'ru' => 'Требования к чистоте совпадают (Умеренно)',
            'en' => 'Cleanliness standards match (Moderate)',
            'kaa' => 'Tazalıq hám tártip talabı birdey (Ortasha)',
            'kk' => 'Тазалық талабы бірдей (Орташа)',
            'tg' => 'Талаботи тозагӣ якхела аст (Миёна)',
            'tk' => 'Arassalyk talaplary bir meňzeş (Ortaça)',
        ],
        'study_silent' => [
            'uz' => 'Dars qilish atmosferasi mos (Sokin va tinch muhit)',
            'ru' => 'Атмосфера для учебы совпадает (В тишине)',
            'en' => 'Study atmosphere matches (Quiet & calm)',
            'kaa' => 'Sabaq tayarlaw atmosferası sáykes (Tınısh orın)',
            'kk' => 'Оқу атмосферасы сәйкес (Тыныш орта)',
            'tg' => 'Фазои дарс мувофиқ аст (Муҳити ором)',
            'tk' => 'Okuw şerti gabat gelýär (Asuda gurşaw)',
        ],
        'study_group' => [
            'uz' => 'Dars qilish atmosferasi mos (Birga muhokama qilish)',
            'ru' => 'Атмосфера для учебы совпадает (В группе)',
            'en' => 'Study atmosphere matches (Group study)',
            'kaa' => 'Sabaq tayarlaw atmosferası sáykes (Birge tallaw)',
            'kk' => 'Оқу атмосферасы сәйкес (Бірге талқылау)',
            'tg' => 'Фазои дарс мувофиқ аст (Дар гурӯҳ)',
            'tk' => 'Okuw şerti gabat gelýär (Topar bilen)',
        ],
        'budget_exact' => [
            'uz' => 'Ijara byudjeti to‘liq mos keladi',
            'ru' => 'Бюджет аренды полностью совпадает',
            'en' => 'Rental budget matches completely',
            'kaa' => 'Ijara byudjeti tolıq sáykes keledi',
            'kk' => 'Жалдау бюджеті толық сәйкес келеді',
            'tg' => 'Бюҷети иҷора пурра мувофиқат мекунад',
            'tk' => 'Kireýne býujeti doly gabat gelýär',
        ],
        'no_smoking' => [
            'uz' => 'Zararli odatlardan xoli (Chekmaydi)',
            'ru' => 'Без вредных привычек (Не курит)',
            'en' => 'No bad habits (Non-smoker)',
            'kaa' => 'Zıyanlı ádetlerden awlaq (Shekpeydi)',
            'kk' => 'Жаман әдеттерден аулақ (Шекпейді)',
            'tg' => 'Бе одатҳои бад (Тамоку намекашад)',
            'tk' => 'Zyýanly endiklerden daşda (Çekmeýär)',
        ],
        'study_music' => [
            'uz' => 'Dars qilish atmosferasi mos (Quloqchin / musiqa)',
            'ru' => 'Атмосфера для учебы совпадает (Наушники / музыка)',
            'en' => 'Study atmosphere matches (Headphones / music)',
            'kaa' => 'Sabaq tayarlaw atmosferası sáykes (Qulaqshın / muzıka)',
            'kk' => 'Оқу атмосферасы сәйкес (Құлаққап / музыка)',
            'tg' => 'Фазои дарс мувофиқ аст (Гӯшак / мусиқӣ)',
            'tk' => 'Okuw şerti gabat gelýär (Gulaklyk / aýdym)',
        ],
        'same_uni' => [
            'uz' => "Bitta OTM talabasi ($arg)",
            'ru' => "Студент того же вуза ($arg)",
            'en' => "Student of the same university ($arg)",
            'kaa' => "Bir JOO studenti ($arg)",
            'kk' => "Бір ЖОО студенті ($arg)",
            'tg' => "Донишҷӯи як донишгоҳ ($arg)",
            'tk' => "Şol bir ÝOK talyby ($arg)",
        ]
    ];
    return $dict[$key][$lang] ?? ($dict[$key]['uz'] ?? '');
}

function get_compat_level(int $pct, string $lang): string {
    $tier = $pct >= 90 ? 'ideal' : ($pct >= 75 ? 'high' : 'good');
    $dict = [
        'ideal' => [
            'uz' => 'Ideal moslik', 'ru' => 'Идеальное совпадение', 'en' => 'Ideal match',
            'kaa' => 'Ideal sáykeslik', 'kk' => 'Идеал сәйкестік', 'tg' => 'Мутобиқати беҳтарин', 'tk' => 'Ideal gabat',
        ],
        'high' => [
            'uz' => 'Yuqori moslik', 'ru' => 'Высокое совпадение', 'en' => 'High match',
            'kaa' => 'Joqarı sáykeslik', 'kk' => 'Жоғары сәйкестік', 'tg' => 'Мутобиқати баланд', 'tk' => 'Ýokary gabat',
        ],
        'good' => [
            'uz' => 'Yaxshi moslik', 'ru' => 'Хорошее совпадение', 'en' => 'Good match',
            'kaa' => 'Jaqsı sáykeslik', 'kk' => 'Жақсы сәйкестік', 'tg' => 'Мутобиқати хуб', 'tk' => 'Gowy gabat',
        ],
    ];
    return $dict[$tier][$lang] ?? $dict[$tier]['uz'];
}


$my = null;
// Try to fetch my saved profile from DB if username is provided
if ($myUsername) {
    $myStmt = $pdo->prepare("SELECT * FROM `xonadosh_profiles` WHERE username = ? LIMIT 1");
    $myStmt->execute([$myUsername]);
    $my = $myStmt->fetch(PDO::FETCH_ASSOC);
    if ($my) {
        if ($uniFromGet <= 0 && $my['university_id'] !== null) {
            $myUniId = (int)$my['university_id'];
        }
        if ($wantAnyGender) {
            $myGender = $my['gender'] ?? $myGender;
        }
        $mySleep = $my['sleep_schedule'] ?? $mySleep;
        $myClean = $my['cleanliness'] ?? $myClean;
        $myStudy = $my['study_habit'] ?? $myStudy;
        $myCook = $my['cooking_habit'] ?? $myCook;
        $mySmoke = $my['smoking_habit'] ?? $mySmoke;
        $myBudgetMin = (float)($my['budget_min'] ?? $myBudgetMin);
        $myBudgetMax = (float)($my['budget_max'] ?? $myBudgetMax);
    }
}

$filterGender = $explicitGender;
if ($filterGender === null && !$wantAnyGender) {
    $filterGender = $myGender;
}
// "any" / empty must return all genders — do not silently default to same-gender.

$sql = "SELECT p.*, u.short_name as uni_short_name 
                      FROM `xonadosh_profiles` p
                      LEFT JOIN `xonadosh_universities` u ON p.university_id = u.id
                      WHERE p.status = 'looking'";
$params = [];
if ($filterGender) {
    $sql .= " AND p.gender = ?";
    $params[] = $filterGender;
}
if ($uniFromGet > 0) {
    $sql .= " AND p.university_id = ?";
    $params[] = $uniFromGet;
}
if ($myUsername) {
    $sql .= " AND p.username != ?";
    $params[] = $myUsername;
}
$sql .= " ORDER BY p.id DESC LIMIT 40";
$stmt = $pdo->prepare($sql);
$stmt->execute($params);
$candidates = $stmt->fetchAll(PDO::FETCH_ASSOC);

$matchedList = [];

foreach ($candidates as $c) {
    $score = 0;
    $maxScore = 100;
    $matchReasons = [];

    // 1. Sleep Schedule (20 pts)
    $cSleep = $c['sleep_schedule'];
    if ($mySleep === $cSleep) {
        $score += 20;
        $matchReasons[] = get_match_reason($mySleep === "early_bird" ? "sleep_early" : ($mySleep === "night_owl" ? "sleep_night" : "sleep_flex"), $lang);
    } elseif ($mySleep === 'flexible' || $cSleep === 'flexible') {
        $score += 15;
    } else {
        $score += 5;
    }

    // 2. Cleanliness (20 pts)
    $cClean = $c['cleanliness'];
    if ($myClean === $cClean) {
        $score += 20;
        $matchReasons[] = get_match_reason($myClean === "strict" ? "clean_strict" : "clean_mod", $lang);
    } elseif ($myClean === 'moderate' || $cClean === 'moderate') {
        $score += 15;
    } else {
        $score += 5;
    }

    // 3. Study Habit (20 pts)
    $cStudy = $c['study_habit'];
    if ($myStudy === $cStudy) {
        $score += 20;
        $studyKey = $myStudy === "silent" ? "study_silent" : ($myStudy === "music" ? "study_music" : "study_group");
        $matchReasons[] = get_match_reason($studyKey, $lang);
    } elseif ($myStudy === 'flexible' || $cStudy === 'flexible') {
        $score += 16;
    } else {
        $score += 8;
    }

    // 4. Budget Overlap (20 pts)
    $cMin = (float)$c['budget_min'];
    $cMax = (float)$c['budget_max'];
    $overlapMin = max($myBudgetMin, $cMin);
    $overlapMax = min($myBudgetMax, $cMax);
    if ($overlapMin <= $overlapMax) {
        $score += 20;
        $matchReasons[] = get_match_reason("budget_exact", $lang);
    } else {
        $diff = abs($overlapMin - $overlapMax);
        if ($diff <= 300000) {
            $score += 10;
        } else {
            $score += 2;
        }
    }

    // 5. Habits & Lifestyle (10 pts)
    $cSmoke = $c['smoking_habit'];
    if ($mySmoke === $cSmoke) {
        $score += 10;
        if ($mySmoke === "no") $matchReasons[] = get_match_reason("no_smoking", $lang);
    }

    // 6. University match bonus (10 pts)
    $cUni = (int)($c['university_id'] ?? 0);
    if ($myUniId !== null && $myUniId > 0 && $myUniId === $cUni) {
        $score += 10;
        $matchReasons[] = get_match_reason("same_uni", $lang, $c["uni_short_name"] ?? "OTM");
    }

    $finalPercentage = min(99, max(50, $score));

    $matchedList[] = [
        'profile' => [
            'id' => (int)$c['id'],
            'username' => $c['username'],
            'full_name' => $c['full_name'],
            'phone_number' => $c['phone_number'],
            'telegram_handle' => $c['telegram_handle'],
            'avatar_url' => $c['avatar_url'],
            'gender' => $c['gender'],
            'age' => (int)$c['age'],
            'university_name' => $c['university_name'] ?? 'OTM',
            'university_short' => $c['uni_short_name'] ?? 'OTM',
            'faculty' => $c['faculty'],
            'course_year' => (int)$c['course_year'],
            'budget_min' => (float)$c['budget_min'],
            'budget_max' => (float)$c['budget_max'],
            'target_district' => $c['target_district'],
            'sleep_schedule' => $c['sleep_schedule'],
            'cleanliness' => $c['cleanliness'],
            'study_habit' => $c['study_habit'],
            'cooking_habit' => $c['cooking_habit'],
            'smoking_habit' => $c['smoking_habit'],
            'about_me' => $c['about_me'] ?? '',
            'looking_for_text' => $c['looking_for_text'] ?? ''
        ],
        'compatibility_score' => $finalPercentage,
        'compatibility_level' => get_compat_level((int)$finalPercentage, $lang),
        'match_reasons' => $matchReasons
    ];
}

// Sort by highest compatibility score first
usort($matchedList, function($a, $b) {
    return $b['compatibility_score'] <=> $a['compatibility_score'];
});

json_response([
    'ok' => true,
    'count' => count($matchedList),
    'matches' => $matchedList
]);
