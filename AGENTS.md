# Savings App — Project Context

## Overview
Offline-only personal savings tracker (Flutter). No network, no cloud.
Spec: `v1-build-prompt.md`.

## Stack
Flutter 3.41 / Dart 3.11 / sqflite / Riverpod 3 / go_router 17 / fl_chart / intl

## Commands
- Analyze: `flutter analyze`
- Test: `flutter test`
- Run: `flutter run`

## Architecture
Feature-first, three layers per feature: `data/` (repo), `application/` (providers), `presentation/` (screens).

### File Map
| File | Purpose |
|------|---------|
| `lib/main.dart` | Entry point, ProviderScope |
| `lib/app/app.dart` | MaterialApp + gate (onboarding → lock → main) |
| `lib/app/router.dart` | go_router + bottom nav shell (5 tabs) |
| `lib/core/db/database.dart` | SQLite schema v3, migrations, settings helpers, seed defaults (14 categories), orphan repair |
| `lib/core/calculations.dart` | Pure functions: `savingsRate()`, `goalProgress()`, `colorFromHex()` |
| `lib/core/money.dart` | `MoneyInputFormatter` (monetary input), `validateAmount()`, `ArabicDigitFormatter` (PIN-only), `formatAmount()`, `formatCompactAmount()` (K/M/B for narrow UI), currency symbols |
| `lib/core/theme.dart` | Material3 light/dark with green seed |
| `lib/core/settings_provider.dart` | Riverpod Notifier for settings key-value |
| `lib/core/date_utils.dart` | Billing cycle math (`monthDateRange`, prev/next) |
| `lib/core/seed_categories.dart` | Category display name lookup (EN + AR) |
| `lib/features/categories/` | Category CRUD, archive (not delete), type-filtered seed defaults |
| `lib/features/transactions/` | Transaction CRUD, keyset-paginated list, type-filtered category picker |
| `lib/features/transactions/presentation/transaction_tile.dart` | Standalone transaction list item widget |
| `lib/features/transactions/presentation/transaction_filter_chips.dart` | Type filter chips (All/Income/Expense/Saving) |
| `lib/features/goals/` | Goal CRUD, contribute/withdraw, projected completion, paginated history |
| `lib/features/goals/presentation/goal_contribute_dialog.dart` | Contribute/withdraw dialog (static `showContribute`/`showWithdraw`) |
| `lib/features/goals/presentation/goal_edit_dialog.dart` | Goal edit dialog |
| `lib/features/dashboard/application/dashboard_provider.dart` | `DashboardData` class + `dashboardDataProvider` + `invalidateDashboard()` |
| `lib/features/dashboard/presentation/balance_card.dart` | Spendable balance card |
| `lib/features/dashboard/presentation/month_summary_card.dart` | Monthly income/expenses/net/savings rate |
| `lib/features/dashboard/presentation/goal_progress_card.dart` | Goal progress card for dashboard |
| `lib/features/reports/` | Month picker, pie chart, bar trend, keyset-paginated top expenses |
| `lib/features/reports/presentation/month_picker.dart` | Month picker widget |
| `lib/features/reports/presentation/report_summary_card.dart` | Report summary totals |
| `lib/features/reports/presentation/category_chart.dart` | Pie chart (expenses by category) |
| `lib/features/reports/presentation/trend_chart.dart` | Bar chart (6-cycle savings trend) |
| `lib/features/reports/presentation/top_expense_tile.dart` | Top expense list item |
| `lib/features/settings/` | Currency, theme, backup/restore, PIN change |
| `lib/features/settings/data/backup_restore.dart` | Database backup/restore helpers (free functions) |
| `lib/features/onboarding/` | 6-step wizard (language, welcome, currency, balance, goal) |
| `lib/features/app_lock/` | PIN gate |

## Bottom Nav
| Tab | Label | Route |
|-----|-------|-------|
| 0 | Home | `/` |
| 1 | Activity | `/transactions` |
| 2 | Reports | `/reports` |
| 3 | Goals | `/goals` |
| 4 | Settings | `/settings` |

Categories (`/categories`) is not in the nav — reached via the Activity screen's category icon.

## Conventions

### Established rules — do not relitigate or regress

