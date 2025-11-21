// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:report_designer/main.dart';

void main() {
  testWidgets('Report Designer app smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const ReportDesignerDemoApp());

    // Verify that the app loads with the main title
    expect(find.text('Report Designer Demo'), findsOneWidget);
    
    // Verify that tabs are present
    expect(find.text('Viewer'), findsOneWidget);
    expect(find.text('Builder'), findsOneWidget);
    expect(find.text('Info'), findsOneWidget);
  });
}
