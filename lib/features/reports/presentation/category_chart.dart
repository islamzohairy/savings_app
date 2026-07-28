import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../core/money.dart';
import '../../../core/calculations.dart';
import '../../../core/seed_categories.dart';
import '../../../l10n/app_localizations.dart';

class CategoryChart extends StatelessWidget {
  const CategoryChart({super.key, required this.data});
  final List<Map<String, dynamic>> data;

  @override
  Widget build(BuildContext context) {
    final total = data.fold<int>(0, (sum, d) => sum + (d['total'] as int));
    final chartHeight = MediaQuery.of(context).size.height * 0.25;
    return Column(
      children: [
        SizedBox(
          height: chartHeight,
          child: RepaintBoundary(
            child: PieChart(
              PieChartData(
                sections: data.map((d) {
                  final amount = d['total'] as int;
                  final color = colorFromHex(d['colorHex'] as String);
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
        ),
        const SizedBox(height: 8),
        ...data.map((d) {
          final amount = d['total'] as int;
          final color = colorFromHex(d['colorHex'] as String);
          final pct = total > 0 ? (amount / total * 100) : 0.0;
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: Row(
              children: [
                Container(width: 12, height: 12, color: color),
                const SizedBox(width: 8),
                Expanded(child: Text(displayCategoryName(d['name'] as String, Localizations.localeOf(context).languageCode), overflow: TextOverflow.ellipsis)),
                Flexible(child: FittedBox(fit: BoxFit.scaleDown, child: Text(formatAmount(amount)))),
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
