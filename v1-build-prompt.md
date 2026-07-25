# Build Prompt — Monthly Savings App with Detailed Reports (V1 / MVP)

> Paste this directly to the builder model (e.g. Claude Code) as the first instruction for this repo.

## Role & Objective

You are building **Version 1 (MVP)** of a personal, single-user, fully offline savings app in Flutter. The product's core value in V1 is: fast transaction logging + a genuinely useful monthly report (not just a raw list of numbers). No accounts, no cloud, no network calls of any kind.

Work in the phased order below. Treat each phase as a checkpoint: implement it fully, run `flutter analyze` and `flutter test`, fix anything broken, then move to the next phase. Do not attempt to generate the whole app in one pass.

**Token-efficiency rules for you (the builder) to follow throughout:**
- Don't restate this spec back to me. Don't narrate what you're about to do at length — just do it, then give a short summary of what changed.
- Edit files with targeted diffs, not full-file rewrites, once a file exists.
- Don't print full file contents in your responses unless something failed and you need to show why.
- Skip comments that restate what the code obviously does. Comment only non-obvious business logic (e.g. money-in-minor-units handling, month-boundary math).
- No speculative abstractions for features not in this MVP list. Build exactly this scope.

---

## Tech Stack

Use `flutter pub add` / `dart pub add` for every package below rather than hand-writing versions in `pubspec.yaml` — this resolves to whatever is current and compatible at build time, which is what "up to date" should mean for a project that outlives this conversation.

| Concern | Package | Why |
|---|---|---|
| State management | `flutter_riverpod`, `riverpod_annotation` (+ dev: `riverpod_generator`) | Compile-time-safe, no `BuildContext` plumbing, current default for new Flutter projects |
| Local database | `drift` (+ `sqlite3_flutter_libs`, `path_provider`, `path`; dev: `drift_dev`) | SQL-backed, actively maintained (unlike Isar/Hive, both stalled) — and SQL aggregation is exactly what monthly/category reports need |
| Charts | `fl_chart` | Actively maintained, covers line/bar/pie which is all this app needs |
| Formatting | `intl` | Currency, date, and number formatting per locale |
| Navigation | `go_router` | Maintained by the Flutter team, declarative routing |
| Biometric/PIN lock | `local_auth`, `flutter_secure_storage` | OS-level biometric prompt; secure storage is already encrypted at rest, so it's fine to store the PIN there directly — no separate hashing layer needed for V1 |
| Backup/restore file handling | `file_picker`, `share_plus` | Pick a restore file / share the exported backup file |
| Codegen | `build_runner` (dev) | Required by Drift and Riverpod generators |

Do not add: Isar, Hive, GetX, Provider, Bloc, Firebase, or any analytics/crash-reporting SDK. This app must build and run with zero network permissions.

---

## Architecture

Feature-first structure, three layers per feature:

```
lib/
  main.dart
  app/                      # MaterialApp, theme, router, app-lock gate
  core/
    money.dart              # amountMinor <-> display string helpers, currency formatting
    db/
      database.dart         # Drift database class + tables
      daos/                 # one DAO per table
  features/
    onboarding/
    transactions/
      data/                 # repository wrapping the DAO
      application/          # Riverpod providers/notifiers
      presentation/         # screens + widgets
    categories/
    goals/
    reports/
    settings/
    app_lock/
```

**Rules:**
- All money amounts are stored and passed around as **integers in minor currency units** (cents/piastres), never as `double`. Convert to display strings only at the presentation edge via `core/money.dart`. This is non-negotiable — floating point must never touch a stored or summed amount.
- Use Drift's reactive `.watch()` streams end to end: DAO exposes a `Stream<...>`, repository maps it, a Riverpod `StreamProvider`/`@riverpod` function exposes it to the UI. No manual "refresh" calls anywhere — the UI updates because the data changed.
- Use Drift's generated row classes directly as the domain model for V1. Don't add a parallel hand-written model layer (e.g. freezed classes) yet — that's premature for this scope and costs build time for no benefit until V2 needs richer domain logic.
- Repositories, not widgets, contain business logic (e.g. computing savings rate, monthly totals, goal projections). Widgets only read providers and render.

---

## Data Model (Drift tables)

**Categories**
`id, name, iconKey (text), colorHex (text), type (enum: income/expense), isArchived (bool, default false), sortOrder (int), createdAt`

**Goals**
`id, name, targetAmountMinor (int, nullable), targetDate (date, nullable), iconKey (text), colorHex (text), status (enum: active/paused/completed/archived), sortOrder (int), createdAt`

**Transactions**
`id, type (enum: income/expense/saving), amountMinor (int, always positive), categoryId (FK -> Categories, nullable for saving type), goalId (FK -> Goals, nullable — set when type=saving), date, note (text, nullable), createdAt, updatedAt`

**Settings** (single key-value table)
`key (text, primary key), value (text)` — holds: `currencyCode`, `monthStartDay` (default 1), `firstDayOfWeek`, `themeMode`, `appLockEnabled`, `biometricEnabled`, `hasCompletedOnboarding`.

Add a Drift migration strategy from day one (`schemaVersion = 1`, `onUpgrade` stub) even though there's nothing to migrate yet — retrofitting this later on a real user's database is painful.

