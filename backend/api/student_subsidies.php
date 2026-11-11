<?php
declare(strict_types=1);

/**
 * API: Student Housing Subsidy & Legal Lease Agreement Advisory
 * - O'zbekiston Respublikasi Vazirlar Mahkamasi 605-son qarori (Talabalarga 50% ijara kompensatsiyasi)
 * - ijara.soliq.uz orqali qonuniy ro'yxatdan o'tkazish tartibi
 * - Qonuniy namunaviy shartnoma shablonlari
 */

require_once dirname(__DIR__) . '/includes/bootstrap.php';

json_response([
    'ok' => true,
    'title' => "Talabalarga 50% Davlat Ijara Kompensatsiyasi va Qonuniy Shartnoma Qo'llanmasi",
    'subsidy_info' => [
        'legal_basis' => "Vazirlar Mahkamasining 2021-yil 24-sentabrdagi 605-son qarori",
        'amount_tashkent' => "BHMning 1 baravari (oyiga 375 000 so'mgacha)",
        'amount_regions' => "BHMning 0.5 baravari (oyiga 187 500 so'mgacha)",
        'eligibility' => [
            "Davlat Oliy Ta’lim Muassasalarining kunduzgi bo‘limida tahsil olayotgan talabalar",
            "Yotoqxona bilan ta’minlanmagan va ijarada yashovchi talabalar",
            "Ijara shartnomasi soliq organlarida (ijara.soliq.uz) hisobga qo‘yilgan bo‘lishi shart"
        ],
        'steps_to_apply' => [
            [
                'step' => 1,
                'title' => "ijara.soliq.uz orqali shartnoma tuzish",
                'description' => "Uy egasi va talaba OneID (E-GOV) orqali tizimga kirib, ijara shartnomasini bepul va soliq to'lamasdan ro'yxatdan o'tkazadi. Eslatma: talabalarga ijaraga berilganda uy egasi daromad solig'idan to'liq ozod qilingan!"
            ],
            [
                'step' => 2,
                'title' => "Arizani dekanat / tyutorga topshirish",
                'description' => "OTM rektori nomiga ijara kompensatsiyasi so'rab ariza va soliqdan olingan QR-kodli ijara shartnomasi nusxasi taqdim etiladi."
            ],
            [
                'step' => 3,
                'title' => "Mablag'ni bank kartasiga qabul qilish",
                'description' => "Komissiya arizani ko'rib chiqib, har oyning 10-sanasiga qadar talabaning plastik kartasiga kompensatsiya pulini o'tkazib beradi."
            ]
        ],
        'official_portal_url' => "https://ijara.soliq.uz/",
        'tax_benefit_for_landlord' => "Soliq Kodeksining 378-moddasiga binoan, talabalarga turar joyni ijaraga berishdan olingan daromadlar jismoniy shaxslardan olinadigan daromad solig'iga (JShODS 12%) tortilmaydi! Uy egasiga hech qanday soliq majburiyati yuklanmaydi."
    ],
    'sample_contracts' => [
        [
            'id' => 'legal_lease_standard',
            'title' => "Kvartira / Xonani Ijaraga Berish Namunaviy Shartnomasi",
            'type' => 'lease',
            'description' => "O'zbekiston Respublikasi Fuqarolik Kodeksi talablariga to'liq mos keluvchi, uy egasi va talaba huquqlarini himoya qiluvchi shartnoma matni.",
            'download_hint' => "Ushbu shablon asosida ma'lumotlarni to'ldirib, tomonlar imzolashi yoki ijara.soliq.uz portaliga kiritishi mumkin."
        ],
        [
            'id' => 'roommate_code_of_conduct',
            'title' => "Xonadoshlar O'zaro Hamjihatlik va Tartib Shartnomasi (House Code)",
            'type' => 'coliving',
            'description' => "Xonadoshlar o'rtasida tozalik, navbatchilik, tinchlik soatlari (23:00-07:00) va umumiy xarajatlarni to'lash majburiyatlari qayd etilgan bitim.",
            'rules' => [
                "Tinchlik soatlari: soat 23:00 dan 07:00 gacha xonadonda shovqin solish, baland musiqa va mehmon chaqirish taqiqlanadi.",
                "Tozalik navbati: belgilangan kunda navbatchi oshxona, vannaxona va umumiy joylarni tozalashi shart.",
                "Kommunal va ijara to'lovlari: har oyning 5-sanasiga qadar hisoblangan hissa so'zsiz to'lanishi lozim.",
                "Oziq-ovqat adolati: umumiy bozorlik mahsulotlari teng taqsimlanadi, shaxsiy mahsulotlar egasining ruxsatisiz olinmaydi.",
                "Zararli odatlar: xonadon ichida chekish va spirtli ichimliklar iste'mol qilish qat'iyan man etiladi."
            ]
        ]
    ]
]);
