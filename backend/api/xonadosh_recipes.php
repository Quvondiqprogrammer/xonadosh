<?php
declare(strict_types=1);
/**
 * API: Student Recipes & Weekly Meal Planner (3 meals/day)
 */
require_once dirname(__DIR__) . '/includes/bootstrap.php';
require_once dirname(__DIR__) . '/includes/db.php';
try { $pdo = db_connect($cfg); }
catch (Throwable $e) { json_response(['ok'=>false,'error'=>'Database connection failed: '.$e->getMessage()],500); }

$groupCode = isset($_GET['group_code']) ? trim($_GET['group_code']) : 'home_default';
$method = $_SERVER['REQUEST_METHOD'] ?? 'GET';

if ($method === 'POST') {
    $raw = file_get_contents('php://input');
    $body = json_decode($raw, true) ?? $_POST;
    $action = $body['action'] ?? 'set_plan';

    if ($action === 'set_plan') {
        $day      = (string)($body['day_of_week'] ?? 'dushanba');
        $mealTime = (string)($body['meal_time']   ?? 'dinner');
        $recipeId = isset($body['recipe_id']) && $body['recipe_id'] !== '' ? (int)$body['recipe_id'] : null;
        $recipeName = trim((string)($body['recipe_name'] ?? 'Kechki ovqat'));
        $cookName   = trim((string)($body['cook_name']   ?? 'Xonadosh'));
        $notes      = trim((string)($body['notes'] ?? ''));

        $ex = $pdo->prepare("SELECT id FROM `xonadosh_meal_plans` WHERE group_code=? AND day_of_week=? AND meal_time=?");
        $ex->execute([$groupCode, $day, $mealTime]);
        $planId = $ex->fetchColumn();

        if ($planId) {
            $stmt = $pdo->prepare("UPDATE `xonadosh_meal_plans` SET `recipe_id`=?,`recipe_name`=?,`cook_name`=?,`notes`=? WHERE id=?");
            $stmt->execute([$recipeId, $recipeName, $cookName, $notes, $planId]);
        } else {
            $stmt = $pdo->prepare("INSERT INTO `xonadosh_meal_plans` (`group_code`,`day_of_week`,`meal_time`,`recipe_id`,`recipe_name`,`cook_name`,`notes`) VALUES (?,?,?,?,?,?,?)");
            $stmt->execute([$groupCode, $day, $mealTime, $recipeId, $recipeName, $cookName, $notes]);
        }
        json_response(['ok'=>true,'message'=>'Haftalik taomlar rejasi yangilandi!']);
    }

    if ($action === 'create_recipe') {
        $nameUz        = trim((string)($body['name_uz'] ?? ''));
        $category      = (string)($body['category']      ?? 'Kechki ovqat');
        $prepTimeMin   = (int)($body['prep_time_min']    ?? 30);
        $costLevel     = (string)($body['cost_level']    ?? 'budget');
        $ingredients   = is_array($body['ingredients'] ?? null) ? $body['ingredients'] : [];
        $instructionsUz= trim((string)($body['instructions_uz'] ?? ''));
        $caloriesKcal  = (int)($body['calories_kcal']   ?? 450);
        $imageUrl      = (string)($body['image_url']    ?? '');

        if (empty($nameUz)) {
            json_response(['ok'=>false,'error'=>'Taom nomi kiritilishi shart'],400);
        }
        $stmt = $pdo->prepare("INSERT INTO `xonadosh_recipes` (`name_uz`,`category`,`prep_time_min`,`cost_level`,`ingredients_json`,`instructions_uz`,`calories_kcal`,`image_url`) VALUES (?,?,?,?,?,?,?,?)");
        $stmt->execute([$nameUz,$category,$prepTimeMin,$costLevel,json_encode($ingredients,JSON_UNESCAPED_UNICODE),$instructionsUz,$caloriesKcal,$imageUrl]);
        $recipeId = (int)$pdo->lastInsertId();
        json_response(['ok'=>true,'message'=>'Yangi taom qo\'shildi!','recipe_id'=>$recipeId]);
    }
}

