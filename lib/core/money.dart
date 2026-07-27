import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

/// Global currency code kept in sync by [SettingsNotifier].
String activeCurrencyCode = 'USD';

String currencyPrefix() => '${symbolFor(activeCurrencyCode)} ';

String formatAmount(int amountMinor) {
  final amount = amountMinor / 100;
  final fmt = NumberFormat.currency(locale: 'en_US', symbol: symbolFor(activeCurrencyCode));
  return fmt.format(amount);
}

/// Converts Eastern Arabic numerals (٠–٩) and the Arabic decimal separator (٫)
/// to their Western equivalents so downstream parsers handle them correctly.
String toWesternDigits(String input) {
  const eastern = '٠١٢٣٤٥٦٧٨٩';
  final buf = StringBuffer();
  for (final ch in input.runes) {
    final digit = eastern.indexOf(String.fromCharCode(ch));
    if (digit != -1) {
      buf.write(digit);
    } else if (ch == 0x066B) {
      buf.write('.');
    } else {
      buf.writeCharCode(ch);
    }
  }
  return buf.toString();
}

/// Maximum integer digits allowed in monetary input (before decimal point).
const int _maxIntegerDigits = 12;

/// Maximum decimal places allowed in monetary input.
const int _maxDecimalPlaces = 2;

/// Maximum representable value in minor units: 99,999,999,999.99
const int _maxMinorUnits = 9999999999999;

/// [TextInputFormatter] for monetary input.
///
/// - Converts Eastern Arabic digits to Western in real time.
/// - Allows only digits and a single decimal point.
/// - Enforces [_maxIntegerDigits] in the integer part.
/// - Enforces [_maxDecimalPlaces] in the fractional part.
/// - Handles paste, selection, and edge cases.
class MoneyInputFormatter extends TextInputFormatter {
  const MoneyInputFormatter();

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final converted = toWesternDigits(newValue.text);

    // Allow empty input
    if (converted.isEmpty) {
      return const TextEditingValue(
        text: '',
        selection: TextSelection.collapsed(offset: 0),
      );
    }

    // Strip everything except digits and one decimal point
    final cleaned = converted.replaceAll(RegExp(r'[^\d.]'), '');

    // Handle multiple decimal points — keep only the first
    final firstDot = cleaned.indexOf('.');
    final result = firstDot == -1
        ? cleaned
        : '${cleaned.substring(0, firstDot + 1)}${cleaned.substring(firstDot + 1).replaceAll('.', '')}';

    // Split into integer and decimal parts
    final parts = result.split('.');
    final integerPart = parts[0];
    final decimalPart = parts.length > 1 ? parts[1] : '';

    // Enforce max integer digits
    final clampedInteger = integerPart.length > _maxIntegerDigits
        ? integerPart.substring(0, _maxIntegerDigits)
        : integerPart;

    // Enforce max decimal places
    final clampedDecimal = decimalPart.length > _maxDecimalPlaces
        ? decimalPart.substring(0, _maxDecimalPlaces)
        : decimalPart;

    final formatted = parts.length > 1
        ? '$clampedInteger.$clampedDecimal'
        : result.contains('.')
            ? '$clampedInteger.'
            : clampedInteger;

    if (formatted == newValue.text) return newValue;

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

/// [TextInputFormatter] that auto-replaces Eastern Arabic digits with Western
/// ones. Used for PIN fields and other non-monetary digit inputs.
class ArabicDigitFormatter extends TextInputFormatter {
  const ArabicDigitFormatter();
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final converted = toWesternDigits(newValue.text);
    if (converted == newValue.text) return newValue;
    return TextEditingValue(
      text: converted,
      selection: TextSelection.collapsed(offset: converted.length),
    );
  }
}

/// Result of monetary input validation.
class AmountValidationResult {
  const AmountValidationResult({required this.isValid, this.minorUnits = 0, this.error});

  final bool isValid;
  final int minorUnits;
  final String? error;
}

/// Validates a monetary input string and returns the amount in minor units.
///
/// Checks for: empty input, zero/negative, exceeds maximum value,
/// multiple decimal points, and malformed input.
AmountValidationResult validateAmount(String text) {
  final cleaned = toWesternDigits(text).replaceAll(RegExp(r'[^\d.]'), '');

  if (cleaned.isEmpty) {
    return const AmountValidationResult(isValid: false, error: 'amount_empty');
  }

  // Reject trailing decimal (e.g. "123.")
  if (cleaned.endsWith('.')) {
    return const AmountValidationResult(isValid: false, error: 'amount_incomplete');
  }

  final parsed = double.tryParse(cleaned);
  if (parsed == null) {
    return const AmountValidationResult(isValid: false, error: 'amount_invalid');
  }

  if (parsed <= 0) {
    return const AmountValidationResult(isValid: false, error: 'amount_zero');
  }

  final minorUnits = (parsed * 100).round();

  if (minorUnits > _maxMinorUnits) {
    return const AmountValidationResult(isValid: false, error: 'amount_too_large');
  }

  return AmountValidationResult(isValid: true, minorUnits: minorUnits);
}

String symbolFor(String code) {
  switch (code) {
    case 'USD': return '\$';
    case 'EUR': return '€';
    case 'GBP': return '£';
    case 'EGP': return 'E£';
    case 'SAR': return '﷼';
    case 'AED': return 'د.إ';
    default: return code;
  }
}
