import 'package:intl/intl.dart';

/// Global currency code kept in sync by [SettingsNotifier].
String activeCurrencyCode = 'USD';

String currencyPrefix() => '${symbolFor(activeCurrencyCode)} ';

String formatAmount(int amountMinor) {
  final amount = amountMinor / 100;
  final fmt = NumberFormat.currency(locale: 'en_US', symbol: symbolFor(activeCurrencyCode));
  return fmt.format(amount);
}

int parseAmountToMinor(String text) {
  final cleaned = text.replaceAll(RegExp(r'[^\d.]'), '');
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
