/// Returns the start (inclusive) and end (inclusive, 23:59:59) of the billing
/// cycle that [anchor] falls in, given [monthStartDay] (1–28).
///
/// A cycle runs from [monthStartDay] of one month to the day before
/// [monthStartDay] of the next month (at 23:59:59). When [monthStartDay] is 1
/// this is identical to a standard calendar month.
(DateTime start, DateTime end) monthDateRange(DateTime anchor, int monthStartDay) {
  final year = anchor.year;
  final month = anchor.month;

  if (anchor.day >= monthStartDay) {
    final s = DateTime(year, month, monthStartDay);
    final nextMonth = month < 12 ? month + 1 : 1;
    final nextYear = month < 12 ? year : year + 1;
    final e = DateTime(nextYear, nextMonth, monthStartDay).subtract(const Duration(seconds: 1));
    return (s, e);
  } else {
    final prevMonth = month > 1 ? month - 1 : 12;
    final prevYear = month > 1 ? year : year - 1;
    final s = DateTime(prevYear, prevMonth, monthStartDay);
    final e = DateTime(year, month, monthStartDay).subtract(const Duration(seconds: 1));
    return (s, e);
  }
}

/// Returns the start of the previous cycle relative to [cycleStart].
DateTime previousCycleStart(DateTime cycleStart, int monthStartDay) {
  final prevAnchor = cycleStart.subtract(const Duration(days: 1));
  return monthDateRange(prevAnchor, monthStartDay).$1;
}

/// Returns the start of the next cycle relative to [cycleStart].
DateTime nextCycleStart(DateTime cycleStart, int monthStartDay) {
  // The next cycle starts on monthStartDay of the month after the current cycle's month.
  final year = cycleStart.year;
  final month = cycleStart.month;
  final nextMonth = month < 12 ? month + 1 : 1;
  final nextYear = month < 12 ? year : year + 1;
  return DateTime(nextYear, nextMonth, monthStartDay);
}
