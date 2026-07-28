# Savings App

Offline-only personal savings tracker built with Flutter. No network, no cloud — your data stays on your device.

## Features

### Core
- **Dashboard** — spendable balance, monthly summary (income/expenses/net/savings rate), goal progress cards
- **Activity (Transactions)** — full CRUD, type filter chips (All/Income/Expense/Saving), keyset-paginated list, category picker filtered by transaction type
- **Goals** — create/pause/resume/complete/archive goals, contribute/withdraw, progress bar with percentage, projected completion date, paginated contribution history
- **Reports** — month picker, pie chart (expenses by category), bar chart (6-cycle savings trend), top expenses list
- **Categories** — 14 seed categories (9 expense + 5 income), add/edit/archive/delete, type-filtered picker

### Settings
- Currency selection (USD, EUR, GBP, EGP, SAR, AED)
- Language selection (System / English / العربية)
- Theme (System / Light / Dark) — Material3 with green seed
- App Lock — 4-digit PIN gate on launch
- Backup / Restore — export/import database file

### Onboarding
6-step setup wizard: Language → Welcome → Currency → Balance → Goal → Done

### Localization
- Full English + Arabic support with RTL layout
- 161 translation keys across both languages
- Arabic numeral input handling (Eastern Arabic digits → Western digits)
- Localized category display names
- Localized percentage formatting

## Tech Stack

| Technology | Version | Purpose |
|------------|---------|---------|
| Flutter | 3.41 | UI framework |
| Dart | 3.11 | Language |
| sqflite | 2.4.2 | Local SQLite database |
| Riverpod | 3.3.2 | State management |
| go_router | 17.3.0 | Declarative routing |
| fl_chart | 1.2.0 | Pie & bar charts |
| intl | 0.20.2 | Date/number formatting |
| flutter_secure_storage | 10.3.1 | Secure PIN storage |
| file_picker | ≥8.0.0 | Database file import |
| share_plus | ≥10.0.0 | Database file export |

## Architecture

Feature-first, three-layer architecture per feature:

```
lib/
├── main.dart                    # Entry point, ProviderScope
├── app/
│   ├── app.dart                 # MaterialApp + gate (onboarding → lock → main)
│   └── router.dart              # go_router + bottom nav shell (5 tabs)
├── core/
│   ├── db/database.dart         # SQLite schema v3, migrations, settings, seed defaults, orphan repair
│   ├── calculations.dart        # Pure functions: savingsRate, goalProgress, colorFromHex
│   ├── money.dart               # MoneyInputFormatter, validateAmount, formatCompactAmount, ArabicDigitFormatter (PIN-only)
│   ├── theme.dart               # Material3 light/dark with green seed
│   ├── seed_categories.dart     # Category display name lookup (EN + AR)
│   ├── settings_provider.dart   # Riverpod Notifier for settings key-value
│   └── date_utils.dart          # Billing cycle math
├── l10n/
│   ├── app_en.arb               # English translations (161 keys)
│   └── app_ar.arb               # Arabic translations (161 keys)
└── features/
    ├── dashboard/
    │   ├── application/
    │   │   └── dashboard_provider.dart
    │   └── presentation/
    │       ├── dashboard_screen.dart
    │       ├── balance_card.dart
    │       ├── month_summary_card.dart
    │       └── goal_progress_card.dart
    ├── transactions/
    │   ├── data/transaction_repository.dart
    │   ├── application/transaction_provider.dart
    │   └── presentation/
    │       ├── transactions_screen.dart
    │       ├── add_edit_transaction_screen.dart
    │       ├── transaction_tile.dart
    │       └── transaction_filter_chips.dart
    ├── goals/
    │   ├── data/goal_repository.dart
    │   ├── application/goal_provider.dart
    │   └── presentation/
    │       ├── goals_screen.dart
    │       ├── goal_detail_screen.dart
    │       ├── goal_history_list.dart
    │       ├── goal_contribute_dialog.dart
    │       └── goal_edit_dialog.dart
    ├── reports/
    │   └── presentation/
    │       ├── reports_screen.dart
    │       ├── month_picker.dart
    │       ├── report_summary_card.dart
    │       ├── category_chart.dart
    │       ├── trend_chart.dart
    │       └── top_expense_tile.dart
    ├── categories/
    │   ├── data/category_repository.dart
    │   ├── application/category_provider.dart
    │   └── presentation/categories_screen.dart
    ├── settings/
    │   ├── data/
    │   │   └── backup_restore.dart
    │   └── presentation/
    │       └── settings_screen.dart
    ├── onboarding/
    │   └── presentation/onboarding_screen.dart
    └── app_lock/
        └── presentation/app_lock_screen.dart
```

Each feature follows:
- `data/` — Repository (SQLite queries)
- `application/` — Riverpod providers/notifiers
- `presentation/` — Screens and widgets

## Bottom Navigation

