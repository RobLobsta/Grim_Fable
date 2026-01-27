import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'adventure_repository.dart';
import '../../core/models/adventure.dart';
import '../../core/models/character.dart';
import '../character/character_provider.dart';
import '../../core/services/ai_provider.dart';
import '../../core/services/ai_service.dart';
import '../../core/services/settings_service.dart';

final adventureRepositoryProvider = Provider((ref) => AdventureRepository());

final characterAdventuresProvider = Provider.autoDispose<List<Adventure>>((ref) {
  final repository = ref.watch(adventureRepositoryProvider);
  final characterId = ref.watch(activeCharacterProvider.select((c) => c?.id));
  if (characterId == null) return [];
  return repository.getAdventuresForCharacter(characterId);
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

  Future<void> startNewAdventure() async {
    if (_activeCharacter == null) return;

    final adventure = Adventure.create(characterId: _activeCharacter!.id);
    state = adventure;

    // Generate first prompt
    final firstPromptFull = await _generateFirstPrompt();
    final parsed = _parseResponse(firstPromptFull);
    final firstSegment = StorySegment(
      playerInput: "Starting the journey...",
      aiResponse: parsed.text,
      recommendedChoices: parsed.choices,
      timestamp: DateTime.now(),
    );

    final updatedAdventure = adventure.copyWith(
      storyHistory: [firstSegment],
    );

    await _saveAdventure(updatedAdventure);

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
    if (state == null || _activeCharacter == null) return;

    final systemMessage = """
You are a creative storyteller for Grim Fable.
Character: ${_activeCharacter!.name}
Backstory: ${_activeCharacter!.backstory}

Keep your responses short, exactly 1 paragraph (1-5 sentences).
Maintain a dark fantasy, gritty, and realistic tone.
""";

    final history = state!.storyHistory.takeLast(5).expand((s) => [
      {'role': 'user', 'content': s.playerInput},
      {'role': 'assistant', 'content': s.aiResponse},
    ]).toList();

    final temperature = _ref.read(temperatureProvider);
    final maxTokens = _ref.read(maxTokensProvider);
    final recommendedEnabled = _ref.read(recommendedResponsesProvider);

    final finalSystemMessage = recommendedEnabled
        ? "$systemMessage\nAt the end of your response, provide 2-3 recommended player actions in the following format: [CHOICES] Action 1 | Action 2 | Action 3"
        : systemMessage;

    final fullResponse = await _aiService.generateResponse(
      action,
      systemMessage: finalSystemMessage,
      history: history,
      temperature: temperature,
      maxTokens: maxTokens,
    );

    final parsed = _parseResponse(fullResponse);

    final newSegment = StorySegment(
      playerInput: action,
      aiResponse: parsed.text,
      recommendedChoices: parsed.choices,
      timestamp: DateTime.now(),
    );

    final updatedAdventure = state!.copyWith(
      storyHistory: [...state!.storyHistory, newSegment],
      lastPlayedAt: DateTime.now(),
    );

    await _saveAdventure(updatedAdventure);

    // Update last played time on character
    if (_activeCharacter != null) {
      await _characterNotifier.updateCharacter(
        _activeCharacter!.copyWith(lastPlayedAt: DateTime.now()),
      );
    }
  }

  Future<void> continueAdventure() async {
    if (state == null || _activeCharacter == null || state!.storyHistory.isEmpty) return;

    final systemMessage = """
You are a creative storyteller for Grim Fable.
Character: ${_activeCharacter!.name}
Backstory: ${_activeCharacter!.backstory}

Continue the story naturally from the last point.
Keep your responses short, exactly 1 paragraph (1-5 sentences).
Maintain a dark fantasy, gritty, and realistic tone.
""";

    final history = state!.storyHistory.takeLast(5).expand((s) => [
      {'role': 'user', 'content': s.playerInput},
      {'role': 'assistant', 'content': s.aiResponse},
    ]).toList();

    final temperature = _ref.read(temperatureProvider);
    final maxTokens = _ref.read(maxTokensProvider);
    final recommendedEnabled = _ref.read(recommendedResponsesProvider);

    final finalSystemMessage = recommendedEnabled
        ? "$systemMessage\nAt the end of your response, provide 2-3 recommended player actions in the following format: [CHOICES] Action 1 | Action 2 | Action 3"
        : systemMessage;

    final fullResponse = await _aiService.generateResponse(
      "Continue",
      systemMessage: finalSystemMessage,
      history: history,
      temperature: temperature,
      maxTokens: maxTokens,
    );

    final parsed = _parseResponse(fullResponse);

    final lastSegment = state!.storyHistory.last;
    final updatedSegment = StorySegment(
      playerInput: lastSegment.playerInput,
      aiResponse: "${lastSegment.aiResponse}\n\n${parsed.text}",
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
    final newBackstory = await _aiService.generateBackstoryUpdate(
      _activeCharacter!.backstory,
      summary,
    );

    await _characterNotifier.updateCharacter(
      _activeCharacter!.copyWith(
        backstory: newBackstory,
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

  Future<String> _generateFirstPrompt() async {
    if (_activeCharacter == null) return "";

    final systemMessage = """
You are a creative storyteller for a dark fantasy adventure called Grim Fable.
Character: ${_activeCharacter!.name}
Backstory: ${_activeCharacter!.backstory}
""";

    const prompt = "Set the scene for a new adventure. Describe the location and the immediate situation in exactly 2 paragraphs. Maintain a gritty and realistic dark fantasy tone.";

    final temperature = _ref.read(temperatureProvider);
    final recommendedEnabled = _ref.read(recommendedResponsesProvider);

    final finalSystemMessage = recommendedEnabled
        ? "$systemMessage\nAt the end of your response, provide 2-3 recommended player actions in the following format: [CHOICES] Action 1 | Action 2 | Action 3"
        : systemMessage;

    final response = await _aiService.generateResponse(
      prompt,
      systemMessage: finalSystemMessage,
      temperature: temperature,
      maxTokens: 1000, // First prompt can be slightly longer
    );

    return response;
  }

  _ParsedResponse _parseResponse(String response) {
    if (response.contains("[CHOICES]")) {
      final parts = response.split("[CHOICES]");
      final text = parts[0].trim();
      final choicesPart = parts[1].trim();
      final choices = choicesPart.split("|").map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
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
