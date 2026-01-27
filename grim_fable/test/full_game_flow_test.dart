import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:grim_fable/main.dart';
import 'package:grim_fable/features/character/character_repository.dart';
import 'package:grim_fable/features/character/character_provider.dart';
import 'package:grim_fable/features/adventure/adventure_repository.dart';
import 'package:grim_fable/features/adventure/adventure_provider.dart';
import 'package:grim_fable/core/services/ai_provider.dart';
import 'package:grim_fable/core/services/fake_ai_service.dart';
import 'package:mockito/mockito.dart';
import 'mocks.mocks.dart';

void main() {
  testWidgets('Full Game Flow: Create, Play, Complete', (WidgetTester tester) async {
    final mockCharacterRepo = MockCharacterRepository();
    final mockAdventureRepo = MockAdventureRepository();

    // We'll use a real-ish but mocked state
    final characters = <dynamic>[];
    final adventures = <dynamic>[];

    when(mockCharacterRepo.init()).thenAnswer((_) async {});
    when(mockCharacterRepo.getAllCharacters()).thenAnswer((_) => characters.cast());
    when(mockCharacterRepo.saveCharacter(any)).thenAnswer((invocation) async {
      final char = invocation.positionalArguments[0];
      characters.removeWhere((c) => c.id == char.id);
      characters.add(char);
    });

    when(mockAdventureRepo.init()).thenAnswer((_) async {});
    when(mockAdventureRepo.getAdventuresForCharacter(any)).thenAnswer((invocation) {
      final charId = invocation.positionalArguments[0];
      return adventures.where((a) => a.characterId == charId).toList().cast();
    });
    when(mockAdventureRepo.getLatestAdventure(any)).thenAnswer((invocation) {
      final charId = invocation.positionalArguments[0];
      final charAdventures = adventures.where((a) => a.characterId == charId && a.isActive).toList();
      if (charAdventures.isEmpty) return null;
      return charAdventures.last;
    });
    when(mockAdventureRepo.saveAdventure(any)).thenAnswer((invocation) async {
      final adv = invocation.positionalArguments[0];
      adventures.removeWhere((a) => a.id == adv.id);
      adventures.add(adv);
    });

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          characterRepositoryProvider.overrideWithValue(mockCharacterRepo),
          adventureRepositoryProvider.overrideWithValue(mockAdventureRepo),
          aiServiceProvider.overrideWithValue(FakeAIService()),
        ],
        child: const GrimFableApp(),
      ),
    );

    await tester.pumpAndSettle();

    // 1. Start Journey (Create Character)
    expect(find.text('BEGIN JOURNEY'), findsOneWidget);
    await tester.tap(find.text('BEGIN JOURNEY'));
    await tester.pumpAndSettle();

    expect(find.text('FORGE CHARACTER'), findsOneWidget);
    await tester.enterText(find.byType(TextFormField).first, 'Sir Test');
    await tester.ensureVisible(find.text('FORGE LEGEND'));
    await tester.tap(find.text('FORGE LEGEND'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();

    // Should be back on Home Screen with character
    expect(find.text('SIR TEST'), findsOneWidget);

    // 2. Start New Adventure
    await tester.ensureVisible(find.text('NEW ADVENTURE'));
    await tester.tap(find.text('NEW ADVENTURE'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    // It calls AI service for first prompt which takes ~2s in FakeAIService
    await tester.pump(const Duration(seconds: 5));
    // After AI finishes, loading screen should be gone and navigation complete
    await tester.pumpAndSettle();

    // Should be on Adventure Screen
    expect(find.byIcon(Icons.done_all), findsOneWidget);
    expect(find.text('WHAT IS THY WILL?'), findsOneWidget);

    // 3. Play a turn
    await tester.enterText(find.byType(TextField), 'I search the room.');
    await tester.tap(find.byIcon(Icons.send_rounded));
    await tester.pump();
    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();

    expect(find.text('I SEARCH THE ROOM.'), findsOneWidget);

    // 4. Complete Adventure
    await tester.tap(find.byIcon(Icons.done_all));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Complete'));
    await tester.tap(find.text('Complete'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 3)); // Backstory update
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();

    // Should be back on Home Screen
    expect(find.text('SIR TEST'), findsOneWidget);

    // Check if chronicles list has the adventure
    await tester.ensureVisible(find.text('VIEW CHRONICLES'));
    await tester.tap(find.text('VIEW CHRONICLES'));
    await tester.pumpAndSettle();
    expect(find.text('New Adventure'), findsOneWidget);
    expect(find.text('Completed'), findsOneWidget);
  });
}
