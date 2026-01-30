import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'adventure_repository.dart';
import '../../core/models/adventure.dart';
import '../../core/models/character.dart';
import '../character/character_provider.dart';
import '../../core/services/ai_provider.dart';
import '../../core/services/ai_service.dart';
import '../../core/services/settings_service.dart';
import '../../core/utils/tag_processor.dart';
import '../../core/utils/extensions.dart';

final adventureRepositoryProvider = Provider((ref) => AdventureRepository());

final characterAdventuresProvider = Provider.autoDispose<List<Adventure>>((ref) {
  final repository = ref.watch(adventureRepositoryProvider);
  final character = ref.watch(activeCharacterProvider);
  if (character == null) return [];
  return repository.getAdventuresForCharacter(character.id);
});

final hasActiveAdventureProvider = Provider.autoDispose<bool>((ref) {
  // Watch active adventure to react to state changes in the notifier
  final activeAdv = ref.watch(activeAdventureProvider);
  if (activeAdv != null) {
    return activeAdv.isActive;
  }

  // Fallback to checking the repository for the active character
  final repository = ref.watch(adventureRepositoryProvider);
  final charId = ref.watch(activeCharacterProvider.select((c) => c?.id));
  if (charId == null) return false;

  final latest = repository.getLatestAdventure(charId);
  return latest != null && latest.isActive;
});

final activeAdventureProvider = StateNotifierProvider<AdventureNotifier, Adventure?>((ref) {
  final repository = ref.watch(adventureRepositoryProvider);
  final aiService = ref.watch(aiServiceProvider);
  // Watch only the character ID to prevent provider recreation when character's lastPlayedAt updates
  ref.watch(activeCharacterProvider.select((c) => c?.id));
  final activeCharacter = ref.read(activeCharacterProvider);
  final characterNotifier = ref.read(charactersProvider.notifier);

  return AdventureNotifier(ref, repository, aiService, activeCharacter, characterNotifier);
});

class AdventureNotifier extends StateNotifier<Adventure?> {
  final Ref _ref;
  final AdventureRepository _repository;
  final AIService _aiService;
  final Character? _activeCharacter;
  final CharacterNotifier _characterNotifier;

  AdventureNotifier(
    this._ref,
    this._repository,
    this._aiService,
    this._activeCharacter,
    this._characterNotifier,
  ) : super(null);

  Future<void> startNewAdventure({String? customPrompt}) async {
    final activeChar = _activeCharacter;
    if (activeChar == null) return;

    // Generate first story segment
    final story = await _generateFirstStory(customPrompt: customPrompt);

    // Generate thematic title and secret main goal separately
    final titleAndGoal = await _aiService.generateAdventureTitleAndGoal(
      activeChar.name,
      activeChar.backstory,
      story,
    );

    final adventure = Adventure.create(
      characterId: activeChar.id,
      title: titleAndGoal.title,
      mainGoal: titleAndGoal.mainGoal,
    );
    state = adventure;

    final firstSegment = StorySegment(
      playerInput: customPrompt ?? "Starting the journey...",
      aiResponse: story,
      recommendedChoices: null,
      timestamp: DateTime.now(),
    );

    final updatedAdventure = adventure.copyWith(
      storyHistory: [firstSegment],
    );

    await _saveAdventure(updatedAdventure);

    // If recommended actions enabled, get them in second call
    if (_ref.read(recommendedResponsesProvider)) {
      final choices = await _getChoices(story, []);
      final segmentWithChoices = StorySegment(
        playerInput: firstSegment.playerInput,
        aiResponse: firstSegment.aiResponse,
        recommendedChoices: choices,
        timestamp: firstSegment.timestamp,
      );
      await _saveAdventure(updatedAdventure.copyWith(
        storyHistory: [segmentWithChoices],
      ));
    }

    // Update last played time on character
    await _characterNotifier.updateCharacter(
      activeChar.copyWith(lastPlayedAt: DateTime.now()),
    );
  }

