import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:e_clearance_mobile/core/app_state.dart';
import 'package:e_clearance_mobile/core/routes.dart';
import 'package:e_clearance_mobile/core/theme/app_theme.dart';

Widget _buildApp() {
  return ChangeNotifierProvider(
    create: (_) => AppState(),
    child: MaterialApp(
      theme: AppTheme.light,
      initialRoute: AppRoutes.login,
      routes: AppRoutes.table,
    ),
  );
}

void main() {
  testWidgets('Login screen shows email, password and Log in button',
          (tester) async {
        await tester.pumpWidget(_buildApp());

        expect(find.text('E-Clearance'), findsOneWidget);
        expect(find.text('Email'), findsOneWidget);
        expect(find.text('Password'), findsOneWidget);
        expect(find.text('Log in'), findsOneWidget);
      });

  testWidgets('Empty email shows a validation error', (tester) async {
    await tester.pumpWidget(_buildApp());

    await tester.enterText(find.byType(TextFormField).first, '');
    await tester.tap(find.text('Log in'));
    await tester.pump();

    expect(find.text('Email is required'), findsOneWidget);
  });

  testWidgets('Wrong password shows an error message', (tester) async {
    await tester.pumpWidget(_buildApp());

    await tester.enterText(find.byType(TextFormField).last, 'Wrong@1234');
    await tester.tap(find.text('Log in'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 2));

    expect(find.text('Invalid email or password.'), findsOneWidget);
  });

  testWidgets('Correct login opens the empty dashboard', (tester) async {
    await tester.pumpWidget(_buildApp());

    await tester.tap(find.text('Log in'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle();

    expect(find.text('Ahsan Khan'), findsOneWidget);
    expect(find.text('No active clearance'), findsOneWidget);
    expect(find.text('Start Clearance'), findsOneWidget);
  });
}