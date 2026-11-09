<?php
declare(strict_types=1);

/**
 * API: Fetch message history for a conversation and mark as read.
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

$convId = isset($_GET['conversation_id']) ? (int)$_GET['conversation_id'] : (isset($_POST['conversation_id']) ? (int)$_POST['conversation_id'] : 0);
$limit = min(100, max(10, isset($_GET['limit']) ? (int)$_GET['limit'] : 50));
$beforeId = isset($_GET['before_id']) ? (int)$_GET['before_id'] : null;

if ($convId <= 0) {
    json_response(['ok' => false, 'error' => 'conversation_id talab qilinadi'], 400);
}

// 1. Check membership
$partStmt = $pdo->prepare("SELECT id, unread_count FROM xd_chat_participants WHERE conversation_id = ? AND username = ?");
$partStmt->execute([$convId, $username]);
$participant = $partStmt->fetch(PDO::FETCH_ASSOC);

if (!$participant) {
    json_response(['ok' => false, 'error' => 'Bu suhbatga kirish huquqingiz yo‘q'], 403);
}

// 2. Mark unread messages as read
try {
    $pdo->prepare("UPDATE xd_chat_participants SET unread_count = 0, last_read_at = NOW() WHERE conversation_id = ? AND username = ?")
        ->execute([$convId, $username]);
    $pdo->prepare("UPDATE xd_chat_messages SET is_read = 1 WHERE conversation_id = ? AND sender_username != ? AND is_read = 0")
        ->execute([$convId, $username]);
} catch (Throwable $ignore) {}

// 3. Query messages
$sql = "SELECT id, conversation_id, sender_username, message_type, body, metadata_json, is_read, created_at
        FROM xd_chat_messages
        WHERE conversation_id = ?";
$params = [$convId];

if ($beforeId !== null && $beforeId > 0) {
    $sql .= " AND id < ?";
    $params[] = $beforeId;
}

$sql .= " ORDER BY id DESC LIMIT " . (int)$limit;

$msgStmt = $pdo->prepare($sql);
$msgStmt->execute($params);
$rawMessages = $msgStmt->fetchAll(PDO::FETCH_ASSOC);

// Return in chronological order (oldest first)
$rawMessages = array_reverse($rawMessages);

$messages = [];
foreach ($rawMessages as $m) {
    $meta = null;
    if (!empty($m['metadata_json'])) {
        $meta = json_decode((string)$m['metadata_json'], true);
    }

    $messages[] = [
        'id' => (int)$m['id'],
        'conversation_id' => (int)$m['conversation_id'],
        'sender_username' => (string)$m['sender_username'],
        'is_me' => ($m['sender_username'] === $username),
        'message_type' => (string)$m['message_type'],
        'body' => (string)$m['body'],
        'metadata' => $meta,
        'is_read' => (bool)$m['is_read'],
        'created_at' => (string)$m['created_at'],
    ];
}

json_response([
    'ok' => true,
    'conversation_id' => $convId,
    'messages' => $messages,
    'count' => count($messages),
]);
