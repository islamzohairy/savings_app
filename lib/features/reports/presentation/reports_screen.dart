import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../../../core/date_utils.dart';
import '../../../core/money.dart';
import '../../../core/seed_categories.dart';
import '../../../l10n/app_localizations.dart';
import '../../transactions/application/transaction_provider.dart';

class ReportsScreen extends ConsumerStatefulWidget {
  const ReportsScreen({super.key});

  @override
  ConsumerState<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends ConsumerState<ReportsScreen> {
  late DateTime _cycleStart;
  late DateTime _cycleEnd;
  late Future<_ReportData> _future;
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

  Future<_ReportData> _load() async {
    final txnRepo = ref.read(transactionRepoProvider);
    final income = await txnRepo.monthTotal(0, _cycleStart, _cycleEnd);
    final expenses = await txnRepo.monthTotal(1, _cycleStart, _cycleEnd);
    final net = income - expenses;
    final rate = income > 0 ? ((income - expenses) / income * 100).clamp(0.0, 100.0) : 0.0;
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
  }

  Future<void> _loadMoreTopExpenses() async {
    if (_loadingMore || !_hasMoreTopExpenses) return;
    setState(() => _loadingMore = true);
    final txnRepo = ref.read(transactionRepoProvider);
    final batch = await txnRepo.topExpensesPaginated(_cycleStart, _cycleEnd, limit: _topBatchSize, cursorAmountMinor: _topCursorAmount, cursorId: _topCursorId);
    setState(() {
      _topExpenses.addAll(batch);
      _hasMoreTopExpenses = batch.length == _topBatchSize;
      if (_hasMoreTopExpenses && batch.isNotEmpty) {
        _topCursorAmount = batch.last['amountMinor'] as int;
        _topCursorId = batch.last['id'] as int;
      }
      _loadingMore = false;
    });
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
      body: FutureBuilder<_ReportData>(
        future: _future,
        builder: (ctx, snap) {
          if (!snap.hasData) return const Center(child: CircularProgressIndicator());
          final d = snap.data!;
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _MonthPicker(
                cycleStart: _cycleStart,
                cycleEnd: _cycleEnd,
                onPrev: _prevCycle,
                onNext: _nextCycle,
              ),
              const SizedBox(height: 16),
              _SummaryCard(income: d.income, expenses: d.expenses, net: d.net, rate: d.rate),
              const SizedBox(height: 16),
              if (d.breakdown.isNotEmpty) ...[
                Text(AppLocalizations.of(context)!.sectionTitle_expensesByCategory, style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                _CategoryChart(data: d.breakdown),
              ],
              const SizedBox(height: 16),
              if (d.trend.isNotEmpty) ...[
                Text(AppLocalizations.of(context)!.sectionTitle_savingsTrend, style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                _TrendChart(data: d.trend),
              ],
              const SizedBox(height: 16),
              if (d.topExpenses.isNotEmpty) ...[
                Text(AppLocalizations.of(context)!.sectionTitle_topExpenses, style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                ...d.topExpenses.map((t) => ListTile(
                  dense: true,
                  title: Text(formatAmount(t['amountMinor'] as int)),
                  subtitle: Text(t['categoryName'] != null ? displayCategoryName(t['categoryName'] as String, Localizations.localeOf(context).languageCode) : AppLocalizations.of(context)!.label_unknownCategory),
                  trailing: Text(DateFormat.MMMd().format(DateTime.parse(t['date'] as String))),
                )),
                if (_hasMoreTopExpenses)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: _loadingMore
                        ? const Center(child: CircularProgressIndicator())
                        : TextButton(
                            onPressed: () async {
                              await _loadMoreTopExpenses();
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

class _MonthPicker extends StatelessWidget {
  const _MonthPicker({required this.cycleStart, required this.cycleEnd, required this.onPrev, required this.onNext});
  final DateTime cycleStart, cycleEnd;
  final VoidCallback onPrev, onNext;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final isCurrentCycle = !cycleEnd.isBefore(DateTime(now.year, now.month, now.day));
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        IconButton(onPressed: onPrev, icon: const Icon(Icons.chevron_left)),
        Flexible(
          child: Text(
            AppLocalizations.of(context)!.label_cycleDateRange(DateFormat('MMM d').format(cycleStart), DateFormat('MMM d, yyyy').format(cycleEnd)),
            style: Theme.of(context).textTheme.titleMedium,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        IconButton(
          onPressed: isCurrentCycle ? null : onNext,
          icon: const Icon(Icons.chevron_right),
        ),
      ],
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.income, required this.expenses, required this.net, required this.rate});
  final int income, expenses, net;
  final double rate;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _Stat(AppLocalizations.of(context)!.label_income, income, Theme.of(context).colorScheme.primary),
                _Stat(AppLocalizations.of(context)!.label_expenses, expenses, Theme.of(context).colorScheme.error),
                _Stat(AppLocalizations.of(context)!.label_net, net, Theme.of(context).colorScheme.tertiary),
              ],
            ),
            const Divider(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(AppLocalizations.of(context)!.label_savingsRate),
                Text(AppLocalizations.of(context)!.label_percent(rate.toStringAsFixed(1)), style: Theme.of(context).textTheme.titleMedium),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat(this.label, this.amount, this.color);
  final String label;
  final int amount;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(label, style: Theme.of(context).textTheme.bodySmall),
        const SizedBox(height: 4),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(formatAmount(amount), style: TextStyle(color: color, fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }
}

class _CategoryChart extends StatelessWidget {
  const _CategoryChart({required this.data});
  final List<Map<String, dynamic>> data;

  @override
  Widget build(BuildContext context) {
    final total = data.fold<int>(0, (sum, d) => sum + (d['total'] as int));
    final chartHeight = MediaQuery.of(context).size.height * 0.25;
    return Column(
      children: [
        SizedBox(
          height: chartHeight,
          child: PieChart(
            PieChartData(
              sections: data.map((d) {
                final amount = d['total'] as int;
                final color = Color(int.parse('FF${d['colorHex']}', radix: 16));
                final pct = total > 0 ? (amount / total * 100) : 0.0;
                return PieChartSectionData(
                  value: amount.toDouble(),
                  color: color,
                  title: AppLocalizations.of(context)!.label_percent(pct.toStringAsFixed(0)),
                  radius: chartHeight / 2 - 20,
                  titleStyle: TextStyle(color: Theme.of(context).colorScheme.onPrimary, fontSize: 12, fontWeight: FontWeight.bold),
                );
              }).toList(),
              centerSpaceRadius: 0,
              sectionsSpace: 2,
            ),
          ),
        ),
        const SizedBox(height: 8),
        ...data.map((d) {
          final amount = d['total'] as int;
          final color = Color(int.parse('FF${d['colorHex']}', radix: 16));
          final pct = total > 0 ? (amount / total * 100) : 0.0;
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: Row(
              children: [
                Container(width: 12, height: 12, color: color),
                const SizedBox(width: 8),
                Expanded(child: Text(displayCategoryName(d['name'] as String, Localizations.localeOf(context).languageCode))),
                Text(formatAmount(amount)),
                const SizedBox(width: 8),
                Text(AppLocalizations.of(context)!.label_percent(pct.toStringAsFixed(1)), style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          );
        }),
      ],
    );
  }
}

class _TrendChart extends StatelessWidget {
  const _TrendChart({required this.data});
  final List<Map<String, dynamic>> data;

  @override
  Widget build(BuildContext context) {
    final spots = <FlSpot>[];
    final labels = <String>[];
    for (var i = 0; i < data.length; i++) {
      spots.add(FlSpot(i.toDouble(), (data[i]['net'] as int).toDouble()));
      labels.add(data[i]['month'] as String);
    }
    if (spots.isEmpty) return const SizedBox.shrink();
    final chartHeight = MediaQuery.of(context).size.height * 0.25;
    return SizedBox(
      height: chartHeight,
      child: BarChart(
        BarChartData(
          barGroups: spots.map((s) => BarChartGroupData(
            x: s.x.toInt(),
            barRods: [
              BarChartRodData(
                toY: s.y,
                color: s.y >= 0 ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.error,
                width: 20,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
              ),
            ],
          )).toList(),
          alignment: BarChartAlignment.spaceAround,
          titlesData: FlTitlesData(
            leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  final idx = value.toInt();
                  if (idx >= 0 && idx < labels.length) {
                    final parts = labels[idx].split('-');
                    return Text(parts.length > 1 ? parts[1] : labels[idx], style: Theme.of(context).textTheme.labelSmall);
                  }
                  return const Text('');
                },
              ),
            ),
          ),
          borderData: FlBorderData(show: false),
          gridData: const FlGridData(show: false),
        ),
      ),
    );
  }
}
