<?php
declare(strict_types=1);
/**
 * API: Grocery Calculator v3.5
 * - Aggregates ingredients across all 21 weekly meals (breakfast + lunch + dinner)
 * - Scales accurately with roommate count (1 to 10 people)
 * - Uses realistic Uzbekistan market prices (Chorsu, Qo'yliq, O'rikzor)
 * - Computes min/max price range, savings potential, and detailed bread breakdown
 */
require_once dirname(__DIR__) . '/includes/bootstrap.php';
require_once dirname(__DIR__) . '/includes/db.php';

try {
    $pdo = db_connect($cfg);
} catch (Throwable $e) {
    $pdo = null;
}

$groupCode     = trim($_GET['group_code'] ?? 'home_default');
$roommateCount = max(1, min(10, (int)($_GET['roommates'] ?? $_GET['roommate_count'] ?? 4)));
$days          = max(1, min(7,  (int)($_GET['days'] ?? 7)));

// --- Market Prices Master Dictionary (Fallback if DB is offline or table is empty)
$defaultPrices = [
    'beef' => [
        'item_key' => 'beef', 'name_uz' => "Mol go'shti (Lahm / Suyaksiz)", 'category' => "Go'sht",
        'unit' => 'kg', 'avg_price_uzs' => 95000, 'min_price_uzs' => 90000, 'max_price_uzs' => 105000,
        'cheapest_source' => 'Chorsu Eski Juva go‘sht rastasi (07:00–09:00)',
        'buying_tips' => '3–5 kg bo‘lakda olinganda 90 000 so‘m/kg gacha tushib beriladi'
    ],
    'chicken_fillet' => [
        'item_key' => 'chicken_fillet', 'name_uz' => "Tovuq filesi (Toza lahm)", 'category' => "Go'sht",
        'unit' => 'kg', 'avg_price_uzs' => 45000, 'min_price_uzs' => 42000, 'max_price_uzs' => 49000,
        'cheapest_source' => 'Chorsu / Sergeli parrandachilik paviloni',
        'buying_tips' => '10 kg quti bilan ulgurji olinganda 40 000–42 000 so‘m/kg'
    ],
    'minced_meat' => [
        'item_key' => 'minced_meat', 'name_uz' => "Mol go'shti qiymasi", 'category' => "Go'sht",
        'unit' => 'kg', 'avg_price_uzs' => 85000, 'min_price_uzs' => 80000, 'max_price_uzs' => 92000,
        'cheapest_source' => 'Chorsu qassoblar rastasi',
        'buying_tips' => 'Ko‘z oldingizda yangi go‘shtdan tortib berishini so‘rang'
    ],
    'rice_alanga' => [
        'item_key' => 'rice_alanga', 'name_uz' => 'Guruch (Alanga saralangan)', 'category' => 'Don & Dukkak',
        'unit' => 'kg', 'avg_price_uzs' => 19000, 'min_price_uzs' => 17000, 'max_price_uzs' => 22000,
        'cheapest_source' => 'Qo‘yliq ulgurji dehqon bozori',
        'buying_tips' => 'Talabalar palovi va mastavasi uchun eng to‘yimli va tejamkor'
    ],
    'rice_lazer' => [
        'item_key' => 'rice_lazer', 'name_uz' => 'Guruch (Lazer Xorazm)', 'category' => 'Don & Dukkak',
        'unit' => 'kg', 'avg_price_uzs' => 26000, 'min_price_uzs' => 23000, 'max_price_uzs' => 30000,
        'cheapest_source' => 'Qo‘yliq guruch rastasi',
        'buying_tips' => 'To‘yona va damlama oshlar uchun eng a’lo nav'
    ],
    'potato' => [
        'item_key' => 'potato', 'name_uz' => 'Kartoshka (Qizil / Oq)', 'category' => 'Sabzavot',
        'unit' => 'kg', 'avg_price_uzs' => 6000, 'min_price_uzs' => 5000, 'max_price_uzs' => 7500,
        'cheapest_source' => 'Qo‘yliq mashinalar ulgurji qatori',
        'buying_tips' => '1 qop (25 kg) olinganda 5 000 so‘m/kg dan beriladi'
    ],
    'onion' => [
        'item_key' => 'onion', 'name_uz' => 'Piyoz (Oshbop sariq)', 'category' => 'Sabzavot',
        'unit' => 'kg', 'avg_price_uzs' => 4000, 'min_price_uzs' => 3200, 'max_price_uzs' => 5000,
        'cheapest_source' => 'Qo‘yliq ulgurji qator',
        'buying_tips' => '1 qop (30 kg) olinganda 3 200 so‘m/kg'
    ],
    'carrot_yellow' => [
        'item_key' => 'carrot_yellow', 'name_uz' => 'Sabzi (Sariq oshbop)', 'category' => 'Sabzavot',
        'unit' => 'kg', 'avg_price_uzs' => 4500, 'min_price_uzs' => 3500, 'max_price_uzs' => 5500,
        'cheapest_source' => 'Qo‘yliq / Chorsu dehqon bozori',
        'buying_tips' => '10 kg dan ortiq olinganda 3 500 so‘m/kg'
    ],
    'carrot_red' => [
        'item_key' => 'carrot_red', 'name_uz' => 'Sabzi (Qizil vitaminli)', 'category' => 'Sabzavot',
        'unit' => 'kg', 'avg_price_uzs' => 5000, 'min_price_uzs' => 4000, 'max_price_uzs' => 6000,
        'cheapest_source' => 'Dehqon bozorlari',
        'buying_tips' => 'Sho‘rva va salatlar uchun zarur'
    ],
    'tomato' => [
        'item_key' => 'tomato', 'name_uz' => 'Pomidor (Yangi qizil)', 'category' => 'Sabzavot',
        'unit' => 'kg', 'avg_price_uzs' => 14000, 'min_price_uzs' => 10000, 'max_price_uzs' => 19000,
        'cheapest_source' => 'Chorsu dehqon bozori (17:00 dan keyin)',
        'buying_tips' => 'Kechqurun 17:00 dan so‘ng dehqonlar 20–30% arzonlashtirib sotadi'
    ],
    'cucumber' => [
        'item_key' => 'cucumber', 'name_uz' => 'Bodring (Mayda / Tillo)', 'category' => 'Sabzavot',
        'unit' => 'kg', 'avg_price_uzs' => 9000, 'min_price_uzs' => 7000, 'max_price_uzs' => 13000,
        'cheapest_source' => 'Chorsu / Qo‘yliq dehqon bozori',
        'buying_tips' => 'Nonushta va lanchboks salati uchun yangi bodring'
    ],
    'bell_pepper' => [
        'item_key' => 'bell_pepper', 'name_uz' => 'Bolgar qalampiri', 'category' => 'Sabzavot',
        'unit' => 'kg', 'avg_price_uzs' => 16000, 'min_price_uzs' => 12000, 'max_price_uzs' => 22000,
        'cheapest_source' => 'Chorsu sabzavot paviloni',
        'buying_tips' => 'Dimlama va qovurmalarga ajoyib xushbo‘ylik beradi'
    ],
    'cabbage' => [
        'item_key' => 'cabbage', 'name_uz' => 'Karam (Yangi oq)', 'category' => 'Sabzavot',
        'unit' => 'kg', 'avg_price_uzs' => 4500, 'min_price_uzs' => 3500, 'max_price_uzs' => 6000,
        'cheapest_source' => 'Dehqon bozorlari',
        'buying_tips' => '1 dona katta karam bir haftalik dimlama va qovurmalarga yetadi'
    ],
    'greens' => [
        'item_key' => 'greens', 'name_uz' => 'Ko‘katlar (Kashnich, ukrop, petrushka)', 'category' => 'Sabzavot',
        'unit' => "bog'", 'avg_price_uzs' => 2500, 'min_price_uzs' => 2000, 'max_price_uzs' => 3500,
        'cheapest_source' => 'Chorsu ko‘katlar rastasi',
        'buying_tips' => '5 ta bog‘ birgalikda olinganda 8 000–10 000 so‘m'
    ],
    'eggs' => [
        'item_key' => 'eggs', 'name_uz' => 'Tuxum (Saralangan C-1)', 'category' => 'Sut & Tuxum',
        'unit' => 'dona', 'avg_price_uzs' => 1600, 'min_price_uzs' => 1400, 'max_price_uzs' => 1800,
        'cheapest_source' => 'Chorsu tuxum qatori / Parrandachilik savdo rastasi',
        'buying_tips' => '30 donalik lotok bilan olish tejamkor (lotogi 42 000 so‘m)'
    ],
    'milk' => [
        'item_key' => 'milk', 'name_uz' => 'Sut (Pasterizatsiyalangan)', 'category' => 'Sut & Tuxum',
        'unit' => 'litr', 'avg_price_uzs' => 10000, 'min_price_uzs' => 8500, 'max_price_uzs' => 12000,
        'cheapest_source' => 'Mahalliy sut do‘koni / Ferma savdo nuqtasi',
        'buying_tips' => 'Ertalabki bo‘tqa va sutli choy uchun'
    ],
    'oil_vegetable' => [
        'item_key' => 'oil_vegetable', 'name_uz' => 'O‘simlik yog‘i (Pista yog‘i)', 'category' => 'Yog‘ & Moy',
        'unit' => 'litr', 'avg_price_uzs' => 18000, 'min_price_uzs' => 16500, 'max_price_uzs' => 20000,
        'cheapest_source' => 'Qo‘yliq ulgurji baqqollik / Havas aksiyasi',
        'buying_tips' => '5 litrlik idishda olinganda 1 litri 16 500 so‘mga to‘g‘ri keladi'
    ],
    'bread_bukhanka' => [
        'item_key' => 'bread_bukhanka', 'name_uz' => 'Non (Qolipli Buxanka)', 'category' => 'Non mahsulotlari',
        'unit' => 'dona', 'avg_price_uzs' => 3000, 'min_price_uzs' => 2800, 'max_price_uzs' => 3500,
        'cheapest_source' => 'Mahalla novvoyxonasi',
        'buying_tips' => 'Kuniga yangi issiq olinadi (ertalab va kechqurun)'
    ],
    'bread_patir' => [
        'item_key' => 'bread_patir', 'name_uz' => 'Non (Tandir Patir / Obi non)', 'category' => 'Non mahsulotlari',
        'unit' => 'dona', 'avg_price_uzs' => 5000, 'min_price_uzs' => 4000, 'max_price_uzs' => 8000,
        'cheapest_source' => 'Tandir novvoyxonalari',
        'buying_tips' => 'Palov va kechki ovqat kunlari tandirdan issiq olinadi'
    ],
    'pasta_makaron' => [
        'item_key' => 'pasta_makaron', 'name_uz' => 'Makaron (450g pachka)', 'category' => 'Baqqollik',
        'unit' => 'pachka', 'avg_price_uzs' => 9500, 'min_price_uzs' => 8000, 'max_price_uzs' => 12000,
        'cheapest_source' => 'Havas / FixPrice / Ulgurji savdo',
        'buying_tips' => '10 pachkalik blokda olinganda 8 000 so‘m/pachka'
    ],
    'mung_bean_mosh' => [
        'item_key' => 'mung_bean_mosh', 'name_uz' => 'Mosh (O‘zbek mosh)', 'category' => 'Don & Dukkak',
        'unit' => 'kg', 'avg_price_uzs' => 17000, 'min_price_uzs' => 14000, 'max_price_uzs' => 20000,
        'cheapest_source' => 'Chorsu dukkakliklar rastasi',
        'buying_tips' => 'Moshkichiri uchun eng yuqori tabiiy oqsil manbai'
    ],
    'buckwheat_grechka' => [
        'item_key' => 'buckwheat_grechka', 'name_uz' => 'Grechka (1 kg)', 'category' => 'Don & Dukkak',
        'unit' => 'kg', 'avg_price_uzs' => 15000, 'min_price_uzs' => 13000, 'max_price_uzs' => 18000,
        'cheapest_source' => 'Chorsu / Havas supermarket',
        'buying_tips' => 'Tez pishadigan toza qovurilgan don'
    ],
    'sugar' => [
        'item_key' => 'sugar', 'name_uz' => 'Shakar (1 kg)', 'category' => 'Baqqollik',
        'unit' => 'kg', 'avg_price_uzs' => 14000, 'min_price_uzs' => 12500, 'max_price_uzs' => 16000,
        'cheapest_source' => 'Qo‘yliq ulgurji shakar bozori (5 kg xaltada)',
        'buying_tips' => '5 kg xaltada 12 500 so‘m/kg'
    ],
    'tea_green_black' => [
        'item_key' => 'tea_green_black', 'name_uz' => 'Ko‘k choy (95-nav, 100g pachka)', 'category' => 'Baqqollik',
        'unit' => 'pachka', 'avg_price_uzs' => 10000, 'min_price_uzs' => 8000, 'max_price_uzs' => 14000,
        'cheapest_source' => 'Chorsu choy rastasi',
        'buying_tips' => 'Talabalar uchun klassik 95-nav ko‘k choy'
    ],
    'salt_spices' => [
        'item_key' => 'salt_spices', 'name_uz' => 'Ziravorlar to‘plami (Zira, murch, tuz)', 'category' => 'Ziravor',
        'unit' => 'to‘plam', 'avg_price_uzs' => 8000, 'min_price_uzs' => 5000, 'max_price_uzs' => 12000,
        'cheapest_source' => 'Chorsu ziravorchilar qatori',
        'buying_tips' => 'Osh va sho‘rvalar uchun saralangan zira va murch'
    ]
];

