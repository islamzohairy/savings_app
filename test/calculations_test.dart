import 'package:flutter_test/flutter_test.dart';
import 'package:savings_app/core/calculations.dart';

void main() {
  group('savingsRate', () {
    test('returns correct percentage', () {
      expect(savingsRate(100000, 60000), 40.0);
    });

    test('returns 0 when income is 0', () {
      expect(savingsRate(0, 5000), 0.0);
    });

    test('returns 0 when income is negative', () {
      expect(savingsRate(-100, 50), 0.0);
    });

    test('clamps to 0 when expenses exceed income', () {
      expect(savingsRate(10000, 20000), 0.0);
    });

    test('clamps to 100 when expenses are 0', () {
      expect(savingsRate(10000, 0), 100.0);
    });

    test('handles equal income and expenses', () {
      expect(savingsRate(50000, 50000), 0.0);
    });
  });

  group('goalProgress', () {
    test('returns correct ratio', () {
      expect(goalProgress(500, 1000), 0.5);
    });

    test('clamps to 1.0 when overfunded', () {
      expect(goalProgress(1500, 1000), 1.0);
    });

    test('returns 0 when target is null', () {
      expect(goalProgress(500, null), 0.0);
    });

    test('returns 0 when target is 0', () {
      expect(goalProgress(500, 0), 0.0);
    });

    test('returns 0 when target is negative', () {
      expect(goalProgress(500, -100), 0.0);
    });

    test('returns 0 when current is 0', () {
      expect(goalProgress(0, 1000), 0.0);
    });

    test('returns 1.0 when current equals target', () {
      expect(goalProgress(1000, 1000), 1.0);
    });
  });

  group('colorFromHex', () {
    test('parses valid 6-digit hex', () {
      final color = colorFromHex('FF9800');
      expect(color.r, closeTo(1.0, 0.01));
      expect(color.g, closeTo(0.596, 0.01));
      expect(color.b, 0.0);
    });

    test('parses white', () {
      final color = colorFromHex('FFFFFF');
      expect(color.r, closeTo(1.0, 0.01));
      expect(color.g, closeTo(1.0, 0.01));
      expect(color.b, closeTo(1.0, 0.01));
    });

    test('parses black', () {
      final color = colorFromHex('000000');
      expect(color.r, 0.0);
      expect(color.g, 0.0);
      expect(color.b, 0.0);
    });

    test('throws on invalid hex', () {
      expect(() => colorFromHex('ZZZZZZ'), throwsA(anything));
    });
  });
}
