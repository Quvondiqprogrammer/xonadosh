<?php
declare(strict_types=1);

/**
 * Server-Side Rendered (SSR) SEO Landing Pages for XonaDosh
 * URLs: honadosh.uz/uylar/ or honadosh.uz/uylar/[slug]
 */

require_once dirname(__DIR__) . '/includes/bootstrap.php';
require_once dirname(__DIR__) . '/includes/db.php';

header('Content-Type: text/html; charset=utf-8');

try {
    $pdo = db_connect($cfg);
} catch (Throwable $e) {
    die("Xatolik yuz berdi: " . htmlspecialchars($e->getMessage()));
}

$rawSlug = trim((string)($_GET['slug'] ?? ''));
$slug = strtolower(preg_replace('/[^a-zA-Z0-9\-_]/', '', $rawSlug));

$districtMap = [
    'chilonzor' => 'Chilonzor',
    'yunusobod' => 'Yunusobod',
    'olmazor' => 'Olmazor',
    'mirzo-ulugbek' => 'Mirzo Ulug‘bek',
    'mirobod' => 'Mirobod',
    'shayxontohur' => 'Shayxontohur',
    'uchtepa' => 'Uchtepa',
    'yakkasaroy' => 'Yakkasaroy',
    'sergeli' => 'Sergeli',
    'yashnobod' => 'Yashnobod'
];

$matchedUni = null;
$matchedDistrict = null;

if (!empty($slug)) {
    // Check if matching university short_name or slug
    $uniStmt = $pdo->prepare("SELECT * FROM `xonadosh_universities` WHERE LOWER(short_name) = ? OR LOWER(short_name) LIKE ? LIMIT 1");
    $uniStmt->execute([$slug, '%' . $slug . '%']);
    $matchedUni = $uniStmt->fetch(PDO::FETCH_ASSOC);

    if (!$matchedUni && isset($districtMap[$slug])) {
        $matchedDistrict = $districtMap[$slug];
    }
}

// Build query
$where = "l.status = 'active' AND (l.crowd_broker_reports < 3 OR l.crowd_broker_reports IS NULL) AND (l.expires_at IS NULL OR l.expires_at > NOW())";
$params = [];

if ($matchedUni) {
    $where .= " AND l.nearest_university_id = ?";
    $params[] = (int)$matchedUni['id'];
    $pageTitle = htmlspecialchars($matchedUni['short_name']) . " yaqinida talabalar uchun ijara uylar va xonadoshlar — XonaDosh";
    $pageHeading = htmlspecialchars($matchedUni['name_uz']) . " atrofida ijara uylar";
    $pageDesc = htmlspecialchars($matchedUni['short_name']) . " yaqinidagi eng arzon ijara xonadonlar va xonadoshlar. Maklersiz, metroga yaqin va subsidiya shartnomali uylar ro‘yxati.";
} elseif ($matchedDistrict) {
    $where .= " AND l.district LIKE ?";
    $params[] = '%' . $matchedDistrict . '%';
    $pageTitle = htmlspecialchars($matchedDistrict) . " tumanida talabalar uchun ijara uylar — XonaDosh";
    $pageHeading = htmlspecialchars($matchedDistrict) . " tumanida ijara uylar va xonadoshlar";
    $pageDesc = htmlspecialchars($matchedDistrict) . " tumanidagi eng yaxshi ijara uylar, arzon xonadonlar va talabalar uchun xonadoshlar.";
} else {
    $pageTitle = "Toshkentda talabalar uchun ijara uylar va xonadoshlar — XonaDosh";
    $pageHeading = "Toshkentda talabalar uchun barcha ijara uylar";
    $pageDesc = "OTMlar yaqinida arzon, maklersiz ijara uylar, metro masofasi, haqiqiy oylik xarajatlar va xonadoshlar qidirish platformasi.";
}

