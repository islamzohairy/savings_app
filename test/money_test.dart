import 'package:flutter_test/flutter_test.dart';
import 'package:savings_app/core/money.dart';

void main() {
  group('toWesternDigits', () {
    test('converts Eastern Arabic digits', () {
      expect(toWesternDigits('١٢٣'), '123');
    });

    test('converts all ten digits', () {
      expect(toWesternDigits('٠١٢٣٤٥٦٧٨٩'), '0123456789');
    });

    test('converts Arabic decimal separator', () {
      expect(toWesternDigits('٥٦٫٧٨'), '56.78');
    });

    test('passes through Western digits unchanged', () {
      expect(toWesternDigits('123.45'), '123.45');
    });

    test('passes through non-digit text unchanged', () {
      expect(toWesternDigits('abc'), 'abc');
    });

    test('handles mixed Arabic and Western', () {
      expect(toWesternDigits('١٢abc٣٤'), '12abc34');
    });

    test('handles empty string', () {
      expect(toWesternDigits(''), '');
    });
  });

  group('MoneyInputFormatter', () {
    const fmt = MoneyInputFormatter();
    const empty = TextEditingValue(text: '');

    test('converts Arabic digits in real time', () {
      final result = fmt.formatEditUpdate(empty, const TextEditingValue(text: '١٢٣'));
      expect(result.text, '123');
    });

    test('passes through Western digits unchanged', () {
      final value = const TextEditingValue(text: '123');
      final result = fmt.formatEditUpdate(empty, value);
      expect(result.text, '123');
    });

    test('converts Arabic decimal separator', () {
      final result = fmt.formatEditUpdate(empty, const TextEditingValue(text: '٥٦٫٧٨'));
      expect(result.text, '56.78');
    });

    test('strips non-digit non-dot characters', () {
      final result = fmt.formatEditUpdate(empty, const TextEditingValue(text: '\$12.50'));
      expect(result.text, '12.50');
    });

    test('allows single decimal point', () {
      final result = fmt.formatEditUpdate(empty, const TextEditingValue(text: '12.50'));
      expect(result.text, '12.50');
    });

    test('keeps only first decimal point, clamps fraction on paste', () {
      final result = fmt.formatEditUpdate(empty, const TextEditingValue(text: '12.34.56'));
      expect(result.text, '12.34');
    });

    test('enforces max 2 decimal places', () {
      final result = fmt.formatEditUpdate(empty, const TextEditingValue(text: '12.567'));
      expect(result.text, '12.56');
    });

    test('enforces max 10 integer digits', () {
      final result = fmt.formatEditUpdate(empty, const TextEditingValue(text: '1234567890123'));
      expect(result.text, '1234567890');
    });

    test('allows trailing decimal point', () {
      final result = fmt.formatEditUpdate(empty, const TextEditingValue(text: '12.'));
      expect(result.text, '12.');
    });

    test('handles empty input', () {
      final result = fmt.formatEditUpdate(empty, const TextEditingValue(text: ''));
      expect(result.text, '');
    });
  });

  group('validateAmount', () {
    test('validates simple decimal', () {
      final result = validateAmount('12.50');
      expect(result.isValid, true);
      expect(result.minorUnits, 1250);
    });

    test('validates integer', () {
      final result = validateAmount('100');
      expect(result.isValid, true);
      expect(result.minorUnits, 10000);
    });

    test('rejects empty string', () {
      final result = validateAmount('');
      expect(result.isValid, false);
      expect(result.error, 'amount_empty');
    });

    test('rejects zero', () {
      final result = validateAmount('0');
      expect(result.isValid, false);
      expect(result.error, 'amount_zero');
    });

    test('negative sign is stripped by validation (formatter prevents it)', () {
      final result = validateAmount('-5');
      expect(result.isValid, true);
      expect(result.minorUnits, 500);
    });

    test('rejects trailing decimal', () {
      final result = validateAmount('12.');
      expect(result.isValid, false);
      expect(result.error, 'amount_incomplete');
    });

    test('rejects amount exceeding max', () {
      final result = validateAmount('1000000000000.00');
      expect(result.isValid, false);
      expect(result.error, 'amount_too_large');
    });

    test('accepts max value at boundary', () {
      final result = validateAmount('99999999999.99');
      expect(result.isValid, true);
      expect(result.minorUnits, 9999999999999);
    });

    test('parses Eastern Arabic digits', () {
      final result = validateAmount('١٢٣٤');
      expect(result.isValid, true);
      expect(result.minorUnits, 123400);
    });

    test('parses Arabic decimal', () {
      final result = validateAmount('٥٦٫٧٨');
      expect(result.isValid, true);
      expect(result.minorUnits, 5678);
    });

    test('strips currency symbols', () {
      final result = validateAmount('\$25.99');
      expect(result.isValid, true);
      expect(result.minorUnits, 2599);
    });

    test('rounds correctly', () {
      final result = validateAmount('10.999');
      expect(result.isValid, true);
      expect(result.minorUnits, 1100);
    });

    test('handles mixed Arabic and currency', () {
      final result = validateAmount('\$١٢٣.٤٥');
      expect(result.isValid, true);
      expect(result.minorUnits, 12345);
    });
  });

  group('ArabicDigitFormatter', () {
    test('converts Arabic digits in real time', () {
      const formatter = ArabicDigitFormatter();
      const old = TextEditingValue(text: '');
      final newValue = TextEditingValue(text: '١٢٣');
      final result = formatter.formatEditUpdate(old, newValue);
      expect(result.text, '123');
    });

    test('passes through Western digits', () {
      const formatter = ArabicDigitFormatter();
      const old = TextEditingValue(text: '');
      final newValue = TextEditingValue(text: '123');
      final result = formatter.formatEditUpdate(old, newValue);
      expect(result.text, '123');
      expect(identical(result, newValue), isTrue);
    });

    test('converts Arabic decimal separator', () {
      const formatter = ArabicDigitFormatter();
      const old = TextEditingValue(text: '');
      final newValue = TextEditingValue(text: '٥٦٫٧٨');
      final result = formatter.formatEditUpdate(old, newValue);
      expect(result.text, '56.78');
    });
  });

  group('formatAmount', () {
    test('formats cents to dollars', () {
      expect(formatAmount(1250), contains('12.50'));
    });

    test('formats zero', () {
      expect(formatAmount(0), contains('0.00'));
    });

    test('formats large amount', () {
      expect(formatAmount(1000000), contains('10,000.00'));
    });

    test('formats with EUR', () {
      activeCurrencyCode = 'EUR';
      final result = formatAmount(5000);
      expect(result, contains('50.00'));
      expect(result, contains('€'));
    });

    test('formats with GBP', () {
      activeCurrencyCode = 'GBP';
      final result = formatAmount(3000);
      expect(result, contains('30.00'));
      expect(result, contains('£'));
    });
  });

  group('formatCompactAmount', () {
    setUp(() { activeCurrencyCode = 'USD'; });

    test('formats zero', () {
      expect(formatCompactAmount(0), '\$0.00');
    });

    test('formats below 1000000 minor units as full amount', () {
      expect(formatCompactAmount(999999), '\$9,999.99');
    });

    test('formats 1000000 minor units as 10.0K', () {
      expect(formatCompactAmount(1000000), '\$10.0K');
    });

    test('formats 1500000 minor units as 15.0K', () {
      expect(formatCompactAmount(1500000), '\$15.0K');
    });

    test('formats 500000000 minor units as 5.0M', () {
      expect(formatCompactAmount(500000000), '\$5.0M');
    });

    test('formats 5000000000 minor units as 50.0M', () {
      expect(formatCompactAmount(5000000000), '\$50.0M');
    });

    test('formats 99900000000 minor units as 999.0M', () {
      expect(formatCompactAmount(99900000000), '\$999.0M');
    });

    test('formats 1000000000000 minor units as 10.0B', () {
      expect(formatCompactAmount(1000000000000), '\$10.0B');
    });

    test('formats negative large amount', () {
      expect(formatCompactAmount(-5000000000), '-\$50.0M');
    });

    test('formats with EGP', () {
      activeCurrencyCode = 'EGP';
      expect(formatCompactAmount(1500000), 'E£15.0K');
    });

    test('formats with SAR', () {
      activeCurrencyCode = 'SAR';
      expect(formatCompactAmount(10000000000), '﷼100.0M');
    });
  });
}
