import 'dart:ui';

/// Savings rate as a percentage (0–100), clamped.
double savingsRate(int income, int expenses) {
  if (income <= 0) return 0.0;
  return ((income - expenses) / income * 100).clamp(0.0, 100.0);
}

/// Goal progress as a ratio (0.0–1.0), clamped.
/// Returns 0.0 if target is null or non-positive.
double goalProgress(int current, int? target) {
  if (target == null || target <= 0) return 0.0;
  return (current / target).clamp(0.0, 1.0);
}

/// Parse a 6-digit hex string (e.g. `'FF9800'`) to a [Color].
Color colorFromHex(String hex) {
  return Color(int.parse('FF$hex', radix: 16));
}
