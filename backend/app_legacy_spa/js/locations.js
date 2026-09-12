/**
 * Uzbekistan regions / districts — ported from Flutter xonadosh_locations.dart
 */
const Locations = (() => {
  const regions = [
    {
      id: 'toshkent_sh',
      name: 'Toshkent shahri',
      flag: '🏙️',
      districts: [
        'Yunusobod', 'Chilonzor', 'Mirzo Ulug‘bek', 'Mirobod', 'Yakkasaroy',
        'Shayxontohur', 'Olmazor', 'Yashnobod', 'Sergeli', 'Uchtepa',
        'Bektemir', 'Yangihayot',
      ],
    },
    {
      id: 'toshkent_vil',
      name: 'Toshkent viloyati',
      flag: '🏔️',
      districts: [
        'Chirchiq shahri', 'Olmaliq shahri', 'Angren shahri', 'Bekobod shahri',
        'Yangiyo‘l shahri', 'Nurafshon shahri', 'Qibray tumani', 'Zangiota tumani',
        'Bo‘stonliq tumani', 'Toshkent tumani', 'Parkent tumani', 'Yuqori Chirchiq',
        'O‘rta Chirchiq', 'Quyi Chirchiq', 'Piskent tumani', 'Oqqo‘rg‘on tumani',
        'Bo‘ka tumani', 'Chinoz tumani',
      ],
    },
    {
      id: 'samarqand',
      name: 'Samarqand viloyati',
      flag: '🕌',
      districts: [
        'Samarqand shahri', 'Kattaqo‘rg‘on shahri', 'Urgut tumani', 'Pastdarg‘om tumani',
        'Payariq tumani', 'Ishtixon tumani', 'Bulung‘ur tumani', 'Jomboy tumani',
        'Toyloq tumani', 'Narpay tumani', 'Paxtachi tumani', 'Samarqand tumani',
        'Qo‘shrabot tumani', 'Nurobod tumani', 'Oqdaryo tumani',
      ],
    },
    {
      id: 'fargona',
      name: 'Farg‘ona viloyati',
      flag: '🌸',
      districts: [
        'Farg‘ona shahri', 'Marg‘ilon shahri', 'Qo‘qon shahri', 'Quvasoy shahri',
        'Oltiariq tumani', 'Rishton tumani', 'Uchko‘prik tumani', 'Bag‘dod tumani',
        'Buvayda tumani', 'Dang‘ara tumani', 'Beshariq tumani', 'Quva tumani',
        'Toshloq tumani', 'Farg‘ona tumani', 'Yozyovon tumani', 'So‘x tumani',
      ],
    },
    {
      id: 'andijon',
      name: 'Andijon viloyati',
      flag: '🌳',
      districts: [
        'Andijon shahri', 'Xonobod shahri', 'Asaka tumani', 'Shahrixon tumani',
        'Oltinko‘l tumani', 'Baliqchi tumani', 'Bo‘ston tumani', 'Buloqboshi tumani',
        'Izboskan tumani', 'Jalaquduq tumani', 'Marhamat tumani', 'Paxtaobod tumani',
        'Qo‘rg‘ontepa tumani', 'Ulug‘nor tumani', 'Xo‘jaobod tumani', 'Andijon tumani',
      ],
    },
    {
      id: 'namangan',
      name: 'Namangan viloyati',
      flag: '🌺',
      districts: [
        'Namangan shahri', 'Davlatobod tumani', 'Yangi Namangan', 'Chortoq tumani',
        'Chust tumani', 'Kosonsoy tumani', 'Mingbuloq tumani', 'Pop tumani',
        'To‘raqo‘rg‘on tumani', 'Uchqo‘rg‘on tumani', 'Uychi tumani',
        'Yangiqo‘rg‘on tumani', 'Norin tumani',
      ],
    },
    {
      id: 'buxoro',
      name: 'Buxoro viloyati',
      flag: '🏺',
      districts: [
        'Buxoro shahri', 'Kogon shahri', 'G‘ijduvon tumani', 'Jondor tumani',
        'Vobkent tumani', 'Romitan tumani', 'Shofirkon tumani', 'Peshku tumani',
        'Qorako‘l tumani', 'Qorovulbozor tumani', 'Olot tumani', 'Buxoro tumani',
      ],
    },
    {
      id: 'qashqadaryo',
      name: 'Qashqadaryo viloyati',
      flag: '☀️',
      districts: [
        'Qarshi shahri', 'Shahrisabz shahri', 'Kitob tumani', 'Yakkabog‘ tumani',
        'Koson tumani', 'G‘uzor tumani', 'Nishon tumani', 'Qamashi tumani',
        'Chiroqchi tumani', 'Ko‘kdala tumani', 'Dehqonobod tumani', 'Kasbi tumani',
        'Mirishkor tumani', 'Muborak tumani',
      ],
    },
    {
      id: 'surxondaryo',
      name: 'Surxondaryo viloyati',
      flag: '🌴',
      districts: [
        'Termiz shahri', 'Denov tumani', 'Sherobod tumani', 'Boysun tumani',
        'Jarqo‘rg‘on tumani', 'Qumqo‘rg‘on tumani', 'Sho‘rchi tumani', 'Sariosiyo tumani',
        'Oltinsoy tumani', 'Angor tumani', 'Bandixon tumani', 'Muzrabot tumani',
        'Qiziriq tumani', 'Termiz tumani', 'Uzun tumani',
      ],
    },
    {
      id: 'xorazm',
      name: 'Xorazm viloyati',
      flag: '🏰',
      districts: [
        'Urganch shahri', 'Xiva shahri', 'Shovot tumani', 'Gurlan tumani',
        'Xonqa tumani', 'Bog‘ot tumani', 'Yangiariq tumani', 'Yangibozor tumani',
        'Qo‘shko‘pir tumani', 'Hazorasp tumani', 'Tuproqqal‘a tumani',
      ],
    },
    {
      id: 'navoiy',
      name: 'Navoiy viloyati',
      flag: '✨',
      districts: [
        'Navoiy shahri', 'Zarafshon shahri', 'Karmana tumani', 'Qiziltepa tumani',
        'Xatirchi tumani', 'Nurota tumani', 'Konimex tumani', 'Navbahor tumani',
        'Tomdi tumani', 'Uchquduq tumani',
      ],
    },
    {
      id: 'jizzax',
      name: 'Jizzax viloyati',
      flag: '🌄',
      districts: [
        'Jizzax shahri', 'Zomin tumani', 'G‘allaorol tumani', 'Sharof Rashidov',
        'Do‘stlik tumani', 'Zarbdor tumani', 'Zafarobod tumani', 'Mirzacho‘l tumani',
        'Paxtakor tumani', 'Forish tumani', 'Baxmal tumani', 'Yangiobod tumani',
        'Arnasoy tumani',
      ],
    },
    {
      id: 'sirdaryo',
      name: 'Sirdaryo viloyati',
      flag: '🌾',
      districts: [
        'Guliston shahri', 'Yangiyer shahri', 'Shirin shahri', 'Boyovut tumani',
        'Mirzaobod tumani', 'Oqoltin tumani', 'Sardoba tumani', 'Sayxunobod tumani',
        'Sirdaryo tumani', 'Xovos tumani',
      ],
    },
    {
      id: 'qoraqalpogiston',
      name: 'Qoraqalpog‘iston Res.',
      flag: '🌊',
      districts: [
        'Nukus shahri', 'Beruniy tumani', 'To‘rtko‘l tumani', 'Qo‘ng‘irot tumani',
        'Xo‘jayli tumani', 'Chimboy tumani', 'Amudaryo tumani', 'Ellikqal‘a tumani',
        'Mo‘ynoq tumani', 'Qanliko‘l tumani', 'Qorao‘zak tumani', 'Kegeyli tumani',
        'Shumanay tumani', 'Taxtako‘pir tumani', 'Taxiatosh shahri', 'Bo‘zatov tumani',
      ],
    },
    {
      id: 'xorij',
      name: 'Xorij / Xalqaro (International)',
      flag: '🌍',
      isInternational: true,
      districts: [
        'Rossiya (Moskva)', 'Rossiya (Sankt-Peterburg)', 'Rossiya (Qozon)',
        'Rossiya (Novosibirsk)', 'Turkiya (Istanbul)', 'Turkiya (Anqara)',
        'Turkiya (Antaliya)', 'Janubiy Koreya (Seul)', 'Janubiy Koreya (Pusan)',
        'Janubiy Koreya (Incheon)', 'AQSH (Nyu-York)', 'AQSH (Chikago)',
        'AQSH (Los-Anjeles)', 'Qozog‘iston (Almati)', 'Qozog‘iston (Ostona)',
        'Qirg‘iziston (Bishkek)', 'Tojikiston (Dushanbe)', 'BAA (Dubay)',
        'BAA (Abu Dabi)', 'Germaniya (Berlin)', 'Germaniya (Myunxen)',
        'Buyuk Britaniya (London)', 'Polsha (Varshava)', 'Yaponiya (Tokio)',
        'Xitoy (Pekin)', 'Xitoy (Shanxay)', 'Boshqa shahar / Davlat',
      ],
    },
  ];

  const currencySymbols = {
    UZS: 'so‘m',
    USD: '$',
    EUR: '€',
    RUB: '₽',
  };

  const pricePeriods = ['month', 'day', 'year', 'total'];

  const presetPhotos = [
    { title: 'Zamonaviy Kvartira', url: 'https://images.unsplash.com/photo-1522708323590-d24dbb6b0267?w=800' },
    { title: 'Shinam Xona', url: 'https://images.unsplash.com/photo-1502672260266-1c1ef2d93688?w=800' },
    { title: 'Yangi Hovli Uy', url: 'https://images.unsplash.com/photo-1568605114967-8130f3a36994?w=800' },
    { title: 'Studiya / Kvartira', url: 'https://images.unsplash.com/photo-1560448204-e02f11c3d0e2?w=800' },
    { title: 'Yorug‘ Mehmonxona', url: 'https://images.unsplash.com/photo-1512917774080-9991f1c4c750?w=800' },
    { title: 'Kottej / Villa', url: 'https://images.unsplash.com/photo-1600585154340-be6161a56a0c?w=800' },
  ];

  function districtsFor(city) {
    if (!city) return [];
    const region = regions.find((r) => r.name.toLowerCase() === String(city).toLowerCase());
    return region ? region.districts.slice() : (regions[0] ? regions[0].districts.slice() : []);
  }

  return { regions, districtsFor, currencySymbols, pricePeriods, presetPhotos };
})();
