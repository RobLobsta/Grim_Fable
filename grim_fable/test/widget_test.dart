import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:grim_fable/main.dart';

void main() {
  testWidgets('Welcome screen smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(
      const ProviderScope(
        child: GrimFableApp(),
      ),
    );

    // Verify that our welcome message is displayed.
    expect(find.text('Welcome to Grim Fable'), findsOneWidget);
    expect(find.text('Your dark adventure awaits...'), findsOneWidget);
    expect(find.text('Begin Journey'), findsOneWidget);
  });
}