- **Money:** always `int` in minor units. Never `double` anywhere an amount is stored, summed, or passed between layers.
- **Monetary input:** always use `MoneyInputFormatter` (limits to 2 decimal places, max 12 integer digits, strips non-numeric). `ArabicDigitFormatter` only for PIN fields. Save-time validation via `validateAmount()` with SnackBar feedback. Optional fields (goal target) check `isNotEmpty` before validating.
- **Compact money:** use `formatCompactAmount()` in narrow UI areas (stat columns, subtitles, trailing text). Use `formatAmount()` for full-width displays.
- **One source of truth for cross-cutting calculations:** date/month boundaries go through `monthDateRange` only; aggregation queries (month totals, category breakdowns, trends) live in one shared repository consumed by both Dashboard and Reports — never reimplemented per-feature.
- **Reactivity:** domain-scoped invalidation via `ref.invalidate()` on the specific providers a write affects. Never a single global refresh counter that everything depends on.
- **Typed enums, not raw ints:** `TransactionType`, `GoalStatus`, `CategoryType` are enums above the data-layer boundary. Raw int conversion happens only at the SQLite read/write boundary, nowhere else.
- **Layering:** `presentation/` is widgets and composition only. Any file with no widget in it — calculations, file I/O, business logic — belongs in `data/` or `application/`, never `presentation/`, regardless of how small or "helper"-like it is.
- **File size as a signal, not a target:** a `presentation/` file crossing ~250 lines is worth examining for an extractable dialog, list-item widget, or state-view — not because of the number itself, but because that's usually where a mixed-concerns problem is hiding. A file that's long but genuinely single-purpose doesn't need splitting just to hit a line count.
- **Localization:** Western (Latin) numerals always, even under the Arabic locale. Charts and the PIN keypad stay left-to-right regardless of locale. Seed category names use the `seedKey` + ARB-lookup pattern, cleared automatically when the user edits the name, so translations never clobber a user's customization.

### Project-specific conventions

- **Pure functions:** `savingsRate()`, `goalProgress()`, `colorFromHex()` in `lib/core/calculations.dart`.
- **DB tables:** `categories`, `transactions`, `goals`, `settings` (key-value).
- **Screen naming:** "Activity" throughout (list screen, add/edit dialogs, delete confirmation, empty state, Semantics labels).

## Best practices

**Dart style (Effective Dart):**
- Standard naming: `UpperCamelCase` for classes/enums/typedefs, `lowerCamelCase` for variables/functions/parameters, `lowercase_with_underscores` for file and directory names.
- Prefer `final` for any local that's never reassigned; `const` wherever a value is compile-time constant.
- Public classes, methods, and non-trivial functions get a `///` doc comment — especially anything encoding a business rule (the spendable-balance formula, goal auto-complete logic, month-boundary math).
- Avoid the `!` null-assertion operator except where nullability was just ruled out immediately above — prefer proper null-handling (`??`, `?.`, early returns).

**Flutter widget practices:**
- `const` constructors everywhere the widget's inputs are compile-time constant.
- Keep `build()` methods pure — no async calls, no state mutation, no side effects inside `build()`.
- Prefer composition (small widgets assembled together) over deep conditional branching inside one widget's `build()`.
- `RepaintBoundary` around expensive/animated subtrees (charts, custom painting) if repaint cost ever becomes visible.

**Riverpod conventions:**
- `ref.watch` belongs in `build()`/provider bodies; `ref.read` belongs in callbacks and event handlers. Watching inside a callback is a common correctness bug.
- Keep providers narrow — one provider per cohesive piece of state/query, not one large provider bag holding unrelated data.
- Use `autoDispose` for providers tied to a screen's lifetime (form state, a specific goal's detail data) so they don't linger after navigating away.

**Testing conventions:**
- Test names describe behavior, not implementation ("shows an error when the PIN is wrong," not "test4").
- Prefer testing observable behavior over internal implementation details that could change without the behavior changing.

## Tooling & hygiene

- Every new dependency needs a reason; prefer the smallest dependency set that does the job.
- Resolve to current versions via `flutter pub add` rather than hand-pinning version numbers in `pubspec.yaml`.
- `dart format .` and `flutter analyze` clean before considering any pass finished.

## Accessibility

- Any new interactive widget needs a `Semantics` label, following the pattern already established for the Activity screen.
- Respect system text-scaling — layouts shouldn't break at larger accessibility font sizes.

## Error handling

- Any operation that can fail (DB write, file I/O) should surface a real error state to the user, not fail silently. Treat this as the default expectation for anything added.

### Accepted trade-off: no encryption at rest

The original product plan listed "optional local encryption of stored data" as a non-functional requirement. The SQLite file itself isn't encrypted at rest — only the PIN is, via `flutter_secure_storage`. **Decision: accepted as-is.** This is an offline, single-user, non-cloud app; the PIN already gates app access, which covers the realistic threat model (someone else picks up an unlocked phone). Defending against extraction from a rooted/jailbroken device is a materially higher bar than this app needs to clear. Revisit only if the app's data sensitivity or threat model changes.