  Future<void> continueLatestAdventure() async {
    if (_activeCharacter == null) return;

    final latest = _repository.getLatestAdventure(_activeCharacter.id);
    if (latest != null) {
      state = latest;
    } else {
      await startNewAdventure();
    }
  }

  void loadAdventure(Adventure adventure) {
    state = adventure;
  }

  Future<void> submitAction(String action) async {
    final activeCharacter = _ref.read(activeCharacterProvider);
    if (state == null || activeCharacter == null) return;

    final inventoryList = activeCharacter.inventory.isEmpty ? "None" : activeCharacter.inventory.join(", ");
    final maxTokens = _ref.read(maxTokensProvider);
    final targetTokens = (maxTokens * 0.8).toInt();
    final turnCount = state!.storyHistory.length + 1;
    final nudge = (turnCount % 5 == 0)
        ? "\n\nGently nudge the story toward the main goal: ${state!.mainGoal}. The character might ponder their situation or notice something relevant to this goal."
        : "";

    final systemMessage = """
You are a creative storyteller for Grim Fable. Always write in the third person.
Character: ${activeCharacter.name}
Occupation: ${activeCharacter.occupation}
Backstory: ${activeCharacter.backstory}
Inventory: $inventoryList
Gold: ${activeCharacter.gold}

Keep your responses short, exactly 1 paragraph (3-5 sentences).
The maximum length for your response is $maxTokens tokens. To avoid being cut off mid-sentence, aim for a length of about $targetTokens tokens.
Maintain a dark fantasy, gritty, and realistic tone.
Use third person exclusively (e.g., "${activeCharacter.name} enters the room" NOT "I enter the room").

You can grant or remove items or gold from the player using these tags at the end of your response:
[ITEM_GAINED: Item Name]
[ITEM_REMOVED: Item Name]
[GOLD_GAINED: Number]
[GOLD_REMOVED: Number]
Do not constantly remind the player of their inventory or gold.
If the main goal (${state!.mainGoal}) has been clearly and successfully achieved, add the tag [ADVENTURE_COMPLETE] at the end of your response.
$nudge
""";

    final history = state!.storyHistory.takeLast(5).expand((s) => [
      {'role': 'user', 'content': s.playerInput},
      {'role': 'assistant', 'content': s.aiResponse},
    ]).toList();

    final temperature = _ref.read(temperatureProvider);
    final topP = _ref.read(topPProvider);
    final frequencyPenalty = _ref.read(frequencyPenaltyProvider);
    final recommendedEnabled = _ref.read(recommendedResponsesProvider);

    final fullResponse = await _aiService.generateResponse(
      action,
      systemMessage: systemMessage,
      history: history,
      temperature: temperature,
      maxTokens: maxTokens,
      topP: topP,
      frequencyPenalty: frequencyPenalty,
    );

    final parsed = _parseResponse(fullResponse);
    final processed = await _processInventoryTags(parsed.text);

    final newSegment = StorySegment(
      playerInput: action,
      aiResponse: processed,
      recommendedChoices: parsed.choices, // Might still parse if AI misbehaves and adds them
      timestamp: DateTime.now(),
    );

    final updatedAdventure = state!.copyWith(
      storyHistory: [...state!.storyHistory, newSegment],
      lastPlayedAt: DateTime.now(),
    );

    await _saveAdventure(updatedAdventure);

    // Check for auto-finalization
    if (await _checkCompletion(fullResponse)) {
      await completeAdventure();
      return;
    }

    if (recommendedEnabled && (newSegment.recommendedChoices == null || newSegment.recommendedChoices!.isEmpty)) {
      final choices = await _getChoices(parsed.text, history);
      final segmentWithChoices = StorySegment(
        playerInput: newSegment.playerInput,
        aiResponse: newSegment.aiResponse,
        recommendedChoices: choices,
        timestamp: newSegment.timestamp,
      );
      final finalHistory = [...state!.storyHistory];
      finalHistory[finalHistory.length - 1] = segmentWithChoices;
      await _saveAdventure(state!.copyWith(
        storyHistory: finalHistory,
      ));
    }

    // Update last played time on character
    final activeChar = _ref.read(activeCharacterProvider);
    if (activeChar != null) {
      await _characterNotifier.updateCharacter(
        activeChar.copyWith(lastPlayedAt: DateTime.now()),
      );
    }
  }