// Default 21 standard student recipe ingredients master map
$defaultRecipeMap = [
    1 => ['name' => 'Pomidorli Tuxum Quymoq', 'ingredients' => [
        ['key'=>'eggs','qty_per_person'=>2.0,'unit'=>'dona'],
        ['key'=>'tomato','qty_per_person'=>0.10,'unit'=>'kg'],
        ['key'=>'onion','qty_per_person'=>0.04,'unit'=>'kg'],
        ['key'=>'oil_vegetable','qty_per_person'=>0.02,'unit'=>'litr']
    ]],
    2 => ['name' => 'Tuxumli Issiq Grenki', 'ingredients' => [
        ['key'=>'eggs','qty_per_person'=>2.0,'unit'=>'dona'],
        ['key'=>'milk','qty_per_person'=>0.05,'unit'=>'litr'],
        ['key'=>'oil_vegetable','qty_per_person'=>0.02,'unit'=>'litr']
    ]],
    3 => ['name' => 'Qaynatilgan Tuxum & Tandir Non', 'ingredients' => [
        ['key'=>'eggs','qty_per_person'=>2.0,'unit'=>'dona']
    ]],
    4 => ['name' => 'Sutli Suli Bo‘tqasi', 'ingredients' => [
        ['key'=>'milk','qty_per_person'=>0.20,'unit'=>'litr']
    ]],
    5 => ['name' => 'Lavash Roll', 'ingredients' => [
        ['key'=>'eggs','qty_per_person'=>2.0,'unit'=>'dona'],
        ['key'=>'tomato','qty_per_person'=>0.08,'unit'=>'kg'],
        ['key'=>'cucumber','qty_per_person'=>0.06,'unit'=>'kg'],
        ['key'=>'oil_vegetable','qty_per_person'=>0.01,'unit'=>'litr']
    ]],
    6 => ['name' => 'Sabzavotli Omlet', 'ingredients' => [
        ['key'=>'eggs','qty_per_person'=>2.0,'unit'=>'dona'],
        ['key'=>'bell_pepper','qty_per_person'=>0.06,'unit'=>'kg'],
        ['key'=>'tomato','qty_per_person'=>0.08,'unit'=>'kg'],
        ['key'=>'onion','qty_per_person'=>0.04,'unit'=>'kg'],
        ['key'=>'oil_vegetable','qty_per_person'=>0.02,'unit'=>'litr']
    ]],
    7 => ['name' => 'Sutli Choy va Non', 'ingredients' => [
        ['key'=>'milk','qty_per_person'=>0.05,'unit'=>'litr']
    ]],
    8 => ['name' => 'Lanchboks: Tovuqli Sendvich', 'ingredients' => [
        ['key'=>'chicken_fillet','qty_per_person'=>0.10,'unit'=>'kg'],
        ['key'=>'cucumber','qty_per_person'=>0.08,'unit'=>'kg'],
        ['key'=>'tomato','qty_per_person'=>0.08,'unit'=>'kg']
    ]],
    9 => ['name' => 'Issiq Tovuqli Vermishel Sho‘rva', 'ingredients' => [
        ['key'=>'chicken_fillet','qty_per_person'=>0.10,'unit'=>'kg'],
        ['key'=>'potato','qty_per_person'=>0.12,'unit'=>'kg'],
        ['key'=>'carrot_red','qty_per_person'=>0.06,'unit'=>'kg'],
        ['key'=>'pasta_makaron','qty_per_person'=>0.12,'unit'=>'pachka'],
        ['key'=>'greens','qty_per_person'=>0.25,'unit'=>"bog'"]
    ]],
    10 => ['name' => 'Karam & Tuxum Qovurmasi', 'ingredients' => [
        ['key'=>'cabbage','qty_per_person'=>0.20,'unit'=>'kg'],
        ['key'=>'eggs','qty_per_person'=>2.0,'unit'=>'dona'],
        ['key'=>'onion','qty_per_person'=>0.06,'unit'=>'kg'],
        ['key'=>'oil_vegetable','qty_per_person'=>0.03,'unit'=>'litr']
    ]],
    11 => ['name' => 'Kartoshka-Tovuq Qovurma', 'ingredients' => [
        ['key'=>'potato','qty_per_person'=>0.20,'unit'=>'kg'],
        ['key'=>'chicken_fillet','qty_per_person'=>0.08,'unit'=>'kg'],
        ['key'=>'onion','qty_per_person'=>0.06,'unit'=>'kg'],
        ['key'=>'oil_vegetable','qty_per_person'=>0.03,'unit'=>'litr']
    ]],
    12 => ['name' => 'Pomidorli Guruch Sho‘rva', 'ingredients' => [
        ['key'=>'rice_alanga','qty_per_person'=>0.07,'unit'=>'kg'],
        ['key'=>'tomato','qty_per_person'=>0.10,'unit'=>'kg'],
        ['key'=>'carrot_yellow','qty_per_person'=>0.06,'unit'=>'kg'],
        ['key'=>'onion','qty_per_person'=>0.05,'unit'=>'kg'],
        ['key'=>'oil_vegetable','qty_per_person'=>0.02,'unit'=>'litr'],
        ['key'=>'greens','qty_per_person'=>0.25,'unit'=>"bog'"]
    ]],
    13 => ['name' => 'Tezkor Somsa', 'ingredients' => [
        ['key'=>'chicken_fillet','qty_per_person'=>0.10,'unit'=>'kg'],
        ['key'=>'onion','qty_per_person'=>0.08,'unit'=>'kg'],
        ['key'=>'oil_vegetable','qty_per_person'=>0.03,'unit'=>'litr'],
        ['key'=>'salt_spices','qty_per_person'=>0.15,'unit'=>'to‘plam']
    ]],
    14 => ['name' => 'Tushlik Salat', 'ingredients' => [
        ['key'=>'tomato','qty_per_person'=>0.15,'unit'=>'kg'],
        ['key'=>'cucumber','qty_per_person'=>0.12,'unit'=>'kg'],
        ['key'=>'onion','qty_per_person'=>0.05,'unit'=>'kg'],
        ['key'=>'greens','qty_per_person'=>0.50,'unit'=>"bog'"],
        ['key'=>'oil_vegetable','qty_per_person'=>0.01,'unit'=>'litr']
    ]],
    15 => ['name' => 'Talabacha Tovuqli Palov', 'ingredients' => [
        ['key'=>'chicken_fillet','qty_per_person'=>0.15,'unit'=>'kg'],
        ['key'=>'rice_alanga','qty_per_person'=>0.18,'unit'=>'kg'],
        ['key'=>'carrot_yellow','qty_per_person'=>0.20,'unit'=>'kg'],
        ['key'=>'onion','qty_per_person'=>0.08,'unit'=>'kg'],
        ['key'=>'oil_vegetable','qty_per_person'=>0.05,'unit'=>'litr'],
        ['key'=>'salt_spices','qty_per_person'=>0.25,'unit'=>'to‘plam']
    ]],
    16 => ['name' => 'Qovurma Makaron', 'ingredients' => [
        ['key'=>'pasta_makaron','qty_per_person'=>0.25,'unit'=>'pachka'],
        ['key'=>'eggs','qty_per_person'=>2.0,'unit'=>'dona'],
        ['key'=>'tomato','qty_per_person'=>0.10,'unit'=>'kg'],
        ['key'=>'onion','qty_per_person'=>0.06,'unit'=>'kg'],
        ['key'=>'oil_vegetable','qty_per_person'=>0.03,'unit'=>'litr']
    ]],
    17 => ['name' => 'Sabzavotli Dimlama', 'ingredients' => [
        ['key'=>'chicken_fillet','qty_per_person'=>0.12,'unit'=>'kg'],
        ['key'=>'potato','qty_per_person'=>0.20,'unit'=>'kg'],
        ['key'=>'cabbage','qty_per_person'=>0.15,'unit'=>'kg'],
        ['key'=>'carrot_red','qty_per_person'=>0.10,'unit'=>'kg'],
        ['key'=>'onion','qty_per_person'=>0.08,'unit'=>'kg'],
        ['key'=>'oil_vegetable','qty_per_person'=>0.03,'unit'=>'litr']
    ]],
    18 => ['name' => 'Quyuq Mastava', 'ingredients' => [
        ['key'=>'chicken_fillet','qty_per_person'=>0.10,'unit'=>'kg'],
        ['key'=>'rice_alanga','qty_per_person'=>0.08,'unit'=>'kg'],
        ['key'=>'potato','qty_per_person'=>0.15,'unit'=>'kg'],
        ['key'=>'tomato','qty_per_person'=>0.08,'unit'=>'kg'],
        ['key'=>'onion','qty_per_person'=>0.06,'unit'=>'kg'],
        ['key'=>'greens','qty_per_person'=>0.25,'unit'=>"bog'"]
    ]],
    19 => ['name' => 'Qovurilgan Kartoshka & Tuxum', 'ingredients' => [
        ['key'=>'potato','qty_per_person'=>0.25,'unit'=>'kg'],
        ['key'=>'eggs','qty_per_person'=>2.0,'unit'=>'dona'],
        ['key'=>'onion','qty_per_person'=>0.08,'unit'=>'kg'],
        ['key'=>'oil_vegetable','qty_per_person'=>0.04,'unit'=>'litr']
    ]],
    20 => ['name' => 'Moshkichiri', 'ingredients' => [
        ['key'=>'mung_bean_mosh','qty_per_person'=>0.09,'unit'=>'kg'],
        ['key'=>'rice_alanga','qty_per_person'=>0.07,'unit'=>'kg'],
        ['key'=>'chicken_fillet','qty_per_person'=>0.08,'unit'=>'kg'],
        ['key'=>'potato','qty_per_person'=>0.10,'unit'=>'kg'],
        ['key'=>'onion','qty_per_person'=>0.06,'unit'=>'kg'],
        ['key'=>'oil_vegetable','qty_per_person'=>0.03,'unit'=>'litr']
    ]],
    21 => ['name' => 'Grechka & Tovuqli Sous', 'ingredients' => [
        ['key'=>'buckwheat_grechka','qty_per_person'=>0.12,'unit'=>'kg'],
        ['key'=>'chicken_fillet','qty_per_person'=>0.12,'unit'=>'kg'],
        ['key'=>'onion','qty_per_person'=>0.06,'unit'=>'kg'],
        ['key'=>'carrot_red','qty_per_person'=>0.08,'unit'=>'kg'],
        ['key'=>'tomato','qty_per_person'=>0.08,'unit'=>'kg'],
        ['key'=>'oil_vegetable','qty_per_person'=>0.03,'unit'=>'litr']
    ]]
];

