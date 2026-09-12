<?php
declare(strict_types=1);

/**
 * API: Roommate Profiles (GET list / GET my / POST save / POST delete)
 */

require_once dirname(__DIR__) . '/includes/bootstrap.php';
require_once dirname(__DIR__) . '/includes/db.php';
require_once dirname(__DIR__) . '/includes/auth_lib.php';

try {
    $pdo = db_connect($cfg);
} catch (Throwable $e) {
    json_response(['ok' => false, 'error' => 'Database connection failed: ' . $e->getMessage()], 500);
}

$method = $_SERVER['REQUEST_METHOD'] ?? 'GET';

if ($method === 'POST') {
    $sess = auth_require_token($pdo);
    $username = (string)$sess['username'];
    $userId = isset($sess['user_id']) ? (int)$sess['user_id'] : null;

    $raw = file_get_contents('php://input');
    $body = json_decode($raw ?: '{}', true);
    if (!is_array($body)) {
        $body = $_POST;
    }

    // Handle delete action
    if (($body['action'] ?? '') === 'delete') {
        $del = $pdo->prepare("DELETE FROM `xonadosh_profiles` WHERE username = ? OR (user_id IS NOT NULL AND user_id = ?)");
        $del->execute([$username, $userId]);
        json_response(['ok' => true, 'message' => 'Anketa muvaffaqiyatli o‘chirildi']);
    }

    $fullName = trim((string)($body['full_name'] ?? ($sess['display_name'] ?? 'Talaba')));
    $phoneNumber = trim((string)($body['phone_number'] ?? ($sess['phone_number'] ?? '')));
    $telegramHandle = trim((string)($body['telegram_handle'] ?? ''));
    $avatarUrl = trim((string)($body['avatar_url'] ?? ''));
    $gender = (string)($body['gender'] ?? 'male');
    $age = (int)($body['age'] ?? 20);
    $uniId = isset($body['university_id']) && is_numeric($body['university_id']) ? (int)$body['university_id'] : null;
    $uniName = trim((string)($body['university_name'] ?? ''));
    $faculty = trim((string)($body['faculty'] ?? ''));
    $courseYear = (int)($body['course_year'] ?? 2);
    $budgetMin = (float)($body['budget_min'] ?? 500000.0);
    $budgetMax = (float)($body['budget_max'] ?? 1200000.0);
    $targetDistrict = trim((string)($body['target_district'] ?? ''));
    $sleepSchedule = (string)($body['sleep_schedule'] ?? 'flexible');
    $cleanliness = (string)($body['cleanliness'] ?? 'strict');
    $studyHabit = (string)($body['study_habit'] ?? 'silent');
    $cookingHabit = (string)($body['cooking_habit'] ?? 'rotates');
    $smokingHabit = (string)($body['smoking_habit'] ?? 'no');
    $socialHabit = (string)($body['social_habit'] ?? 'balanced');
    $aboutMe = trim((string)($body['about_me'] ?? ''));
    $lookingForText = trim((string)($body['looking_for_text'] ?? ''));
    $status = (string)($body['status'] ?? 'looking');

    if (empty($fullName)) {
        json_response(['ok' => false, 'error' => 'Ism-familiya kiritilishi shart'], 400);
    }
    if (empty($phoneNumber)) {
        json_response(['ok' => false, 'error' => 'Telefon raqam kiritilishi shart'], 400);
    }

    // Upsert profile based on username or user_id
    $exist = $pdo->prepare("SELECT id FROM `xonadosh_profiles` WHERE username = ? OR (user_id IS NOT NULL AND user_id = ?)");
    $exist->execute([$username, $userId]);
    $exId = $exist->fetchColumn();

    if ($exId) {
        $stmt = $pdo->prepare("UPDATE `xonadosh_profiles` SET
            `user_id` = ?, `full_name` = ?, `phone_number` = ?, `telegram_handle` = ?, `avatar_url` = ?,
            `gender` = ?, `age` = ?, `university_id` = ?, `university_name` = ?,
            `faculty` = ?, `course_year` = ?, `budget_min` = ?, `budget_max` = ?,
            `target_district` = ?, `sleep_schedule` = ?, `cleanliness` = ?,
            `study_habit` = ?, `cooking_habit` = ?, `smoking_habit` = ?,
            `social_habit` = ?, `about_me` = ?, `looking_for_text` = ?, `status` = ?
            WHERE id = ?");
        $stmt->execute([
            $userId, $fullName, $phoneNumber, $telegramHandle, $avatarUrl,
            $gender, $age, $uniId, $uniName,
            $faculty, $courseYear, $budgetMin, $budgetMax,
            $targetDistrict, $sleepSchedule, $cleanliness,
            $studyHabit, $cookingHabit, $smokingHabit,
            $socialHabit, $aboutMe, $lookingForText, $status, $exId
        ]);
    } else {
        $stmt = $pdo->prepare("INSERT INTO `xonadosh_profiles` (
            `user_id`, `username`, `full_name`, `phone_number`, `telegram_handle`, `avatar_url`,
            `gender`, `age`, `university_id`, `university_name`, `faculty`, `course_year`,
            `budget_min`, `budget_max`, `target_district`, `sleep_schedule`, `cleanliness`,
            `study_habit`, `cooking_habit`, `smoking_habit`, `social_habit`, `about_me`, `looking_for_text`, `status`
        ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)");
        $stmt->execute([
            $userId, $username, $fullName, $phoneNumber, $telegramHandle, $avatarUrl,
            $gender, $age, $uniId, $uniName, $faculty, $courseYear,
            $budgetMin, $budgetMax, $targetDistrict, $sleepSchedule, $cleanliness,
            $studyHabit, $cookingHabit, $smokingHabit, $socialHabit, $aboutMe, $lookingForText, $status
        ]);
        $exId = $pdo->lastInsertId();
    }

    json_response([
        'ok' => true,
        'message' => 'Anketa muvaffaqiyatli saqlandi!',
        'profile_id' => (int)$exId
    ]);
}

// GET method: Single profile OR list roommate profiles
$targetUsername = isset($_GET['username']) && is_string($_GET['username']) && trim($_GET['username']) !== '' ? trim($_GET['username']) : null;
$myUsername = isset($_GET['my_username']) && is_string($_GET['my_username']) && trim($_GET['my_username']) !== '' ? trim($_GET['my_username']) : null;
$isMy = isset($_GET['my']) && ($_GET['my'] === '1' || $_GET['my'] === 'true');

if ($targetUsername !== null || $myUsername !== null || $isMy) {
    $searchUser = $targetUsername ?? $myUsername;
    if ($isMy && empty($searchUser)) {
        $sess = session_from_token($pdo, bearer_token());
        $searchUser = $sess['username'] ?? null;
    }

    if ($searchUser) {
        $stmt = $pdo->prepare("SELECT p.*, u.short_name as uni_short_name 
                FROM `xonadosh_profiles` p
                LEFT JOIN `xonadosh_universities` u ON p.university_id = u.id
                WHERE p.username = ? OR p.full_name LIKE ?
                ORDER BY p.id DESC LIMIT 1");
        $stmt->execute([$searchUser, $searchUser]);
        $r = $stmt->fetch(PDO::FETCH_ASSOC);

        if ($r) {
            $p = [
                'id' => (int)$r['id'],
                'user_id' => $r['user_id'] !== null ? (int)$r['user_id'] : null,
                'username' => $r['username'],
                'full_name' => $r['full_name'],
                'phone_number' => $r['phone_number'],
                'telegram_handle' => $r['telegram_handle'],
                'avatar_url' => $r['avatar_url'],
                'gender' => $r['gender'],
                'age' => (int)$r['age'],
                'university_id' => $r['university_id'] !== null ? (int)$r['university_id'] : null,
                'university_name' => $r['university_name'] ?? 'OTM',
                'university_short' => $r['uni_short_name'] ?? 'OTM',
                'faculty' => $r['faculty'],
                'course_year' => (int)$r['course_year'],
                'budget_min' => (float)$r['budget_min'],
                'budget_max' => (float)$r['budget_max'],
                'target_district' => $r['target_district'],
                'sleep_schedule' => $r['sleep_schedule'],
                'cleanliness' => $r['cleanliness'],
                'study_habit' => $r['study_habit'],
                'cooking_habit' => $r['cooking_habit'],
                'smoking_habit' => $r['smoking_habit'],
                'social_habit' => $r['social_habit'],
                'about_me' => $r['about_me'] ?? '',
                'looking_for_text' => $r['looking_for_text'] ?? '',
                'status' => $r['status'],
                'created_at' => $r['created_at']
            ];
            json_response([
                'ok' => true,
                'profile' => $p
            ]);
        }
    }
    json_response(['ok' => true, 'profile' => null]);
}

$uniId = isset($_GET['university_id']) && is_numeric($_GET['university_id']) ? (int)$_GET['university_id'] : null;
$gender = isset($_GET['gender']) && is_string($_GET['gender']) && $_GET['gender'] !== '' ? trim($_GET['gender']) : null;
$q = isset($_GET['q']) && is_string($_GET['q']) ? trim($_GET['q']) : null;

$sql = "SELECT p.*, u.short_name as uni_short_name 
        FROM `xonadosh_profiles` p
        LEFT JOIN `xonadosh_universities` u ON p.university_id = u.id
        WHERE p.status = 'looking'";
$params = [];

if ($gender !== null && $gender !== 'all') {
    $sql .= " AND p.gender = ?";
    $params[] = $gender;
}

if ($uniId !== null && $uniId > 0) {
    $sql .= " AND p.university_id = ?";
    $params[] = $uniId;
}

if ($q !== null && $q !== '') {
    $sql .= " AND (p.full_name LIKE ? OR p.university_name LIKE ? OR p.faculty LIKE ? OR p.about_me LIKE ?)";
    $like = '%' . $q . '%';
    $params[] = $like;
    $params[] = $like;
    $params[] = $like;
    $params[] = $like;
}

$sql .= " ORDER BY p.id DESC LIMIT 50";

try {
    $stmt = $pdo->prepare($sql);
    $stmt->execute($params);
    $rows = $stmt->fetchAll(PDO::FETCH_ASSOC);

    $profiles = [];
    foreach ($rows as $r) {
        $profiles[] = [
            'id' => (int)$r['id'],
            'user_id' => $r['user_id'] !== null ? (int)$r['user_id'] : null,
            'username' => $r['username'],
            'full_name' => $r['full_name'],
            'phone_number' => $r['phone_number'],
            'telegram_handle' => $r['telegram_handle'],
            'avatar_url' => $r['avatar_url'],
            'gender' => $r['gender'],
            'age' => (int)$r['age'],
            'university_id' => $r['university_id'] !== null ? (int)$r['university_id'] : null,
            'university_name' => $r['university_name'] ?? 'OTM',
            'university_short' => $r['uni_short_name'] ?? 'OTM',
            'faculty' => $r['faculty'],
            'course_year' => (int)$r['course_year'],
            'budget_min' => (float)$r['budget_min'],
            'budget_max' => (float)$r['budget_max'],
            'target_district' => $r['target_district'],
            'sleep_schedule' => $r['sleep_schedule'],
            'cleanliness' => $r['cleanliness'],
            'study_habit' => $r['study_habit'],
            'cooking_habit' => $r['cooking_habit'],
            'smoking_habit' => $r['smoking_habit'],
            'social_habit' => $r['social_habit'],
            'about_me' => $r['about_me'] ?? '',
            'looking_for_text' => $r['looking_for_text'] ?? '',
            'status' => $r['status'],
            'created_at' => $r['created_at']
        ];
    }

    json_response([
        'ok' => true,
        'count' => count($profiles),
        'profiles' => $profiles
    ]);
} catch (Throwable $e) {
    json_response(['ok' => false, 'error' => $e->getMessage()], 500);
}
