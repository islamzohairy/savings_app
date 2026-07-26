import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../l10n/app_localizations.dart';

class MonthPicker extends StatelessWidget {
  const MonthPicker({super.key, required this.cycleStart, required this.cycleEnd, required this.onPrev, required this.onNext});
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
