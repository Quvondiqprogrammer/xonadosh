import 'package:flutter/services.dart';

import 'phone_countries.dart';

export 'phone_countries.dart' show PhoneCountry;

/// International numbers stored as E.164 (`+998…`, `+7…`, `+1…`).
/// Bare 9-digit values still default to Uzbekistan.
class IntlPhone {
  IntlPhone._();

  static final _nonDigit = RegExp(r'\D');

  static String digits(String raw) => raw.replaceAll(_nonDigit, '');

  static String _stripIntlPrefix(String d) {
    if (d.startsWith('00')) return d.substring(2);
    return d;
  }

  static bool _explicitIntl(String raw) {
    final t = raw.trim();
    return t.startsWith('+') || t.startsWith('00');
  }

  static PhoneCountry? detectCountry(String raw) {
    var d = _stripIntlPrefix(digits(raw));
    if (d.isEmpty) return null;
    for (final c in PhoneCountry.byLongestDial) {
      if (c.dial.isEmpty) continue;
      if (!d.startsWith(c.dial)) continue;
      final national = d.substring(c.dial.length);
      if (national.length < c.minNational || national.length > c.maxNational) {
        continue;
      }
      if (c.dial == '7') return _russiaOrKazakhstan(national);
      return c;
    }
    return null;
  }

  static PhoneCountry _russiaOrKazakhstan(String national) {
    if (national.startsWith('6') || national.startsWith('7')) {
      return PhoneCountry.byIso('KZ');
    }
    return PhoneCountry.byIso('RU');
  }

  static String nationalDigits(String raw, PhoneCountry country) {
    var d = _stripIntlPrefix(digits(raw));
    if (country.dial.isNotEmpty && d.startsWith(country.dial)) {
      d = d.substring(country.dial.length);
    }
    if (d.length > country.maxNational) {
      d = d.substring(d.length - country.maxNational);
    }
    return d;
  }

  static String formatNational(String national, PhoneCountry country) {
    final d = digits(national);
    if (country.iso == 'UZ') return _groupUz(d);
    if (d.length <= 3) return d;
    final buf = StringBuffer();
    for (var i = 0; i < d.length; i++) {
      if (i > 0 && i % 3 == 0) buf.write(' ');
      buf.write(d[i]);
    }
    return buf.toString();
  }

  static String _groupUz(String d) {
    if (d.length <= 2) return d;
    if (d.length <= 5) return '${d.substring(0, 2)} ${d.substring(2)}';
    if (d.length <= 7) {
      return '${d.substring(0, 2)} ${d.substring(2, 5)} ${d.substring(5)}';
    }
    return '${d.substring(0, 2)} ${d.substring(2, 5)} ${d.substring(5, 7)} ${d.substring(7)}';
  }

  /// E.164, or empty if the value cannot be a phone number.
  static String normalize(String raw, {PhoneCountry? country}) {
    final selected = country ?? PhoneCountry.uzbekistan;
    final t = raw.trim();
    var d = _stripIntlPrefix(digits(t));
    if (d.isEmpty) return '';

    if (_explicitIntl(t) || (selected.dial.isEmpty && d.length >= 8)) {
      if (d.length < 8 || d.length > 15 || d.startsWith('0')) return '';
      return '+$d';
    }

    if (selected.dial.isEmpty) {
      if (d.length < 8 || d.length > 15 || d.startsWith('0')) return '';
      return '+$d';
    }

    if (d.startsWith(selected.dial)) {
      final rest = d.substring(selected.dial.length);
      if (rest.length >= selected.minNational &&
          rest.length <= selected.maxNational) {
        return '+$d';
      }
    }

    if (d.length >= selected.minNational &&
        d.length <= selected.maxNational &&
        !d.startsWith('0')) {
      return '+${selected.dial}$d';
    }

    // Legacy UZ: 9 digits regardless of selected country if they typed a local UZ mobile.
    if (selected.iso == 'UZ' || !_explicitIntl(t)) {
      if (d.length == 9 && !d.startsWith('0') && selected.iso == 'UZ') {
        return '+998$d';
      }
    }

    final detected = detectCountry(t.startsWith('+') ? t : '+$d');
    if (detected != null) {
      return '+${detected.dial}${nationalDigits(d, detected)}';
    }

    if (d.length >= 10 && d.length <= 15 && !d.startsWith('0')) {
      return '+$d';
    }
    return '';
  }

  static bool isValid(String raw, {PhoneCountry? country}) {
    final n = normalize(raw, country: country);
    return n.length >= 9 && n.length <= 16 && n.startsWith('+');
  }

  static bool looksLikePhone(String raw) {
    final d = _stripIntlPrefix(digits(raw));
    if (d.length < 8) return false;
    return raw.contains('+') || d.length >= 9;
  }
}

/// National digits for the selected country (strips `+dial` if pasted).
class PhoneNationalFormatter extends TextInputFormatter {
  PhoneNationalFormatter(this.country);

  final PhoneCountry country;

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final raw = newValue.text.trim();
    if (raw.startsWith('+') || raw.startsWith('00')) {
      final detected = IntlPhone.detectCountry(raw);
      if (detected != null && detected.iso != country.iso) {
        return newValue;
      }
    }
    var d = IntlPhone.digits(newValue.text);
    if (d.startsWith('00')) d = d.substring(2);
    if (country.dial.isNotEmpty && d.startsWith(country.dial)) {
      d = d.substring(country.dial.length);
    }
    if (d.length > country.maxNational) {
      d = d.substring(0, country.maxNational);
    }
    final formatted = IntlPhone.formatNational(d, country);
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

/// Back-compat helpers: 9-digit local numbers still mean Uzbekistan.
class UzPhone {
  UzPhone._();

  static String digits(String raw) => IntlPhone.digits(raw);

  static String normalize(String raw) =>
      IntlPhone.normalize(raw, country: PhoneCountry.uzbekistan);

  static bool isValid(String raw) =>
      IntlPhone.isValid(raw, country: PhoneCountry.uzbekistan);

  static String formatLocal(String raw) => IntlPhone.formatNational(
    IntlPhone.nationalDigits(raw, PhoneCountry.uzbekistan),
    PhoneCountry.uzbekistan,
  );
}

class UzLocalPhoneFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    return PhoneNationalFormatter(
      PhoneCountry.uzbekistan,
    ).formatEditUpdate(oldValue, newValue);
  }
}

class AuthUsername {
  AuthUsername._();

  static final pattern = RegExp(r'^[a-z0-9._]{3,32}$');

  static String normalize(String raw) =>
      raw.trim().toLowerCase().replaceAll(RegExp(r'\s+'), '');

  static bool isValid(String raw) => pattern.hasMatch(normalize(raw));
}
