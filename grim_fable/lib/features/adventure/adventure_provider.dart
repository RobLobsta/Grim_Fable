import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'adventure_repository.dart';
import '../../core/models/adventure.dart';
import '../../core/models/character.dart';
import '../character/character_provider.dart';
import '../../core/services/ai_provider.dart';
import '../../core/services/ai_service.dart';
import '../../core/services/settings_service.dart';
import '../../core/utils/item_parser.dart';

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
  final characterId = ref.watch(activeCharacterProvider.select((c) => c?.id));
  if (characterId == null) return false;

  final latest = repository.getLatestAdventure(characterId);
  return latest != null && latest.isActive;
});

final activeAdventureProvider = StateNotifierProvider<AdventureNotifier, Adventure?>((ref) {
  final repository = ref.watch(adventureRepositoryProvider);
  final aiService = ref.watch(aiServiceProvider);
  // Watch only the character ID to prevent provider recreation when character's lastPlayedAt updates
  final characterId = ref.watch(activeCharacterProvider.select((c) => c?.id));
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
    if (_activeCharacter == null) return;

    // Generate first prompt and title
    final result = await _generateFirstPrompt(customPrompt: customPrompt);

    final adventure = Adventure.create(
      characterId: _activeCharacter!.id,
      title: result.title,
    );
    state = adventure;

    final firstSegment = StorySegment(
      playerInput: customPrompt ?? "Starting the journey...",
      aiResponse: result.story,
      recommendedChoices: null,
      timestamp: DateTime.now(),
    );

    final updatedAdventure = adventure.copyWith(
      storyHistory: [firstSegment],
    );

    await _saveAdventure(updatedAdventure);

    // If recommended actions enabled, get them in second call
    if (_ref.read(recommendedResponsesProvider)) {
      final choices = await _getChoices(result.story, []);
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
    if (_activeCharacter != null) {
      await _characterNotifier.updateCharacter(
        _activeCharacter!.copyWith(lastPlayedAt: DateTime.now()),
      );
    }
  }

  Future<void> continueLatestAdventure() async {
    if (_activeCharacter == null) return;

    final latest = _repository.getLatestAdventure(_activeCharacter!.id);
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

    final systemMessage = """
You are a creative storyteller for Grim Fable. Always write in the third person.
Character: ${activeCharacter.name}
Occupation: ${activeCharacter.occupation}
Backstory: ${activeCharacter.backstory}
Inventory: $inventoryList

Keep your responses short, exactly 1 paragraph (3-5 sentences).
Maintain a dark fantasy, gritty, and realistic tone.
Use third person exclusively (e.g., "${activeCharacter.name} enters the room" NOT "I enter the room").

You can grant or remove items from the player's inventory using these tags at the end of your response:
[ITEM_GAINED: Item Name]
[ITEM_REMOVED: Item Name]
Do not constantly remind the player of their inventory.
""";

    final history = state!.storyHistory.takeLast(5).expand((s) => [
      {'role': 'user', 'content': s.playerInput},
      {'role': 'assistant', 'content': s.aiResponse},
    ]).toList();

    final temperature = _ref.read(temperatureProvider);
    final maxTokens = _ref.read(maxTokensProvider);
    final recommendedEnabled = _ref.read(recommendedResponsesProvider);

    final fullResponse = await _aiService.generateResponse(
      action,
      systemMessage: systemMessage,
      history: history,
      temperature: temperature,
      maxTokens: maxTokens,
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
    if (_activeCharacter != null) {
      await _characterNotifier.updateCharacter(
        _activeCharacter!.copyWith(lastPlayedAt: DateTime.now()),
      );
    }
  }

  Future<void> continueAdventure() async {
    final activeCharacter = _ref.read(activeCharacterProvider);
    if (state == null || activeCharacter == null || state!.storyHistory.isEmpty) return;

    final inventoryList = activeCharacter.inventory.isEmpty ? "None" : activeCharacter.inventory.join(", ");

    final systemMessage = """
You are a creative storyteller for Grim Fable. Always write in the third person.
Character: ${activeCharacter.name}
Occupation: ${activeCharacter.occupation}
Backstory: ${activeCharacter.backstory}
Inventory: $inventoryList

Continue the story naturally from the last point.
Keep your responses short, exactly 1 paragraph (3-5 sentences).
Maintain a dark fantasy, gritty, and realistic tone.
Use third person exclusively.

You can grant or remove items from the player's inventory using these tags at the end of your response:
[ITEM_GAINED: Item Name]
[ITEM_REMOVED: Item Name]
Do not constantly remind the player of their inventory.
""";

    final history = state!.storyHistory.takeLast(5).expand((s) => [
      {'role': 'user', 'content': s.playerInput},
      {'role': 'assistant', 'content': s.aiResponse},
    ]).toList();

    final temperature = _ref.read(temperatureProvider);
    final maxTokens = _ref.read(maxTokensProvider);
    final recommendedEnabled = _ref.read(recommendedResponsesProvider);

    final fullResponse = await _aiService.generateResponse(
      "Continue",
      systemMessage: systemMessage,
      history: history,
      temperature: temperature,
      maxTokens: maxTokens,
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
    if (_activeCharacter != null) {
      await _characterNotifier.updateCharacter(
        _activeCharacter!.copyWith(lastPlayedAt: DateTime.now()),
      );
    }
  }

  Future<void> completeAdventure() async {
    if (state == null || _activeCharacter == null) return;

    final summary = state!.storyHistory.map((s) => s.aiResponse).join(" ");

    // 2-3 short sentences, scaled by length
    int aiResponseCount = state!.storyHistory.length;
    int sentences = (aiResponseCount / 10).ceil().clamp(2, 6);

    final backstoryAppend = await _aiService.generateBackstoryAppend(
      _activeCharacter!.backstory,
      summary,
      sentences,
    );

    final newBackstory = "${_activeCharacter!.backstory}\n\n$backstoryAppend";

    // Evolve occupation
    final newOccupation = await _aiService.generateOccupationEvolution(
      _activeCharacter!.occupation,
      summary,
    );

    await _characterNotifier.updateCharacter(
      _activeCharacter!.copyWith(
        backstory: newBackstory,
        occupation: newOccupation,
        lastPlayedAt: DateTime.now(),
      ),
    );

    final updatedAdventure = state!.copyWith(isActive: false);
    await _saveAdventure(updatedAdventure);
  }

  Future<void> _saveAdventure(Adventure adventure) async {
    await _repository.saveAdventure(adventure);
    state = adventure;
  }

  Future<String> _processInventoryTags(String response) async {
    final activeCharacter = _ref.read(activeCharacterProvider);
    if (activeCharacter == null) return response;

    final gainedItems = ItemParser.parseGainedItems(response);
    final removedItems = ItemParser.parseRemovedItems(response);

    if (gainedItems.isEmpty && removedItems.isEmpty) return response;

    List<String> newInventory = List<String>.from(activeCharacter.inventory);

    for (final item in gainedItems) {
      if (!newInventory.any((i) => i.toLowerCase() == item.toLowerCase())) {
        newInventory.add(item);
      }
    }

    for (final item in removedItems) {
      newInventory.removeWhere((i) => i.toLowerCase() == item.toLowerCase());
    }

    await _characterNotifier.updateCharacter(activeCharacter.copyWith(inventory: newInventory));

    // Strip tags from response
    return ItemParser.cleanText(response);
  }

  Future<({String title, String story})> _generateFirstPrompt({String? customPrompt}) async {
    final activeCharacter = _ref.read(activeCharacterProvider);
    if (activeCharacter == null) return (title: "New Adventure", story: "");

    final inventoryList = activeCharacter.inventory.isEmpty ? "None" : activeCharacter.inventory.join(", ");

    final systemMessage = """
You are a creative storyteller for a dark fantasy adventure called Grim Fable. Always write in the third person.
Character: ${activeCharacter.name}
Occupation: ${activeCharacter.occupation}
Backstory: ${activeCharacter.backstory}
Inventory: $inventoryList

Your response must include a thematic title for this adventure and the first story segment.
The story segment must be exactly 1 paragraph (3-5 sentences).
Maintain a gritty and realistic dark fantasy tone.
Use third person exclusively.

Format your response exactly as follows:
Title: [Thematic Title]
Story: [Starting Paragraph]
""";

    final prompt = customPrompt ?? "Set the scene for a new adventure. Describe the location and the immediate situation.";

    final temperature = _ref.read(temperatureProvider);

    final response = await _aiService.generateResponse(
      prompt,
      systemMessage: systemMessage,
      temperature: temperature,
      maxTokens: 1000, // First prompt can be slightly longer
    );

    String title = "New Adventure";
    String story = response;

    final titleMatch = RegExp(r"Title:\s*(.+)", caseSensitive: false).firstMatch(response);
    final storyMatch = RegExp(r"Story:\s*(.+)", caseSensitive: false).firstMatch(response);

    if (titleMatch != null) {
      title = titleMatch.group(1)!.trim();
    }
    if (storyMatch != null) {
      story = response.substring(storyMatch.start + 6).trim();
    }

    final processedStory = await _processInventoryTags(story);
    return (title: title, story: processedStory);
  }

  Future<List<String>> _getChoices(String storyResponse, List<Map<String, String>> history) async {
    final temperature = _ref.read(temperatureProvider);
    final prompt = "stop the story and recommend exactly 3 short, plausible choices for ${_activeCharacter!.name}. Don't reference these choices later.";

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

extension ListTakeLast<T> on List<T> {
  List<T> takeLast(int n) {
    if (length <= n) return this;
    return sublist(length - n);
  }
}
