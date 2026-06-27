// Smoke test sederhana untuk layar login.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:merchant_app/screens/login_screen.dart';

void main() {
  testWidgets('Login screen menampilkan judul & tombol Masuk', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: LoginScreen()));

    expect(find.text('SI-TEPAT'), findsOneWidget);
    expect(find.text('Masuk'), findsOneWidget);
    expect(find.widgetWithText(TextFormField, 'Username'), findsOneWidget);
  });
}