// Load market prices from database if available
$priceMap = $defaultPrices;
if ($pdo) {
    try {
        $priceRows = $pdo->query("SELECT * FROM `xonadosh_market_prices`")->fetchAll(PDO::FETCH_ASSOC);
        foreach ($priceRows as $p) {
            $key = $p['item_key'];
            $priceMap[$key] = [
                'item_key'        => $key,
                'name_uz'         => $p['name_uz'] ?? ($defaultPrices[$key]['name_uz'] ?? $key),
                'category'        => $p['category'] ?? ($defaultPrices[$key]['category'] ?? 'Boshqa'),
                'unit'            => $p['unit'] ?? ($defaultPrices[$key]['unit'] ?? 'kg'),
                'avg_price_uzs'   => (int)($p['avg_price_uzs'] ?? $defaultPrices[$key]['avg_price_uzs'] ?? 10000),
                'min_price_uzs'   => (int)($p['min_price_uzs'] ?? $defaultPrices[$key]['min_price_uzs'] ?? 8000),
                'max_price_uzs'   => (int)($p['max_price_uzs'] ?? $defaultPrices[$key]['max_price_uzs'] ?? 12000),
                'cheapest_source' => $p['cheapest_source'] ?? ($defaultPrices[$key]['cheapest_source'] ?? 'Chorsu bozor'),
                'buying_tips'     => $p['buying_tips'] ?? ($defaultPrices[$key]['buying_tips'] ?? ''),
            ];
        }
    } catch (Throwable $e) {}
}

