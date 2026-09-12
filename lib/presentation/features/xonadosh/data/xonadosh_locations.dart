/// O'zbekistonning barcha 14 ta ma'muriy hududi va Xalqaro yo'nalishlar ma'lumotlar bazasi
class XonadoshRegion {
  const XonadoshRegion({
    required this.id,
    required this.name,
    required this.districts,
    this.isInternational = false,
    this.flag = '🇺🇿',
  });

  final String id;
  final String name;
  final List<String> districts;
  final bool isInternational;
  final String flag;
}

class XonadoshLocationData {
  XonadoshLocationData._();

  static const List<XonadoshRegion> regions = [
    XonadoshRegion(
      id: 'toshkent_sh',
      name: 'Toshkent shahri',
      flag: '🏙️',
      districts: [
        'Yunusobod',
        'Chilonzor',
        'Mirzo Ulug‘bek',
        'Mirobod',
        'Yakkasaroy',
        'Shayxontohur',
        'Olmazor',
        'Yashnobod',
        'Sergeli',
        'Uchtepa',
        'Bektemir',
        'Yangihayot',
      ],
    ),
    XonadoshRegion(
      id: 'toshkent_vil',
      name: 'Toshkent viloyati',
      flag: '🏔️',
      districts: [
        'Chirchiq shahri',
        'Olmaliq shahri',
        'Angren shahri',
        'Bekobod shahri',
        'Yangiyo‘l shahri',
        'Nurafshon shahri',
        'Qibray tumani',
        'Zangiota tumani',
        'Bo‘stonliq tumani',
        'Toshkent tumani',
        'Parkent tumani',
        'Yuqori Chirchiq',
        'O‘rta Chirchiq',
        'Quyi Chirchiq',
        'Piskent tumani',
        'Oqqo‘rg‘on tumani',
        'Bo‘ka tumani',
        'Chinoz tumani',
      ],
    ),
    XonadoshRegion(
      id: 'samarqand',
      name: 'Samarqand viloyati',
      flag: '🕌',
      districts: [
        'Samarqand shahri',
        'Kattaqo‘rg‘on shahri',
        'Urgut tumani',
        'Pastdarg‘om tumani',
        'Payariq tumani',
        'Ishtixon tumani',
        'Bulung‘ur tumani',
        'Jomboy tumani',
        'Toyloq tumani',
        'Narpay tumani',
        'Paxtachi tumani',
        'Samarqand tumani',
        'Qo‘shrabot tumani',
        'Nurobod tumani',
        'Oqdaryo tumani',
      ],
    ),
    XonadoshRegion(
      id: 'fargona',
      name: 'Farg‘ona viloyati',
      flag: '🌸',
      districts: [
        'Farg‘ona shahri',
        'Marg‘ilon shahri',
        'Qo‘qon shahri',
        'Quvasoy shahri',
        'Oltiariq tumani',
        'Rishton tumani',
        'Uchko‘prik tumani',
        'Bag‘dod tumani',
        'Buvayda tumani',
        'Dang‘ara tumani',
        'Beshariq tumani',
        'Quva tumani',
        'Toshloq tumani',
        'Farg‘ona tumani',
        'Yozyovon tumani',
        'So‘x tumani',
      ],
    ),
    XonadoshRegion(
      id: 'andijon',
      name: 'Andijon viloyati',
      flag: '🌳',
      districts: [
        'Andijon shahri',
        'Xonobod shahri',
        'Asaka tumani',
        'Shahrixon tumani',
        'Oltinko‘l tumani',
        'Baliqchi tumani',
        'Bo‘ston tumani',
        'Buloqboshi tumani',
        'Izboskan tumani',
        'Jalaquduq tumani',
        'Marhamat tumani',
        'Paxtaobod tumani',
        'Qo‘rg‘ontepa tumani',
        'Ulug‘nor tumani',
        'Xo‘jaobod tumani',
        'Andijon tumani',
      ],
    ),
    XonadoshRegion(
      id: 'namangan',
      name: 'Namangan viloyati',
      flag: '🌺',
      districts: [
        'Namangan shahri',
        'Davlatobod tumani',
        'Yangi Namangan',
        'Chortoq tumani',
        'Chust tumani',
        'Kosonsoy tumani',
        'Mingbuloq tumani',
        'Pop tumani',
        'To‘raqo‘rg‘on tumani',
        'Uchqo‘rg‘on tumani',
        'Uychi tumani',
        'Yangiqo‘rg‘on tumani',
        'Norin tumani',
      ],
    ),
    XonadoshRegion(
      id: 'buxoro',
      name: 'Buxoro viloyati',
      flag: '🏺',
      districts: [
        'Buxoro shahri',
        'Kogon shahri',
        'G‘ijduvon tumani',
        'Jondor tumani',
        'Vobkent tumani',
        'Romitan tumani',
        'Shofirkon tumani',
        'Peshku tumani',
        'Qorako‘l tumani',
        'Qorovulbozor tumani',
        'Olot tumani',
        'Buxoro tumani',
      ],
    ),
    XonadoshRegion(
      id: 'qashqadaryo',
      name: 'Qashqadaryo viloyati',
      flag: '☀️',
      districts: [
        'Qarshi shahri',
        'Shahrisabz shahri',
        'Kitob tumani',
        'Yakkabog‘ tumani',
        'Koson tumani',
        'G‘uzor tumani',
        'Nishon tumani',
        'Qamashi tumani',
        'Chiroqchi tumani',
        'Ko‘kdala tumani',
        'Dehqonobod tumani',
        'Kasbi tumani',
        'Mirishkor tumani',
        'Muborak tumani',
      ],
    ),
    XonadoshRegion(
      id: 'surxondaryo',
      name: 'Surxondaryo viloyati',
      flag: '🌴',
      districts: [
        'Termiz shahri',
        'Denov tumani',
        'Sherobod tumani',
        'Boysun tumani',
        'Jarqo‘rg‘on tumani',
        'Qumqo‘rg‘on tumani',
        'Sho‘rchi tumani',
        'Sariosiyo tumani',
        'Oltinsoy tumani',
        'Angor tumani',
        'Bandixon tumani',
        'Muzrabot tumani',
        'Qiziriq tumani',
        'Termiz tumani',
        'Uzun tumani',
      ],
    ),
    XonadoshRegion(
      id: 'xorazm',
      name: 'Xorazm viloyati',
      flag: '🏰',
      districts: [
        'Urganch shahri',
        'Xiva shahri',
        'Shovot tumani',
        'Gurlan tumani',
        'Xonqa tumani',
        'Bog‘ot tumani',
        'Yangiariq tumani',
        'Yangibozor tumani',
        'Qo‘shko‘pir tumani',
        'Hazorasp tumani',
        'Tuproqqal‘a tumani',
      ],
    ),
    XonadoshRegion(
      id: 'navoiy',
      name: 'Navoiy viloyati',
      flag: '✨',
      districts: [
        'Navoiy shahri',
        'Zarafshon shahri',
        'Karmana tumani',
        'Qiziltepa tumani',
        'Xatirchi tumani',
        'Nurota tumani',
        'Konimex tumani',
        'Navbahor tumani',
        'Tomdi tumani',
        'Uchquduq tumani',
      ],
    ),
    XonadoshRegion(
      id: 'jizzax',
      name: 'Jizzax viloyati',
      flag: '🌄',
      districts: [
        'Jizzax shahri',
        'Zomin tumani',
        'G‘allaorol tumani',
        'Sharof Rashidov',
        'Do‘stlik tumani',
        'Zarbdor tumani',
        'Zafarobod tumani',
        'Mirzacho‘l tumani',
        'Paxtakor tumani',
        'Forish tumani',
        'Baxmal tumani',
        'Yangiobod tumani',
        'Arnasoy tumani',
      ],
    ),
    XonadoshRegion(
      id: 'sirdaryo',
      name: 'Sirdaryo viloyati',
      flag: '🌾',
      districts: [
        'Guliston shahri',
        'Yangiyer shahri',
        'Shirin shahri',
        'Boyovut tumani',
        'Mirzaobod tumani',
        'Oqoltin tumani',
        'Sardoba tumani',
        'Sayxunobod tumani',
        'Sirdaryo tumani',
        'Xovos tumani',
      ],
    ),
    XonadoshRegion(
      id: 'qoraqalpogiston',
      name: 'Qoraqalpog‘iston Res.',
      flag: '🌊',
      districts: [
        'Nukus shahri',
        'Beruniy tumani',
        'To‘rtko‘l tumani',
        'Qo‘ng‘irot tumani',
        'Xo‘jayli tumani',
        'Chimboy tumani',
        'Amudaryo tumani',
        'Ellikqal‘a tumani',
        'Mo‘ynoq tumani',
        'Qanliko‘l tumani',
        'Qorao‘zak tumani',
        'Kegeyli tumani',
        'Shumanay tumani',
        'Taxtako‘pir tumani',
        'Taxiatosh shahri',
        'Bo‘zatov tumani',
      ],
    ),
    XonadoshRegion(
      id: 'xorij',
      name: 'Xorij / Xalqaro (International)',
      flag: '🌍',
      isInternational: true,
      districts: [
        'Rossiya (Moskva)',
        'Rossiya (Sankt-Peterburg)',
        'Rossiya (Qozon)',
        'Rossiya (Novosibirsk)',
        'Turkiya (Istanbul)',
        'Turkiya (Anqara)',
        'Turkiya (Antaliya)',
        'Janubiy Koreya (Seul)',
        'Janubiy Koreya (Pusan)',
        'Janubiy Koreya (Incheon)',
        'AQSH (Nyu-York)',
        'AQSH (Chikago)',
        'AQSH (Los-Anjeles)',
        'Qozog‘iston (Almati)',
        'Qozog‘iston (Ostona)',
        'Qirg‘iziston (Bishkek)',
        'Tojikiston (Dushanbe)',
        'BAA (Dubay)',
        'BAA (Abu Dabi)',
        'Germaniya (Berlin)',
        'Germaniya (Myunxen)',
        'Buyuk Britaniya (London)',
        'Polsha (Varshava)',
        'Yaponiya (Tokio)',
        'Xitoy (Pekin)',
        'Xitoy (Shanxay)',
        'Boshqa shahar / Davlat',
      ],
    ),
  ];

