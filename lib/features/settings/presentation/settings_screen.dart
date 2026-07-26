import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../../core/settings_provider.dart';
import '../../../core/money.dart';
import '../../../l10n/app_localizations.dart';
import 'backup_restore.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final currency = settings['currencyCode'] ?? 'USD';
    final themeMode = settings['themeMode'] ?? 'system';
    final languageCode = settings['languageCode'] ?? 'system';
    final appLockEnabled = settings['appLockEnabled'] == 'true';

    return Scaffold(
      appBar: AppBar(title: Text(AppLocalizations.of(context)!.appBarTitle_settings)),
      body: ListView(
        children: [
          _section(AppLocalizations.of(context)!.sectionTitle_general, context),
          ListTile(
            title: Text(AppLocalizations.of(context)!.setting_currency),
            subtitle: Text(currency),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _pickCurrency(context, ref),
          ),
          ListTile(
            title: Text(AppLocalizations.of(context)!.setting_theme),
            subtitle: Text(_themeLabel(themeMode, AppLocalizations.of(context)!)),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _pickTheme(context, ref),
          ),
          ListTile(
            title: Text(AppLocalizations.of(context)!.setting_language),
            subtitle: Text(_languageLabel(languageCode, AppLocalizations.of(context)!)),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _pickLanguage(context, ref),
          ),
          const Divider(),
          _section(AppLocalizations.of(context)!.sectionTitle_security, context),
          SwitchListTile(
            title: Text(AppLocalizations.of(context)!.setting_appLock),
            subtitle: Text(AppLocalizations.of(context)!.setting_appLockSubtitle),
            value: appLockEnabled,
            onChanged: (v) => ref.read(settingsProvider.notifier).set('appLockEnabled', '$v'),
          ),
          if (appLockEnabled)
            ListTile(
              title: Text(AppLocalizations.of(context)!.setting_changePin),
              subtitle: Text(AppLocalizations.of(context)!.setting_changePinSubtitle),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => _changePin(context),
            ),
          const Divider(),
          _section(AppLocalizations.of(context)!.sectionTitle_data, context),
          ListTile(
            title: Text(AppLocalizations.of(context)!.setting_backup),
            subtitle: Text(AppLocalizations.of(context)!.setting_backupSubtitle),
            trailing: const Icon(Icons.download),
            onTap: () => backupDatabase(context),
          ),
          ListTile(
            title: Text(AppLocalizations.of(context)!.setting_restore),
            subtitle: Text(AppLocalizations.of(context)!.setting_restoreSubtitle),
            trailing: const Icon(Icons.upload),
            onTap: () => restoreDatabase(context),
          ),
          const Divider(),
          _section(AppLocalizations.of(context)!.sectionTitle_about, context),
          ListTile(
            title: Text(AppLocalizations.of(context)!.setting_appName),
            subtitle: Text(AppLocalizations.of(context)!.setting_appVersion),
          ),
        ],
      ),
    );
  }

  Widget _section(String title, BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Builder(builder: (context) => Text(title, style: Theme.of(context).textTheme.labelLarge?.copyWith(
        color: Theme.of(context).colorScheme.primary,
      ))),
    );
  }

  String _themeLabel(String mode, AppLocalizations loc) {
    switch (mode) {
      case 'light': return loc.theme_light;
      case 'dark': return loc.theme_dark;
      default: return loc.theme_system;
    }
  }

  String _languageLabel(String code, AppLocalizations loc) {
    switch (code) {
      case 'en': return loc.lang_en;
      case 'ar': return loc.lang_ar;
      default: return loc.lang_system;
    }
  }

  Future<void> _pickLanguage(BuildContext context, WidgetRef ref) async {
    final loc = AppLocalizations.of(context)!;
    final options = [
      ('system', loc.lang_system),
      ('en', loc.lang_en),
      ('ar', loc.lang_ar),
    ];
    final picked = await showDialog<String>(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: Text(loc.dialog_languageTitle),
        children: options.map((o) => SimpleDialogOption(
          onPressed: () => Navigator.pop(ctx, o.$1),
          child: Text(o.$2),
        )).toList(),
      ),
    );
    if (picked != null) {
      await ref.read(settingsProvider.notifier).set('languageCode', picked);
    }
  }

  Future<void> _pickCurrency(BuildContext context, WidgetRef ref) async {
    final currencies = ['USD', 'EUR', 'GBP', 'EGP', 'SAR', 'AED'];
    final picked = await showDialog<String>(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: Text(AppLocalizations.of(context)!.dialog_currencyTitle),
        children: currencies.map((c) => SimpleDialogOption(
          onPressed: () => Navigator.pop(ctx, c),
          child: Text(c),
        )).toList(),
      ),
    );
    if (picked != null) {
      await ref.read(settingsProvider.notifier).set('currencyCode', picked);
    }
  }

  Future<void> _pickTheme(BuildContext context, WidgetRef ref) async {
    final modes = ['system', 'light', 'dark'];
    final picked = await showDialog<String>(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: Text(AppLocalizations.of(context)!.dialog_themeTitle),
        children: modes.map((m) => SimpleDialogOption(
          onPressed: () => Navigator.pop(ctx, m),
          child: Text(_themeLabel(m, AppLocalizations.of(context)!)),
        )).toList(),
      ),
    );
    if (picked != null) {
      await ref.read(settingsProvider.notifier).set('themeMode', picked);
    }
  }

  Future<void> _changePin(BuildContext context) async {
    final storage = const FlutterSecureStorage();
    final storedPin = await storage.read(key: 'app_lock_pin');
    if (storedPin == null || storedPin.isEmpty) return;

    if (!context.mounted) return;
    final pinCtrl = TextEditingController();
    final verified = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.dialog_verifyCurrentPinTitle),
        content: TextField(
          controller: pinCtrl,
          keyboardType: TextInputType.number,
          obscureText: true,
          maxLength: 4,
          inputFormatters: const [ArabicDigitFormatter()],
          decoration: const InputDecoration(counterText: ''),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(AppLocalizations.of(context)!.btn_cancel)),
          FilledButton(onPressed: () => Navigator.pop(ctx, toWesternDigits(pinCtrl.text) == storedPin), child: Text(AppLocalizations.of(context)!.btn_verify)),
        ],
      ),
    );
    if (verified != true) return;
    if (context.mounted) await _showSetPinDialog(context, storage);
  }

  Future<void> _showSetPinDialog(BuildContext context, FlutterSecureStorage storage) async {
    final pinCtrl = TextEditingController();
    final confirmCtrl = TextEditingController();
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.dialog_setNewPinTitle),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: pinCtrl,
              keyboardType: TextInputType.number,
              obscureText: true,
              maxLength: 4,
              inputFormatters: const [ArabicDigitFormatter()],
              decoration: InputDecoration(labelText: AppLocalizations.of(context)!.fieldLabel_newPin, counterText: ''),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: confirmCtrl,
              keyboardType: TextInputType.number,
              obscureText: true,
              maxLength: 4,
              inputFormatters: const [ArabicDigitFormatter()],
              decoration: InputDecoration(labelText: AppLocalizations.of(context)!.fieldLabel_confirmPin, counterText: ''),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(AppLocalizations.of(context)!.btn_cancel)),
          FilledButton(
            onPressed: () {
              if (pinCtrl.text.length == 4 && pinCtrl.text == confirmCtrl.text) {
                Navigator.pop(ctx, true);
              } else if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(AppLocalizations.of(context)!.snackbar_pinValidation)));
              }
            },
            child: Text(AppLocalizations.of(context)!.btn_save),
          ),
        ],
      ),
    );
    if (result == true) {
      await storage.write(key: 'app_lock_pin', value: pinCtrl.text);
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(AppLocalizations.of(context)!.snackbar_pinUpdated)));
    }
  }
}
