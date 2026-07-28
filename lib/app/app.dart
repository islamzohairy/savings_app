import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/theme.dart';
import '../core/settings_provider.dart';
import '../l10n/app_localizations.dart';
import '../features/onboarding/presentation/onboarding_screen.dart';
import '../features/app_lock/presentation/app_lock_screen.dart';
import 'router.dart';

class SavingsApp extends ConsumerWidget {
  const SavingsApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final locale = ref.read(settingsProvider.notifier).resolvedLocale;
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Savings',
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: _resolveThemeMode(settings['themeMode']),
      locale: locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
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
  String? _initError;

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
    setState(() { _isLoading = true; _initError = null; });
    try {
      await ref.read(settingsProvider.notifier).load();
      final settings = ref.read(settingsProvider);
      _onboardingDone = settings['hasCompletedOnboarding'] == 'true';
      _appLockEnabled = settings['appLockEnabled'] == 'true';
      if (mounted) setState(() { _isLoading = false; _initError = null; });
    } catch (e) {
      if (mounted) setState(() { _isLoading = false; _initError = '$e'; });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_initError != null) {
      return Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline, size: 48),
                const SizedBox(height: 12),
                Text(AppLocalizations.of(context)!.error_generic(_initError!), textAlign: TextAlign.center),
                const SizedBox(height: 12),
                FilledButton(onPressed: _init, child: Text(AppLocalizations.of(context)!.btn_retry)),
              ],
            ),
          ),
        ),
      );
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
    final settings = ref.watch(settingsProvider);
    final themeMode = settings['themeMode'];
    final locale = ref.read(settingsProvider.notifier).resolvedLocale;
    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: _resolveThemeMode(themeMode),
      locale: locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
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
