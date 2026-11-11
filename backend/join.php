<?php

declare(strict_types=1);

$code = trim((string)($_GET['code'] ?? ''));
if ($code === '') {
    header('Location: /app/');
    exit;
}

$safeCode = htmlspecialchars($code, ENT_QUOTES, 'UTF-8');
$webUrl = "https://xonadoshim.uz/app/?join=" . urlencode($code);
$appDeepLink = "xonadosh://join?code=" . urlencode($code);
$playStoreUrl = "https://play.google.com/store/apps/details?id=uz.zargo.xonadosh";
?>
<!DOCTYPE html>
<html lang="uz">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no">
    <title>Xonadonga qo‘shilish — XonaDosh</title>
    <meta name="description" content="XonaDosh ilovasida umumiy xonadonga qo‘shiling. Birgalikda navbatchilik, xarajatlar va oshxona rejalarini boshqaring.">
    <link rel="icon" type="image/png" href="/app/assets/assets/brand/xonadosh_icon.png">
    <style>
        :root {
            --primary: #0D9488;
            --primary-dark: #0F766E;
            --primary-light: #F0FDFA;
            --slate-900: #0F172A;
            --slate-700: #334155;
            --slate-500: #64748B;
            --slate-200: #E2E8F0;
            --slate-100: #F1F5F9;
            --white: #FFFFFF;
        }
        * {
            box-sizing: border-box;
            margin: 0;
            padding: 0;
            font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, Helvetica, Arial, sans-serif;
            -webkit-tap-highlight-color: transparent;
        }
        body {
            background-color: #F8FAFC;
            color: var(--slate-900);
            min-height: 100vh;
            display: flex;
            align-items: center;
            justify-content: center;
            padding: 20px;
        }
        .card {
            background: var(--white);
            border: 1px solid var(--slate-200);
            border-radius: 24px;
            max-width: 440px;
            width: 100%;
            padding: 32px 24px;
            text-align: center;
            box-shadow: 0 10px 25px -5px rgba(0, 0, 0, 0.05), 0 8px 10px -6px rgba(0, 0, 0, 0.03);
        }
        .logo-wrap {
            width: 72px;
            height: 72px;
            margin: 0 auto 16px;
            border-radius: 20px;
            background: var(--primary-light);
            display: flex;
            align-items: center;
            justify-content: center;
            border: 2px solid #CCFBF1;
        }
        .logo-wrap img {
            width: 52px;
            height: 52px;
            border-radius: 12px;
            object-fit: cover;
        }
        h1 {
            font-size: 22px;
            font-weight: 800;
            color: var(--slate-900);
            margin-bottom: 8px;
            letter-spacing: -0.02em;
        }
        p.subtitle {
            font-size: 14px;
            color: var(--slate-500);
            line-height: 1.5;
            margin-bottom: 24px;
        }
        .code-box {
            background: var(--primary-light);
            border: 2px dashed #99F6E4;
            border-radius: 16px;
            padding: 16px;
            margin-bottom: 24px;
        }
        .code-label {
            font-size: 11px;
            font-weight: 700;
            text-transform: uppercase;
            letter-spacing: 0.08em;
            color: var(--primary-dark);
            margin-bottom: 6px;
        }
        .code-value {
            font-size: 24px;
            font-weight: 800;
            letter-spacing: 2px;
            color: var(--primary-dark);
            font-family: ui-monospace, SFMono-Regular, Menlo, Monaco, Consolas, monospace;
        }
        .btn {
            display: flex;
            align-items: center;
            justify-content: center;
            width: 100%;
            padding: 14px 20px;
            border-radius: 14px;
            font-size: 15px;
            font-weight: 700;
            text-decoration: none;
            transition: all 0.2s ease;
            cursor: pointer;
            border: none;
            margin-bottom: 10px;
        }
        .btn-primary {
            background-color: var(--primary);
            color: var(--white);
            box-shadow: 0 4px 14px rgba(13, 148, 136, 0.35);
        }
        .btn-primary:active {
            background-color: var(--primary-dark);
            transform: scale(0.98);
        }
        .btn-secondary {
            background-color: var(--slate-100);
            color: var(--slate-700);
            border: 1px solid var(--slate-200);
        }
        .btn-secondary:active {
            background-color: #E2E8F0;
            transform: scale(0.98);
        }
        .benefits {
            margin-top: 24px;
            padding-top: 20px;
            border-top: 1px solid var(--slate-200);
            text-align: left;
        }
        .benefit-item {
            display: flex;
            align-items: center;
            gap: 10px;
            font-size: 13px;
            color: var(--slate-700);
            margin-bottom: 8px;
        }
        .benefit-icon {
            font-size: 16px;
        }
    </style>
</head>
<body>
    <div class="card">
        <div class="logo-wrap">
            <img src="/app/assets/assets/brand/xonadosh_icon.png" alt="XonaDosh Logo" onerror="this.src='/favicon.ico';">
        </div>
        <h1>Xonadonga taklif</h1>
        <p class="subtitle">Sizni XonaDosh'dagi umumiy xonadonga taklif qilishdi. Birgalikda qulay hayot kechiring!</p>

        <div class="code-box">
            <div class="code-label">Xonadon kodi</div>
            <div class="code-value" id="inviteCode"><?= $safeCode ?></div>
        </div>

        <a href="<?= $appDeepLink ?>" class="btn btn-primary" id="openAppBtn">
            📱 Ilovada ochish
        </a>

        <a href="<?= $webUrl ?>" class="btn btn-secondary">
            🌐 Veb-versiyada ochish
        </a>

        <a href="<?= $playStoreUrl ?>" target="_blank" rel="noopener" class="btn btn-secondary" style="font-size: 13px; color: var(--slate-500);">
            ▶ Google Play'dan yuklab olish
        </a>

        <div class="benefits">
            <div class="benefit-item">
                <span class="benefit-icon">🧹</span>
                <span>Kunlik va haftalik adolatli navbatchilik</span>
            </div>
            <div class="benefit-item">
                <span class="benefit-icon">💰</span>
                <span>Umumiy kassa va xarajatlarni teng taqsimlash</span>
            </div>
            <div class="benefit-item">
                <span class="benefit-icon">🍲</span>
                <span>Oshxona menyusi va bozorlik ro‘yxati</span>
            </div>
            <div class="benefit-item">
                <span class="benefit-icon">⚖️</span>
                <span>Raqamli xonadon qoidalari va kelishuv</span>
            </div>
        </div>
    </div>

    <script>
        // Avto-redirect: Agar mobil qurilma bo'lsa ilovani ochishga urinadi
        const isMobile = /Android|iPhone|iPad|iPod/i.test(navigator.userAgent);
        const deepLink = <?= json_encode($appDeepLink) ?>;
        
        if (isMobile) {
            const start = Date.now();
            window.location.href = deepLink;
            setTimeout(() => {
                // Agar ilova ochilmasa, web versiyani taklif qilamiz
                if (Date.now() - start < 2000) {
                    console.log('App not installed or scheme unsupported');
                }
            }, 1500);
        }
    </script>
</body>
</html>
