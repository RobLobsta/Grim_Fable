import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'adventure_repository.dart';
import '../../core/models/adventure.dart';
import '../../core/models/character.dart';
import '../character/character_provider.dart';
import '../../core/services/ai_provider.dart';
import '../../core/services/ai_service.dart';

final adventureRepositoryProvider = Provider((ref) => AdventureRepository());

final activeAdventureProvider = StateNotifierProvider<AdventureNotifier, Adventure?>((ref) {
  final repository = ref.watch(adventureRepositoryProvider);
  final aiService = ref.watch(aiServiceProvider);
  // Watch only the character ID to prevent provider recreation when character's lastPlayedAt updates
  final characterId = ref.watch(activeCharacterProvider.select((c) => c?.id));
  final activeCharacter = ref.read(activeCharacterProvider);
  final characterNotifier = ref.read(charactersProvider.notifier);

  return AdventureNotifier(repository, aiService, activeCharacter, characterNotifier);
});

class AdventureNotifier extends StateNotifier<Adventure?> {
  final AdventureRepository _repository;
  final AIService _aiService;
  final Character? _activeCharacter;
  final CharacterNotifier _characterNotifier;

  AdventureNotifier(
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
    final firstPrompt = await _generateFirstPrompt();
    final firstSegment = StorySegment(
      playerInput: "Starting the journey...",
      aiResponse: firstPrompt,
      timestamp: DateTime.now(),
    );

    final updatedAdventure = adventure.copyWith(
      storyHistory: [firstSegment],
    );

    await _saveAdventure(updatedAdventure);
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

  Future<void> submitAction(String action) async {
    if (state == null) return;

    final prompt = _buildPrompt(action);
    final response = await _aiService.generateResponse(prompt);

    final newSegment = StorySegment(
      playerInput: action,
      aiResponse: response,
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
    final prompt = """
<s>[INST] You are a creative storyteller for a dark fantasy adventure called Grim Fable.
Character: ${_activeCharacter!.name}
Backstory: ${_activeCharacter!.backstory}

Set the scene for a new adventure. Describe the location and the immediate situation in 2-3 paragraphs.
The tone should be dark fantasy.
[/INST]
""";
    return _aiService.generateResponse(prompt);
  }

  String _buildPrompt(String action) {
    final history = state!.storyHistory.takeLast(5).map((s) => "Player: ${s.playerInput}\nAI: ${s.aiResponse}").join("\n");

    return """
<s>[INST] You are a creative storyteller for Grim Fable.
Character: ${_activeCharacter!.name}
Backstory: ${_activeCharacter!.backstory}

Recent History:
$history

Player Action: $action

Generate the next story segment (2-3 paragraphs).
[/INST]
""";
  }
}

extension ListTakeLast<T> on List<T> {
  List<T> takeLast(int n) {
    if (length <= n) return this;
    return sublist(length - n);
  }
}
