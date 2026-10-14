import 'package:flutter_test/flutter_test.dart';
import 'package:xonadosh/domain/uz_phone.dart';

void main() {
  group('UzPhone / UZ default', () {
    test('normalizes common Uzbekistan formats to +998', () {
      expect(UzPhone.normalize('901234567'), '+998901234567');
      expect(UzPhone.normalize('90 123 45 67'), '+998901234567');
      expect(UzPhone.normalize('+998 90 123-45-67'), '+998901234567');
      expect(UzPhone.normalize('998901234567'), '+998901234567');
      expect(UzPhone.normalize('00998901234567'), '+998901234567');
    });

    test('rejects too-short numbers', () {
      expect(UzPhone.normalize('12345'), '');
      expect(UzPhone.isValid('90 12'), isFalse);
    });

    test('formats local grouping', () {
      expect(UzPhone.formatLocal('901234567'), '90 123 45 67');
    });
  });

  group('IntlPhone', () {
    test('keeps explicit international numbers', () {
      expect(IntlPhone.normalize('+1 415 555 2671'), '+14155552671');
      expect(IntlPhone.normalize('+90 532 123 4567'), '+905321234567');
      expect(IntlPhone.normalize('00 82 10 1234 5678'), '+821012345678');
    });

    test('uses selected country for local digits', () {
      final kz = PhoneCountry.byIso('KZ');
      expect(IntlPhone.normalize('7011234567', country: kz), '+77011234567');
      expect(IntlPhone.isValid('7011234567', country: kz), isTrue);
    });

    test('detects Kazakhstan vs Russia on +7', () {
      expect(IntlPhone.detectCountry('+7 701 123 4567')?.iso, 'KZ');
      expect(IntlPhone.detectCountry('+7 912 345 6789')?.iso, 'RU');
    });

    test('does not treat a US number as Uzbekistan', () {
      expect(IntlPhone.normalize('+14155552671'), isNot(startsWith('+998')));
    });
  });

  group('UzLocalPhoneFormatter', () {
    test('strips country code when pasted', () {
      final formatter = UzLocalPhoneFormatter();
      final next = formatter.formatEditUpdate(
        TextEditingValue.empty,
        const TextEditingValue(text: '+998901234567'),
      );
      expect(next.text, '90 123 45 67');
    });
  });

  group('AuthUsername', () {
    test('lowercases and strips spaces', () {
      expect(AuthUsername.normalize(' Ali Valiyev '), 'alivaliyev');
      expect(AuthUsername.isValid('ali.valiyev'), isTrue);
      expect(AuthUsername.isValid('ab'), isFalse);
      expect(AuthUsername.isValid('Ali'), isTrue);
    });
  });
}
