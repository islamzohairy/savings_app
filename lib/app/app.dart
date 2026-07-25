import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/theme.dart';
import '../core/settings_provider.dart';
import '../core/db/database.dart';
import '../features/onboarding/presentation/onboarding_screen.dart';
import '../features/app_lock/presentation/app_lock_screen.dart';
import 'router.dart';

class SavingsApp extends ConsumerWidget {
  const SavingsApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    return MaterialApp(
      title: 'Savings',
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: _resolveThemeMode(settings['themeMode']),
      home: const _Gate(),
    );
  }

  ThemeMode _resolveThemeMode(String? mode) {
    switch (mode) {
      case 'light': return ThemeMode.light;
      case 'dark': return ThemeMode.dark;
      default: return ThemeMode.system;
    }
  }
}

class _Gate extends ConsumerStatefulWidget {
  const _Gate();

  @override
  ConsumerState<_Gate> createState() => _GateState();
}

class _GateState extends ConsumerState<_Gate> with WidgetsBindingObserver {
  bool _onboardingDone = false;
  bool _appLockEnabled = false;
  bool _unlocked = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _init();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _onboardingDone && _appLockEnabled && _unlocked) {
      setState(() => _unlocked = false);
    }
  }

  Future<void> _init() async {
    final db = AppDatabase.instance;

    // Load settings into reactive provider first
    await ref.read(settingsProvider.notifier).load();

    _onboardingDone = await db.hasCompletedOnboarding();
    if (_onboardingDone) {
      _appLockEnabled = (await db.getSetting('appLockEnabled')) == 'true';
    }
    if (mounted) setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (!_onboardingDone) {
      return OnboardingScreen(onComplete: _init);
    }

    if (_appLockEnabled && !_unlocked) {
      return AppLockScreen(onUnlocked: () => setState(() => _unlocked = true));
    }

    return const _MainApp();
  }
}

class _MainApp extends ConsumerWidget {
  const _MainApp();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    final themeMode = ref.watch(settingsProvider.select((s) => s['themeMode']));
    return MaterialApp.router(
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: _resolveThemeMode(themeMode),
      routerConfig: router,
    );
  }

  ThemeMode _resolveThemeMode(String? mode) {
    switch (mode) {
      case 'light': return ThemeMode.light;
      case 'dark': return ThemeMode.dark;
      default: return ThemeMode.system;
    }
  }
}