$stmt = $pdo->prepare("SELECT l.*, u.short_name as uni_short_name, u.name_uz as uni_name_uz 
    FROM `xonadosh_listings` l
    LEFT JOIN `xonadosh_universities` u ON l.nearest_university_id = u.id
    WHERE $where
    ORDER BY l.id DESC LIMIT 40");
$stmt->execute($params);
$listings = $stmt->fetchAll(PDO::FETCH_ASSOC);

// Fetch all unis for footer links
$allUnis = $pdo->query("SELECT short_name, name_uz FROM `xonadosh_universities` ORDER BY short_name ASC")->fetchAll(PDO::FETCH_ASSOC);
?>
<!DOCTYPE html>
<html lang="uz">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title><?= $pageTitle ?></title>
    <meta name="description" content="<?= $pageDesc ?>">
    <meta name="keywords" content="ijara uy, talabalar ijarasi, xonadosh, toshkent ijara, bez makler, subsidiya, tatu, ozmu">
    <link rel="canonical" href="https://honadosh.uz/uylar/<?= htmlspecialchars($slug) ?>">
    
    <!-- Open Graph -->
    <meta property="og:title" content="<?= $pageTitle ?>">
    <meta property="og:description" content="<?= $pageDesc ?>">
    <meta property="og:type" content="website">
    <meta property="og:url" content="https://honadosh.uz/uylar/<?= htmlspecialchars($slug) ?>">
    <meta property="og:image" content="https://honadosh.uz/assets/img/og_image.png">

    <style>
        :root {
            --primary: #1E3A8A;
            --primary-light: #3B82F6;
            --accent: #10B981;
            --bg: #F8FAFC;
            --card-bg: #FFFFFF;
            --text-main: #0F172A;
            --text-muted: #64748B;
            --border: #E2E8F0;
        }
        * { box-sizing: border-box; margin: 0; padding: 0; font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif; }
        body { background-color: var(--bg); color: var(--text-main); line-height: 1.5; }
        .header { background: #FFFFFF; border-bottom: 1px solid var(--border); padding: 14px 20px; position: sticky; top: 0; z-index: 100; display: flex; justify-content: space-between; align-items: center; }
        .logo-wrap { display: flex; align-items: center; gap: 10px; text-decoration: none; color: var(--primary); font-size: 22px; font-weight: 800; }
        .app-btn { background: var(--primary); color: #fff; text-decoration: none; padding: 8px 16px; border-radius: 20px; font-weight: 600; font-size: 14px; transition: 0.2s; }
        .app-btn:hover { background: #1e40af; }
        .hero { max-width: 1200px; margin: 30px auto 20px; padding: 0 20px; }
        .hero h1 { font-size: 28px; font-weight: 800; color: #1e293b; margin-bottom: 8px; }
        .hero p { color: var(--text-muted); font-size: 16px; max-width: 800px; }
        .badges-bar { display: flex; flex-wrap: wrap; gap: 8px; margin-top: 16px; }
        .filter-chip { display: inline-block; padding: 6px 14px; background: #EEF2F6; color: #334155; border-radius: 20px; font-size: 13px; text-decoration: none; font-weight: 500; }
        .filter-chip.active { background: var(--primary); color: #fff; }
        .grid { max-width: 1200px; margin: 24px auto 40px; padding: 0 20px; display: grid; grid-template-columns: repeat(auto-fill, minmax(320px, 1fr)); gap: 20px; }
        .card { background: var(--card-bg); border: 1px solid var(--border); border-radius: 16px; overflow: hidden; display: flex; flex-direction: column; box-shadow: 0 4px 6px -1px rgba(0,0,0,0.05); transition: transform 0.2s, box-shadow 0.2s; }
        .card:hover { transform: translateY(-3px); box-shadow: 0 10px 15px -3px rgba(0,0,0,0.1); }
        .card-header { padding: 16px; flex: 1; }
        .card-price { font-size: 22px; font-weight: 800; color: var(--primary); margin-bottom: 4px; }
        .card-price small { font-size: 14px; font-weight: 500; color: var(--text-muted); }
        .true-cost { font-size: 12px; color: #059669; background: #ECFDF5; padding: 4px 8px; border-radius: 6px; display: inline-block; margin-bottom: 10px; font-weight: 600; }
        .card-title { font-size: 17px; font-weight: 700; color: #1e293b; margin-bottom: 8px; line-height: 1.3; }
        .card-meta { font-size: 13px; color: var(--text-muted); display: flex; flex-direction: column; gap: 4px; margin-bottom: 12px; }
        .tags { display: flex; flex-wrap: wrap; gap: 6px; margin-top: 8px; }
        .tag { font-size: 11px; font-weight: 600; padding: 3px 8px; border-radius: 4px; }
        .tag-nobroker { background: #DCFCE7; color: #166534; }
        .tag-subsidy { background: #FEF3C7; color: #92400E; }
        .tag-women { background: #FCE7F3; color: #9D174D; }
        .card-footer { padding: 12px 16px; background: #F8FAFC; border-top: 1px solid var(--border); display: flex; justify-content: space-between; align-items: center; }
        .btn-call { background: var(--accent); color: white; text-decoration: none; padding: 8px 14px; border-radius: 8px; font-weight: 600; font-size: 13px; }
        .btn-detail { color: var(--primary-light); text-decoration: none; font-weight: 600; font-size: 13px; }
        .footer { background: #0F172A; color: #94A3B8; padding: 40px 20px; margin-top: 60px; }
        .footer-inner { max-width: 1200px; margin: 0 auto; }
        .footer h3 { color: #fff; margin-bottom: 14px; font-size: 16px; }
        .footer-links { display: flex; flex-wrap: wrap; gap: 10px; margin-bottom: 24px; }
        .footer-links a { color: #CBD5E1; text-decoration: none; font-size: 13px; background: #1E293B; padding: 4px 10px; border-radius: 6px; }
        .footer-links a:hover { color: #fff; background: #334155; }
    </style>
</head>
<body>

<header class="header">
    <a href="https://honadosh.uz" class="logo-wrap">
        <span>🏠 XonaDosh</span>
    </a>
    <a href="https://honadosh.uz/app/" class="app-btn">Ilovani ochish</a>
</header>

<main>
    <div class="hero">
        <h1><?= $pageHeading ?></h1>
        <p><?= $pageDesc ?></p>

        <div class="badges-bar">
            <a href="https://honadosh.uz/uylar" class="filter-chip <?= empty($slug) ? 'active' : '' ?>">Barchasi</a>
            <a href="https://honadosh.uz/uylar/tatu" class="filter-chip <?= $slug === 'tatu' ? 'active' : '' ?>">TATU</a>
            <a href="https://honadosh.uz/uylar/ozmu" class="filter-chip <?= $slug === 'ozmu' ? 'active' : '' ?>">O‘zMU</a>
            <a href="https://honadosh.uz/uylar/tdtu" class="filter-chip <?= $slug === 'tdtu' ? 'active' : '' ?>">TDTU</a>
            <a href="https://honadosh.uz/uylar/tdiu" class="filter-chip <?= $slug === 'tdiu' ? 'active' : '' ?>">TDIU (Narxoz)</a>
            <a href="https://honadosh.uz/uylar/chilonzor" class="filter-chip <?= $slug === 'chilonzor' ? 'active' : '' ?>">Chilonzor tumani</a>
            <a href="https://honadosh.uz/uylar/yunusobod" class="filter-chip <?= $slug === 'yunusobod' ? 'active' : '' ?>">Yunusobod tumani</a>
        </div>
    </div>

    <div class="grid">
        <?php if (empty($listings)): ?>
            <div style="grid-column: 1/-1; text-align: center; padding: 60px 20px; background: #fff; border-radius: 16px;">
                <h3>Ushbu so‘rov bo‘yicha hozircha e‘lonlar topilmadi.</h3>
                <p style="margin-top: 8px; color: var(--text-muted);">Boshqa tumanlar yoki OTMlarni tanlang yoki o‘zingiz birinchi bo‘lib e‘lon bering!</p>
                <a href="https://honadosh.uz/app/" class="app-btn" style="display: inline-block; margin-top: 16px;">E‘lon berish</a>
            </div>
        <?php else: ?>
            <?php foreach ($listings as $l): 
                $priceUzs = (float)$l['price'];
                $metroFareMonthly = 1700 * 44;
                $trueCost = $priceUzs + $metroFareMonthly;
            ?>
                <div class="card">
                    <div class="card-header">
                        <div class="card-price">
                            <?= number_format($priceUzs, 0, '', ' ') ?> <small>so‘m/oy</small>
                        </div>
                        <div class="true-cost">
                            Haqiqiy oylik: <?= number_format($trueCost, 0, '', ' ') ?> so‘m (yo‘l xarajati bilan)
                        </div>
                        <h2 class="card-title"><?= htmlspecialchars($l['title']) ?></h2>
                        <div class="card-meta">
                            <div>📍 <?= htmlspecialchars($l['city']) ?>, <?= htmlspecialchars($l['district']) ?></div>
                            <?php if (!empty($l['nearest_metro'])): ?>
                                <div>🚇 Yaqin metro: <b><?= htmlspecialchars($l['nearest_metro']) ?></b></div>
                            <?php endif; ?>
                            <?php if (!empty($l['uni_short_name'])): ?>
                                <div>🎓 OTM: <b><?= htmlspecialchars($l['uni_short_name']) ?></b> (<?= number_format((float)($l['distance_to_university_km'] ?? 1.5), 1) ?> km)</div>
                            <?php endif; ?>
                        </div>
                        <div class="tags">
                            <span class="tag tag-nobroker">✓ Maklersiz</span>
                            <?php if (!empty($l['has_subsidy_contract'])): ?>
                                <span class="tag tag-subsidy">📜 Subsidiya shartnoma bor</span>
                            <?php endif; ?>
                            <?php if (!empty($l['is_women_only']) || $l['target_gender'] === 'girls'): ?>
                                <span class="tag tag-women">🌸 Qizlar uchun</span>
                            <?php endif; ?>
                        </div>
                    </div>
                    <div class="card-footer">
                        <a href="tel:<?= htmlspecialchars($l['phone_number']) ?>" class="btn-call">📞 <?= htmlspecialchars($l['phone_number']) ?></a>
                        <a href="https://honadosh.uz/app/" class="btn-detail">Ilovada ko‘rish &rarr;</a>
                    </div>
                </div>
            <?php endforeach; ?>
        <?php endif; ?>
    </div>
</main>

<footer class="footer">
    <div class="footer-inner">
        <h3>OTMlar bo‘yicha ijara uylar:</h3>
        <div class="footer-links">
            <?php foreach ($allUnis as $u): ?>
                <a href="https://honadosh.uz/uylar/<?= strtolower(urlencode($u['short_name'])) ?>">
                    <?= htmlspecialchars($u['short_name']) ?>
                </a>
            <?php endforeach; ?>
        </div>
        <p style="font-size: 12px; margin-top: 20px;">&copy; <?= date('Y') ?> XonaDosh — Talabalar uchun qulay va xavfsiz xonadoshlik ekotizimi.</p>
    </div>
</footer>

</body>
</html>