  static List<String> getDistrictsForRegion(String regionName) {
    final region = regions.firstWhere(
      (r) => r.name.toLowerCase() == regionName.toLowerCase(),
      orElse: () => regions.first,
    );
    return region.districts;
  }

  static XonadoshRegion? findRegionByDistrict(String districtName) {
    for (final r in regions) {
      if (r.districts.any((d) => d.toLowerCase() == districtName.toLowerCase())) {
        return r;
      }
    }
    return null;
  }

  static const List<String> availableCurrencies = [
    'UZS',
    'USD',
    'EUR',
    'RUB',
  ];

  static const Map<String, String> currencySymbols = {
    'UZS': 'so‘m',
    'USD': '\$',
    'EUR': '€',
    'RUB': '₽',
  };

  static const List<String> pricePeriods = [
    'month',
    'day',
    'year',
    'total',
  ];

  static const Map<String, String> pricePeriodLabels = {
    'month': 'Oylik (oyiga)',
    'day': 'Kunlik (kuniga)',
    'year': 'Yillik (yiliga)',
    'total': 'Umumiy summa',
  };

  static const List<Map<String, String>> presetPhotos = [
    {
      'title': 'Zamonaviy Kvartira',
      'url': 'https://images.unsplash.com/photo-1522708323590-d24dbb6b0267?w=800',
    },
    {
      'title': 'Shinam Xona',
      'url': 'https://images.unsplash.com/photo-1502672260266-1c1ef2d93688?w=800',
    },
    {
      'title': 'Yangi Hovli Uy',
      'url': 'https://images.unsplash.com/photo-1568605114967-8130f3a36994?w=800',
    },
    {
      'title': 'Studiya / Kvartira',
      'url': 'https://images.unsplash.com/photo-1560448204-e02f11c3d0e2?w=800',
    },
    {
      'title': 'Yorug‘ Mehmonxona',
      'url': 'https://images.unsplash.com/photo-1512917774080-9991f1c4c750?w=800',
    },
    {
      'title': 'Kottej / Villa',
      'url': 'https://images.unsplash.com/photo-1600585154340-be6161a56a0c?w=800',
    },
  ];
}
