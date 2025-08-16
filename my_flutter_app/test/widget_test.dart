// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:qr_chat_app/main.dart';

void main() {
  testWidgets('ChatApp displays welcome screen with QR chat features', (
    WidgetTester tester,
  ) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(ChatApp());

    // Verify that the app title is displayed.
    expect(find.text('ChatterQR'), findsOneWidget);

    // Verify that the main action buttons are present.
    expect(find.text('Generate QR Code'), findsOneWidget);
    expect(find.text('Scan QR Code'), findsOneWidget);
    expect(find.text('Chat History'), findsOneWidget);

    // Verify that relevant icons are present.
    expect(find.byIcon(Icons.qr_code), findsOneWidget);
    expect(find.byIcon(Icons.qr_code_scanner), findsOneWidget);
    expect(find.byIcon(Icons.history), findsOneWidget);

    // Verify descriptive text is present.
    expect(
      find.textContaining('Connect instantly with anyone through'),
      findsOneWidget,
    );
  });
}
