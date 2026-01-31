import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'saga_repository.dart';
import '../../core/models/saga.dart';
import '../../core/models/saga_progress.dart';
import '../../core/models/adventure.dart';
import '../../core/models/character.dart';
import '../adventure/adventure_repository.dart';
import '../adventure/adventure_provider.dart';
import '../character/character_provider.dart';
import '../../core/services/ai_provider.dart';
import '../../core/services/ai_service.dart';
import '../../core/utils/tag_processor.dart';
import '../../core/utils/extensions.dart';

final sagaRepositoryProvider = Provider((ref) => SagaRepository());

final sagasProvider = FutureProvider<List<Saga>>((ref) async {
  final repository = ref.watch(sagaRepositoryProvider);
  return repository.loadSagas();
});

final selectedSagaIdProvider = StateProvider<String?>((ref) => null);

final activeSagaProvider = Provider<Saga?>((ref) {
  final sagas = ref.watch(sagasProvider).value ?? [];
  final selectedId = ref.watch(selectedSagaIdProvider);
  if (selectedId == null) return null;
  return sagas.firstWhere((s) => s.id == selectedId);
});

final sagaProgressProvider = StateProvider<SagaProgress?>((ref) {
  final repository = ref.watch(sagaRepositoryProvider);
  final saga = ref.watch(activeSagaProvider);
  if (saga == null) return null;
  return repository.getProgress(saga.id);
});

final activeSagaAdventureProvider = StateNotifierProvider<SagaNotifier, Adventure?>((ref) {
  final repository = ref.watch(sagaRepositoryProvider);
  final advRepository = ref.watch(adventureRepositoryProvider);
  final aiService = ref.watch(aiServiceProvider);
  final activeCharacter = ref.watch(activeCharacterProvider);
  final characterNotifier = ref.read(charactersProvider.notifier);

  return SagaNotifier(ref, repository, advRepository, aiService, activeCharacter, characterNotifier);
});

class SagaNotifier extends StateNotifier<Adventure?> {
  final Ref _ref;
  final SagaRepository _repository;
  final AdventureRepository _advRepository;
  final AIService _aiService;
  final Character? _activeCharacter;
  final CharacterNotifier _characterNotifier;
  bool _isDisposed = false;

