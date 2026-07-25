import 'package:flutter_test/flutter_test.dart';
import 'package:savings_app/core/money.dart';

void main() {
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