---

## Screens (MVP scope only)

1. **Onboarding** — currency picker, optional starting balance, optional first goal, choose default categories or start blank, optional app-lock setup. Single pass, skippable where noted.
2. **App Lock** — PIN entry or biometric prompt; shown on launch and on resume-from-background if enabled.
3. **Dashboard** — current balance, this month's income/expenses/net savings, this month's savings rate, active goal progress cards, quick-add button.
4. **Add/Edit Transaction** — type toggle (income/expense/saving), amount, category (or goal, if saving), date, optional note.
5. **Transactions List** — reverse-chronological, filterable by date range and category.
6. **Categories** — list, add, edit, archive (archiving, not deleting, if a category has existing transactions).
7. **Goals List + Goal Detail** — progress bar, projected completion date at current pace, contribute/withdraw, edit, pause/archive.
8. **Reports** (see below — this is the section to spend the most care on).
9. **Settings** — currency, theme (light/dark/system), month start day, app lock toggle, manual backup/restore, app version.

## Reports Screen — Detail Spec

This is the differentiator for V1, so implement it properly rather than as an afterthought:

- **Monthly summary card**: total income, total expenses, net saved, savings rate (%) for the selected month.
- **Month picker**: step backward/forward through any past month that has data.
- **Category breakdown**: bar or pie chart of expenses by category for the selected month, with amount and % per category, sorted descending.
- **Trend chart**: line/bar chart of net savings for the last 6 months (or fewer if less history exists), so the user sees direction at a glance.
- **Savings rate trend**: same chart or a second small chart showing savings rate % per month over the same window.
- **Top expenses**: the 5 largest expense transactions in the selected month, tappable to open that transaction.
- All of the above are computed via SQL aggregation queries in the DAO layer (`SUM`, `GROUP BY category`, `GROUP BY month`) — not by pulling every transaction into Dart and summing in memory. This matters for correctness and for performance once the user has years of data.
- Empty state: if a selected month has no transactions, show a clear empty state, not a broken chart.

Explicitly **out of scope for V1**: forecasting, spending heatmaps, rolling averages beyond the 6-month trend above, year-over-year comparison, essential-vs-discretionary breakdown. These are V1.5/V2 per the roadmap.

---

## Backup & Restore

Drift's SQLite file is the entire database. Don't build a custom export/import format for V1 — just:
- **Backup**: copy the live `.sqlite` file to a user-chosen location via `share_plus` (share sheet) or a save dialog.
- **Restore**: let the user pick a `.sqlite` file via `file_picker`, replace the local database file, then prompt an app restart.
- Validate the picked file is a readable SQLite database before replacing anything; keep the previous file until the new one is confirmed to open successfully.

---

## Build Order (phases)

1. Project scaffold: dependencies, folder structure, `go_router` skeleton, light/dark theme, app entry point.
2. Data layer: Drift schema, tables, DAOs, migration stub, Settings key-value access.
3. `core/money.dart`: minor-unit <-> formatted-string helpers using `intl` and the selected currency.
4. Categories feature (data → application → presentation), seeded with a sensible default set on first run.
5. Transactions feature: add/edit/delete, list with date-range + category filters.
6. Goals feature: CRUD, contribute/withdraw (as `saving`-type transactions linked to a goal), progress + projected completion date calculation.
7. Dashboard screen, wired to real reactive data.
8. Onboarding flow (build after the features it configures exist, so it can actually create real data).
9. Reports screen per the detail spec above — this phase gets the most implementation time.
10. Settings screen: currency/theme/month-start-day, backup/restore, about.
11. App Lock: PIN setup + biometric, launch gate, resume gate.
12. Polish pass: empty states everywhere, error states, accessibility labels on interactive elements, large-number layout check.
13. Tests: unit tests for money math and every SQL aggregation used in Reports (monthly totals, category breakdown, savings rate, trend) — this is the logic that must not be wrong. A handful of widget tests for add-transaction and the dashboard.

---

## Non-Functional Constraints

- Zero network permissions in the manifest/entitlements — the app must be structurally incapable of phoning home.
- Cold start to a populated dashboard in ~1 second on a mid-range device.
- No business logic duplicated between the DAO/repository layer and widgets.
- Support Android + iOS. Don't spend V1 effort on desktop/web-specific handling (Drift's web target needs extra setup) — skip that platform target for now unless it comes up.

## Definition of Done (V1)

- [ ] User can complete onboarding and land on a populated dashboard
- [ ] Add/edit/delete income, expense, and saving transactions
- [ ] Custom categories with archive (not hard-delete once used)
- [ ] At least one goal, contributions reflected in progress + projected completion date
- [ ] Dashboard shows live balance, month income/expense/net savings, savings rate, goal progress
- [ ] Reports screen matches the detail spec above for any month with data, and handles the empty-month case
- [ ] Manual backup and restore both work end to end (backup → wipe app data → restore → data is back)
- [ ] App lock (PIN or biometric) gates launch and resume
- [ ] Light/dark theme both look correct on every screen
- [ ] `flutter analyze` is clean and the test suite from phase 13 passes
