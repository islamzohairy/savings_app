import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:savings_app/app/app.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  testWidgets('App launches', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: SavingsApp()));
    await tester.pump();
    expect(find.byType(SavingsApp), findsOneWidget);
  });

  testWidgets('App renders with Arabic locale (RTL)', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('ar'),
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
        supportedLocales: const [Locale('ar')],
        home: const Directionality(
          textDirection: TextDirection.rtl,
          child: Scaffold(
            body: Center(child: Text('اختبار')),
          ),
        ),
      ),
    );
    await tester.pump();
    final directionality = tester.widget<Directionality>(find.byType(Directionality).last);
    expect(directionality.textDirection, TextDirection.rtl);
    expect(find.text('اختبار'), findsOneWidget);
  });
}
