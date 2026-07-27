import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';
import 'app_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('ar'),
    Locale('en'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'Savings'**
  String get appTitle;

  /// No description provided for @navHome.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get navHome;

  /// No description provided for @navActivity.
  ///
  /// In en, this message translates to:
  /// **'Activity'**
  String get navActivity;

  /// No description provided for @navReports.
  ///
  /// In en, this message translates to:
  /// **'Reports'**
  String get navReports;

  /// No description provided for @navGoals.
  ///
  /// In en, this message translates to:
  /// **'Goals'**
  String get navGoals;

  /// No description provided for @navSettings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get navSettings;

  /// No description provided for @appBarTitle_home.
  ///
  /// In en, this message translates to:
  /// **'Savings'**
  String get appBarTitle_home;

  /// No description provided for @appBarTitle_activity.
  ///
  /// In en, this message translates to:
  /// **'Activity'**
  String get appBarTitle_activity;

  /// No description provided for @appBarTitle_reports.
  ///
  /// In en, this message translates to:
  /// **'Reports'**
  String get appBarTitle_reports;

  /// No description provided for @appBarTitle_goals.
  ///
  /// In en, this message translates to:
  /// **'Goals'**
  String get appBarTitle_goals;

  /// No description provided for @appBarTitle_settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get appBarTitle_settings;

  /// No description provided for @appBarTitle_categories.
  ///
  /// In en, this message translates to:
  /// **'Categories'**
  String get appBarTitle_categories;

  /// No description provided for @appBarTitle_addActivity.
  ///
  /// In en, this message translates to:
  /// **'Add Activity'**
  String get appBarTitle_addActivity;

  /// No description provided for @appBarTitle_editActivity.
  ///
  /// In en, this message translates to:
  /// **'Edit Activity'**
  String get appBarTitle_editActivity;

  /// No description provided for @label_spendableBalance.
  ///
  /// In en, this message translates to:
  /// **'Spendable Balance'**
  String get label_spendableBalance;

  /// No description provided for @label_inGoals.
  ///
  /// In en, this message translates to:
  /// **'In Goals: {amount}'**
  String label_inGoals(String amount);

  /// No description provided for @label_monthSummary.
  ///
  /// In en, this message translates to:
  /// **'{period} Summary'**
  String label_monthSummary(String period);

  /// No description provided for @label_income.
  ///
  /// In en, this message translates to:
  /// **'Income'**
  String get label_income;

  /// No description provided for @label_expenses.
  ///
  /// In en, this message translates to:
  /// **'Expenses'**
  String get label_expenses;

  /// No description provided for @label_net.
  ///
  /// In en, this message translates to:
  /// **'Net'**
  String get label_net;

  /// No description provided for @label_savingsRate.
  ///
  /// In en, this message translates to:
  /// **'Savings Rate'**
  String get label_savingsRate;

  /// No description provided for @label_movedToGoals.
  ///
  /// In en, this message translates to:
  /// **'Moved to Goals'**
  String get label_movedToGoals;

  /// No description provided for @label_unknownCategory.
  ///
  /// In en, this message translates to:
  /// **'Unknown'**
  String get label_unknownCategory;

  /// No description provided for @label_percent.
  ///
  /// In en, this message translates to:
  /// **'{value}%'**
  String label_percent(String value);

  /// No description provided for @label_amountOfTarget.
  ///
  /// In en, this message translates to:
  /// **'{current} / {target}'**
  String label_amountOfTarget(String current, String target);

  /// No description provided for @label_percentSaved.
  ///
  /// In en, this message translates to:
  /// **'{percent}% saved'**
  String label_percentSaved(String percent);

  /// No description provided for @label_targetReachedExtra.
  ///
  /// In en, this message translates to:
  /// **'Target reached — {extra} extra saved'**
  String label_targetReachedExtra(String extra);

  /// No description provided for @label_savedSoFar.
  ///
  /// In en, this message translates to:
  /// **'Saved so far'**
  String get label_savedSoFar;

  /// No description provided for @label_projectedCompletion.
  ///
  /// In en, this message translates to:
  /// **'Projected completion: {date}'**
  String label_projectedCompletion(String date);

  /// No description provided for @label_cycleDateRange.
  ///
  /// In en, this message translates to:
  /// **'{start} – {end}'**
  String label_cycleDateRange(String start, String end);

  /// No description provided for @toggle_monthly.
  ///
  /// In en, this message translates to:
  /// **'Monthly'**
  String get toggle_monthly;

  /// No description provided for @toggle_lifetime.
  ///
  /// In en, this message translates to:
  /// **'Lifetime'**
  String get toggle_lifetime;

  /// No description provided for @sectionTitle_goals.
  ///
  /// In en, this message translates to:
  /// **'Goals'**
  String get sectionTitle_goals;

  /// No description provided for @sectionTitle_history.
  ///
  /// In en, this message translates to:
  /// **'History'**
  String get sectionTitle_history;

  /// No description provided for @sectionTitle_general.
  ///
  /// In en, this message translates to:
  /// **'General'**
  String get sectionTitle_general;

  /// No description provided for @sectionTitle_security.
  ///
  /// In en, this message translates to:
  /// **'Security'**
  String get sectionTitle_security;

  /// No description provided for @sectionTitle_data.
  ///
  /// In en, this message translates to:
  /// **'Data'**
  String get sectionTitle_data;

  /// No description provided for @sectionTitle_about.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get sectionTitle_about;

  /// No description provided for @sectionTitle_expensesByCategory.
  ///
  /// In en, this message translates to:
  /// **'Expenses by Category'**
  String get sectionTitle_expensesByCategory;

  /// No description provided for @sectionTitle_savingsTrend.
  ///
  /// In en, this message translates to:
  /// **'Savings Trend (6 cycles)'**
  String get sectionTitle_savingsTrend;

  /// No description provided for @sectionTitle_topExpenses.
  ///
  /// In en, this message translates to:
  /// **'Top Expenses'**
  String get sectionTitle_topExpenses;

  /// No description provided for @filter_all.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get filter_all;

  /// No description provided for @filter_income.
  ///
  /// In en, this message translates to:
  /// **'Income'**
  String get filter_income;

  /// No description provided for @filter_expense.
  ///
  /// In en, this message translates to:
  /// **'Expense'**
  String get filter_expense;

  /// No description provided for @filter_saving.
  ///
  /// In en, this message translates to:
  /// **'Saving'**
  String get filter_saving;

  /// No description provided for @type_income.
  ///
  /// In en, this message translates to:
  /// **'Income'**
  String get type_income;

  /// No description provided for @type_expense.
  ///
  /// In en, this message translates to:
  /// **'Expense'**
  String get type_expense;

  /// No description provided for @type_saving.
  ///
  /// In en, this message translates to:
  /// **'Saving'**
  String get type_saving;

  /// No description provided for @emptyState_startTracking.
  ///
  /// In en, this message translates to:
  /// **'Start tracking your savings!'**
  String get emptyState_startTracking;

  /// No description provided for @emptyState_noActivity.
  ///
  /// In en, this message translates to:
  /// **'No activity'**
  String get emptyState_noActivity;

  /// No description provided for @emptyState_noGoals.
  ///
  /// In en, this message translates to:
  /// **'No goals yet'**
  String get emptyState_noGoals;

  /// No description provided for @emptyState_noCategories.
  ///
  /// In en, this message translates to:
  /// **'No categories'**
  String get emptyState_noCategories;

  /// No description provided for @emptyState_noContributions.
  ///
  /// In en, this message translates to:
  /// **'No contributions yet'**
  String get emptyState_noContributions;

  /// No description provided for @emptyState_noDataForCycle.
  ///
  /// In en, this message translates to:
  /// **'No data for this cycle'**
  String get emptyState_noDataForCycle;

  /// No description provided for @error_generic.
  ///
  /// In en, this message translates to:
  /// **'Error: {error}'**
  String error_generic(String error);

  /// No description provided for @error_insufficientBalance.
  ///
  /// In en, this message translates to:
  /// **'Insufficient balance'**
  String get error_insufficientBalance;

  /// No description provided for @btn_add.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get btn_add;

  /// No description provided for @btn_update.
  ///
  /// In en, this message translates to:
  /// **'Update'**
  String get btn_update;

  /// No description provided for @btn_save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get btn_save;

  /// No description provided for @btn_delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get btn_delete;

  /// No description provided for @btn_cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get btn_cancel;

  /// No description provided for @btn_create.
  ///
  /// In en, this message translates to:
  /// **'Create'**
  String get btn_create;

  /// No description provided for @btn_verify.
  ///
  /// In en, this message translates to:
  /// **'Verify'**
  String get btn_verify;

  /// No description provided for @btn_back.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get btn_back;

  /// No description provided for @btn_next.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get btn_next;

  /// No description provided for @btn_skip.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get btn_skip;

  /// No description provided for @btn_getStarted.
  ///
  /// In en, this message translates to:
  /// **'Get Started'**
  String get btn_getStarted;

  /// No description provided for @btn_startSaving.
  ///
  /// In en, this message translates to:
  /// **'Start Saving'**
  String get btn_startSaving;

  /// No description provided for @btn_loadMore.
  ///
  /// In en, this message translates to:
  /// **'Load more'**
  String get btn_loadMore;

  /// No description provided for @btn_contribute.
  ///
  /// In en, this message translates to:
  /// **'Contribute'**
  String get btn_contribute;

  /// No description provided for @btn_withdraw.
  ///
  /// In en, this message translates to:
  /// **'Withdraw'**
  String get btn_withdraw;

  /// No description provided for @btn_ok.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get btn_ok;

  /// No description provided for @menu_edit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get menu_edit;

  /// No description provided for @menu_delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get menu_delete;

  /// No description provided for @menu_archive.
  ///
  /// In en, this message translates to:
  /// **'Archive'**
  String get menu_archive;

  /// No description provided for @menu_unarchive.
  ///
  /// In en, this message translates to:
  /// **'Unarchive'**
  String get menu_unarchive;

  /// No description provided for @menu_pause.
  ///
  /// In en, this message translates to:
  /// **'Pause'**
  String get menu_pause;

  /// No description provided for @menu_resume.
  ///
  /// In en, this message translates to:
  /// **'Resume'**
  String get menu_resume;

  /// No description provided for @menu_markComplete.
  ///
  /// In en, this message translates to:
  /// **'Mark Complete'**
  String get menu_markComplete;

  /// No description provided for @fieldLabel_amount.
  ///
  /// In en, this message translates to:
  /// **'Amount'**
  String get fieldLabel_amount;

  /// No description provided for @fieldLabel_name.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get fieldLabel_name;

  /// No description provided for @fieldLabel_type.
  ///
  /// In en, this message translates to:
  /// **'Type'**
  String get fieldLabel_type;

  /// No description provided for @fieldLabel_date.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get fieldLabel_date;

  /// No description provided for @fieldLabel_noteOptional.
  ///
  /// In en, this message translates to:
  /// **'Note (optional)'**
  String get fieldLabel_noteOptional;

  /// No description provided for @fieldLabel_source.
  ///
  /// In en, this message translates to:
  /// **'Source'**
  String get fieldLabel_source;

  /// No description provided for @fieldLabel_category.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get fieldLabel_category;

  /// No description provided for @fieldLabel_goal.
  ///
  /// In en, this message translates to:
  /// **'Goal'**
  String get fieldLabel_goal;

  /// No description provided for @fieldLabel_targetAmount.
  ///
  /// In en, this message translates to:
  /// **'Target amount'**
  String get fieldLabel_targetAmount;

  /// No description provided for @fieldLabel_targetAmountOptional.
  ///
  /// In en, this message translates to:
  /// **'Target amount (optional)'**
  String get fieldLabel_targetAmountOptional;

  /// No description provided for @fieldLabel_goalName.
  ///
  /// In en, this message translates to:
  /// **'Goal name'**
  String get fieldLabel_goalName;

  /// No description provided for @fieldLabel_currentBalance.
  ///
  /// In en, this message translates to:
  /// **'Current savings balance'**
  String get fieldLabel_currentBalance;

  /// No description provided for @fieldLabel_newPin.
  ///
  /// In en, this message translates to:
  /// **'New PIN'**
  String get fieldLabel_newPin;

  /// No description provided for @fieldLabel_confirmPin.
  ///
  /// In en, this message translates to:
  /// **'Confirm PIN'**
  String get fieldLabel_confirmPin;

  /// No description provided for @dialog_deleteActivityTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete activity?'**
  String get dialog_deleteActivityTitle;

  /// No description provided for @dialog_deleteGoalTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete goal?'**
  String get dialog_deleteGoalTitle;

  /// No description provided for @dialog_deleteGoalConfirm.
  ///
  /// In en, this message translates to:
  /// **'All contribution history will be lost.'**
  String get dialog_deleteGoalConfirm;

  /// No description provided for @dialog_deleteEntryTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete entry?'**
  String get dialog_deleteEntryTitle;

  /// No description provided for @dialog_deleteEntryConfirm.
  ///
  /// In en, this message translates to:
  /// **'This will affect your goal balance.'**
  String get dialog_deleteEntryConfirm;

  /// No description provided for @dialog_deleteCategoryTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete category?'**
  String get dialog_deleteCategoryTitle;

  /// No description provided for @dialog_deleteCategoryConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this category?'**
  String get dialog_deleteCategoryConfirm;

  /// No description provided for @dialog_addCategoryTitle.
  ///
  /// In en, this message translates to:
  /// **'Add Category'**
  String get dialog_addCategoryTitle;

  /// No description provided for @dialog_editCategoryTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit Category'**
  String get dialog_editCategoryTitle;

  /// No description provided for @dialog_newGoalTitle.
  ///
  /// In en, this message translates to:
  /// **'New Goal'**
  String get dialog_newGoalTitle;

  /// No description provided for @dialog_editGoalTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit Goal'**
  String get dialog_editGoalTitle;

  /// No description provided for @dialog_contributeTitle.
  ///
  /// In en, this message translates to:
  /// **'Contribute'**
  String get dialog_contributeTitle;

  /// No description provided for @dialog_withdrawTitle.
  ///
  /// In en, this message translates to:
  /// **'Withdraw'**
  String get dialog_withdrawTitle;

  /// No description provided for @dialog_currencyTitle.
  ///
  /// In en, this message translates to:
  /// **'Currency'**
  String get dialog_currencyTitle;

  /// No description provided for @dialog_themeTitle.
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get dialog_themeTitle;

  /// No description provided for @dialog_verifyCurrentPinTitle.
  ///
  /// In en, this message translates to:
  /// **'Verify Current PIN'**
  String get dialog_verifyCurrentPinTitle;

  /// No description provided for @dialog_setNewPinTitle.
  ///
  /// In en, this message translates to:
  /// **'Set New PIN'**
  String get dialog_setNewPinTitle;

  /// No description provided for @categoryInUseWarning.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{Not used in any transactions} one{Used in 1 transaction} two{Used in 2 transactions} few{Used in {count} transactions} many{Used in {count} transactions} other{Used in {count} transactions}}'**
  String categoryInUseWarning(int count);

  /// No description provided for @categoryDeleteBlocked.
  ///
  /// In en, this message translates to:
  /// **'This category is used by {count} {count, plural, one{transaction} other{transactions}} and cannot be deleted. Use Archive instead.'**
  String categoryDeleteBlocked(int count);

  /// No description provided for @dialog_deleteActivityConfirm.
  ///
  /// In en, this message translates to:
  /// **'This action cannot be undone.'**
  String get dialog_deleteActivityConfirm;

  /// No description provided for @categoryType_income.
  ///
  /// In en, this message translates to:
  /// **'INCOME'**
  String get categoryType_income;

  /// No description provided for @categoryType_expense.
  ///
  /// In en, this message translates to:
  /// **'EXPENSE'**
  String get categoryType_expense;

  /// No description provided for @goalStatus_active.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get goalStatus_active;

  /// No description provided for @goalStatus_paused.
  ///
  /// In en, this message translates to:
  /// **'Paused'**
  String get goalStatus_paused;

  /// No description provided for @goalStatus_completed.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get goalStatus_completed;

  /// No description provided for @goalStatus_archived.
  ///
  /// In en, this message translates to:
  /// **'Archived'**
  String get goalStatus_archived;

  /// No description provided for @theme_system.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get theme_system;

  /// No description provided for @theme_light.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get theme_light;

  /// No description provided for @theme_dark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get theme_dark;

  /// No description provided for @setting_language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get setting_language;

  /// No description provided for @setting_languageSubtitle.
  ///
  /// In en, this message translates to:
  /// **'System default'**
  String get setting_languageSubtitle;

  /// No description provided for @dialog_languageTitle.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get dialog_languageTitle;

  /// No description provided for @lang_system.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get lang_system;

  /// No description provided for @lang_en.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get lang_en;

  /// No description provided for @lang_ar.
  ///
  /// In en, this message translates to:
  /// **'العربية'**
  String get lang_ar;

  /// No description provided for @setting_currency.
  ///
  /// In en, this message translates to:
  /// **'Currency'**
  String get setting_currency;

  /// No description provided for @setting_theme.
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get setting_theme;

  /// No description provided for @setting_appLock.
  ///
  /// In en, this message translates to:
  /// **'App Lock'**
  String get setting_appLock;

  /// No description provided for @setting_appLockSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Require PIN on launch'**
  String get setting_appLockSubtitle;

  /// No description provided for @setting_changePin.
  ///
  /// In en, this message translates to:
  /// **'Change PIN'**
  String get setting_changePin;

  /// No description provided for @setting_changePinSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Update your app lock PIN'**
  String get setting_changePinSubtitle;

  /// No description provided for @setting_backup.
  ///
  /// In en, this message translates to:
  /// **'Backup'**
  String get setting_backup;

  /// No description provided for @setting_backupSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Export database file'**
  String get setting_backupSubtitle;

  /// No description provided for @setting_restore.
  ///
  /// In en, this message translates to:
  /// **'Restore'**
  String get setting_restore;

  /// No description provided for @setting_restoreSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Import database file'**
  String get setting_restoreSubtitle;

  /// No description provided for @setting_appName.
  ///
  /// In en, this message translates to:
  /// **'Savings App'**
  String get setting_appName;

  /// No description provided for @setting_appVersion.
  ///
  /// In en, this message translates to:
  /// **'Version 1.0.0'**
  String get setting_appVersion;

  /// No description provided for @share_backupLabel.
  ///
  /// In en, this message translates to:
  /// **'Savings App Backup'**
  String get share_backupLabel;

  /// No description provided for @snackbar_invalidDbFile.
  ///
  /// In en, this message translates to:
  /// **'Invalid database file'**
  String get snackbar_invalidDbFile;

  /// No description provided for @snackbar_dbRestored.
  ///
  /// In en, this message translates to:
  /// **'Database restored. Please restart the app.'**
  String get snackbar_dbRestored;

  /// No description provided for @snackbar_restoreFailed.
  ///
  /// In en, this message translates to:
  /// **'Restore failed: {error}'**
  String snackbar_restoreFailed(String error);

  /// No description provided for @snackbar_pinValidation.
  ///
  /// In en, this message translates to:
  /// **'PINs must match and be 4 digits'**
  String get snackbar_pinValidation;

  /// No description provided for @snackbar_pinUpdated.
  ///
  /// In en, this message translates to:
  /// **'PIN updated'**
  String get snackbar_pinUpdated;

  /// No description provided for @txnSubtitle_savingToGoal.
  ///
  /// In en, this message translates to:
  /// **'{goalName}'**
  String txnSubtitle_savingToGoal(String goalName);

  /// No description provided for @txnSubtitle_saving.
  ///
  /// In en, this message translates to:
  /// **'Saving'**
  String get txnSubtitle_saving;

  /// No description provided for @semantics_addNewActivity.
  ///
  /// In en, this message translates to:
  /// **'Add new activity'**
  String get semantics_addNewActivity;

  /// No description provided for @semantics_manageCategories.
  ///
  /// In en, this message translates to:
  /// **'Manage categories'**
  String get semantics_manageCategories;

  /// No description provided for @semantics_addNewCategory.
  ///
  /// In en, this message translates to:
  /// **'Add new category'**
  String get semantics_addNewCategory;

  /// No description provided for @onboarding_languageTitle.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get onboarding_languageTitle;

  /// No description provided for @onboarding_welcomeTitle.
  ///
  /// In en, this message translates to:
  /// **'Welcome to Savings'**
  String get onboarding_welcomeTitle;

  /// No description provided for @onboarding_welcomeBody.
  ///
  /// In en, this message translates to:
  /// **'Track your savings, see where your money goes.'**
  String get onboarding_welcomeBody;

  /// No description provided for @onboarding_currencyTitle.
  ///
  /// In en, this message translates to:
  /// **'Currency'**
  String get onboarding_currencyTitle;

  /// No description provided for @onboarding_balanceTitle.
  ///
  /// In en, this message translates to:
  /// **'Starting Balance (optional)'**
  String get onboarding_balanceTitle;

  /// No description provided for @onboarding_goalTitle.
  ///
  /// In en, this message translates to:
  /// **'First Goal (optional)'**
  String get onboarding_goalTitle;

  /// No description provided for @onboarding_doneTitle.
  ///
  /// In en, this message translates to:
  /// **'All Set!'**
  String get onboarding_doneTitle;

  /// No description provided for @onboarding_doneBody.
  ///
  /// In en, this message translates to:
  /// **'You\'re ready to start tracking your savings.'**
  String get onboarding_doneBody;

  /// No description provided for @note_startingBalance.
  ///
  /// In en, this message translates to:
  /// **'Starting balance'**
  String get note_startingBalance;

  /// No description provided for @note_initialContribution.
  ///
  /// In en, this message translates to:
  /// **'Initial contribution'**
  String get note_initialContribution;

  /// No description provided for @appLock_enterPin.
  ///
  /// In en, this message translates to:
  /// **'Enter PIN'**
  String get appLock_enterPin;

  /// No description provided for @appLock_setPin.
  ///
  /// In en, this message translates to:
  /// **'Set PIN'**
  String get appLock_setPin;

  /// No description provided for @appLock_wrongPin.
  ///
  /// In en, this message translates to:
  /// **'Wrong PIN'**
  String get appLock_wrongPin;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['ar', 'en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar':
      return AppLocalizationsAr();
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