## Deletion policies

| Entity | Delete? | Behavior |
|--------|---------|----------|
| **Category** | Only if no transactions reference it | Blocked with SnackBar when linked transactions exist; offer archive instead. Physical delete only when `countTransactions == 0`. |
| **Goal** | Yes | Atomic delete inside `db.transaction`: all related `goalId` references SET NULL, goal entity removed. Financial ledger (type=2 transactions) is **never** deleted. |
| **Transaction** | Yes | Standard delete. Balances recalculated via existing aggregation queries. |

### Referential integrity

- `PRAGMA foreign_keys = ON` enforced after every `openDatabase` call (enforced in app and tests).
- FK constraints on `transactions.categoryId → categories(id)` and `transactions.goalId → goals(id)` defined in both `_createTables` and `onUpgrade` v1→v2.

### Migration: orphan repair (v3)

Database version is 3. On upgrade from v2→v3, `_repairOrphans()` runs:
- Orphaned `categoryId` (references deleted category) → relinks to recovery category.
- Orphaned `goalId` (references deleted goal) → set to NULL.
- Never deletes orphaned rows. Preserves financial ledger.

### Recovery category

Seed key: `'recovered_unknown'`. Created by `_repairOrphans()` when orphaned categories exist. Always archived (`isArchived = 1`). Localized via `seedCategoryDisplayNames` in `seed_categories.dart`.

### UI guardrails

All delete dialogs use `StatefulWidget` for double-tap protection (`_deleting` flag). All async operations wrapped in try/catch with SnackBar error feedback. Mounted guards on all `setState`/`ref.invalidate` calls after async gaps. App initialization failure shows error screen with retry. Route parameter parsing protected with `int.tryParse`. All financial mutations (contribute, withdraw) wrapped in `db.transaction` for atomicity. Amount validation rejects zero/negative values at repository boundary.

## Removed features — do not reintroduce without a dedicated pass

- **Biometric authentication** — removed after repeated crashes. PIN is the only lock method until this gets its own careful, tested reintroduction.
- **Month Start Day customization** — removed from Settings, hardcoded to calendar month (day 1). The underlying `monthDateRange` function still supports it; it's just not user-facing.

## Reporting discipline

- **A checklist line is not evidence.** Any claim that a refactor, fix, or decomposition landed should come with the concrete number that proves it — a line count, a test count, a before/after diff — not a summary sentence.
- **When a prompt asks for a specific artifact** — a file-size inventory, a test count, a before/after comparison — report that artifact in full. Don't fold it into a one-line status update instead of actually producing it.

## Status
- [x] Phases 1-11: scaffold, data, features, onboarding, reports, settings, app lock
- [x] Simplification pass: keyset pagination, responsive UI, month start removed
- [x] Naming/seed pass: Activity rename, type-filtered category picker, 14-category seed
- [x] Localization: EN + AR, 161 keys, RTL, Arabic numeral input, language picker
- [x] Polish: debug banner removed, FAB padding, goal delete/withdraw confirmations
- [x] Architecture review: separation of concerns, domain-scoped invalidation, typed enums, ValueKey on list items, mounted guards
- [x] Screen decomposition: extracted 13 standalone widgets from 5 large screens (reports, dashboard, goal_detail, transactions, settings)
- [x] Decomposition cleanup: moved backup_restore to data layer, added 22 widget tests (80 total)
- [x] Delete audit: UI guardrails (mounted checks, double-tap, loading, error handling), goal atomic delete, v3 orphan repair, 18 new tests (30 total in database_test.dart)
- [x] Stabilization: MoneyInputFormatter + validateAmount (38 tests), filtered-list normalization, overflow fixes, mounted checks (115 total tests, 3 analyzer infos)
- [x] Stabilization pass 2: error handling (try/catch + error UI/retry on 5 screens), archive lifecycle fix, formatCompactAmount (K/M/B for narrow UI), btn_retry ARB key, 29 new tests (boundary stress, financial invariants, archive lifecycle, pagination, compact formatter) — 144 total, 3 analyzer infos
- [x] QA hardening: 19 tasks across 7 phases — critical error handling (app init, route parsing, financial atomicity), high error handling (goal edit, onboarding, history, progress card, app lock), medium error handling (categories, settings, backup, dropdown safety), UI overflow, 9 new tests — 158 total, 0 analyzer issues (2 pre-existing shader failures)

## Known Issues
1. Spec called for Drift; implementation uses raw sqflite (deviation accepted)