  Future<void> continueAdventure() async {
    final activeCharacter = _ref.read(activeCharacterProvider);
    if (state == null || activeCharacter == null || state!.storyHistory.isEmpty) return;

    final inventoryList = activeCharacter.inventory.isEmpty ? "None" : activeCharacter.inventory.join(", ");
    final maxTokens = _ref.read(maxTokensProvider);
    final targetTokens = (maxTokens * 0.8).toInt();
    // continueAdventure doesn't increment turn count as it appends to the last segment,
    // but we can still check if we should nudge based on current history length.
    final turnCount = state!.storyHistory.length;
    final nudge = (turnCount > 0 && turnCount % 5 == 0)
        ? "\n\nGently nudge the story toward the main goal: ${state!.mainGoal}. The character might ponder their situation or notice something relevant to this goal."
        : "";

    final systemMessage = """
You are a creative storyteller for Grim Fable. Always write in the third person.
Character: ${activeCharacter.name}
Occupation: ${activeCharacter.occupation}
Backstory: ${activeCharacter.backstory}
Inventory: $inventoryList
Gold: ${activeCharacter.gold}

Continue the story naturally from the last point.
Keep your responses short, exactly 1 paragraph (3-5 sentences).
The maximum length for your response is $maxTokens tokens. To avoid being cut off mid-sentence, aim for a length of about $targetTokens tokens.
Maintain a dark fantasy, gritty, and realistic tone.
Use third person exclusively.

You can grant or remove items or gold from the player using these tags at the end of your response:
[ITEM_GAINED: Item Name]
[ITEM_REMOVED: Item Name]
[GOLD_GAINED: Number]
[GOLD_REMOVED: Number]
Do not constantly remind the player of their inventory or gold.
If the main goal (${state!.mainGoal}) has been clearly and successfully achieved, add the tag [ADVENTURE_COMPLETE] at the end of your response.
$nudge
""";

    final history = state!.storyHistory.takeLast(5).expand((s) => [
      {'role': 'user', 'content': s.playerInput},
      {'role': 'assistant', 'content': s.aiResponse},
    ]).toList();

    final temperature = _ref.read(temperatureProvider);
    final topP = _ref.read(topPProvider);
    final frequencyPenalty = _ref.read(frequencyPenaltyProvider);
    final recommendedEnabled = _ref.read(recommendedResponsesProvider);

    final fullResponse = await _aiService.generateResponse(
      "Continue",
      systemMessage: systemMessage,
      history: history,
      temperature: temperature,
      maxTokens: maxTokens,
      topP: topP,
      frequencyPenalty: frequencyPenalty,
    );

    final parsed = _parseResponse(fullResponse);
    final processed = await _processInventoryTags(parsed.text);

    final lastSegment = state!.storyHistory.last;
    // Use double line break to separate the new response from the previous one
    final updatedSegment = StorySegment(
      playerInput: lastSegment.playerInput,
      aiResponse: "${lastSegment.aiResponse}\n\n$processed",
      recommendedChoices: parsed.choices,
      timestamp: DateTime.now(),
    );

    final updatedHistory = List<StorySegment>.from(state!.storyHistory);
    updatedHistory[updatedHistory.length - 1] = updatedSegment;

    final updatedAdventure = state!.copyWith(
      storyHistory: updatedHistory,
      lastPlayedAt: DateTime.now(),
    );

    await _saveAdventure(updatedAdventure);

    // Check for auto-finalization
    if (await _checkCompletion(fullResponse)) {
      await completeAdventure();
      return;
    }

    if (recommendedEnabled && (updatedSegment.recommendedChoices == null || updatedSegment.recommendedChoices!.isEmpty)) {
      final choices = await _getChoices(parsed.text, history);
      final segmentWithChoices = StorySegment(
        playerInput: updatedSegment.playerInput,
        aiResponse: updatedSegment.aiResponse,
        recommendedChoices: choices,
        timestamp: updatedSegment.timestamp,
      );
      final finalHistory = [...state!.storyHistory];
      finalHistory[finalHistory.length - 1] = segmentWithChoices;
      await _saveAdventure(state!.copyWith(
        storyHistory: finalHistory,
      ));
    }

    // Update last played time on character
    final activeChar = _ref.read(activeCharacterProvider);
    if (activeChar != null) {
      await _characterNotifier.updateCharacter(
        activeChar.copyWith(lastPlayedAt: DateTime.now()),
      );
    }
  }

