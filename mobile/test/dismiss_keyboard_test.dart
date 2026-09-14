import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bytesync/shared/widgets/dismiss_keyboard.dart';

void main() {
  testWidgets('tapping outside a text field dismisses the keyboard', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: DismissKeyboard(
          child: Scaffold(
            body: Column(
              children: [
                TextField(),
                Text('点击这里收起键盘'),
              ],
            ),
          ),
        ),
      ),
    );

    final field = find.byType(TextField);
    await tester.tap(field);
    await tester.pump();
    expect(tester.binding.focusManager.primaryFocus, isNotNull);

    await tester.tap(find.text('点击这里收起键盘'));
    await tester.pump();
    expect(
      tester.binding.focusManager.primaryFocus,
      isNot(isA<EditableTextState>()),
    );
  });
}