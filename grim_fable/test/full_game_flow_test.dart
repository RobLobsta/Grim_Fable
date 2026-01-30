import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:grim_fable/main.dart';
import 'package:grim_fable/features/character/character_provider.dart';
import 'package:grim_fable/features/adventure/adventure_provider.dart';
import 'package:grim_fable/features/adventure/adventure_screen.dart';
import 'package:grim_fable/core/services/ai_provider.dart';
import 'package:grim_fable/core/services/ai_service.dart';
import 'package:grim_fable/core/services/settings_service.dart';
import 'package:mockito/mockito.dart';
import 'mocks.mocks.dart';

void main() {
  testWidgets('Full Game Flow: Create, Play, Complete', (WidgetTester tester) async {
    final mockCharacterRepo = MockCharacterRepository();
    final mockAdventureRepo = MockAdventureRepository();
    final mockSettingsService = MockSettingsService();
    final mockAiService = MockAIService();

    when(mockAiService.validateIdentity(any, any)).thenAnswer((_) async => ValidationResult.valid());
    when(mockAiService.generateBackstory(any, any, description: anyNamed('description')))
        .thenAnswer((_) async => "Sir Test was born in a storm. [ITEM_GAINED: Rusty Sword]");
    when(mockAiService.verifyItems(any, any)).thenAnswer((_) async => {'Rusty Sword': 'A rusted old blade.'});
    when(mockAiService.generateAdventureTitleAndGoal(any, any, any)).thenAnswer((_) async => (title: 'A New Journey', mainGoal: 'Find the light.'));
    when(mockAiService.generateAdventureSuggestions(any, any, any)).thenAnswer((_) async => ["Investigate the strange lights.", "Seek out the hermit.", "Defend the village.", "Follow the trail."]);
    when(mockAiService.generateResponse(any,
            systemMessage: anyNamed('systemMessage'),
            history: anyNamed('history'),
            temperature: anyNamed('temperature'),
            maxTokens: anyNamed('maxTokens'),
            topP: anyNamed('topP'),
            frequencyPenalty: anyNamed('frequencyPenalty')))
        .thenAnswer((invocation) async {
      final systemMessage = invocation.namedArguments[#systemMessage] as String?;
      if (systemMessage != null && systemMessage.contains('Respond ONLY with the choices')) {
        return "Choice 1: Go North | Choice 2: Go South | Choice 3: Go East";
      }
      return "The mist swirls around your feet.";
    });
    when(mockAiService.generateBackstoryAppend(any, any, any)).thenAnswer((_) async => "New backstory.");
    when(mockAiService.generateOccupationEvolution(any, any)).thenAnswer((_) async => "Paladin");

    when(mockSettingsService.getUiPreset()).thenReturn('Default');
    when(mockSettingsService.getHfApiKey()).thenReturn('fake-key');
    when(mockSettingsService.getTemperature()).thenReturn(0.8);
    when(mockSettingsService.getMaxTokens()).thenReturn(150);
    when(mockSettingsService.getTopP()).thenReturn(0.9);
    when(mockSettingsService.getFrequencyPenalty()).thenReturn(0.0);
    when(mockSettingsService.getRecommendedResponsesEnabled()).thenReturn(true);
    when(mockSettingsService.getFreeFormInputEnabled()).thenReturn(true);

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
          settingsServiceProvider.overrideWithValue(mockSettingsService),
          aiServiceProvider.overrideWithValue(mockAiService),
        ],
        child: const GrimFableApp(),
      ),
    );

    await tester.pump();

    // 1. Start Journey (Create Character)
    expect(find.text('ADVENTURE MODE'), findsOneWidget);
    await tester.tap(find.text('ADVENTURE MODE'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    expect(find.text('FORGE FIRST CHARACTER'), findsOneWidget);
    await tester.tap(find.text('FORGE FIRST CHARACTER'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    expect(find.text('FORGE CHARACTER'), findsOneWidget);
    await tester.enterText(find.byType(TextFormField).at(0), 'Sir Test');
    await tester.enterText(find.byType(TextFormField).at(1), 'Knight');

    // Need to generate backstory now as it's required
    await tester.tap(find.text('AI DIVINATION'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 3));

    // Close backstory dialog
    expect(find.text('THY DESTINY REVEALED'), findsOneWidget);
    await tester.tap(find.text('ACCEPT'));
    await tester.pumpAndSettle();

    final forgeButton = find.widgetWithText(ElevatedButton, 'FORGE CHARACTER');
    await tester.ensureVisible(forgeButton);
    await tester.tap(forgeButton);
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    // Should be back on Home Screen with character
    await tester.pump(const Duration(seconds: 2));
    expect(find.textContaining('SIR TEST'), findsOneWidget);

    // 2. Start New Adventure
    await tester.ensureVisible(find.text('NEW ADVENTURE'));
    await tester.tap(find.text('NEW ADVENTURE'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    // Should be on New Adventure Screen (suggestions)
    expect(find.text('DIVINE DESTINY'), findsOneWidget);
    await tester.pump(const Duration(seconds: 3)); // Wait for suggestions

    // Tap a suggestion
    await tester.tap(find.textContaining('Investigate').first);
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    // It calls AI service for first prompt and typewriter
    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle();

    // Should be on Adventure Screen
    expect(find.byType(AdventureScreen), findsOneWidget);
    expect(find.byType(MarkdownBody), findsAtLeastNWidgets(1));
    expect(find.text('WHAT IS THY WILL?'), findsOneWidget);

    // 3. Play a turn and trigger auto-finalization
    when(mockAiService.generateResponse(any,
            systemMessage: anyNamed('systemMessage'),
            history: anyNamed('history'),
            temperature: anyNamed('temperature'),
            maxTokens: anyNamed('maxTokens'),
            topP: anyNamed('topP'),
            frequencyPenalty: anyNamed('frequencyPenalty')))
        .thenAnswer((invocation) async {
      final systemMessage = invocation.namedArguments[#systemMessage] as String?;
      if (systemMessage != null && systemMessage.contains('choices')) {
        return "Choice 1: Go North | Choice 2: Go South | Choice 3: Go East";
      }
      final prompt = invocation.positionalArguments[0] as String;
      if (prompt.contains('search')) {
        return "You find the light. [ADVENTURE_COMPLETE]";
      }
      return "The mist swirls around your feet.";
    });

    final textField1 = find.byType(TextField).hitTestable();
    await tester.enterText(textField1, 'I search the room.');
    await tester.tap(find.byIcon(Icons.send_rounded));
    await tester.pump();
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle(); // Wait for AI and typewriter
    await tester.pump(const Duration(seconds: 10)); // Auto-finalization call (backstory update calls AI)
    await tester.pumpAndSettle();


    expect(find.text('RETURN TO HOME'), findsOneWidget);
    await tester.tap(find.text('RETURN TO HOME'));
    await tester.pumpAndSettle();
    await tester.pump(const Duration(seconds: 2));

    // Should be back on Home Screen
    expect(find.textContaining('SIR TEST'), findsAtLeastNWidgets(1));

    // Check if chronicles list has the adventure
    await tester.ensureVisible(find.text('VIEW CHRONICLES'));
    await tester.tap(find.text('VIEW CHRONICLES'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('A New Journey'), findsOneWidget);
    expect(find.text('Completed'), findsOneWidget);
  });
}