  SagaNotifier(
    this._ref,
    this._repository,
    this._advRepository,
    this._aiService,
    this._activeCharacter,
    this._characterNotifier,
  ) : super(null);

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }

  Future<void> startSaga(Saga saga) async {
    try {
      Character? effectiveCharacter = _activeCharacter;

      if (saga.requiredCharacter != null) {
        final reqChar = saga.requiredCharacter!;
        final name = reqChar['name'] as String;

        if (effectiveCharacter == null || effectiveCharacter.name != name) {
          await _ensureCharacter(reqChar);
          // Wait for a microtask to allow the provider to be recreated with the new character
          await Future.microtask(() {});
          if (!_isDisposed) {
            await _ref.read(activeSagaAdventureProvider.notifier).startSaga(saga);
          }
          return;
        }
      }

      if (effectiveCharacter == null) {
        throw Exception("Please create or select a character before beginning a Saga.");
      }

      final existingProgress = _repository.getProgress(saga.id);
      if (existingProgress != null) {
        final activeChar = _activeCharacter!;
        final characterAdventures = _advRepository.getAdventuresForCharacter(activeChar.id);
        final adventure = characterAdventures.where((a) => a.id == existingProgress.adventureId).firstOrNull;

        if (adventure != null) {
          state = adventure;
          _ref.read(sagaProgressProvider.notifier).state = existingProgress;
          return;
        } else {
          // Progress exists but adventure is missing for this character (e.g. character was re-created)
          await _repository.deleteProgress(saga.id);
        }
      }

      // Start New Saga Adventure
    final firstChapter = saga.chapters.first;
    final activeChar = _activeCharacter!;

    final adventure = Adventure.create(
      characterId: activeChar.id,
      title: "${saga.title}: ${firstChapter.title}",
      mainGoal: firstChapter.hiddenGoal,
    );

    final progress = SagaProgress(
      sagaId: saga.id,
      currentChapterIndex: 0,
      adventureId: adventure.id,
      mechanicsState: firstChapter.mechanics,
    );

    final firstSegment = StorySegment(
      playerInput: "Begin the Saga: ${saga.title}",
      aiResponse: firstChapter.startingPrompt,
      timestamp: DateTime.now(),
    );

    final updatedAdventure = adventure.copyWith(
      storyHistory: [firstSegment],
    );

    await _advRepository.saveAdventure(updatedAdventure);
    await _repository.saveProgress(progress);

    state = updatedAdventure;
    _ref.read(sagaProgressProvider.notifier).state = progress;

      // Update character last played
      await _characterNotifier.updateCharacter(
        _activeCharacter.copyWith(lastPlayedAt: DateTime.now()),
      );
    } catch (e) {
      rethrow;
    }
  }

  Future<Character> _ensureCharacter(Map<String, dynamic> data) async {
    final name = data['name'] as String;
    final characters = _ref.read(charactersProvider);
    Character? character = characters.where((c) => c.name == name).firstOrNull;

    if (character == null) {
      character = Character.create(
        name: name,
        occupation: data['occupation'] as String? ?? "Adventurer",
        backstory: data['backstory'] as String? ?? "",
        itemDescriptions: Map<String, String>.from(data['itemDescriptions'] ?? {}),
        isSagaCharacter: true,
      ).copyWith(
        inventory: List<String>.from(data['inventory'] ?? []),
      );
      await _characterNotifier.addCharacter(character);
    }

    _ref.read(selectedCharacterIdProvider.notifier).state = character.id;
    return character;
  }

  Future<void> submitSagaAction(String action) async {
    final saga = _ref.read(activeSagaProvider);
    final progress = _ref.read(sagaProgressProvider);
    if (state == null || saga == null || progress == null || _activeCharacter == null) return;

    final currentChapter = saga.chapters[progress.currentChapterIndex];
    final activeChar = _activeCharacter;
    final inventoryList = activeChar.inventory.isEmpty ? "None" : activeChar.inventory.join(", ");

    // Saga-specific system message
    String mechanicsContext = "";
    if (saga.id == 'legacy_of_blood') {
      final corruption = progress.mechanicsState['corruption'] ?? progress.mechanicsState['initial_corruption'] ?? 0.1;
      mechanicsContext = "\nArmor's Influence (Corruption): $corruption (0.0 to 1.0). At higher levels, Norrec becomes more aggressive and bloodthirsty. The armor may take control of his actions.";
    }

    final globalLore = saga.loreContext != null ? "\nWorld Lore: ${saga.loreContext}" : "";
    final chapterLore = currentChapter.loreContext != null ? "\nChapter Lore: ${currentChapter.loreContext}" : "";
    final knowledge = currentChapter.hiddenKnowledge != null ? "\nHidden Knowledge (Secret): ${currentChapter.hiddenKnowledge}" : "";

    final systemMessage = """
You are a creative storyteller for Grim Fable, currently running a SAGA MODE adventure.
Saga: ${saga.title}
Chapter: ${currentChapter.title}
Protagonist: ${activeChar.name} (Played by the player)

CHAPTER OBJECTIVE (Hidden from player): ${currentChapter.hiddenGoal}
IMPORTANT: When this objective is met, you MUST append the tag [CHAPTER_COMPLETE] to your response.

Lore Lexicon (Important Nouns): ${currentChapter.importantNouns.join(", ")}
Plot Anchors to weave in: ${currentChapter.plotAnchors.join(" | ")}
$globalLore$chapterLore$knowledge
$mechanicsContext

Inventory: $inventoryList
Gold: ${_activeCharacter.gold}

Your task is to guide the story through the current chapter's plot anchors.
Keep your responses short, exactly 1 paragraph (3-5 sentences).
Maintain a dark fantasy, gritty, and realistic tone consistent with the setting.
Use third person exclusively.

If a plot anchor is clearly achieved, add the tag [ANCHOR_WITNESSED: Description].
Standard tags apply: [ITEM_GAINED: Name], [GOLD_GAINED: Number], etc.
""";

    final activeAdventure = state;
    if (activeAdventure == null) return;

    final history = activeAdventure.storyHistory.takeLast(5).expand((s) => [
      {'role': 'user', 'content': s.playerInput},
      {'role': 'assistant', 'content': s.aiResponse},
    ]).toList();

    final fullResponse = await _aiService.generateResponse(
      action,
      systemMessage: systemMessage,
      history: history,
      maxTokens: 300,
    );

    if (_isDisposed) return;

    // Process Tags
    String processed = await _processSagaTags(fullResponse);

    final newSegment = StorySegment(
      playerInput: action,
      aiResponse: processed,
      timestamp: DateTime.now(),
    );

    final updatedAdventure = state!.copyWith(
      storyHistory: [...state!.storyHistory, newSegment],
      lastPlayedAt: DateTime.now(),
    );

    await _advRepository.saveAdventure(updatedAdventure);

    if (_isDisposed) return;
    state = updatedAdventure;

    if (fullResponse.contains("[CHAPTER_COMPLETE]")) {
      await _moveToNextChapter();
    }

    if (_isDisposed) return;
    await _characterNotifier.updateCharacter(
      _activeCharacter.copyWith(lastPlayedAt: DateTime.now()),
    );
  }

  Future<void> _moveToNextChapter() async {
    final saga = _ref.read(activeSagaProvider);
    final progress = _ref.read(sagaProgressProvider);
    if (saga == null || progress == null) return;

    final nextIndex = progress.currentChapterIndex + 1;
    if (nextIndex >= saga.chapters.length) {
      // Saga Complete
      final updatedAdventure = state!.copyWith(isActive: false, title: "${saga.title} (Completed)");
      await _advRepository.saveAdventure(updatedAdventure);
      state = updatedAdventure;
      return;
    }

    final nextChapter = saga.chapters[nextIndex];

    // Update progress
    final updatedProgress = progress.copyWith(
      currentChapterIndex: nextIndex,
      completedChapterIds: [...progress.completedChapterIds, saga.chapters[progress.currentChapterIndex].id],
    );

    await _repository.saveProgress(updatedProgress);
    if (_isDisposed) return;
    _ref.read(sagaProgressProvider.notifier).state = updatedProgress;

    // Add a transition segment
    final transitionSegment = StorySegment(
      playerInput: "Transition to ${nextChapter.title}",
      aiResponse: "--- CHAPTER COMPLETE ---\n\n${nextChapter.startingPrompt}",
      timestamp: DateTime.now(),
    );

    final updatedAdventure = state!.copyWith(
      storyHistory: [...state!.storyHistory, transitionSegment],
      title: "${saga.title}: ${nextChapter.title}",
      mainGoal: nextChapter.hiddenGoal,
    );

    await _advRepository.saveAdventure(updatedAdventure);
    state = updatedAdventure;
  }

  Future<String> _processSagaTags(String response) async {
    String cleanResponse = await TagProcessor.processInventoryTags(
      response: response,
      character: _activeCharacter!,
      characterNotifier: _characterNotifier,
      aiService: _aiService,
    );

    // Process ANCHOR_WITNESSED
    final anchorRegex = RegExp(r"\[ANCHOR_WITNESSED:\s*(.+?)\]");
    final anchorMatches = anchorRegex.allMatches(response);
    if (anchorMatches.isNotEmpty) {
      final progress = _ref.read(sagaProgressProvider);
      if (progress != null) {
        List<String> newAnchors = [...progress.witnessedAnchors];
        for (final m in anchorMatches) {
          final anchorDesc = m.group(1)!;
          if (!newAnchors.contains(anchorDesc)) {
            newAnchors.add(anchorDesc);
          }
        }
        final updatedProgress = progress.copyWith(witnessedAnchors: newAnchors);
        await _repository.saveProgress(updatedProgress);
        _ref.read(sagaProgressProvider.notifier).state = updatedProgress;
      }
      cleanResponse = cleanResponse.replaceAll(anchorRegex, '');
    }

    // Process CHAPTER_COMPLETE
    cleanResponse = cleanResponse.replaceAll("[CHAPTER_COMPLETE]", '');

    // For Legacy of Blood: Corruption updates (AI might suggest it in text or we auto-increment)
    // Let's look for [CORRUPTION: +0.1] or similar
    final corruptionRegex = RegExp(r"\[CORRUPTION:\s*([+-]?\d*\.?\d+)\]");
    final corrMatch = corruptionRegex.firstMatch(response);
    if (corrMatch != null) {
      final delta = double.tryParse(corrMatch.group(1)!) ?? 0.0;
      final progress = _ref.read(sagaProgressProvider);
      if (progress != null) {
        double current = progress.mechanicsState['corruption'] ?? progress.mechanicsState['initial_corruption'] ?? 0.1;
        double next = (current + delta).clamp(0.0, 1.0);
        final newState = Map<String, dynamic>.from(progress.mechanicsState);
        newState['corruption'] = next;
        final updatedProgress = progress.copyWith(mechanicsState: newState);
        await _repository.saveProgress(updatedProgress);
        _ref.read(sagaProgressProvider.notifier).state = updatedProgress;
      }
      cleanResponse = cleanResponse.replaceAll(corruptionRegex, '');
    } else {
      // Auto-increment corruption slightly if it's Legacy of Blood
      final saga = _ref.read(activeSagaProvider);
      if (saga != null && saga.id == 'legacy_of_blood') {
         final progress = _ref.read(sagaProgressProvider);
         if (progress != null) {
            final chapter = saga.chapters[progress.currentChapterIndex];
            final step = (chapter.mechanics['corruption_step'] ?? 0.02) as double;
            double current = progress.mechanicsState['corruption'] ?? progress.mechanicsState['initial_corruption'] ?? 0.1;
            double next = (current + step).clamp(0.0, 1.0);
            final newState = Map<String, dynamic>.from(progress.mechanicsState);
            newState['corruption'] = next;
            final updatedProgress = progress.copyWith(mechanicsState: newState);
            await _repository.saveProgress(updatedProgress);
            _ref.read(sagaProgressProvider.notifier).state = updatedProgress;
         }
      }
    }

    // Clean up extra whitespace from removed tags
    return cleanResponse.trim();
  }
}
