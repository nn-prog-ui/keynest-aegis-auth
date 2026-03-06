import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:aegis_auth/keynest/keynest_app.dart';

void main() {
  testWidgets('Aegis Auth home renders', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(const AegisAuthApp());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    final welcomeFound =
        find.text('Welcome to Aegis Auth').evaluate().isNotEmpty;
    final lockTitleFound = find.text('保護されたアクセス').evaluate().isNotEmpty;
    final homeTitleFound = find.text('このアプリでできること').evaluate().isNotEmpty;
    final loadingFound =
        find.byType(CircularProgressIndicator).evaluate().isNotEmpty;

    expect(welcomeFound || lockTitleFound || homeTitleFound || loadingFound,
        isTrue);
  });
}
