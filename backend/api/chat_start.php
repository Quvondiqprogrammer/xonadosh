<?php
declare(strict_types=1);

/**
 * API: Start or find an existing conversation with another user or for a listing.
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
$currentUsername = (string)$user['username'];

$payload = request_payload();
$targetUsername = trim((string)($payload['target_username'] ?? ($_POST['target_username'] ?? '')));
$listingId = isset($payload['listing_id']) ? (int)$payload['listing_id'] : (isset($_POST['listing_id']) ? (int)$_POST['listing_id'] : null);
$colivingGroupCode = trim((string)($payload['coliving_group_code'] ?? ($_POST['coliving_group_code'] ?? '')));
$initialMessage = trim((string)($payload['initial_message'] ?? ($_POST['initial_message'] ?? '')));

if ($targetUsername === '' && $listingId === null && $colivingGroupCode === '') {
    json_response(['ok' => false, 'error' => 'target_username, listing_id yoki coliving_group_code kiritilishi shart'], 400);
}

// If listingId provided but no targetUsername, resolve owner from listing
if ($listingId !== null && $targetUsername === '') {
    $lStmt = $pdo->prepare("SELECT username, owner_name FROM xonadosh_listings WHERE id = ?");
    $lStmt->execute([$listingId]);
    $lRow = $lStmt->fetch(PDO::FETCH_ASSOC);
    if (!$lRow) {
        json_response(['ok' => false, 'error' => 'E\'lon topilmadi'], 404);
    }
    $targetUsername = (string)$lRow['username'];
}

if ($targetUsername === $currentUsername && $colivingGroupCode === '') {
    json_response(['ok' => false, 'error' => 'O\'zingiz bilan chat ocholmaysiz'], 400);
}

// 1. Check if direct conversation already exists between current user and target
$existingConvId = null;

if ($targetUsername !== '') {
    $checkSql = "
        SELECT cp1.conversation_id
        FROM xd_chat_participants cp1
        JOIN xd_chat_participants cp2 ON cp1.conversation_id = cp2.conversation_id
        JOIN xd_conversations c ON c.id = cp1.conversation_id
        WHERE cp1.username = ? AND cp2.username = ? AND c.type != 'coliving_group'
    ";
    $params = [$currentUsername, $targetUsername];

    if ($listingId !== null) {
        $checkSql .= " AND (c.listing_id = ? OR c.listing_id IS NULL)";
        $params[] = $listingId;
    }

    $checkSql .= " LIMIT 1";

    $checkStmt = $pdo->prepare($checkSql);
    $checkStmt->execute($params);
    $existing = $checkStmt->fetch(PDO::FETCH_ASSOC);
    if ($existing) {
        $existingConvId = (int)$existing['conversation_id'];
    }
}

$pdo->beginTransaction();
try {
    if ($existingConvId === null) {
        // Create new conversation
        $type = $listingId !== null ? 'listing_inquiry' : ($colivingGroupCode !== '' ? 'coliving_group' : 'direct');
        $title = $colivingGroupCode !== '' ? "Xonadon: {$colivingGroupCode}" : null;

        $insConv = $pdo->prepare(
            "INSERT INTO xd_conversations (type, listing_id, coliving_group_code, title, last_message_text, last_message_sender, last_message_at)
             VALUES (?, ?, ?, ?, ?, ?, NOW())"
        );
        $insConv->execute([
            $type,
            $listingId,
            $colivingGroupCode !== '' ? $colivingGroupCode : null,
            $title,
            $initialMessage !== '' ? $initialMessage : 'Suhbat boshlandi',
            $currentUsername,
        ]);
        $existingConvId = (int)$pdo->lastInsertId();

        // Add current user
        $insPart = $pdo->prepare(
            "INSERT INTO xd_chat_participants (conversation_id, username, unread_count, last_read_at)
             VALUES (?, ?, 0, NOW())"
        );
        $insPart->execute([$existingConvId, $currentUsername]);

        // Add target user if specified
        if ($targetUsername !== '') {
            $insTarget = $pdo->prepare(
                "INSERT INTO xd_chat_participants (conversation_id, username, unread_count)
                 VALUES (?, ?, ?)"
            );
            $insTarget->execute([$existingConvId, $targetUsername, $initialMessage !== '' ? 1 : 0]);
        }

        // If initial message provided, insert it
        if ($initialMessage !== '') {
            $insMsg = $pdo->prepare(
                "INSERT INTO xd_chat_messages (conversation_id, sender_username, message_type, body)
                 VALUES (?, ?, 'text', ?)"
            );
            $insMsg->execute([$existingConvId, $currentUsername, $initialMessage]);
        }
    } else if ($initialMessage !== '') {
        // Send initial message to existing conversation
        $insMsg = $pdo->prepare(
            "INSERT INTO xd_chat_messages (conversation_id, sender_username, message_type, body)
             VALUES (?, ?, 'text', ?)"
        );
        $insMsg->execute([$existingConvId, $currentUsername, $initialMessage]);

        $updConv = $pdo->prepare(
            "UPDATE xd_conversations SET last_message_text = ?, last_message_sender = ?, last_message_at = NOW() WHERE id = ?"
        );
        $updConv->execute([$initialMessage, $currentUsername, $existingConvId]);

        $updPart = $pdo->prepare(
            "UPDATE xd_chat_participants SET unread_count = unread_count + 1 WHERE conversation_id = ? AND username != ?"
        );
        $updPart->execute([$existingConvId, $currentUsername]);
    }

    $pdo->commit();
} catch (Throwable $e) {
    if ($pdo->inTransaction()) {
        $pdo->rollBack();
    }
    json_response(['ok' => false, 'error' => 'Suhbatni boshlashda xatolik: ' . $e->getMessage()], 500);
}

// Fetch other user's info for response
$targetInfo = null;
if ($targetUsername !== '') {
    $tStmt = $pdo->prepare(
        "SELECT u.username, u.full_name, u.avatar_url, p.avatar_url as profile_avatar, p.full_name as profile_name
         FROM xd_users u
         LEFT JOIN xonadosh_profiles p ON p.username = u.username
         WHERE u.username = ? LIMIT 1"
    );
    $tStmt->execute([$targetUsername]);
    $tRow = $tStmt->fetch(PDO::FETCH_ASSOC);
    if ($tRow) {
        $targetInfo = [
            'username' => (string)$tRow['username'],
            'name' => (string)($tRow['profile_name'] ?: ($tRow['full_name'] ?: $tRow['username'])),
            'avatar_url' => (string)($tRow['profile_avatar'] ?: ($tRow['avatar_url'] ?: '')),
        ];
    }
}

json_response([
    'ok' => true,
    'conversation_id' => $existingConvId,
    'target_user' => $targetInfo,
]);
