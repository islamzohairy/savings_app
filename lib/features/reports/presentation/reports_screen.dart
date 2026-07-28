import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/date_utils.dart';
import '../../../core/db/database.dart';
import '../../../core/calculations.dart';
import '../../../l10n/app_localizations.dart';
import '../../transactions/application/transaction_provider.dart';
import 'month_picker.dart';
import 'report_summary_card.dart';
import 'category_chart.dart';
import 'trend_chart.dart';
import 'top_expense_tile.dart';

class ReportsScreen extends ConsumerStatefulWidget {
  const ReportsScreen({super.key});

  @override
  ConsumerState<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends ConsumerState<ReportsScreen> {
  late DateTime _cycleStart;
  late DateTime _cycleEnd;
  late Future<_ReportData?> _future;
  final List<Map<String, dynamic>> _topExpenses = [];
  bool _hasMoreTopExpenses = true;
  bool _loadingMore = false;
  static const _topBatchSize = 50;
  int? _topCursorAmount;
  int? _topCursorId;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    final (start, end) = monthDateRange(now, 1);
    _cycleStart = start;
    _cycleEnd = end;
    _future = _load();
  }

  Future<_ReportData?> _load() async {
    try {
      final txnRepo = ref.read(transactionRepoProvider);
      final income = await txnRepo.monthTotal(TransactionType.income, _cycleStart, _cycleEnd);
      final expenses = await txnRepo.monthTotal(TransactionType.expense, _cycleStart, _cycleEnd);
      final net = income - expenses;
      final rate = savingsRate(income, expenses);
      final breakdown = await txnRepo.categoryBreakdown(_cycleStart, _cycleEnd);
      final trend = await txnRepo.monthlyTrend(6, _cycleStart, 1);
      final topBatch = await txnRepo.topExpensesPaginated(_cycleStart, _cycleEnd, limit: _topBatchSize);
      _topExpenses
        ..clear()
        ..addAll(topBatch);
      _hasMoreTopExpenses = topBatch.length == _topBatchSize;
      if (_hasMoreTopExpenses && topBatch.isNotEmpty) {
        _topCursorAmount = topBatch.last['amountMinor'] as int;
        _topCursorId = topBatch.last['id'] as int;
      }
      return _ReportData(income, expenses, net, rate, breakdown, trend, List.from(_topExpenses), _hasMoreTopExpenses);
    } catch (e) {
      return null;
    }
  }

  Future<void> _loadMoreTopExpenses() async {
    if (_loadingMore || !_hasMoreTopExpenses) return;
    setState(() => _loadingMore = true);
    try {
      final txnRepo = ref.read(transactionRepoProvider);
      final batch = await txnRepo.topExpensesPaginated(_cycleStart, _cycleEnd, limit: _topBatchSize, cursorAmountMinor: _topCursorAmount, cursorId: _topCursorId);
      if (!mounted) return;
      setState(() {
        _topExpenses.addAll(batch);
        _hasMoreTopExpenses = batch.length == _topBatchSize;
        if (_hasMoreTopExpenses && batch.isNotEmpty) {
          _topCursorAmount = batch.last['amountMinor'] as int;
          _topCursorId = batch.last['id'] as int;
        }
        _loadingMore = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loadingMore = false);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.error_generic('$e'))),
        );
      }
    }
  }

  void _prevCycle() {
    final newStart = previousCycleStart(_cycleStart, 1);
    final (_, newEnd) = monthDateRange(newStart, 1);
    setState(() {
      _cycleStart = newStart;
      _cycleEnd = newEnd;
      _future = _load();
    });
  }

  void _nextCycle() {
    final newStart = nextCycleStart(_cycleStart, 1);
    final (_, newEnd) = monthDateRange(newStart, 1);
    final now = DateTime.now();
    final (_, currentEnd) = monthDateRange(now, 1);
    if (!newStart.isAfter(currentEnd)) {
      setState(() {
        _cycleStart = newStart;
        _cycleEnd = newEnd;
        _future = _load();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(AppLocalizations.of(context)!.appBarTitle_reports)),
      body: FutureBuilder<_ReportData?>(
        future: _future,
        builder: (ctx, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.data == null) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.error_outline, size: 48),
                    const SizedBox(height: 12),
                    Text(AppLocalizations.of(context)!.error_generic(''), textAlign: TextAlign.center),
                    const SizedBox(height: 12),
                    FilledButton(
                      onPressed: () => setState(() => _future = _load()),
                      child: Text(AppLocalizations.of(context)!.btn_retry),
                    ),
                  ],
                ),
              ),
            );
          }
          final d = snap.data!;
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              MonthPicker(cycleStart: _cycleStart, cycleEnd: _cycleEnd, onPrev: _prevCycle, onNext: _nextCycle),
              const SizedBox(height: 16),
              ReportSummaryCard(income: d.income, expenses: d.expenses, net: d.net, rate: d.rate),
              const SizedBox(height: 16),
              if (d.breakdown.isNotEmpty) ...[
                Text(AppLocalizations.of(context)!.sectionTitle_expensesByCategory, style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                CategoryChart(data: d.breakdown),
              ],
              const SizedBox(height: 16),
              if (d.trend.isNotEmpty) ...[
                Text(AppLocalizations.of(context)!.sectionTitle_savingsTrend, style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                TrendChart(data: d.trend),
              ],
              const SizedBox(height: 16),
              if (d.topExpenses.isNotEmpty) ...[
                Text(AppLocalizations.of(context)!.sectionTitle_topExpenses, style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                ...d.topExpenses.map((t) => TopExpenseTile(expense: t)),
                if (_hasMoreTopExpenses)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: _loadingMore
                        ? const Center(child: CircularProgressIndicator())
                        : TextButton(
                            onPressed: () async {
                              await _loadMoreTopExpenses();
                              if (!mounted) return;
                              setState(() {});
                            },
                            child: Text(AppLocalizations.of(context)!.btn_loadMore),
                          ),
                  ),
              ],
              if (d.breakdown.isEmpty && d.trend.isEmpty && d.topExpenses.isEmpty)
                Center(child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Text(AppLocalizations.of(context)!.emptyState_noDataForCycle, style: Theme.of(context).textTheme.bodyLarge),
                )),
            ],
          );
        },
      ),
    );
  }
}

class _ReportData {
  final int income, expenses, net;
  final double rate;
  final List<Map<String, dynamic>> breakdown, trend, topExpenses;
  final bool hasMoreTopExpenses;
  _ReportData(this.income, this.expenses, this.net, this.rate, this.breakdown, this.trend, this.topExpenses, this.hasMoreTopExpenses);
}