  Future<void> completeAdventure() async {
    final activeChar = _ref.read(activeCharacterProvider);
    if (state == null || activeChar == null) return;

    final summary = state!.storyHistory.map((s) => s.aiResponse).join(" ");

    // 2-3 short sentences, scaled by length
    int aiResponseCount = state!.storyHistory.length;
    int sentences = (aiResponseCount / 10).ceil().clamp(2, 6);

    final backstoryAppend = await _aiService.generateBackstoryAppend(
      activeChar.backstory,
      summary,
      sentences,
    );

    final newBackstory = "${activeChar.backstory}\n\n$backstoryAppend";

    // Evolve occupation
    final newOccupation = await _aiService.generateOccupationEvolution(
      activeChar.occupation,
      summary,
    );

    await _characterNotifier.updateCharacter(
      activeChar.copyWith(
        backstory: newBackstory,
        occupation: newOccupation,
        lastPlayedAt: DateTime.now(),
      ),
    );

    final updatedAdventure = state!.copyWith(isActive: false);
    await _saveAdventure(updatedAdventure);
  }

  Future<bool> _checkCompletion(String response) async {
    if (response.contains("[ADVENTURE_COMPLETE]")) return true;

    // Intelligent parsing for common completion indicators
    final lower = response.toLowerCase();
    final completionTerms = [
      'the adventure ends',
      'journey is complete',
      'mission accomplished',
      'finally at rest',
      'goal has been met',
      'quest is over',
      'his journey concluded',
      'her journey concluded',
      'their journey concluded',
    ];
    bool suspected = completionTerms.any((term) => lower.contains(term));

    if (suspected) {
      // Ask AI for clarification if ambiguous
      const systemMessage = "You are a precise validator for Grim Fable. Determine if the story segment indicates the successful completion of the character's main goal.";
      final prompt = """
Main Goal: ${state!.mainGoal}
Story Segment: $response

Based on the story segment, has the character successfully achieved their main goal?
Return ONLY 'YES' or 'NO'.
""";
      try {
        final clarification = await _aiService.generateResponse(prompt, systemMessage: systemMessage, maxTokens: 10, temperature: 0.0);
        return clarification.trim().toUpperCase().contains('YES');
      } catch (_) {
        return false;
      }
    }

    return false;
  }

  Future<void> _saveAdventure(Adventure adventure) async {
    await _repository.saveAdventure(adventure);
    state = adventure;
  }

  Future<String> _processInventoryTags(String response) async {
    final activeCharacter = _ref.read(activeCharacterProvider);
    if (activeCharacter == null) return response;

    return TagProcessor.processInventoryTags(
      response: response,
      character: activeCharacter,
      characterNotifier: _characterNotifier,
      aiService: _aiService,
    );
  }

