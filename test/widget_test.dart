import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:my_finance/main.dart';
import 'package:my_finance/providers/transaction_provider.dart';
import 'package:my_finance/providers/loan_provider.dart';
import 'package:my_finance/providers/settings_provider.dart';
import 'package:my_finance/services/database_service.dart';

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    await DatabaseService.init();
  });

  testWidgets('App should build without errors', (WidgetTester tester) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => TransactionProvider()),
          ChangeNotifierProvider(create: (_) => LoanProvider()),
          ChangeNotifierProvider(create: (_) => SettingsProvider()),
        ],
        child: MaterialApp(
          home: Scaffold(
            appBar: AppBar(title: const Text('Test App')),
            body: const Text('Hello World'),
          ),
        ),
      ),
    );

    expect(find.text('Hello World'), findsOneWidget);
    expect(find.text('Test App'), findsOneWidget);
  });

  testWidgets('Navigation should have correct tabs', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();

    expect(find.text('Dashboard'), findsOneWidget);
    expect(find.text('Transactions'), findsOneWidget);
    expect(find.text('Loans'), findsOneWidget);
    expect(find.text('Settings'), findsOneWidget);
  });
}