// Load recipes
$recipeMap = $defaultRecipeMap;
if ($pdo) {
    try {
        $recipeRows = $pdo->query("SELECT id, name_uz, category, ingredients_json FROM `xonadosh_recipes`")->fetchAll(PDO::FETCH_ASSOC);
        foreach ($recipeRows as $r) {
            $ing = json_decode($r['ingredients_json'], true) ?? [];
            if (!empty($ing)) {
                $recipeMap[(int)$r['id']] = ['name' => $r['name_uz'], 'category' => $r['category'], 'ingredients' => $ing];
            }
        }
    } catch (Throwable $e) {}
}

// Load meal plans from database
$planRows = [];
if ($pdo) {
    try {
        $planStmt = $pdo->prepare("
            SELECT p.recipe_id, p.day_of_week, p.meal_time, p.bread_count
            FROM `xonadosh_meal_plans` p
            WHERE p.group_code = ?
            ORDER BY FIELD(p.day_of_week,'dushanba','seshanba','chorshanba','payshanba','juma','shanba','yakshanba'),
                     FIELD(p.meal_time,'breakfast','lunch','dinner')
        ");
        $planStmt->execute([$groupCode]);
        $planRows = $planStmt->fetchAll(PDO::FETCH_ASSOC);
    } catch (Throwable $e) {}
}

// If no custom plan found in DB, use default 21 standard student meals (1 to 21)
if (empty($planRows)) {
    $daysOfWeek = ['dushanba','seshanba','chorshanba','payshanba','juma','shanba','yakshanba'];
    $idx = 1;
    foreach ($daysOfWeek as $day) {
        $planRows[] = ['recipe_id' => $idx,     'day_of_week' => $day, 'meal_time' => 'breakfast', 'bread_count' => 0.5];
        $planRows[] = ['recipe_id' => $idx + 7, 'day_of_week' => $day, 'meal_time' => 'lunch',     'bread_count' => 0.5];
        $planRows[] = ['recipe_id' => $idx + 14,'day_of_week' => $day, 'meal_time' => 'dinner',    'bread_count' => 0.5];
        $idx++;
    }
}

// Aggregate ingredients across all meals
$aggregated = [];
$breakfastBreadTotal = 0.0;
$lunchBreadTotal     = 0.0;
$dinnerBreadTotal    = 0.0;

foreach ($planRows as $row) {
    $rid = (int)($row['recipe_id'] ?? 0);
    $mealTime = $row['meal_time'] ?? 'dinner';
    $breadCount = (float)($row['bread_count'] ?? 0.5) * $roommateCount;

    match($mealTime) {
        'breakfast' => ($breakfastBreadTotal += $breadCount),
        'lunch'     => ($lunchBreadTotal     += $breadCount),
        'dinner'    => ($dinnerBreadTotal    += $breadCount),
        default     => ($dinnerBreadTotal    += $breadCount),
    };

    if ($rid > 0 && isset($recipeMap[$rid])) {
        foreach ($recipeMap[$rid]['ingredients'] as $ing) {
            $key = $ing['key'] ?? '';
            if (empty($key)) continue;

            // Skip bread & tea because they are globally calculated
            if (in_array($key, ['bread_bukhanka', 'bread_patir', 'tea_green_black'], true)) continue;

            $qty = (float)($ing['qty_per_person'] ?? 0) * $roommateCount;
            if (!isset($aggregated[$key])) {
                $aggregated[$key] = [
                    'key'        => $key,
                    'name'       => $ing['name'] ?? ($priceMap[$key]['name_uz'] ?? $key),
                    'unit'       => $ing['unit'] ?? ($priceMap[$key]['unit'] ?? 'kg'),
                    'qty'        => 0.0,
                    'meal_types' => []
                ];
            }
            $aggregated[$key]['qty'] += $qty;
            if (!in_array($mealTime, $aggregated[$key]['meal_types'], true)) {
                $aggregated[$key]['meal_types'][] = $mealTime;
            }
        }
    }
}

// 1. Bread Calculation
// Breakfast & lunch use standard Buxanka. Dinner uses Tandir Patir on Mon, Thu, Fri, and Buxanka on other days.
$buxankaLoaves = (int)round($breakfastBreadTotal + $lunchBreadTotal + ($dinnerBreadTotal * 4.0 / 7.0));
$patirLoaves   = (int)round($dinnerBreadTotal * 3.0 / 7.0);

$aggregated['bread_bukhanka'] = [
    'key'        => 'bread_bukhanka',
    'name'       => 'Non (Qolipli Buxanka)',
    'unit'       => 'dona',
    'qty'        => max(1, $buxankaLoaves),
    'meal_types' => ['breakfast', 'lunch', 'dinner']
];

$aggregated['bread_patir'] = [
    'key'        => 'bread_patir',
    'name'       => 'Non (Tandir Patir / Obi non)',
    'unit'       => 'dona',
    'qty'        => max(1, $patirLoaves),
    'meal_types' => ['dinner']
];

// 2. Tea Calculation: realistic 100g pack per 2-3 days for 4 students (approx 0.5 pack per roommate per week, min 1)
$teaQty = max(1.0, round($roommateCount * 0.5, 0));
$aggregated['tea_green_black'] = [
    'key'        => 'tea_green_black',
    'name'       => 'Ko‘k choy (95-nav, 100g pachka)',
    'unit'       => 'pachka',
    'qty'        => $teaQty,
    'meal_types' => ['breakfast', 'lunch', 'dinner']
];

// 3. Sugar: approx 0.35 kg per roommate per week (1.5 kg for 4 students)
$sugarQty = max(0.5, round($roommateCount * 0.35, 1));
if (!isset($aggregated['sugar'])) {
    $aggregated['sugar'] = [
        'key'        => 'sugar',
        'name'       => 'Shakar (1 kg)',
        'unit'       => 'kg',
        'qty'        => $sugarQty,
        'meal_types' => ['breakfast', 'lunch', 'dinner']
    ];
} else {
    $aggregated['sugar']['qty'] = max((float)$aggregated['sugar']['qty'], $sugarQty);
}

// 4. Spices bundle (1 bundle per week for the student flat)
if (!isset($aggregated['salt_spices'])) {
    $aggregated['salt_spices'] = [
        'key'        => 'salt_spices',
        'name'       => 'Ziravorlar to‘plami (Zira, murch, tuz)',
        'unit'       => 'to‘plam',
        'qty'        => 1.0,
        'meal_types' => ['dinner']
    ];
}

// 5. Ensure minimum cooking oil
foreach (['oil_vegetable', 'oil_cotton'] as $oilKey) {
    if (isset($aggregated[$oilKey])) {
        $minOil = max(0.5, round($roommateCount * 0.25, 1));
        $aggregated[$oilKey]['qty'] = max((float)$aggregated[$oilKey]['qty'], $minOil);
    }
}

// Calculate final costs and build grocery list
$totalCostUzs    = 0;
$minTotalCostUzs = 0;
$maxTotalCostUzs = 0;
$groceryList     = [];

foreach ($aggregated as $key => $item) {
    $qty = max(0.05, round((float)$item['qty'], 2));
    $price = $priceMap[$key] ?? $defaultPrices[$key] ?? [
        'item_key' => $key, 'name_uz' => $item['name'], 'category' => 'Boshqa',
        'unit' => $item['unit'], 'avg_price_uzs' => 10000, 'min_price_uzs' => 8000, 'max_price_uzs' => 12000,
        'cheapest_source' => 'Dehqon bozor', 'buying_tips' => ''
    ];

    $avgPrice = (int)$price['avg_price_uzs'];
    $minPrice = (int)$price['min_price_uzs'];
    $maxPrice = (int)$price['max_price_uzs'];
    $unit     = $price['unit'] ?? $item['unit'];

    $itemTotalCost = (int)round($avgPrice * $qty);
    $itemMinCost   = (int)round($minPrice * $qty);
    $itemMaxCost   = (int)round($maxPrice * $qty);

    $totalCostUzs    += $itemTotalCost;
    $minTotalCostUzs += $itemMinCost;
    $maxTotalCostUzs += $itemMaxCost;

    $mealLabels = array_map(fn($mt) => match($mt) {
        'breakfast' => '🌅 Nonushta',
        'lunch'     => '🌤 Tushlik',
        'dinner'    => '🌙 Kechki',
        default     => $mt
    }, $item['meal_types'] ?? []);

    $groceryList[] = [
        'item_key'        => $key,
        'name_uz'         => $price['name_uz'] ?? $item['name'],
        'category'        => $price['category'] ?? 'Boshqa',
        'unit'            => $unit,
        'qty_needed'      => $qty,
        'avg_price_uzs'   => $avgPrice,
        'min_price_uzs'   => $minPrice,
        'max_price_uzs'   => $maxPrice,
        'total_cost_uzs'  => $itemTotalCost,
        'cheapest_source' => $price['cheapest_source'] ?? 'Chorsu bozor',
        'buying_tips'     => $price['buying_tips'] ?? '',
        'used_for_meals'  => $mealLabels
    ];
}

// Sort by highest item total cost first
usort($groceryList, fn($a, $b) => $b['total_cost_uzs'] <=> $a['total_cost_uzs']);

$perPersonTotal = $roommateCount > 0 ? (int)round($totalCostUzs / $roommateCount) : 0;
$perPersonDaily = ($days > 0 && $roommateCount > 0) ? (int)round($totalCostUzs / $roommateCount / $days) : 0;

// Category Summary
$categorySummary = [];
foreach ($groceryList as $item) {
    $cat = $item['category'];
    if (!isset($categorySummary[$cat])) {
        $categorySummary[$cat] = ['category' => $cat, 'total_uzs' => 0, 'item_count' => 0];
    }
    $categorySummary[$cat]['total_uzs']  += $item['total_cost_uzs'];
    $categorySummary[$cat]['item_count'] += 1;
}
usort($categorySummary, fn($a, $b) => $b['total_uzs'] <=> $a['total_uzs']);

$buxankaPrice = $priceMap['bread_bukhanka']['avg_price_uzs'] ?? 3000;
$patirPrice   = $priceMap['bread_patir']['avg_price_uzs'] ?? 5000;
$totalBreadSpend = (int)($buxankaLoaves * $buxankaPrice + $patirLoaves * $patirPrice);

json_response([
    'ok'               => true,
    'group_code'       => $groupCode,
    'roommates'        => $roommateCount,
    'roommate_count'   => $roommateCount,
    'days'             => $days,
    'meals_per_day'    => 3,
    'total_meal_slots' => count($planRows),
    'grocery_list'     => $groceryList,
    'summary' => [
        'total_cost_uzs'       => $totalCostUzs,
        'min_total_cost_uzs'   => $minTotalCostUzs,
        'max_total_cost_uzs'   => $maxTotalCostUzs,
        'savings_potential_uzs'=> max(0, $maxTotalCostUzs - $minTotalCostUzs),
        'total_cost_usd'       => round($totalCostUzs / 12800, 1),
        'per_person_uzs'       => $perPersonTotal,
        'per_person_daily_uzs' => $perPersonDaily,
        'per_person_daily_usd' => round($perPersonDaily / 12800, 2),
        'cheapest_market'      => 'Qo‘yliq ulgurji dehqon bozori (Shanba/Yakshanba 07:00–09:00)',
        'shopping_day'         => 'Shanba ertalab (Navbatchi xonadoshlar)',
        'by_category'          => array_values($categorySummary)
    ],
    'bread_breakdown' => [
        'breakfast_lunch_buxanka' => (int)round($breakfastBreadTotal + $lunchBreadTotal),
        'dinner_buxanka'          => (int)round($dinnerBreadTotal * 4.0 / 7.0),
        'dinner_patir'            => $patirLoaves,
        'total_buxanka'           => $buxankaLoaves,
        'total_patir'             => $patirLoaves,
        'weekly_total_bread_spend'=> $totalBreadSpend
    ]
]);
