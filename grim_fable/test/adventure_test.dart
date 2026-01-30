import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:grim_fable/features/adventure/adventure_screen.dart';
import 'package:grim_fable/features/adventure/adventure_provider.dart';
import 'package:grim_fable/shared/widgets/player_action_widget.dart';
import 'package:grim_fable/features/character/character_provider.dart';
import 'package:grim_fable/core/models/character.dart';
import 'package:grim_fable/core/models/adventure.dart';
import 'package:grim_fable/core/services/ai_provider.dart';
import 'package:grim_fable/core/services/settings_service.dart';
import 'package:mockito/mockito.dart';
import 'mocks.mocks.dart';

void main() {
  testWidgets('Adventure Screen Flow Test', (WidgetTester tester) async {
    final mockCharacterRepo = MockCharacterRepository();
    final mockAdventureRepo = MockAdventureRepository();
    final mockSettingsService = MockSettingsService();
    final mockAiService = MockAIService();

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
    when(mockAiService.generateOccupationEvolution(any, any)).thenAnswer((_) async => "Test Hero");

    when(mockSettingsService.getUiPreset()).thenReturn('Default');
    when(mockSettingsService.getRecommendedResponsesEnabled()).thenReturn(true);
    when(mockSettingsService.getHfApiKey()).thenReturn('fake-key');
    when(mockSettingsService.getTemperature()).thenReturn(0.8);
    when(mockSettingsService.getMaxTokens()).thenReturn(150);
    when(mockSettingsService.getTopP()).thenReturn(0.9);
    when(mockSettingsService.getFrequencyPenalty()).thenReturn(0.0);
    when(mockSettingsService.getFreeFormInputEnabled()).thenReturn(true);

    final character = Character.create(name: 'Test Hero', backstory: 'A brave soul.');
    final adventure = Adventure.create(characterId: character.id);

    // Add initial segment
    final initialAdventure = adventure.copyWith(
      storyHistory: [
        StorySegment(
          playerInput: "Starting...",
          aiResponse: "Welcome to the dark woods.",
          timestamp: DateTime.now(),
          recommendedChoices: ["Go North", "Go South", "Go East"],
        )
      ]
    );

    when(mockCharacterRepo.getAllCharacters()).thenReturn([character]);
    when(mockAdventureRepo.getLatestAdventure(character.id)).thenReturn(initialAdventure);
    when(mockAdventureRepo.saveAdventure(any)).thenAnswer((_) async {});

    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => const Scaffold(body: Text('Home')),
        ),
        GoRoute(
          path: '/adventure',
          builder: (context, state) => const AdventureScreen(),
        ),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          characterRepositoryProvider.overrideWithValue(mockCharacterRepo),
          adventureRepositoryProvider.overrideWithValue(mockAdventureRepo),
          settingsServiceProvider.overrideWithValue(mockSettingsService),
          aiServiceProvider.overrideWithValue(mockAiService),
        ],
        child: MaterialApp.router(
          routerConfig: router,
        ),
      ),
    );

    router.push('/adventure');
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    // Initial state might be null if provider hasn't loaded
    // Need to trigger the loading in the provider if necessary,
    // but here we are overriding repositories.

    // Actually, AdventureNotifier starts with null. We need to call continueLatestAdventure.
    final container = ProviderScope.containerOf(tester.element(find.byType(AdventureScreen)));
    await container.read(activeAdventureProvider.notifier).continueLatestAdventure();
    await tester.pump();

    // Need to pump enough to finish typewriter
    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle();
    expect(find.byType(MarkdownBody), findsAtLeastNWidgets(1));

    // Actually MarkdownBody.data contains the text
    expect(find.byWidgetPredicate((w) => w is MarkdownBody && w.data.contains('Welcome to the dark woods.')), findsOneWidget);

    // Submit an action
    await tester.enterText(find.byType(TextField).first, 'I look around.');
    await tester.tap(find.byIcon(Icons.send_rounded));
    await tester.pump(); // Start loading

    // Wait for AI service
    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle(); // Wait for typewriter and choices
    await tester.pump();

    expect(find.byType(PlayerActionWidget), findsAtLeastNWidgets(1));
    expect(find.byWidgetPredicate((w) => w is MarkdownBody && w.data.contains('mist swirls')), findsOneWidget);

    // Test Auto-finalization
    when(mockAiService.generateResponse(argThat(contains('Final action.')),
            systemMessage: anyNamed('systemMessage'),
            history: anyNamed('history'),
            temperature: anyNamed('temperature'),
            maxTokens: anyNamed('maxTokens'),
            topP: anyNamed('topP'),
            frequencyPenalty: anyNamed('frequencyPenalty')))
        .thenAnswer((_) async => "You have achieved your goal. [ADVENTURE_COMPLETE]");

    await tester.enterText(find.byType(TextField), 'Final action.');
    await tester.tap(find.byIcon(Icons.send_rounded));
    await tester.pump();
    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle(); // Wait for AI and typewriter
    await tester.pump(const Duration(seconds: 2)); // Auto-finalization call
    await tester.pumpAndSettle();

    // verify completion happened (saveCharacter called during completeAdventure)
    verify(mockCharacterRepo.saveCharacter(any)).called(greaterThan(1));
  });
}
