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
| `lib/app/router.dart` | go_router + bottom nav shell |
| `lib/core/db/database.dart` | SQLite schema, migrations stub, settings helpers, seed defaults |
| `lib/core/money.dart` | `formatAmount(int minor)`, `parseAmountToMinor(String)`, currency symbols |
| `lib/core/theme.dart` | Material3 light/dark with green seed |
| `lib/core/settings_provider.dart` | Riverpod Notifier for settings key-value |
| `lib/core/date_utils.dart` | Billing cycle math (`monthDateRange`, prev/next) |
| `lib/features/categories/` | Category CRUD, archive (not delete), default seed |
| `lib/features/transactions/` | Transaction CRUD, paginated list, filters, SQL aggregation |
| `lib/features/goals/` | Goal CRUD, contribute/withdraw, projected completion |
| `lib/features/dashboard/` | Balance card, month summary, goal progress |
| `lib/features/reports/` | Month picker, pie chart, bar trend, top expenses |
| `lib/features/settings/` | Currency, theme, month-start, backup/restore, PIN change |
| `lib/features/onboarding/` | 5-step wizard (currency, balance, goal) |
| `lib/features/app_lock/` | PIN keypad + biometric gate |

## Conventions
- All money: `int` in minor units (cents). Never `double` for stored/summed amounts.
- Manual refresh: `_RefreshNotifier` counter pattern (not reactive streams).
- DB tables: `categories`, `transactions`, `goals`, `settings` (key-value).
- Transaction types: 0=income, 1=expense, 2=saving.
- Goal statuses: 0=active, 1=paused, 2=completed, 3=archived.

## Status
- [x] Phases 1-11: scaffold, data, features, onboarding, reports, settings, app lock
- [ ] Phase 12: polish (empty states, error states, accessibility)
- [ ] Phase 13: tests (money + SQL aggregation unit tests, widget tests)

## Known Issues
1. `DropdownButtonFormField` uses `initialValue` (invalid) — should be `value`
2. Stray `features/dashboard/{presentation}/` directory exists
3. Spec called for Drift; implementation uses raw sqflite (deviation accepted)
