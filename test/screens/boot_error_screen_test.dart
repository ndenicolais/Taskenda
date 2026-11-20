import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:taskenda/screens/boot_error_screen.dart';

void main() {
  // BootErrorApp follows the device language, English in tests.
  testWidgets('shows the error message and retries on tap', (tester) async {
    var retries = 0;
    await tester.pumpWidget(
      BootErrorApp(error: Exception('boom'), onRetry: () => retries++),
    );

    expect(find.text('Unable to start Taskenda'), findsOneWidget);

    await tester.tap(find.widgetWithText(FilledButton, 'Retry'));
    expect(retries, 1);
  });
}
