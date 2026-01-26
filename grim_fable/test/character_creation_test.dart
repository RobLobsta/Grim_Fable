import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:grim_fable/features/character/character_creation_screen.dart';
import 'package:grim_fable/core/services/ai_provider.dart';
import 'package:grim_fable/core/services/fake_ai_service.dart';

void main() {
  testWidgets('Character Creation Screen Test', (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          aiServiceProvider.overrideWithValue(FakeAIService()),
        ],
        child: const MaterialApp(
          home: CharacterCreationScreen(),
        ),
      ),
    );

    expect(find.text('Create Character'), findsOneWidget);
    expect(find.text('Character Name'), findsOneWidget);

    // Enter name
    await tester.enterText(find.byType(TextFormField).first, 'Test Hero');

    // Tap AI Generate
    await tester.tap(find.text('AI Generate'));
    await tester.pump(); // Start generating

    // Since MockAIService has a 2-second delay, we need to pump with duration
    await tester.pump(const Duration(seconds: 3));

    // Verify backstory is filled
    final backstoryField = find.byType(TextFormField).last;
    final TextFormField widget = tester.widget(backstoryField);
    expect(widget.controller?.text, contains('Test Hero'));
  });
}
