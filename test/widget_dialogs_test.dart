import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:savings_app/l10n/app_localizations.dart';
import 'package:savings_app/core/db/database.dart';
import 'package:savings_app/features/goals/presentation/goal_contribute_dialog.dart';
import 'package:savings_app/features/goals/presentation/goal_edit_dialog.dart';
import 'package:savings_app/features/goals/presentation/goal_history_list.dart';
import 'package:savings_app/features/dashboard/presentation/goal_progress_card.dart';
import 'package:savings_app/features/goals/data/goal_repository.dart';
import 'package:savings_app/features/transactions/data/transaction_repository.dart';
import 'package:savings_app/features/goals/application/goal_provider.dart';
import 'package:savings_app/features/transactions/application/transaction_provider.dart';

late AppDatabase appDb;
late Database database;
late GoalRepository goalRepo;
late TransactionRepository txnRepo;

Widget wrapWithProviders(Widget child, {required ProviderContainer container}) => UncontrolledProviderScope(
  container: container,
  child: MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(body: child),
  ),
);

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  setUp(() async {
    appDb = AppDatabase();
    database = await openDatabase(
      inMemoryDatabasePath,
      version: 1,
      onCreate: (d, v) async {
        await d.execute('''
          CREATE TABLE categories (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL, iconKey TEXT NOT NULL, colorHex TEXT NOT NULL,
            type INTEGER NOT NULL, isArchived INTEGER NOT NULL DEFAULT 0,
            sortOrder INTEGER NOT NULL DEFAULT 0, createdAt TEXT NOT NULL
          )
        ''');
        await d.execute('''
          CREATE TABLE goals (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL, targetAmountMinor INTEGER, targetDate TEXT,
            iconKey TEXT NOT NULL, colorHex TEXT NOT NULL,
            status INTEGER NOT NULL DEFAULT 0, sortOrder INTEGER NOT NULL DEFAULT 0,
            createdAt TEXT NOT NULL
          )
        ''');
        await d.execute('''
          CREATE TABLE transactions (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            type INTEGER NOT NULL, amountMinor INTEGER NOT NULL,
            categoryId INTEGER, goalId INTEGER, date TEXT NOT NULL,
            note TEXT, createdAt TEXT NOT NULL, updatedAt TEXT NOT NULL,
            FOREIGN KEY (categoryId) REFERENCES categories(id),
            FOREIGN KEY (goalId) REFERENCES goals(id)
          )
        ''');
        await d.execute('CREATE TABLE settings (key TEXT PRIMARY KEY, value TEXT NOT NULL)');
      },
    );
    await appDb.setDatabase(database);
    goalRepo = GoalRepository(appDb);
    txnRepo = TransactionRepository(appDb);
  });

  tearDown(() async {
    await database.close();
  });

  group('GoalContributeDialog', () {
    testWidgets('renders contribute dialog with correct title', (tester) async {
      final container = ProviderContainer(overrides: [
        goalRepoProvider.overrideWithValue(goalRepo),
      ]);
      addTearDown(container.dispose);

      await tester.pumpWidget(wrapWithProviders(
        Builder(builder: (context) => FilledButton(
          onPressed: () => GoalContributeDialog.showContribute(context, goalId: 1, currentAmount: 0, onComplete: () {}),
          child: const Text('Open'),
        )),
        container: container,
      ));
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      expect(find.byType(AlertDialog), findsOneWidget);
      expect(find.byType(TextField), findsOneWidget);
    });

    testWidgets('renders withdraw dialog', (tester) async {
      final container = ProviderContainer(overrides: [
        goalRepoProvider.overrideWithValue(goalRepo),
      ]);
      addTearDown(container.dispose);

      await tester.pumpWidget(wrapWithProviders(
        Builder(builder: (context) => FilledButton(
          onPressed: () => GoalContributeDialog.showWithdraw(context, goalId: 1, currentAmount: 5000, onComplete: () {}),
          child: const Text('Open'),
        )),
        container: container,
      ));
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      expect(find.byType(AlertDialog), findsOneWidget);
    });

    testWidgets('does not crash on empty amount submit', (tester) async {
      final container = ProviderContainer(overrides: [
        goalRepoProvider.overrideWithValue(goalRepo),
      ]);
      addTearDown(container.dispose);

      await tester.pumpWidget(wrapWithProviders(
        Builder(builder: (context) => FilledButton(
          onPressed: () => GoalContributeDialog.showContribute(context, goalId: 1, currentAmount: 0, onComplete: () {}),
          child: const Text('Open'),
        )),
        container: container,
      ));
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      final dialogButtons = find.descendant(of: find.byType(AlertDialog), matching: find.byType(FilledButton));
      await tester.tap(dialogButtons.first);
      await tester.pumpAndSettle();
      expect(find.byType(AlertDialog), findsOneWidget);
    });
  });

  group('GoalEditDialog', () {
    testWidgets('renders with pre-filled goal data', (tester) async {
      final container = ProviderContainer(overrides: [
        goalRepoProvider.overrideWithValue(goalRepo),
      ]);
      addTearDown(container.dispose);

      await tester.pumpWidget(wrapWithProviders(
        GoalEditDialog(
          goalId: 1,
          goal: {'name': 'Vacation', 'targetAmountMinor': 50000},
          onComplete: () {},
        ),
        container: container,
      ));
      await tester.pumpAndSettle();
      expect(find.byType(AlertDialog), findsOneWidget);
      expect(find.text('Vacation'), findsOneWidget);
    });
  });

  group('GoalProgressCard', () {
    testWidgets('renders with goal data', (tester) async {
      final container = ProviderContainer(overrides: [
        goalRepoProvider.overrideWithValue(goalRepo),
      ]);
      addTearDown(container.dispose);

      await tester.pumpWidget(wrapWithProviders(
        GoalProgressCard(goal: {
          'id': 1, 'name': 'Car', 'targetAmountMinor': 100000, 'colorHex': '4CAF50',
        }, currentAmount: 0),
        container: container,
      ));
      await tester.pump();
      expect(find.byType(GoalProgressCard), findsOneWidget);
      expect(find.text('Car'), findsOneWidget);
    });
  });

  group('GoalHistoryList', () {
    testWidgets('renders loading state initially', (tester) async {
      final container = ProviderContainer(overrides: [
        goalRepoProvider.overrideWithValue(goalRepo),
        transactionRepoProvider.overrideWithValue(txnRepo),
      ]);
      addTearDown(container.dispose);

      await tester.pumpWidget(wrapWithProviders(
        GoalHistoryList(goalId: 1, onRefresh: () {}),
        container: container,
      ));
      await tester.pump();
      expect(find.byType(GoalHistoryList), findsOneWidget);
    });
  });
}
