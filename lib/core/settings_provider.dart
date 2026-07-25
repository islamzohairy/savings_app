import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/money.dart';
import 'db/database.dart';

final settingsProvider = NotifierProvider<SettingsNotifier, Map<String, String>>(SettingsNotifier.new);

class SettingsNotifier extends Notifier<Map<String, String>> {
  @override
  Map<String, String> build() => {};

  Future<void> load() async {
    final db = AppDatabase.instance;
    final keys = ['currencyCode', 'themeMode', 'monthStartDay', 'firstDayOfWeek', 'appLockEnabled', 'biometricEnabled', 'hasCompletedOnboarding'];
    final map = <String, String>{};
    for (final k in keys) {
      final v = await db.getSetting(k);
      if (v != null) map[k] = v;
    }
    state = map;
    activeCurrencyCode = currencyCode;
  }

  Future<void> set(String key, String value) async {
    await AppDatabase.instance.setSetting(key, value);
    state = {...state, key: value};
    if (key == 'currencyCode') activeCurrencyCode = value;
  }

  String get currencyCode => state['currencyCode'] ?? 'USD';

  ThemeMode get themeMode {
    switch (state['themeMode']) {
      case 'light': return ThemeMode.light;
      case 'dark': return ThemeMode.dark;
      default: return ThemeMode.system;
    }
  }
}
