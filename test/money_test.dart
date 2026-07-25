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

  group('parseAmountToMinor', () {
    test('parses simple decimal', () {
      expect(parseAmountToMinor('12.50'), 1250);
    });

    test('parses integer', () {
      expect(parseAmountToMinor('100'), 10000);
    });

    test('strips currency symbol', () {
      expect(parseAmountToMinor('\$25.99'), 2599);
    });

    test('returns 0 for empty string', () {
      expect(parseAmountToMinor(''), 0);
    });

    test('handles euro symbol', () {
      expect(parseAmountToMinor('€50.00'), 5000);
    });

    test('rounds correctly', () {
      expect(parseAmountToMinor('10.999'), 1100);
    });

    test('parses Eastern Arabic digits', () {
      expect(parseAmountToMinor('١٢٣٤'), 123400);
    });

    test('parses Arabic decimal', () {
      expect(parseAmountToMinor('٥٦٫٧٨'), 5678);
    });

    test('parses mixed Arabic and currency symbol', () {
      expect(parseAmountToMinor('\$١٢٣.٤٥'), 12345);
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
}
