// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Arabic (`ar`).
class AppLocalizationsAr extends AppLocalizations {
  AppLocalizationsAr([String locale = 'ar']) : super(locale);

  @override
  String get appTitle => 'المدخرات';

  @override
  String get navHome => 'الرئيسية';

  @override
  String get navActivity => 'النشاط';

  @override
  String get navReports => 'التقارير';

  @override
  String get navGoals => 'الأهداف';

  @override
  String get navSettings => 'الإعدادات';

  @override
  String get appBarTitle_home => 'المدخرات';

  @override
  String get appBarTitle_activity => 'النشاط';

  @override
  String get appBarTitle_reports => 'التقارير';

  @override
  String get appBarTitle_goals => 'الأهداف';

  @override
  String get appBarTitle_settings => 'الإعدادات';

  @override
  String get appBarTitle_categories => 'الفئات';

  @override
  String get appBarTitle_addActivity => 'إضافة معاملة';

  @override
  String get appBarTitle_editActivity => 'تعديل المعاملة';

  @override
  String get label_spendableBalance => 'الرصيد المتاح';

  @override
  String label_inGoals(String amount) {
    return 'في الأهداف: $amount';
  }

  @override
  String label_monthSummary(String period) {
    return 'ملخص $period';
  }

  @override
  String get label_income => 'الدخل';

  @override
  String get label_expenses => 'المصروفات';

  @override
  String get label_net => 'الصافي';

  @override
  String get label_savingsRate => 'معدل الادخار';

  @override
  String get label_movedToGoals => 'تحويل للأهداف';

