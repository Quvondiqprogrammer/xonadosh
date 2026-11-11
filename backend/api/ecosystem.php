<?php

declare(strict_types=1);

require_once __DIR__ . '/../includes/bootstrap.php';
require_once __DIR__ . '/../includes/HamyonEcosystemBridge.php';

header('Content-Type: application/json; charset=utf-8');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, POST, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type, Authorization, X-Ecosystem-Source');

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit;
}

$action = $_GET['action'] ?? $_POST['action'] ?? 'directory';

switch ($action) {
    case 'verify_sso':
        $token = $_POST['token'] ?? $_GET['token'] ?? '';
        $data = \XonaDosh\Includes\HamyonEcosystemBridge::verifySsoToken($token);
        echo json_encode(['success' => (bool)$data, 'data' => $data]);
        break;

    case 'escrow_rent':
        $tenantId = (string)($_POST['tenant_id'] ?? 'tenant_1');
        $landlordId = (string)($_POST['landlord_id'] ?? 'landlord_1');
        $amount = (float)($_POST['amount'] ?? 0);
        $listingId = (string)($_POST['listing_id'] ?? 'listing_1');
        $result = \XonaDosh\Includes\HamyonEcosystemBridge::processRentEscrow($tenantId, $landlordId, $amount, $listingId);
        echo json_encode(['success' => true, 'data' => $result]);
        break;

    case 'directory':
    default:
        echo json_encode([
            'success' => true,
            'service' => 'xonadosh',
            'apps' => \XonaDosh\Includes\HamyonEcosystemBridge::getDirectory(),
        ]);
        break;
}
