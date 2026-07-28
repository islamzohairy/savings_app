import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/db/database.dart';
import '../../../core/money.dart';
import '../../../core/settings_provider.dart';
import '../../../l10n/app_localizations.dart';
import '../../goals/application/goal_provider.dart';
import '../../transactions/application/transaction_provider.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key, this.onComplete});
  final VoidCallback? onComplete;

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _pageCtrl = PageController();
  int _step = 0;
  String _language = 'system';
  String _currency = 'USD';
  final _balanceCtrl = TextEditingController();
  final _goalNameCtrl = TextEditingController();
  final _goalAmountCtrl = TextEditingController();
  bool _isFinishing = false;

  static const _currencies = ['USD', 'EUR', 'GBP', 'EGP', 'SAR', 'AED'];

  @override
  void dispose() {
    _pageCtrl.dispose();
    _balanceCtrl.dispose();
    _goalNameCtrl.dispose();
    _goalAmountCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: PageView(
          controller: _pageCtrl,
          physics: const NeverScrollableScrollPhysics(),
          children: [
            _languageStep(),
            _welcomeStep(),
            _currencyStep(),
            _balanceStep(),
            _goalStep(),
            _doneStep(),
          ],
        ),
      ),
    );
  }

  Widget _languageStep() => _stepShell(
    title: AppLocalizations.of(context)!.onboarding_languageTitle,
    child: Column(
      children: [
        const SizedBox(height: 32),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            ChoiceChip(
              label: Text(AppLocalizations.of(context)!.lang_system),
              selected: _language == 'system',
              onSelected: (_) => _setLanguage('system'),
            ),
            ChoiceChip(
              label: Text(AppLocalizations.of(context)!.lang_en),
              selected: _language == 'en',
              onSelected: (_) => _setLanguage('en'),
            ),
            ChoiceChip(
              label: Text(AppLocalizations.of(context)!.lang_ar),
              selected: _language == 'ar',
              onSelected: (_) => _setLanguage('ar'),
            ),
          ],
        ),
        const Spacer(),
        Row(
          children: [
            const Spacer(),
            FilledButton(onPressed: _next, child: Text(AppLocalizations.of(context)!.btn_next)),
          ],
        ),
        const SizedBox(height: 16),
      ],
    ),
  );

  void _setLanguage(String code) {
    setState(() => _language = code);
    ref.read(settingsProvider.notifier).set('languageCode', code);
  }

  Widget _welcomeStep() => _stepShell(
    title: AppLocalizations.of(context)!.onboarding_welcomeTitle,
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.savings, size: 80),
        const SizedBox(height: 24),
        Text(AppLocalizations.of(context)!.onboarding_welcomeBody, style: Theme.of(context).textTheme.bodyLarge, textAlign: TextAlign.center),
        const Spacer(),
        Row(
          children: [
            TextButton(onPressed: _prev, child: Text(AppLocalizations.of(context)!.btn_back)),
            const Spacer(),
            FilledButton(onPressed: _next, child: Text(AppLocalizations.of(context)!.btn_getStarted)),
          ],
        ),
        const SizedBox(height: 16),
      ],
    ),
  );

  Widget _currencyStep() => _stepShell(
    title: AppLocalizations.of(context)!.onboarding_currencyTitle,
    child: Column(
      children: [
        const SizedBox(height: 32),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _currencies.map((c) => ChoiceChip(
            label: Text(c),
            selected: _currency == c,
            onSelected: (_) => setState(() => _currency = c),
          )).toList(),
        ),
        const Spacer(),
        Row(
          children: [
            TextButton(onPressed: _prev, child: Text(AppLocalizations.of(context)!.btn_back)),
            const Spacer(),
            FilledButton(onPressed: _next, child: Text(AppLocalizations.of(context)!.btn_next)),
          ],
        ),
        const SizedBox(height: 16),
      ],
    ),
  );

  Widget _balanceStep() => _stepShell(
    title: AppLocalizations.of(context)!.onboarding_balanceTitle,
    child: Column(
      children: [
        const SizedBox(height: 32),
        TextField(
          controller: _balanceCtrl,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: const [MoneyInputFormatter()],
          decoration: InputDecoration(labelText: AppLocalizations.of(context)!.fieldLabel_currentBalance, prefixText: '${symbolFor(_currency)} '),
        ),
        const Spacer(),
        Row(
          children: [
            TextButton(onPressed: _prev, child: Text(AppLocalizations.of(context)!.btn_back)),
            const Spacer(),
            TextButton(onPressed: _next, child: Text(AppLocalizations.of(context)!.btn_skip)),
            const SizedBox(width: 8),
            FilledButton(onPressed: _next, child: Text(AppLocalizations.of(context)!.btn_next)),
          ],
        ),
        const SizedBox(height: 16),
      ],
    ),
  );

  Widget _goalStep() => _stepShell(
    title: AppLocalizations.of(context)!.onboarding_goalTitle,
    child: Column(
      children: [
        const SizedBox(height: 32),
        TextField(controller: _goalNameCtrl, maxLength: 50, decoration: InputDecoration(labelText: AppLocalizations.of(context)!.fieldLabel_goalName)),
        const SizedBox(height: 16),
        TextField(
          controller: _goalAmountCtrl,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: const [MoneyInputFormatter()],
          decoration: InputDecoration(labelText: AppLocalizations.of(context)!.fieldLabel_targetAmount, prefixText: '${symbolFor(_currency)} '),
        ),
        const Spacer(),
        Row(
          children: [
            TextButton(onPressed: _prev, child: Text(AppLocalizations.of(context)!.btn_back)),
            const Spacer(),
            TextButton(onPressed: _next, child: Text(AppLocalizations.of(context)!.btn_skip)),
            const SizedBox(width: 8),
            FilledButton(onPressed: _next, child: Text(AppLocalizations.of(context)!.btn_next)),
          ],
        ),
        const SizedBox(height: 16),
      ],
    ),
  );

  Widget _doneStep() => Padding(
    padding: const EdgeInsets.all(24),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(AppLocalizations.of(context)!.onboarding_doneTitle, style: Theme.of(context).textTheme.headlineSmall, textAlign: TextAlign.center),
        const Spacer(),
        Icon(Icons.check_circle, size: 80, color: Theme.of(context).colorScheme.primary),
        const SizedBox(height: 24),
        Text(AppLocalizations.of(context)!.onboarding_doneBody, style: Theme.of(context).textTheme.bodyLarge, textAlign: TextAlign.center),
        const Spacer(),
        FilledButton(
          onPressed: _isFinishing ? null : _finish,
          child: _isFinishing
              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
              : Text(AppLocalizations.of(context)!.btn_startSaving),
        ),
        const SizedBox(height: 16),
      ],
    ),
  );

  Widget _stepShell({required String title, required Widget child}) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.headlineSmall),
          Expanded(child: child),
        ],
      ),
    );
  }

  void _next() {
    if (_step < 5) {
      _pageCtrl.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
      _step++;
    }
  }

  void _prev() {
    if (_step > 0) {
      _pageCtrl.previousPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
      _step--;
    }
  }

  Future<void> _finish() async {
    if (_isFinishing) return;
    setState(() => _isFinishing = true);
    try {
      final db = AppDatabase.instance;
      await ref.read(settingsProvider.notifier).set('currencyCode', _currency);
      if (!mounted) return;

      final balanceValidation = validateAmount(_balanceCtrl.text);
      if (balanceValidation.isValid && balanceValidation.minorUnits > 0) {
        final now = DateTime.now().toIso8601String();
        final txnRepo = ref.read(transactionRepoProvider);
        await txnRepo.insert({
          'type': TransactionType.income.index,
          'amountMinor': balanceValidation.minorUnits,
          'date': now,
          'note': AppLocalizations.of(context)!.note_startingBalance,
          'createdAt': now,
          'updatedAt': now,
        });
      }
      if (!mounted) return;

      if (_goalNameCtrl.text.trim().isNotEmpty) {
        final goalValidation = validateAmount(_goalAmountCtrl.text);
        final now = DateTime.now().toIso8601String();
        await ref.read(goalRepoProvider).insert({
          'name': _goalNameCtrl.text.trim(),
          'targetAmountMinor': goalValidation.isValid && goalValidation.minorUnits > 0 ? goalValidation.minorUnits : null,
          'iconKey': 'flag',
          'colorHex': '3F51B5',
          'status': GoalStatus.active.index,
          'sortOrder': 0,
          'createdAt': now,
        });
      }
      if (!mounted) return;

      await db.completeOnboarding();

      if (mounted) {
        widget.onComplete?.call();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isFinishing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.error_generic('$e'))),
        );
      }
    }
  }
}
