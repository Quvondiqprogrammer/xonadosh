<?php

declare(strict_types=1);

require dirname(__DIR__) . '/includes/bootstrap.php';
require dirname(__DIR__) . '/includes/db.php';
require dirname(__DIR__) . '/includes/auth_lib.php';

try {
    $pdo = db_connect($cfg);
} catch (Throwable $e) {
    json_response(['ok' => false, 'error' => 'Database connection failed'], 500);
}

$user = auth_require_token($pdo);
$username = (string)$user['username'];
$userId = (int)$user['user_id'];

$raw = file_get_contents('php://input');
$body = json_decode($raw, true) ?? $_POST;

$studentId = trim((string)($body['student_id'] ?? ''));
$universityName = trim((string)($body['university_name'] ?? ''));
$faculty = trim((string)($body['faculty'] ?? ''));
$courseYear = isset($body['course_year']) ? (int)$body['course_year'] : 2;

if ($studentId === '') {
    json_response(['ok' => false, 'error' => 'Talaba ID (HEMIS ID) kiritilishi shart'], 400);
}

try {
    $stmt = $pdo->prepare("UPDATE `xonadosh_profiles` SET 
        `is_hemis_verified` = 1,
        `university_name` = COALESCE(NULLIF(?, ''), `university_name`),
        `faculty` = COALESCE(NULLIF(?, ''), `faculty`),
        `course_year` = ?
        WHERE `username` = ? OR `user_id` = ?");
    $stmt->execute([$universityName, $faculty, $courseYear, $username, $userId]);

    json_response([
        'ok' => true,
        'message' => 'Talabalik maqomi HEMIS orqali muvaffaqiyatli tasdiqlandi!',
        'verified' => true,
        'student_id' => $studentId,
        'badge' => 'Tasdiqlangan Talaba'
    ]);
} catch (Throwable $e) {
    json_response(['ok' => false, 'error' => 'Tasdiqlashda xatolik yuz berdi: ' . $e->getMessage()], 500);
}
