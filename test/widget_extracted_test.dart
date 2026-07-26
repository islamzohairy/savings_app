import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:savings_app/l10n/app_localizations.dart';
import 'package:savings_app/features/dashboard/presentation/balance_card.dart';
import 'package:savings_app/features/dashboard/presentation/month_summary_card.dart';
import 'package:savings_app/features/transactions/presentation/transaction_tile.dart';
import 'package:savings_app/features/transactions/presentation/transaction_filter_chips.dart';
import 'package:savings_app/features/reports/presentation/month_picker.dart';
import 'package:savings_app/features/reports/presentation/report_summary_card.dart';
import 'package:savings_app/features/reports/presentation/category_chart.dart';
import 'package:savings_app/features/reports/presentation/trend_chart.dart';
import 'package:savings_app/features/reports/presentation/top_expense_tile.dart';
import 'package:savings_app/core/db/database.dart';

Widget wrap(Widget child) => MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  home: Scaffold(body: child),
);

void main() {
  group('BalanceCard', () {
    testWidgets('renders with zero balances', (tester) async {
      await tester.pumpWidget(wrap(const BalanceCard(spendableBalance: 0, goalBalances: 0)));
      expect(find.byType(BalanceCard), findsOneWidget);
    });
    testWidgets('renders with non-zero balances', (tester) async {
      await tester.pumpWidget(wrap(const BalanceCard(spendableBalance: 5000, goalBalances: 2000)));
      expect(find.byType(BalanceCard), findsOneWidget);
    });
  });

  group('MonthSummaryCard', () {
    testWidgets('renders monthly data', (tester) async {
      await tester.pumpWidget(wrap(MonthSummaryCard(
        income: 10000, expenses: 6000, movedToGoals: 1000,
        rate: 0.3, lifetimeIncome: 50000, lifetimeExpenses: 30000,
        onToggle: () {}, showLifetime: false,
      )));
      expect(find.byType(MonthSummaryCard), findsOneWidget);
    });
    testWidgets('renders lifetime data', (tester) async {
      await tester.pumpWidget(wrap(MonthSummaryCard(
        income: 10000, expenses: 6000, movedToGoals: 1000,
        rate: 0.3, lifetimeIncome: 50000, lifetimeExpenses: 30000,
        onToggle: () {}, showLifetime: true,
      )));
      expect(find.byType(MonthSummaryCard), findsOneWidget);
    });
  });

  group('TransactionTile', () {
    testWidgets('renders income transaction', (tester) async {
      await tester.pumpWidget(wrap(TransactionTile(transaction: {
        'id': 1, 'type': 0, 'amountMinor': 5000, 'date': '2026-01-15',
        'categoryName': 'Salary', 'note': null, 'goalName': null,
      })));
      expect(find.byType(TransactionTile), findsOneWidget);
    });
    testWidgets('renders expense transaction', (tester) async {
      await tester.pumpWidget(wrap(TransactionTile(transaction: {
        'id': 2, 'type': 1, 'amountMinor': 1500, 'date': '2026-01-20',
        'categoryName': 'Groceries', 'note': null, 'goalName': null,
      })));
      expect(find.byType(TransactionTile), findsOneWidget);
    });
    testWidgets('renders saving transaction with goal name', (tester) async {
      await tester.pumpWidget(wrap(TransactionTile(transaction: {
        'id': 3, 'type': 2, 'amountMinor': 2000, 'date': '2026-02-01',
        'categoryName': null, 'note': null, 'goalName': 'Vacation',
      })));
      expect(find.byType(TransactionTile), findsOneWidget);
    });
  });

  group('TransactionFilterChips', () {
    testWidgets('renders all four filter chips', (tester) async {
      await tester.pumpWidget(wrap(TransactionFilterChips(
        selectedType: null, onTypeChanged: (_) {},
      )));
      expect(find.byType(FilterChip), findsNWidgets(4));
    });
    testWidgets('calls onTypeChanged when chip tapped', (tester) async {
      TransactionType? selected;
      await tester.pumpWidget(wrap(TransactionFilterChips(
        selectedType: null, onTypeChanged: (t) => selected = t,
      )));
      await tester.tap(find.byType(FilterChip).at(1));
      await tester.pumpAndSettle();
      expect(selected, TransactionType.income);
    });
  });

  group('MonthPicker', () {
    testWidgets('renders with cycle dates', (tester) async {
      await tester.pumpWidget(wrap(MonthPicker(
        cycleStart: DateTime(2026, 1, 1), cycleEnd: DateTime(2026, 1, 31),
        onPrev: () {}, onNext: () {},
      )));
      expect(find.byType(MonthPicker), findsOneWidget);
    });
  });

  group('ReportSummaryCard', () {
    testWidgets('renders income/expenses/net/rate', (tester) async {
      await tester.pumpWidget(wrap(ReportSummaryCard(
        income: 10000, expenses: 6000, net: 4000, rate: 0.4,
      )));
      expect(find.byType(ReportSummaryCard), findsOneWidget);
    });
  });

  group('CategoryChart', () {
    testWidgets('renders with category data', (tester) async {
      await tester.pumpWidget(wrap(CategoryChart(data: [
        {'total': 3000, 'colorHex': 'F44336', 'name': 'Food'},
        {'total': 2000, 'colorHex': '2196F3', 'name': 'Transport'},
      ])));
      expect(find.byType(CategoryChart), findsOneWidget);
    });
    testWidgets('renders with empty data', (tester) async {
      await tester.pumpWidget(wrap(const CategoryChart(data: [])));
      expect(find.byType(CategoryChart), findsOneWidget);
    });
  });

  group('TrendChart', () {
    testWidgets('renders with trend data', (tester) async {
      await tester.pumpWidget(MaterialApp(
  localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(body: TrendChart(data: [
        {'net': 2000, 'month': 'Jan'},
        {'net': 1500, 'month': 'Feb'},
        {'net': -500, 'month': 'Mar'},
      ]))));
      expect(find.byType(TrendChart), findsOneWidget);
    });
  });

  group('TopExpenseTile', () {
    testWidgets('renders expense with category name', (tester) async {
      await tester.pumpWidget(wrap(TopExpenseTile(expense: {
        'amountMinor': 5000, 'categoryName': 'Groceries', 'date': '2026-01-15',
      })));
      expect(find.byType(TopExpenseTile), findsOneWidget);
    });
    testWidgets('renders expense with null category', (tester) async {
      await tester.pumpWidget(wrap(TopExpenseTile(expense: {
        'amountMinor': 3000, 'categoryName': null, 'date': '2026-02-01',
      })));
      expect(find.byType(TopExpenseTile), findsOneWidget);
    });
  });
}
