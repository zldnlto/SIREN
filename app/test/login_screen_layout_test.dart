import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:siren/screens/login_screen.dart';

void main() {
  testWidgets('LoginScreen has no layout overflow on phone size', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(home: LoginScreen()),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(tester.takeException(), isNull);
  });

  testWidgets('keypad digit appends to active employee ID field', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(home: LoginScreen()),
      ),
    );
    await tester.pump();

    // 모바일 dev 프리필(6자리)이면 숫자 추가가 막히므로 먼저 지움
    await tester.tap(find.text('지우기'));
    await tester.pump();
    await tester.tap(find.text('1'));
    await tester.pump();

    final field = find.byType(TextFormField).first;
    final editable = tester.widget<TextFormField>(field);
    expect(editable.controller?.text, '1');
  });
}
