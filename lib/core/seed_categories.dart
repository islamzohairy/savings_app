const seedCategoryDisplayNames = <String, Map<String, String>>{
  'Groceries': {'en': 'Groceries', 'ar': 'البقالة'},
  'Food & Dining': {'en': 'Food & Dining', 'ar': 'الطعام والمطاعم'},
  'Transportation': {'en': 'Transportation', 'ar': 'المواصلات'},
  'Housing & Rent': {'en': 'Housing & Rent', 'ar': 'السكن والإيجار'},
  'Utilities & Bills': {'en': 'Utilities & Bills', 'ar': 'المرافق والفواتير'},
  'Shopping': {'en': 'Shopping', 'ar': 'التسوق'},
  'Health & Fitness': {'en': 'Health & Fitness', 'ar': 'الصحة واللياقة'},
  'Entertainment': {'en': 'Entertainment', 'ar': 'الترفيه'},
  'Other Expense': {'en': 'Other Expense', 'ar': 'مصروفات أخرى'},
  'Salary': {'en': 'Salary', 'ar': 'الراتب'},
  'Freelance / Business': {'en': 'Freelance / Business', 'ar': 'عمل حر / تجاري'},
  'Gifts': {'en': 'Gifts', 'ar': 'هدايا'},
  'Investments / Interest': {'en': 'Investments / Interest', 'ar': 'استثمارات / فوائد'},
  'Other Income': {'en': 'Other Income', 'ar': 'دخل آخر'},
};

String displayCategoryName(String dbKey, String languageCode) {
  final names = seedCategoryDisplayNames[dbKey];
  if (names == null) return dbKey;
  return names[languageCode] ?? names['en'] ?? dbKey;
}
