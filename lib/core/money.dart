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

/// [TextInputFormatter] that auto-replaces Eastern Arabic digits with Western
/// ones in real time as the user types or pastes text.
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

int parseAmountToMinor(String text) {
  final cleaned = toWesternDigits(text).replaceAll(RegExp(r'[^\d.]'), '');
  final parsed = double.tryParse(cleaned) ?? 0;
  return (parsed * 100).round();
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