  Future<String> _generateFirstStory({String? customPrompt}) async {
    final activeCharacter = _ref.read(activeCharacterProvider);
    if (activeCharacter == null) return "";

    final inventoryList = activeCharacter.inventory.isEmpty ? "None" : activeCharacter.inventory.join(", ");
    const int maxTokens = 500;
    const int targetTokens = 400;

    final systemMessage = """
You are a creative storyteller for a dark fantasy adventure called Grim Fable. Always write in the third person.
Character: ${activeCharacter.name}
Occupation: ${activeCharacter.occupation}
Backstory: ${activeCharacter.backstory}
Inventory: $inventoryList
Gold: ${activeCharacter.gold}

Your response must be the first story segment of exactly 1 paragraph (3-5 sentences).
The maximum length for your response is $maxTokens tokens. To avoid being cut off mid-sentence, aim for a length of about $targetTokens tokens.
Maintain a gritty and realistic dark fantasy tone.
Use third person exclusively.

You can grant or remove items or gold from the player using these tags at the end of your story:
[ITEM_GAINED: Item Name]
[ITEM_REMOVED: Item Name]
[GOLD_GAINED: Number]
[GOLD_REMOVED: Number]

Return ONLY the starting paragraph followed by any tags.
""";

    final prompt = customPrompt ?? "Set the scene for a new adventure. Describe the location and the immediate situation.";

    final temperature = _ref.read(temperatureProvider);
    final topP = _ref.read(topPProvider);
    final frequencyPenalty = _ref.read(frequencyPenaltyProvider);

    final response = await _aiService.generateResponse(
      prompt,
      systemMessage: systemMessage,
      temperature: temperature,
      maxTokens: maxTokens,
      topP: topP,
      frequencyPenalty: frequencyPenalty,
    );

    return await _processInventoryTags(response.trim());
  }

  Future<List<String>> _getChoices(String storyResponse, List<Map<String, String>> history) async {
    final temperature = _ref.read(temperatureProvider);
    final topP = _ref.read(topPProvider);
    final frequencyPenalty = _ref.read(frequencyPenaltyProvider);
    final prompt = "stop the story and recommend exactly 3 VERY short (max 8 words each), plausible choices for ${_activeCharacter?.name ?? 'the character'}. Don't reference these choices later.";

    // Include the immediate story response in the history
    final updatedHistory = [
      ...history,
      {'role': 'assistant', 'content': storyResponse},
    ];

    final response = await _aiService.generateResponse(
      prompt,
      systemMessage: "You are a creative storyteller for Grim Fable. Always write in the third person. Respond ONLY with the choices formatted as: Choice 1 | Choice 2 | Choice 3",
      history: updatedHistory,
      temperature: temperature,
      maxTokens: 100,
      topP: topP,
      frequencyPenalty: frequencyPenalty,
    );

    return _cleanChoices(response);
  }

  List<String> _cleanChoices(String response) {
    // Remove introductory text like "Here are your choices:"
    // Use non-greedy match to avoid stripping choices that contain colons
    String cleaned = response.replaceFirst(RegExp(r'^.*?:', caseSensitive: false), '');

    // Matches labels like: "Choice 1:", "1.", "1)", "A.", "A)", "- ", "* ", "• "
    final labelPattern = RegExp(
      r'^(?:Choice\s*\d+:?\s*|[a-z0-9][\.\)]\s*|[-*•]\s*)',
      caseSensitive: false,
    );

    // Matches trailing numbers like: " (1)", " [1]", " 1"
    final trailingPattern = RegExp(r'\s*[\(\[]?\s*\d+\s*[\)\]]?$');

    return cleaned.split(RegExp(r'[|\n]'))
        .map((e) => e.trim())
        .map((e) => e.replaceFirst(labelPattern, ''))
        .map((e) => e.replaceFirst(trailingPattern, ''))
        .map((e) => e.trim())
        // Filter out empty choices, choices that are just numbers, or choices that are too short
        .where((e) => e.isNotEmpty && !RegExp(r'^\d+$').hasMatch(e) && e.length > 3)
        .toList();
  }

  _ParsedResponse _parseResponse(String response) {
    if (response.contains("[CHOICES]")) {
      final parts = response.split("[CHOICES]");
      final text = parts[0].trim();
      final choicesPart = parts[1].trim();
      final choices = _cleanChoices(choicesPart);
      return _ParsedResponse(text, choices);
    }
    return _ParsedResponse(response, null);
  }
}

class _ParsedResponse {
  final String text;
  final List<String>? choices;

  _ParsedResponse(this.text, this.choices);
}
