import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:smartresto/features/menu/domain/menu_item.dart';
import 'package:smartresto/features/menu/presentation/menu_controller.dart';
import 'package:smartresto/main.dart';

void main() {
  testWidgets('SmartResto shell renders', (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          menuProvider.overrideWith((ref) async => const <MenuItem>[]),
        ],
        child: const SmartRestoApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('SmartResto'), findsOneWidget);
    expect(find.text('Ask the AI waiter'), findsOneWidget);
  });
}
