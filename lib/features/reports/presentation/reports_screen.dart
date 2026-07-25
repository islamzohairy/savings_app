import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../../../core/money.dart';
import '../../transactions/application/transaction_provider.dart';

class ReportsScreen extends ConsumerStatefulWidget {
  const ReportsScreen({super.key});

  @override
  ConsumerState<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends ConsumerState<ReportsScreen> {
  late DateTime _selectedMonth;
  late Future<_ReportData> _future;

  @override
  void initState() {
    super.initState();
    _selectedMonth = DateTime(DateTime.now().year, DateTime.now().month);
    _future = _load();
  }

  Future<_ReportData> _load() async {
    final txnRepo = ref.read(transactionRepoProvider);
    final m = _selectedMonth;
    final income = await txnRepo.monthTotal(0, m.month, m.year);
    final expenses = await txnRepo.monthTotal(1, m.month, m.year);
    final net = income - expenses;
    final rate = income > 0 ? ((income - expenses) / income * 100).clamp(0.0, 100.0) : 0.0;
    final breakdown = await txnRepo.categoryBreakdown(m.month, m.year);
    final trend = await txnRepo.monthlyTrend(6);
    final topExpenses = await txnRepo.topExpenses(m.month, m.year);
    return _ReportData(income, expenses, net, rate, breakdown, trend, topExpenses);
  }

  void _prevMonth() {
    setState(() {
      _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month - 1);
      _future = _load();
    });
  }

  void _nextMonth() {
    final next = DateTime(_selectedMonth.year, _selectedMonth.month + 1);
    final now = DateTime(DateTime.now().year, DateTime.now().month);
    if (!next.isAfter(now)) {
      setState(() {
        _selectedMonth = next;
        _future = _load();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Reports')),
      body: FutureBuilder<_ReportData>(
        future: _future,
        builder: (ctx, snap) {
          if (!snap.hasData) return const Center(child: CircularProgressIndicator());
          final d = snap.data!;
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _MonthPicker(
                month: _selectedMonth,
                onPrev: _prevMonth,
                onNext: _nextMonth,
              ),
              const SizedBox(height: 16),
              _SummaryCard(income: d.income, expenses: d.expenses, net: d.net, rate: d.rate),
              const SizedBox(height: 16),
              if (d.breakdown.isNotEmpty) ...[
                Text('Expenses by Category', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                _CategoryChart(data: d.breakdown),
              ],
              const SizedBox(height: 16),
              if (d.trend.isNotEmpty) ...[
                Text('Savings Trend (6 months)', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                _TrendChart(data: d.trend),
              ],
              const SizedBox(height: 16),
              if (d.topExpenses.isNotEmpty) ...[
                Text('Top Expenses', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                ...d.topExpenses.map((t) => ListTile(
                  dense: true,
                  title: Text(formatAmount(t['amountMinor'] as int)),
                  subtitle: Text(t['categoryName'] as String? ?? 'Unknown'),
                  trailing: Text(DateFormat.MMMd().format(DateTime.parse(t['date'] as String))),
                )),
              ],
              if (d.breakdown.isEmpty && d.trend.isEmpty && d.topExpenses.isEmpty)
                Center(child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Text('No data for this month', style: Theme.of(context).textTheme.bodyLarge),
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
  _ReportData(this.income, this.expenses, this.net, this.rate, this.breakdown, this.trend, this.topExpenses);
}

class _MonthPicker extends StatelessWidget {
  const _MonthPicker({required this.month, required this.onPrev, required this.onNext});
  final DateTime month;
  final VoidCallback onPrev, onNext;

  @override
  Widget build(BuildContext context) {
    final now = DateTime(DateTime.now().year, DateTime.now().month);
    final isCurrentMonth = month.year == now.year && month.month == now.month;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        IconButton(onPressed: onPrev, icon: const Icon(Icons.chevron_left)),
        Text(DateFormat('MMMM yyyy').format(month), style: Theme.of(context).textTheme.titleLarge),
        IconButton(
          onPressed: isCurrentMonth ? null : onNext,
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
                _Stat('Income', income, Theme.of(context).colorScheme.primary),
                _Stat('Expenses', expenses, Theme.of(context).colorScheme.error),
                _Stat('Net', net, Theme.of(context).colorScheme.tertiary),
              ],
            ),
            const Divider(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Savings Rate'),
                Text('${rate.toStringAsFixed(1)}%', style: Theme.of(context).textTheme.titleMedium),
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
        Text(formatAmount(amount), style: TextStyle(color: color, fontWeight: FontWeight.bold)),
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
                  title: '${pct.toStringAsFixed(0)}%',
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
                Expanded(child: Text(d['name'] as String)),
                Text(formatAmount(amount)),
                const SizedBox(width: 8),
                Text('${pct.toStringAsFixed(1)}%', style: Theme.of(context).textTheme.bodySmall),
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
