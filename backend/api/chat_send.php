<?php
declare(strict_types=1);

/**
 * API: Send a chat message (text, image, location).
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
$username = (string)$user['username'];

$payload = request_payload();
$convId = isset($payload['conversation_id']) ? (int)$payload['conversation_id'] : (isset($_POST['conversation_id']) ? (int)$_POST['conversation_id'] : 0);
$body = trim((string)($payload['body'] ?? ($_POST['body'] ?? '')));
$messageType = trim((string)($payload['message_type'] ?? ($_POST['message_type'] ?? 'text')));
$metadata = isset($payload['metadata']) && is_array($payload['metadata']) ? $payload['metadata'] : null;

if ($convId <= 0) {
    json_response(['ok' => false, 'error' => 'conversation_id talab qilinadi'], 400);
}

if ($body === '' && $messageType === 'text') {
    json_response(['ok' => false, 'error' => 'Xabar matni bo‘sh bo‘lishi mumkin emas'], 400);
}

if (!in_array($messageType, ['text', 'image', 'location', 'system_event'], true)) {
    $messageType = 'text';
}

// 1. Verify membership
$partStmt = $pdo->prepare("SELECT id FROM xd_chat_participants WHERE conversation_id = ? AND username = ?");
$partStmt->execute([$convId, $username]);
if (!$partStmt->fetch()) {
    json_response(['ok' => false, 'error' => 'Bu suhbatga kirish huquqingiz yo‘q'], 403);
}

$metaJson = $metadata !== null ? json_encode($metadata, JSON_UNESCAPED_UNICODE) : null;
$summary = $messageType === 'image' ? '📷 Rasm' : ($messageType === 'location' ? '📍 Joylashuv' : mb_substr($body, 0, 250));

$pdo->beginTransaction();
try {
    // 2. Insert message
    $insStmt = $pdo->prepare(
        "INSERT INTO xd_chat_messages (conversation_id, sender_username, message_type, body, metadata_json, is_read, created_at)
         VALUES (?, ?, ?, ?, ?, 0, NOW())"
    );
    $insStmt->execute([$convId, $username, $messageType, $body, $metaJson]);
    $msgId = (int)$pdo->lastInsertId();

    // 3. Update conversation's last message
    $updConv = $pdo->prepare(
        "UPDATE xd_conversations
         SET last_message_text = ?, last_message_sender = ?, last_message_at = NOW()
         WHERE id = ?"
    );
    $updConv->execute([$summary, $username, $convId]);

    // 4. Increment unread count for other participants
    $updPart = $pdo->prepare(
        "UPDATE xd_chat_participants
         SET unread_count = unread_count + 1
         WHERE conversation_id = ? AND username != ?"
    );
    $updPart->execute([$convId, $username]);

    $pdo->commit();
} catch (Throwable $e) {
    if ($pdo->inTransaction()) {
        $pdo->rollBack();
    }
    json_response(['ok' => false, 'error' => 'Xabarni yuborib bo‘lmadi: ' . $e->getMessage()], 500);
}

json_response([
    'ok' => true,
    'message' => [
        'id' => $msgId,
        'conversation_id' => $convId,
        'sender_username' => $username,
        'is_me' => true,
        'message_type' => $messageType,
        'body' => $body,
        'metadata' => $metadata,
        'is_read' => false,
        'created_at' => date('Y-m-d H:i:s'),
    ],
]);
