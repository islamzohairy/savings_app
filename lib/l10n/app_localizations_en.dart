// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Savings';

  @override
  String get navHome => 'Home';

  @override
  String get navActivity => 'Activity';

  @override
  String get navReports => 'Reports';

  @override
  String get navGoals => 'Goals';

  @override
  String get navSettings => 'Settings';

  @override
  String get appBarTitle_home => 'Savings';

  @override
  String get appBarTitle_activity => 'Activity';

  @override
  String get appBarTitle_reports => 'Reports';

  @override
  String get appBarTitle_goals => 'Goals';

  @override
  String get appBarTitle_settings => 'Settings';

  @override
  String get appBarTitle_categories => 'Categories';

  @override
  String get appBarTitle_addActivity => 'Add Activity';

  @override
  String get appBarTitle_editActivity => 'Edit Activity';

  @override
  String get label_spendableBalance => 'Spendable Balance';

  @override
  String label_inGoals(String amount) {
    return 'In Goals: $amount';
  }

  @override
  String label_monthSummary(String period) {
    return '$period Summary';
  }

  @override
  String get label_income => 'Income';

  @override
  String get label_expenses => 'Expenses';

  @override
  String get label_net => 'Net';

  @override
  String get label_savingsRate => 'Savings Rate';

  @override
  String get label_movedToGoals => 'Moved to Goals';

  @override
  String get label_unknownCategory => 'Unknown';

  @override
  String label_percent(String value) {
    return '$value%';
  }

  @override
  String label_amountOfTarget(String current, String target) {
    return '$current / $target';
  }

  @override
  String label_percentSaved(String percent) {
    return '$percent% saved';
  }

  @override
  String label_targetReachedExtra(String extra) {
    return 'Target reached — $extra extra saved';
  }

  @override
  String get label_savedSoFar => 'Saved so far';

  @override
  String label_projectedCompletion(String date) {
    return 'Projected completion: $date';
  }

  @override
  String label_cycleDateRange(String start, String end) {
    return '$start – $end';
  }

  @override
  String get toggle_monthly => 'Monthly';

  @override
  String get toggle_lifetime => 'Lifetime';

  @override
  String get sectionTitle_goals => 'Goals';

  @override
  String get sectionTitle_history => 'History';

  @override
  String get sectionTitle_general => 'General';

  @override
  String get sectionTitle_security => 'Security';

  @override
  String get sectionTitle_data => 'Data';

  @override
  String get sectionTitle_about => 'About';

  @override
  String get sectionTitle_expensesByCategory => 'Expenses by Category';

  @override
  String get sectionTitle_savingsTrend => 'Savings Trend (6 cycles)';

  @override
  String get sectionTitle_topExpenses => 'Top Expenses';

  @override
  String get filter_all => 'All';

  @override
  String get filter_income => 'Income';

  @override
  String get filter_expense => 'Expense';

  @override
  String get filter_saving => 'Saving';

  @override
  String get type_income => 'Income';

  @override
  String get type_expense => 'Expense';

  @override
  String get type_saving => 'Saving';

  @override
  String get emptyState_startTracking => 'Start tracking your savings!';

  @override
  String get emptyState_noActivity => 'No activity';

  @override
  String get emptyState_noGoals => 'No goals yet';

  @override
  String get emptyState_noCategories => 'No categories';

  @override
  String get emptyState_noContributions => 'No contributions yet';

  @override
  String get emptyState_noDataForCycle => 'No data for this cycle';

  @override
  String error_generic(String error) {
    return 'Error: $error';
  }

  @override
  String get error_insufficientBalance => 'Insufficient balance';

  @override
  String get error_invalidAmount => 'Please enter a valid amount';

  @override
  String get btn_add => 'Add';

  @override
  String get btn_update => 'Update';

  @override
  String get btn_save => 'Save';

  @override
  String get btn_delete => 'Delete';

  @override
  String get btn_cancel => 'Cancel';

  @override
  String get btn_create => 'Create';

  @override
  String get btn_verify => 'Verify';

  @override
  String get btn_back => 'Back';

  @override
  String get btn_next => 'Next';

  @override
  String get btn_skip => 'Skip';

  @override
  String get btn_getStarted => 'Get Started';

  @override
  String get btn_startSaving => 'Start Saving';

  @override
  String get btn_loadMore => 'Load more';

  @override
  String get btn_contribute => 'Contribute';

  @override
  String get btn_withdraw => 'Withdraw';

  @override
  String get btn_ok => 'OK';

  @override
  String get menu_edit => 'Edit';

  @override
  String get menu_delete => 'Delete';

  @override
  String get menu_archive => 'Archive';

  @override
  String get menu_unarchive => 'Unarchive';

  @override
  String get menu_pause => 'Pause';

  @override
  String get menu_resume => 'Resume';

  @override
  String get menu_markComplete => 'Mark Complete';

  @override
  String get menu_reopen => 'Reopen';

  @override
  String get fieldLabel_amount => 'Amount';

  @override
  String get fieldLabel_name => 'Name';

  @override
  String get fieldLabel_type => 'Type';

  @override
  String get fieldLabel_date => 'Date';

  @override
  String get fieldLabel_noteOptional => 'Note (optional)';

  @override
  String get fieldLabel_source => 'Source';

  @override
  String get fieldLabel_category => 'Category';

  @override
  String get fieldLabel_goal => 'Goal';

  @override
  String get fieldLabel_targetAmount => 'Target amount';

  @override
  String get fieldLabel_targetAmountOptional => 'Target amount (optional)';

  @override
  String get fieldLabel_goalName => 'Goal name';

  @override
  String get fieldLabel_currentBalance => 'Current savings balance';

  @override
  String get fieldLabel_newPin => 'New PIN';

  @override
  String get fieldLabel_confirmPin => 'Confirm PIN';

  @override
  String get dialog_deleteActivityTitle => 'Delete activity?';

  @override
  String get dialog_deleteGoalTitle => 'Delete goal?';

  @override
  String get dialog_deleteGoalConfirm =>
      'All contribution history will be lost.';

  @override
  String get dialog_deleteEntryTitle => 'Delete entry?';

  @override
  String get dialog_deleteEntryConfirm => 'This will affect your goal balance.';

  @override
  String get dialog_deleteCategoryTitle => 'Delete category?';

  @override
  String get dialog_deleteCategoryConfirm =>
      'Are you sure you want to delete this category?';

  @override
  String get dialog_addCategoryTitle => 'Add Category';

  @override
  String get dialog_editCategoryTitle => 'Edit Category';

  @override
  String get dialog_newGoalTitle => 'New Goal';

  @override
  String get dialog_editGoalTitle => 'Edit Goal';

  @override
  String get dialog_contributeTitle => 'Contribute';

  @override
  String get dialog_withdrawTitle => 'Withdraw';

  @override
  String get dialog_currencyTitle => 'Currency';

  @override
  String get dialog_themeTitle => 'Theme';

  @override
  String get dialog_verifyCurrentPinTitle => 'Verify Current PIN';

  @override
  String get dialog_setNewPinTitle => 'Set New PIN';

  @override
  String categoryInUseWarning(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Used in $count transactions',
      many: 'Used in $count transactions',
      few: 'Used in $count transactions',
      two: 'Used in 2 transactions',
      one: 'Used in 1 transaction',
      zero: 'Not used in any transactions',
    );
    return '$_temp0';
  }

  @override
  String categoryDeleteBlocked(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'transactions',
      one: 'transaction',
    );
    return 'This category is used by $count $_temp0 and cannot be deleted. Use Archive instead.';
  }

  @override
  String get dialog_deleteActivityConfirm => 'This action cannot be undone.';

  @override
  String get categoryType_income => 'INCOME';

  @override
  String get categoryType_expense => 'EXPENSE';

  @override
  String get goalStatus_active => 'Active';

  @override
  String get goalStatus_paused => 'Paused';

  @override
  String get goalStatus_completed => 'Completed';

  @override
  String get goalStatus_archived => 'Archived';

  @override
  String get theme_system => 'System';

  @override
  String get theme_light => 'Light';

  @override
  String get theme_dark => 'Dark';

  @override
  String get setting_language => 'Language';

  @override
  String get setting_languageSubtitle => 'System default';

  @override
  String get dialog_languageTitle => 'Language';

  @override
  String get lang_system => 'System';

  @override
  String get lang_en => 'English';

  @override
  String get lang_ar => 'العربية';

  @override
  String get setting_currency => 'Currency';

  @override
  String get setting_theme => 'Theme';

  @override
  String get setting_appLock => 'App Lock';

  @override
  String get setting_appLockSubtitle => 'Require PIN on launch';

  @override
  String get setting_changePin => 'Change PIN';

  @override
  String get setting_changePinSubtitle => 'Update your app lock PIN';

  @override
  String get setting_backup => 'Backup';

  @override
  String get setting_backupSubtitle => 'Export database file';

  @override
  String get setting_restore => 'Restore';

  @override
  String get setting_restoreSubtitle => 'Import database file';

  @override
  String get setting_appName => 'Savings App';

  @override
  String get setting_appVersion => 'Version 1.0.0';

  @override
  String get share_backupLabel => 'Savings App Backup';

  @override
  String get snackbar_invalidDbFile => 'Invalid database file';

  @override
  String get snackbar_dbRestored =>
      'Database restored. Please restart the app.';

  @override
  String snackbar_restoreFailed(String error) {
    return 'Restore failed: $error';
  }

  @override
  String get snackbar_pinValidation => 'PINs must match and be 4 digits';

  @override
  String get snackbar_pinUpdated => 'PIN updated';

  @override
  String txnSubtitle_savingToGoal(String goalName) {
    return '$goalName';
  }

  @override
  String get txnSubtitle_saving => 'Saving';

  @override
  String get semantics_addNewActivity => 'Add new activity';

  @override
  String get semantics_manageCategories => 'Manage categories';

  @override
  String get semantics_addNewCategory => 'Add new category';

  @override
  String get onboarding_languageTitle => 'Language';

  @override
  String get onboarding_welcomeTitle => 'Welcome to Savings';

  @override
  String get onboarding_welcomeBody =>
      'Track your savings, see where your money goes.';

  @override
  String get onboarding_currencyTitle => 'Currency';

  @override
  String get onboarding_balanceTitle => 'Starting Balance (optional)';

  @override
  String get onboarding_goalTitle => 'First Goal (optional)';

  @override
  String get onboarding_doneTitle => 'All Set!';

  @override
  String get onboarding_doneBody =>
      'You\'re ready to start tracking your savings.';

  @override
  String get note_startingBalance => 'Starting balance';

  @override
  String get note_initialContribution => 'Initial contribution';

  @override
  String get appLock_enterPin => 'Enter PIN';

  @override
  String get appLock_setPin => 'Set PIN';

  @override
  String get appLock_wrongPin => 'Wrong PIN';
}