  @override
  String get label_unknownCategory => 'غير معروف';

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
    return '$percent% مُدّخر';
  }

  @override
  String label_targetReachedExtra(String extra) {
    return 'تم تحقيق الهدف — $extra إضافية مُدّخرة';
  }

  @override
  String get label_savedSoFar => 'المُدّخر حتى الآن';

  @override
  String label_projectedCompletion(String date) {
    return 'الإنجاز المتوقع: $date';
  }

  @override
  String label_cycleDateRange(String start, String end) {
    return '$start – $end';
  }

  @override
  String get toggle_monthly => 'شهري';

  @override
  String get toggle_lifetime => ' مدى الحياة';

  @override
  String get sectionTitle_goals => 'الأهداف';

  @override
  String get sectionTitle_history => 'السجل';

  @override
  String get sectionTitle_general => 'عام';

  @override
  String get sectionTitle_security => 'الأمان';

  @override
  String get sectionTitle_data => 'البيانات';

  @override
  String get sectionTitle_about => 'حول التطبيق';

  @override
  String get sectionTitle_expensesByCategory => 'المصروفات حسب الفئة';

  @override
  String get sectionTitle_savingsTrend => 'اتجاه الادخار (6 دورات)';

  @override
  String get sectionTitle_topExpenses => 'أكبر المصروفات';

  @override
  String get filter_all => 'الكل';

  @override
  String get filter_income => 'الدخل';

  @override
  String get filter_expense => 'مصروف';

  @override
  String get filter_saving => 'ادخار';

  @override
  String get type_income => 'دخل';

  @override
  String get type_expense => 'مصروف';

  @override
  String get type_saving => 'ادخار';

  @override
  String get emptyState_startTracking => 'ابدأ بتتبع مدخراتك!';

  @override
  String get emptyState_noActivity => 'لا يوجد نشاط';

  @override
  String get emptyState_noGoals => 'لا توجد أهداف بعد';

  @override
  String get emptyState_noCategories => 'لا توجد فئات';

  @override
  String get emptyState_noContributions => 'لا توجد مساهمات بعد';

  @override
  String get emptyState_noDataForCycle => 'لا توجد بيانات لهذه الدورة';

  @override
  String error_generic(String error) {
    return 'خطأ: $error';
  }

  @override
  String get error_insufficientBalance => 'الرصيد غير كافٍ';

  @override
  String get error_invalidAmount => 'الرجاء إدخال مبلغ صحيح';

  @override
  String get error_selectGoal => 'الرجاء اختيار هدف';

  @override
  String get error_selectCategory => 'الرجاء اختيار فئة';

  @override
  String get error_duplicateCategory => 'توجد فئة بهذا الاسم بالفعل';

  @override
  String get error_goalNotFound => 'الهدف غير موجود';

  @override
  String get error_invalidGoalId => 'معرف الهدف غير صالح';

  @override
  String get btn_add => 'إضافة';

  @override
  String get btn_update => 'تحديث';

  @override
  String get btn_save => 'حفظ';

  @override
  String get btn_delete => 'حذف';

  @override
  String get btn_cancel => 'إلغاء';

  @override
  String get btn_create => 'إنشاء';

  @override
  String get btn_verify => 'تحقق';

  @override
  String get btn_back => 'رجوع';

  @override
  String get btn_next => 'التالي';

  @override
  String get btn_skip => 'تخطي';

  @override
  String get btn_getStarted => 'ابدأ الآن';

  @override
  String get btn_startSaving => 'ابدأ الادخار';

  @override
  String get btn_loadMore => 'تحميل المزيد';

  @override
  String get btn_retry => 'إعادة المحاولة';

  @override
  String get btn_contribute => 'إضافة مبلغ';

  @override
  String get btn_withdraw => 'سحب مبلغ';

  @override
  String get btn_ok => 'حسناً';

  @override
  String get menu_edit => 'تعديل';

  @override
  String get menu_delete => 'حذف';

  @override
  String get menu_archive => 'أرشفة';

  @override
  String get menu_unarchive => 'إلغاء الأرشفة';

  @override
  String get menu_pause => 'إيقاف مؤقت';

  @override
  String get menu_resume => 'استئناف';

  @override
  String get menu_markComplete => 'تحديد كمكتمل';

  @override
  String get menu_reopen => 'إعادة فتح';

  @override
  String get fieldLabel_amount => 'المبلغ';

  @override
  String get fieldLabel_name => 'الاسم';

  @override
  String get fieldLabel_type => 'النوع';

  @override
  String get fieldLabel_date => 'التاريخ';

  @override
  String get fieldLabel_noteOptional => 'ملاحظة (اختياري)';

  @override
  String get fieldLabel_source => 'المصدر';

  @override
  String get fieldLabel_category => 'الفئة';

  @override
  String get fieldLabel_goal => 'الهدف';

  @override
  String get fieldLabel_targetAmount => 'المبلغ المستهدف';

  @override
  String get fieldLabel_targetAmountOptional => 'المبلغ المستهدف (اختياري)';

  @override
  String get fieldLabel_goalName => 'اسم الهدف';

  @override
  String get fieldLabel_currentBalance => 'رصيد المدخرات الحالي';

  @override
  String get fieldLabel_newPin => 'الرمز السري الجديد';

  @override
  String get fieldLabel_confirmPin => 'تأكيد الرمز السري';

  @override
  String get dialog_deleteActivityTitle => 'حذف المعاملة؟';

  @override
  String get dialog_deleteGoalTitle => 'حذف الهدف؟';

  @override
  String get dialog_deleteGoalConfirm => 'ستُفقد جميع سجلات الإيداعات.';

  @override
  String get dialog_deleteEntryTitle => 'حذف القيد؟';

  @override
  String get dialog_deleteEntryConfirm => 'سيؤثر هذا على رصيد الهدف.';

  @override
  String get dialog_deleteCategoryTitle => 'حذف الفئة؟';

  @override
  String get dialog_deleteCategoryConfirm => 'هل أنت متأكد من حذف هذه الفئة؟';

  @override
  String get dialog_addCategoryTitle => 'إضافة فئة';

  @override
  String get dialog_editCategoryTitle => 'تعديل الفئة';

  @override
  String get dialog_newGoalTitle => 'هدف جديد';

  @override
  String get dialog_editGoalTitle => 'تعديل الهدف';

  @override
  String get dialog_contributeTitle => 'إضافة مبلغ';

  @override
  String get dialog_withdrawTitle => 'سحب مبلغ';

  @override
  String get dialog_currencyTitle => 'العملة';

  @override
  String get dialog_themeTitle => 'المظهر';

  @override
  String get dialog_verifyCurrentPinTitle => 'تحقق من الرمز السري الحالي';

  @override
  String get dialog_setNewPinTitle => 'تعيين رمز سري جديد';

  @override
  String categoryInUseWarning(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'مستخدم في $count معاملة',
      many: 'مستخدم في $count معاملة',
      few: 'مستخدم في $count معاملات',
      two: 'مستخدم في معاملتين',
      one: 'مستخدم في معاملة واحدة',
      zero: 'غير مستخدم في أي معاملات',
    );
    return '$_temp0';
  }

  @override
  String categoryDeleteBlocked(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'معاملة',
      many: 'معاملة',
      few: 'معاملات',
      two: 'معاملتين',
      one: 'معاملة',
      zero: 'معاملات',
    );
    return 'هذه الفئة مستخدمة في $count $_temp0 ولا يمكن حذفها. استخدم الأرشفة بدلاً من ذلك.';
  }

  @override
  String get dialog_deleteActivityConfirm => 'لا يمكن التراجع عن هذا الإجراء.';

  @override
  String get categoryType_income => 'دخل';

  @override
  String get categoryType_expense => 'مصروف';

  @override
  String get goalStatus_active => 'نشط';

  @override
  String get goalStatus_paused => 'متوقف مؤقتاً';

  @override
  String get goalStatus_completed => 'مكتمل';

  @override
  String get goalStatus_archived => 'مؤرشف';

  @override
  String get theme_system => 'النظام';

  @override
  String get theme_light => 'فاتح';

  @override
  String get theme_dark => 'داكن';

  @override
  String get setting_language => 'اللغة';

  @override
  String get setting_languageSubtitle => 'الإعداد الافتراضي للنظام';

  @override
  String get dialog_languageTitle => 'اللغة';

  @override
  String get lang_system => 'النظام';

  @override
  String get lang_en => 'English';

  @override
  String get lang_ar => 'العربية';

  @override
  String get setting_currency => 'العملة';

  @override
  String get setting_theme => 'المظهر';

  @override
  String get setting_appLock => 'قفل التطبيق';

  @override
  String get setting_appLockSubtitle => 'تطلب الرمز السري عند التشغيل';

  @override
  String get setting_changePin => 'تغيير الرمز السري';

  @override
  String get setting_changePinSubtitle => 'تحديث رمز سري للقفل';

  @override
  String get setting_backup => 'نسخة احتياطية';

  @override
  String get setting_backupSubtitle => 'تصدير ملف قاعدة البيانات';

  @override
  String get setting_restore => 'استعادة';

  @override
  String get setting_restoreSubtitle => 'استيراد ملف قاعدة البيانات';

  @override
  String get setting_appName => 'تطبيق المدخرات';

  @override
  String get setting_appVersion => 'الإصدار 1.0.0';

  @override
  String get share_backupLabel => 'نسخة احتياطية من تطبيق المدخرات';

  @override
  String get snackbar_invalidDbFile => 'ملف قاعدة البيانات غير صالح';

  @override
  String get snackbar_dbRestored =>
      'تمت استعادة قاعدة البيانات. يرجى إعادة تشغيل التطبيق.';

  @override
  String snackbar_restoreFailed(String error) {
    return 'فشلت الاستعادة: $error';
  }

  @override
  String get snackbar_pinValidation =>
      'يجب أن يتطابق الرمزان وأن يكونا 4 أرقام';

  @override
  String get snackbar_pinUpdated => 'تم تحديث الرمز السري';

  @override
  String txnSubtitle_savingToGoal(String goalName) {
    return '$goalName';
  }

  @override
  String get txnSubtitle_saving => 'ادخار';

  @override
  String get semantics_addNewActivity => 'إضافة معاملة جديدة';

  @override
  String get semantics_manageCategories => 'إدارة الفئات';

  @override
  String get semantics_addNewCategory => 'إضافة فئة جديدة';

  @override
  String get onboarding_languageTitle => 'اللغة';

  @override
  String get onboarding_welcomeTitle => 'مرحباً بك في المدخرات';

  @override
  String get onboarding_welcomeBody => 'تتبع مدخراتك وشاهد أين يذهب مالك.';

  @override
  String get onboarding_currencyTitle => 'العملة';

  @override
  String get onboarding_balanceTitle => 'الرصيد الأولي (اختياري)';

  @override
  String get onboarding_goalTitle => 'الهدف الأول (اختياري)';

  @override
  String get onboarding_doneTitle => 'كل شيء جاهز!';

  @override
  String get onboarding_doneBody => 'أنت الآن جاهز لبدء تتبع مدخراتك.';

  @override
  String get note_startingBalance => 'الرصيد الأولي';

  @override
  String get note_initialContribution => 'المساهمة الأولى';

  @override
  String get appLock_enterPin => 'أدخل الرمز السري';

  @override
  String get appLock_setPin => 'تعيين رمز سري';

  @override
  String get appLock_wrongPin => 'رمز سري خاطئ';
}