| Tab | Label | Route |
|-----|-------|-------|
| 0 | Home | `/` |
| 1 | Activity | `/transactions` |
| 2 | Reports | `/reports` |
| 3 | Goals | `/goals` |
| 4 | Settings | `/settings` |

Categories (`/categories`) is reached via the Activity screen's category icon.

## Conventions

- **Money**: All amounts stored as `int` in minor units (cents). Never `double` for stored/summed amounts.
- **Monetary input**: Always use `MoneyInputFormatter` (limits to 2 decimal places, max 12 integer digits, strips non-numeric). `ArabicDigitFormatter` only for PIN fields. Save-time validation via `validateAmount()` with SnackBar feedback. Optional fields (goal target) check `isNotEmpty` before validating.
- **Compact money formatting**: Use `formatCompactAmount()` for narrow UI areas (stat columns, subtitles, trailing text) — K for thousands, M for millions, B for billions. Use `formatAmount()` for full-width displays.
- **One source of truth**: Date/month boundaries go through `monthDateRange` only. Aggregation queries (month totals, category breakdowns, trends) live in one shared repository consumed by both Dashboard and Reports — never reimplemented per-feature.
- **Refresh**: domain-scoped `invalidate*()` using `ref.invalidate()`. Never a single global refresh counter.
- **Typed enums, not raw ints**: `TransactionType` (income/expense/saving), `GoalStatus` (active/paused/completed/archived), `CategoryType` are enums above the data-layer boundary. Raw int conversion happens only at the SQLite read/write boundary.
- **Layering**: `presentation/` is widgets and composition only. Any file with no widget in it — calculations, file I/O, business logic — belongs in `data/` or `application/`, never `presentation/`.
- **Pure functions**: `savingsRate()`, `goalProgress()`, `colorFromHex()` in `lib/core/calculations.dart`.
- **DB tables**: `categories`, `transactions`, `goals`, `settings` (key-value).
- **Screen naming**: "Activity" throughout (list screen, add/edit dialogs, delete confirmation, empty state, Semantics labels).
- **Extracted widgets**: Each large screen delegates to standalone single-responsibility widgets (e.g. `TransactionTile`, `BalanceCard`, `GoalContributeDialog`).
- **Doc comments**: Public classes, methods, and non-trivial functions encoding a business rule get a `///` doc comment.

## Deletion Policies

| Entity | Delete? | Behavior |
|--------|---------|----------|
| **Category** | Only if no transactions reference it | Blocked with SnackBar when linked transactions exist; archive offered instead. Physical delete only when `countTransactions == 0`. |
| **Goal** | Yes | Atomic delete inside `db.transaction`: all related `goalId` references SET NULL, goal entity removed. Financial ledger (type=2 transactions) is **never** deleted. |
| **Transaction** | Yes | Standard delete. Balances recalculated via existing aggregation queries. |

### Referential Integrity

- `PRAGMA foreign_keys = ON` enforced after every `openDatabase` call (both app and tests).
- FK constraints on `transactions.categoryId → categories(id)` and `transactions.goalId → goals(id)` defined in both `_createTables` and `onUpgrade` v1→v2.

### UI Guardrails

All delete dialogs use `StatefulWidget` for double-tap protection (`_deleting` flag). All async operations wrapped in try/catch with SnackBar error feedback. Mounted guards on all `setState`/`ref.invalidate` calls after async gaps.

## Data Integrity & Migration

The database schema is at **version 3**. On upgrade from v2→v3, `_repairOrphans()` runs:

- **Orphaned `categoryId`** (references a deleted category) → relinked to the `Recovered / Unknown` category.
- **Orphaned `goalId`** (references a deleted goal) → set to `NULL`.
- Orphaned rows are **never deleted** — the financial ledger is always preserved.

### Recovery Category

A hidden `Recovered / Unknown` category (seed key: `recovered_unknown`) is created automatically during the v3 migration when orphaned transactions exist. It is always archived (`isArchived = 1`) and does not appear in the category picker. Localized names are provided via `seedCategoryDisplayNames` in `seed_categories.dart`.

## Seed Categories (14 total)

**Expense (type=1):** Groceries, Food & Dining, Transportation, Housing & Rent, Utilities & Bills, Shopping, Health & Fitness, Entertainment, Other Expense

**Income (type=0):** Salary, Freelance / Business, Gifts, Investments / Interest, Other Income

> A 15th hidden category, `Recovered / Unknown`, is created automatically by the v3 migration for orphaned transactions. It is always archived and does not appear in the category picker.

## Getting Started

```bash
flutter pub get
flutter run
```

## Testing

```bash
flutter test
flutter test --coverage
```

