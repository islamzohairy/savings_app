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
| `lib/core/db/database.dart` | SQLite schema v2, migrations, settings helpers, seed defaults (14 categories) |
| `lib/core/calculations.dart` | Pure functions: `savingsRate()`, `goalProgress()`, `colorFromHex()` |
| `lib/core/money.dart` | `formatAmount(int minor)`, `parseAmountToMinor(String)`, currency symbols |
| `lib/core/theme.dart` | Material3 light/dark with green seed |
| `lib/core/settings_provider.dart` | Riverpod Notifier for settings key-value |
| `lib/core/date_utils.dart` | Billing cycle math (`monthDateRange`, prev/next) |
| `lib/features/categories/` | Category CRUD, archive (not delete), type-filtered seed defaults |
| `lib/features/transactions/` | Transaction CRUD, keyset-paginated list, type-filtered category picker |
| `lib/features/goals/` | Goal CRUD, contribute/withdraw, projected completion, paginated history |
| `lib/features/dashboard/application/dashboard_provider.dart` | `DashboardData` class + `dashboardDataProvider` + `invalidateDashboard()` |
| `lib/features/dashboard/` | Balance card, month summary, goal progress |
| `lib/features/reports/` | Month picker, pie chart, bar trend, keyset-paginated top expenses |
| `lib/features/settings/` | Currency, theme, backup/restore, PIN change |
| `lib/features/onboarding/` | 5-step wizard (currency, balance, goal) |
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
- All money: `int` in minor units (cents). Never `double` for stored/summed amounts.
- Refresh: domain-scoped `invalidate*()` using `ref.invalidate()`.
- Enums: `TransactionType` (income/expense/saving), `GoalStatus` (active/paused/completed/archived).
- Pure functions: `savingsRate()`, `goalProgress()`, `colorFromHex()` in `lib/core/calculations.dart`.
- DB tables: `categories`, `transactions`, `goals`, `settings` (key-value).
- Screen naming: "Activity" throughout (list screen, add/edit dialogs, delete confirmation, empty state, Semantics labels).

## Status
- [x] Phases 1-11: scaffold, data, features, onboarding, reports, settings, app lock
- [x] Simplification pass: keyset pagination, responsive UI, month start removed
- [x] Naming/seed pass: Activity rename, type-filtered category picker, 14-category seed
- [x] Localization: EN + AR, 161 keys, RTL, Arabic numeral input, language picker
- [x] Polish: debug banner removed, FAB padding, goal delete/withdraw confirmations
- [x] Architecture review: separation of concerns, domain-scoped invalidation, typed enums, ValueKey on list items, mounted guards

## Known Issues
1. Spec called for Drift; implementation uses raw sqflite (deviation accepted)
