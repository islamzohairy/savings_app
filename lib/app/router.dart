import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/dashboard/presentation/dashboard_screen.dart';
import '../features/transactions/presentation/transactions_screen.dart';
import '../features/categories/presentation/categories_screen.dart';
import '../features/goals/presentation/goals_screen.dart';
import '../features/goals/presentation/goal_detail_screen.dart';
import '../features/reports/presentation/reports_screen.dart';
import '../features/settings/presentation/settings_screen.dart';
import '../l10n/app_localizations.dart';

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/',
    routes: [
      ShellRoute(
        builder: (context, state, child) => ScaffoldWithNav(child: child),
        routes: [
          GoRoute(path: '/', builder: (_, _) => const DashboardScreen()),
          GoRoute(path: '/transactions', builder: (_, _) => const TransactionsScreen()),
          GoRoute(path: '/categories', builder: (_, _) => const CategoriesScreen()),
          GoRoute(path: '/goals', builder: (_, _) => const GoalsScreen()),
          GoRoute(
            path: '/goals/:id',
            builder: (_, state) => GoalDetailScreen(goalId: int.parse(state.pathParameters['id']!)),
          ),
          GoRoute(path: '/reports', builder: (_, _) => const ReportsScreen()),
          GoRoute(path: '/settings', builder: (_, _) => const SettingsScreen()),
        ],
      ),
    ],
  );
});

class ScaffoldWithNav extends StatelessWidget {
  const ScaffoldWithNav({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _calculateIndex(context),
        onDestinationSelected: (i) => _onTap(context, i),
        destinations: [
          NavigationDestination(icon: const Icon(Icons.home_outlined), selectedIcon: const Icon(Icons.home), label: AppLocalizations.of(context)!.navHome),
          NavigationDestination(icon: const Icon(Icons.receipt_long_outlined), selectedIcon: const Icon(Icons.receipt_long), label: AppLocalizations.of(context)!.navActivity),
          NavigationDestination(icon: const Icon(Icons.bar_chart_outlined), selectedIcon: const Icon(Icons.bar_chart), label: AppLocalizations.of(context)!.navReports),
          NavigationDestination(icon: const Icon(Icons.savings_outlined), selectedIcon: const Icon(Icons.savings), label: AppLocalizations.of(context)!.navGoals),
          NavigationDestination(icon: const Icon(Icons.settings_outlined), selectedIcon: const Icon(Icons.settings), label: AppLocalizations.of(context)!.navSettings),
        ],
      ),
    );
  }

  int _calculateIndex(BuildContext context) {
    final loc = GoRouterState.of(context).uri.toString();
    if (loc.startsWith('/transactions')) return 1;
    if (loc.startsWith('/reports')) return 2;
    if (loc.startsWith('/goals')) return 3;
    if (loc.startsWith('/settings')) return 4;
    return 0;
  }

  void _onTap(BuildContext context, int index) {
    switch (index) {
      case 0: context.go('/');
      case 1: context.go('/transactions');
      case 2: context.go('/reports');
      case 3: context.go('/goals');
      case 4: context.go('/settings');
    }
  }
}