// 1. Fetch all recipes
$recipes = [];
foreach ($pdo->query("SELECT * FROM `xonadosh_recipes` ORDER BY id ASC")->fetchAll(PDO::FETCH_ASSOC) as $r) {
    $ingredients = [];
    if (!empty($r['ingredients_json'])) {
        $decoded = json_decode($r['ingredients_json'], true);
        if (is_array($decoded)) $ingredients = $decoded;
    }
    $recipes[] = [
        'id'              => (int)$r['id'],
        'name_uz'         => $r['name_uz'],
        'category'        => $r['category'],
        'prep_time_min'   => (int)$r['prep_time_min'],
        'cost_level'      => $r['cost_level'],
        'ingredients'     => $ingredients,
        'instructions_uz' => $r['instructions_uz'],
        'calories_kcal'   => (int)$r['calories_kcal'],
        'image_url'       => $r['image_url']
    ];
}

// 2. Fetch weekly meal plans — ALL 3 meals per day
$dayOrder = ['dushanba','seshanba','chorshanba','payshanba','juma','shanba','yakshanba'];
$mealOrder = ['breakfast','lunch','dinner'];

$pStmt = $pdo->prepare("
    SELECT p.*,
           r.image_url   AS recipe_image,
           r.prep_time_min AS recipe_prep_min,
           r.cost_level  AS recipe_cost_level,
           r.calories_kcal AS recipe_calories
    FROM `xonadosh_meal_plans` p
    LEFT JOIN `xonadosh_recipes` r ON p.recipe_id = r.id
    WHERE p.group_code = ?
    ORDER BY FIELD(p.day_of_week,'dushanba','seshanba','chorshanba','payshanba','juma','shanba','yakshanba'),
             FIELD(p.meal_time,'breakfast','lunch','dinner')
");
$pStmt->execute([$groupCode]);
$planRows = $pStmt->fetchAll(PDO::FETCH_ASSOC);

// Build flat list and grouped-by-day view
$weeklyPlan = [];
$weeklyGrouped = [];
foreach ($planRows as $p) {
    $slot = [
        'id'              => (int)$p['id'],
        'day_of_week'     => $p['day_of_week'],
        'meal_time'       => $p['meal_time'],
        'meal_time_label' => match($p['meal_time']) {
            'breakfast' => '🌅 Nonushta',
            'lunch'     => '🌤 Tushlik',
            'dinner'    => '🌙 Kechki ovqat',
            default     => $p['meal_time']
        },
        'recipe_id'       => $p['recipe_id'] !== null ? (int)$p['recipe_id'] : null,
        'recipe_name'     => $p['recipe_name'] ?? '',
        'cook_name'       => $p['cook_name'] ?? 'Xonadosh',
        'prep_schedule'   => $p['prep_schedule']   ?? '',
        'eating_schedule' => $p['eating_schedule'] ?? '',
        'cleanup_schedule'=> $p['cleanup_schedule']?? '',
        'bread_count'     => (float)($p['bread_count'] ?? 0.5),
        'tea_type'        => $p['tea_type'] ?? "Ko'k choy (95-nav)",
        'notes'           => $p['notes'] ?? '',
        'recipe_image'    => $p['recipe_image'],
        'prep_time_min'   => $p['recipe_prep_min'] !== null ? (int)$p['recipe_prep_min'] : 15,
        'cost_level'      => $p['recipe_cost_level'] ?? 'budget',
        'calories_kcal'   => $p['recipe_calories'] !== null ? (int)$p['recipe_calories'] : 400
    ];
    $weeklyPlan[] = $slot;

    // Grouped by day
    $day = $p['day_of_week'];
    if (!isset($weeklyGrouped[$day])) {
        $weeklyGrouped[$day] = ['day_of_week'=>$day,'meals'=>[]];
    }
    $weeklyGrouped[$day]['meals'][$p['meal_time']] = $slot;
}

// Reorder grouped
$groupedOrdered = [];
foreach ($dayOrder as $day) {
    if (isset($weeklyGrouped[$day])) {
        $mealsOrdered = [];
        foreach ($mealOrder as $mt) {
            if (isset($weeklyGrouped[$day]['meals'][$mt])) {
                $mealsOrdered[] = $weeklyGrouped[$day]['meals'][$mt];
            }
        }
        $groupedOrdered[] = ['day_of_week'=>$day,'meals'=>$mealsOrdered];
    }
}

json_response([
    'ok'                => true,
    'recipes_count'     => count($recipes),
    'recipes'           => $recipes,
    'weekly_meal_plan'  => $weeklyPlan,       // flat list (legacy)
    'weekly_grouped'    => $groupedOrdered,    // grouped by day (new)
    'meal_slots_count'  => count($weeklyPlan)
]);
