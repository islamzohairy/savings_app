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
│   ├── db/database.dart         # SQLite schema v2, migrations, settings, seed defaults
│   ├── calculations.dart        # Pure functions: savingsRate, goalProgress, colorFromHex
│   ├── money.dart               # formatAmount, parseAmountToMinor, ArabicDigitFormatter
│   ├── theme.dart               # Material3 light/dark with green seed
│   ├── seed_categories.dart     # Category display name lookup (EN + AR)
│   ├── settings_provider.dart   # Riverpod Notifier for settings key-value
│   └── date_utils.dart          # Billing cycle math
├── l10n/
│   ├── app_en.arb               # English translations (161 keys)
│   └── app_ar.arb               # Arabic translations (161 keys)
└── features/
    ├── dashboard/               # Balance card, month summary, goal progress
    │   └── application/
    │       └── dashboard_provider.dart  # DashboardData + invalidateDashboard()
    ├── transactions/            # CRUD, keyset-paginated list, type-filtered picker
    ├── goals/                   # CRUD, contribute/withdraw, projected completion
    ├── reports/                 # Month picker, pie chart, bar trend, top expenses
    ├── categories/              # CRUD, archive, type-filtered seed defaults
    ├── settings/                # Currency, theme, backup/restore, PIN change
    ├── onboarding/              # 6-step wizard
    └── app_lock/                # PIN gate
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
- **Refresh**: domain-scoped `invalidate*()` using `ref.invalidate()`.
- **Enums**: `TransactionType` (income/expense/saving), `GoalStatus` (active/paused/completed/archived).
- **Pure functions**: `savingsRate()`, `goalProgress()`, `colorFromHex()` in `lib/core/calculations.dart`.
- **DB tables**: `categories`, `transactions`, `goals`, `settings` (key-value).
- **Screen naming**: "Activity" throughout (list screen, add/edit dialogs, delete confirmation, empty state, Semantics labels).

## Seed Categories (14 total)

**Expense (type=1):** Groceries, Food & Dining, Transportation, Housing & Rent, Utilities & Bills, Shopping, Health & Fitness, Entertainment, Other Expense

**Income (type=0):** Salary, Freelance / Business, Gifts, Investments / Interest, Other Income

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

**58 tests** across 5 test files:
- `test/money_test.dart` — 20 tests (toWesternDigits, ArabicDigitFormatter, parseAmountToMinor, formatAmount)
- `test/database_test.dart` — 20 tests (monthTotal, totalBalance, categoryBreakdown, monthlyTrend, topExpenses, savingsRate, spendable balance, goal overfunding, pagination, category filtering)
- `test/invalidation_test.dart` — 9 tests (domain-scoped invalidation regression)
- `test/calculations_test.dart` — 6 tests (savingsRate, goalProgress, colorFromHex)
- `test/widget_test.dart` — 3 tests (app launch, RTL render)

## Code Quality

```bash
flutter analyze
```

Clean — only pre-existing info-level warnings (3x `use_build_context_synchronously`).

## Project Stats

| Metric | Value |
|--------|-------|
| Dart files in `lib/` | 31 |
| Lines of code in `lib/` | 5,763 |
| Test files | 5 |
| Lines of code in `test/` | 819 |
| Total tests | 58 |
| ARB translation keys | 161 |
| Supported languages | 2 (English, Arabic) |
| Seed categories | 14 |
| Features | 8 |
