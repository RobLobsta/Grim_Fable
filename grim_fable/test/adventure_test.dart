import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:grim_fable/features/adventure/adventure_screen.dart';
import 'package:grim_fable/features/adventure/adventure_provider.dart';
import 'package:grim_fable/features/adventure/adventure_repository.dart';
import 'package:grim_fable/features/character/character_provider.dart';
import 'package:grim_fable/core/models/character.dart';
import 'package:grim_fable/core/models/adventure.dart';
import 'package:grim_fable/core/services/ai_provider.dart';
import 'package:grim_fable/core/services/fake_ai_service.dart';
import 'package:mockito/mockito.dart';
import 'mocks.mocks.dart';

void main() {
  testWidgets('Adventure Screen Flow Test', (WidgetTester tester) async {
    final mockCharacterRepo = MockCharacterRepository();
    final mockAdventureRepo = MockAdventureRepository();
    final character = Character.create(name: 'Test Hero', backstory: 'A brave soul.');
    final adventure = Adventure.create(characterId: character.id);

    // Add initial segment
    final initialAdventure = adventure.copyWith(
      storyHistory: [
        StorySegment(
          playerInput: "Starting...",
          aiResponse: "Welcome to the dark woods.",
          timestamp: DateTime.now(),
        )
      ]
    );

    when(mockCharacterRepo.getAllCharacters()).thenReturn([character]);
    when(mockAdventureRepo.getLatestAdventure(character.id)).thenReturn(initialAdventure);
    when(mockAdventureRepo.saveAdventure(any)).thenAnswer((_) async {});

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          characterRepositoryProvider.overrideWithValue(mockCharacterRepo),
          adventureRepositoryProvider.overrideWithValue(mockAdventureRepo),
          aiServiceProvider.overrideWithValue(FakeAIService()),
        ],
        child: const MaterialApp(
          home: AdventureScreen(),
        ),
      ),
    );

    // Initial state might be null if provider hasn't loaded
    // Need to trigger the loading in the provider if necessary,
    // but here we are overriding repositories.

    // Actually, AdventureNotifier starts with null. We need to call continueLatestAdventure.
    final container = ProviderScope.containerOf(tester.element(find.byType(AdventureScreen)));
    await container.read(activeAdventureProvider.notifier).continueLatestAdventure();
    await tester.pump();

    expect(find.text('Welcome to the dark woods.'), findsOneWidget);

    // Submit an action
    await tester.enterText(find.byType(TextField), 'I look around.');
    await tester.tap(find.byIcon(Icons.send));
    await tester.pump(); // Start loading

    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    await tester.pump(const Duration(seconds: 3)); // Wait for MockAIService
    await tester.pumpAndSettle();

    expect(find.text('> I look around.'), findsOneWidget);
    expect(find.textContaining('mist swirls'), findsOneWidget);

    // Test Complete Adventure
    await tester.tap(find.byIcon(Icons.done_all));
    await tester.pumpAndSettle();

    expect(find.text('Complete Adventure'), findsOneWidget);
    await tester.tap(find.text('Complete'));
    await tester.pump(); // Start completing

    await tester.pump(const Duration(seconds: 3)); // Wait for AI
    await tester.pumpAndSettle();

    // Should have popped back to home (but since we are only testing the screen in isolation in this test,
    // we just check if it called the right methods)
    verify(mockCharacterRepo.saveCharacter(any)).called(2);
  });
}