**181 tests** across 7 test files (2 pre-existing shader failures excluded):
- `test/database_test.dart` — 88 tests (monthTotal, totalBalance, categoryBreakdown, monthlyTrend, topExpenses, savingsRate, spendable balance, goal overfunding, pagination, category filtering, **delete behavioral invariants** (goal/category/transaction delete preserves balances), **stress tests** (rapid consecutive deletes, interleaved operations, orphan repair idempotency), **v3 migration/orphan repair** (relink categoryId, idempotent repair, balance after repair), **goal status transitions** (active→paused→completed, active→archived, contribute when paused, withdraw from completed), **boundary stress** (max minor units, 50 rapid inserts, 30 categories, zero-target goal), **archive lifecycle** (archive preserves transactions, FK blocks delete with transactions, archive toggle), **financial invariants** (spendable + goals = total, savingsRate, goalProgress, categoryBreakdown totals, withdraw preserves balance, timestamps preserved), **amount validation** (zero/negative rejection), **atomicity** (contribute/withdraw atomic transactions, auto-complete/revert on target change), **projectedCompletion** (null on no data, null on zero, now when reached, future when saving), **settings CRUD** (round-trip set/get/delete/missing), **cycle boundary math** (previousCycleStart, nextCycleStart edge cases), **topExpensesPaginated** (pagination, limit, empty), **savingsInRange** (income minus expenses over range), **totalByType** (income/expense/saving totals))
- `test/money_test.dart` — 49 tests (toWesternDigits, MoneyInputFormatter, validateAmount, ArabicDigitFormatter, formatAmount, formatCompactAmount)
- `test/widget_extracted_test.dart` — 16 tests (render tests for all extracted widgets)
- `test/calculations_test.dart` — 17 tests (savingsRate, goalProgress, colorFromHex — valid/invalid/edge)
- `test/widget_dialogs_test.dart` — 6 tests (GoalContributeDialog, GoalEditDialog, GoalProgressCard, GoalHistoryList behavioral tests)
- `test/invalidation_test.dart` — 3 tests (domain-scoped invalidation regression)
- `test/widget_test.dart` — 2 tests (app launch, RTL render)

## Code Quality

```bash
flutter analyze
```

Clean — 0 analyzer issues. 2 pre-existing test failures from `ink_sparkle.frag` shader incompatibility in the test environment.

## User-Visible Behavior Changes (Deletion Audit + Stabilization)

- **Category deletion blocked** when linked transactions exist — a SnackBar explains the block and offers to archive the category instead.
- **Goal deletion** shows a confirmation dialog before proceeding.
- **All delete dialogs** now display a loading spinner and disable the button during the async operation.
- **Failed deletions** show an error SnackBar instead of failing silently.
- **Orphaned data from prior versions** is automatically repaired on first launch after upgrade to v3 (the `Recovered / Unknown` category is created if needed).
- **Error screens with retry** on Transactions, Reports, Goal Detail, and Goal Progress cards when data loading fails.
- **Archived categories preserved** in edit dropdown — selecting an archived category for an existing transaction no longer silently nulls it.
- **Compact money formatting** (K/M/B) in narrow stat columns (ReportSummaryCard, MonthSummaryCard, BalanceCard, GoalProgressCard) to prevent overflow on large amounts.
- **App initialization failure** shows error screen with retry button instead of infinite spinner.
- **Route parameter errors** (invalid goal ID) show error page instead of crashing.
- **Financial mutations atomic** — contribute/withdraw execute in single SQLite transaction with rollback on failure.
- **Goal contribute/withdraw** shows loading spinner, disables buttons during operation, catches errors with SnackBar.
- **All financial operations** (goal edit, category insert/edit, settings save, PIN change, backup) wrapped in try/catch with error feedback.
- **Goal history** shows error/retry state on load failure (like reports screen pattern).
- **Goal progress card** refreshes data when goal ID changes (didUpdateWidget).
- **App lock** handles secure storage failures gracefully.
- **Transaction edit/delete** now invalidates goals provider (stale goal data fix).
- **Deleted goal in dropdown** — new transactions clear selection; archived goals preserved for historical records.
- **Text overflow protection** — amounts and names use `maxLines: 1, overflow: TextOverflow.ellipsis` in tiles.
- **Goals screen** — shows error state with retry button and pull-to-refresh (matching Dashboard/Reports pattern).
- **Dashboard screen** — shows error state with retry button when data loading fails.
- **Goal history** — shows error SnackBar on pagination load failure; editing a transaction from goal history now invalidates all affected providers (stale data fix).
- **Goal history pagination** — mounted guard prevents crash if user navigates away during async load.

## Project Stats

| Metric | Value |
|--------|-------|
| Dart files in `lib/` | 44 |
| Lines of code in `lib/` | 6,254 |
| Test files | 7 |
| Lines of code in `test/` | 1,750 |
| Total tests | 181 |
| ARB translation keys | 162 |
| Supported languages | 2 (English, Arabic) |
| Seed categories | 14 (+ 1 hidden recovery category) |
| Features | 8 |
| Database schema version | 3 |
