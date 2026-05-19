import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:siren/main.dart';

void main() {
  testWidgets('SirenApp smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: SirenApp()));
    expect(find.byType(SirenApp), findsOneWidget);
  });
}
