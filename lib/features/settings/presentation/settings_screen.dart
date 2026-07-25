import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as p;
import 'package:share_plus/share_plus.dart';
import 'package:file_picker/file_picker.dart';
import '../../../core/settings_provider.dart';
import '../../../core/db/database.dart';
import '../../dashboard/presentation/dashboard_screen.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final currency = settings['currencyCode'] ?? 'USD';
    final themeMode = settings['themeMode'] ?? 'system';
    final monthStartDay = int.tryParse(settings['monthStartDay'] ?? '1') ?? 1;
    final appLockEnabled = settings['appLockEnabled'] == 'true';

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: [
          _section('General'),
          ListTile(
            title: const Text('Currency'),
            subtitle: Text(currency),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _pickCurrency(context, ref),
          ),
          ListTile(
            title: const Text('Theme'),
            subtitle: Text(themeMode.toUpperCase()),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _pickTheme(context, ref),
          ),
          ListTile(
            title: const Text('Month Start Day'),
            subtitle: Text('Day $monthStartDay'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _pickMonthStartDay(context, ref),
          ),
          const Divider(),
          _section('Security'),
          SwitchListTile(
            title: const Text('App Lock'),
            subtitle: const Text('Require PIN or biometric on launch'),
            value: appLockEnabled,
            onChanged: (v) => ref.read(settingsProvider.notifier).set('appLockEnabled', '$v'),
          ),
          if (appLockEnabled)
            ListTile(
              title: const Text('Change PIN'),
              subtitle: const Text('Update your app lock PIN'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => _changePin(context),
            ),
          const Divider(),
          _section('Data'),
          ListTile(
            title: const Text('Backup'),
            subtitle: const Text('Export database file'),
            trailing: const Icon(Icons.download),
            onTap: _backup,
          ),
          ListTile(
            title: const Text('Restore'),
            subtitle: const Text('Import database file'),
            trailing: const Icon(Icons.upload),
            onTap: () => _restore(context),
          ),
          const Divider(),
          _section('About'),
          const ListTile(
            title: Text('Savings App'),
            subtitle: Text('Version 1.0.0'),
          ),
        ],
      ),
    );
  }

  Widget _section(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Builder(builder: (context) => Text(title, style: Theme.of(context).textTheme.labelLarge?.copyWith(
        color: Theme.of(context).colorScheme.primary,
      ))),
    );
  }

  Future<void> _pickCurrency(BuildContext context, WidgetRef ref) async {
    final currencies = ['USD', 'EUR', 'GBP', 'EGP', 'SAR', 'AED'];
    final picked = await showDialog<String>(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: const Text('Currency'),
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
        title: const Text('Theme'),
        children: modes.map((m) => SimpleDialogOption(
          onPressed: () => Navigator.pop(ctx, m),
          child: Text(m.toUpperCase()),
        )).toList(),
      ),
    );
    if (picked != null) {
      await ref.read(settingsProvider.notifier).set('themeMode', picked);
    }
  }

  Future<void> _pickMonthStartDay(BuildContext context, WidgetRef ref) async {
    final day = await showDialog<int>(
      context: context,
      builder: (ctx) => Dialog(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Month Start Day', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              SizedBox(
                height: 300,
                child: ListView.builder(
                  itemCount: 28,
                  itemBuilder: (ctx, i) => ListTile(
                    title: Text('${i + 1}'),
                    onTap: () => Navigator.pop(ctx, i + 1),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
    if (day != null) {
      await ref.read(settingsProvider.notifier).set('monthStartDay', '$day');
      refreshDashboard(ref);
    }
  }

  Future<void> _backup() async {
    try {
      final dir = await getDatabasesPath();
      final file = File(p.join(dir, 'savings.sqlite'));
      if (!await file.exists()) return;
      await SharePlus.instance.share(ShareParams(files: [XFile(file.path)], text: 'Savings App Backup'));
    } catch (e) {
      // ignore
    }
  }

  Future<void> _restore(BuildContext context) async {
    try {
      final result = await FilePicker.pickFiles(type: FileType.custom, allowedExtensions: ['sqlite', 'db']);
      if (result == null || result.files.isEmpty) return;
      final picked = File(result.files.first.path!);

      final bytes = await picked.readAsBytes();
      if (bytes.length < 16 || String.fromCharCodes(bytes.sublist(0, 16)) != 'SQLite format 3\x00') {
        if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Invalid database file')));
        return;
      }

      // Close the open db connection so we can overwrite the file
      await AppDatabase.instance.close();

      final dbDir = await getDatabasesPath();
      final dbFile = File(p.join(dbDir, 'savings.sqlite'));
      final backup = File(p.join(dbDir, 'savings_backup.sqlite'));
      if (await dbFile.exists()) await dbFile.copy(backup.path);
      await picked.copy(dbFile.path);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Database restored. Please restart the app.')));
      }
    } catch (e) {
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Restore failed: $e')));
    }
  }

  Future<void> _changePin(BuildContext context) async {
    final storage = const FlutterSecureStorage();
    final storedPin = await storage.read(key: 'app_lock_pin');
    if (storedPin == null || storedPin.isEmpty) return;

    // Try biometric first
    final bioEnabled = (await AppDatabase.instance.getSetting('biometricEnabled')) == 'true';
    if (bioEnabled) {
      try {
        final auth = LocalAuthentication();
        final canCheck = await auth.canCheckBiometrics;
        if (canCheck) {
          final didAuth = await auth.authenticate(localizedReason: 'Authenticate to change PIN');
          if (!didAuth) return;
          if (context.mounted) await _showSetPinDialog(context, storage);
          return;
        }
      } on PlatformException {
        // fall through to PIN verification
      }
    }

    // Verify current PIN via dialog
    if (!context.mounted) return;
    final pinCtrl = TextEditingController();
    final verified = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Verify Current PIN'),
        content: TextField(
          controller: pinCtrl,
          keyboardType: TextInputType.number,
          obscureText: true,
          maxLength: 4,
          decoration: const InputDecoration(counterText: ''),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(ctx, pinCtrl.text == storedPin), child: const Text('Verify')),
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
        title: const Text('Set New PIN'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: pinCtrl,
              keyboardType: TextInputType.number,
              obscureText: true,
              maxLength: 4,
              decoration: const InputDecoration(labelText: 'New PIN', counterText: ''),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: confirmCtrl,
              keyboardType: TextInputType.number,
              obscureText: true,
              maxLength: 4,
              decoration: const InputDecoration(labelText: 'Confirm PIN', counterText: ''),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(
            onPressed: () {
              if (pinCtrl.text.length == 4 && pinCtrl.text == confirmCtrl.text) {
                Navigator.pop(ctx, true);
              } else if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('PINs must match and be 4 digits')));
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
    if (result == true) {
      await storage.write(key: 'app_lock_pin', value: pinCtrl.text);
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('PIN updated')));
    }
  }
}
