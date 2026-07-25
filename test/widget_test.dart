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
}
