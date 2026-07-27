import 'dart:io';
import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as p;
import 'package:share_plus/share_plus.dart';
import 'package:file_picker/file_picker.dart';
import '../../../core/db/database.dart';
import '../../../l10n/app_localizations.dart';

Future<void> backupDatabase(BuildContext context) async {
  try {
    final dir = await getDatabasesPath();
    final file = File(p.join(dir, 'savings.sqlite'));
    if (!await file.exists()) return;
    if (!context.mounted) return;
    await SharePlus.instance.share(ShareParams(files: [XFile(file.path)], text: AppLocalizations.of(context)!.share_backupLabel));
  } catch (e) {
    // ignore
  }
}

Future<void> restoreDatabase(BuildContext context) async {
  try {
    final result = await FilePicker.pickFiles(type: FileType.custom, allowedExtensions: ['sqlite', 'db']);
    if (result == null || result.files.isEmpty) return;
    final picked = File(result.files.first.path!);

    final bytes = await picked.readAsBytes();
    if (bytes.length < 16 || String.fromCharCodes(bytes.sublist(0, 16)) != 'SQLite format 3\x00') {
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(AppLocalizations.of(context)!.snackbar_invalidDbFile)));
      return;
    }

    await AppDatabase.instance.close();

    final dbDir = await getDatabasesPath();
    final dbFile = File(p.join(dbDir, 'savings.sqlite'));
    final backup = File(p.join(dbDir, 'savings_backup.sqlite'));
    if (await dbFile.exists()) await dbFile.copy(backup.path);
    await picked.copy(dbFile.path);

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(AppLocalizations.of(context)!.snackbar_dbRestored)));
    }
  } catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(AppLocalizations.of(context)!.snackbar_restoreFailed('$e'))));
    }
  }
}
