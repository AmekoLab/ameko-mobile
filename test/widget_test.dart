// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'package:ameko_app/main.dart';
import 'package:ameko_app/injection_container.dart';

void main() {
  setUp(() async {
    await sl.reset();
    // Mock SharedPreferences
    SharedPreferences.setMockInitialValues({});
    // Mock DotEnv
    dotenv.testLoad(mergeWith: {'BASE_URL': 'https://localhost:5001/'});
    // Initialize dependencies
    await setupDependencies();
  });

  testWidgets('App splash screen smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const AmekoApp());

    // Verify that our splash screen shows the app name.
    expect(find.text('Ameko'), findsOneWidget);
    expect(find.text('Custom Keyboard Marketplace'), findsOneWidget);

    // Advance time to allow splash screen timer to finish
    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();
  });
}
