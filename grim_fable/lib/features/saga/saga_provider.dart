import 'dart:math';
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
  // Watch only the character ID to prevent provider recreation when character's metadata updates
  ref.watch(activeCharacterProvider.select((c) => c?.id));
  final characterNotifier = ref.read(charactersProvider.notifier);

  return SagaNotifier(ref, repository, advRepository, aiService, characterNotifier);
});

class SagaNotifier extends StateNotifier<Adventure?> {
  final Ref _ref;
  final SagaRepository _repository;
  final AdventureRepository _advRepository;
  final AIService _aiService;
  final CharacterNotifier _characterNotifier;
  bool _isDisposed = false;

  SagaNotifier(
    this._ref,
    this._repository,
    this._advRepository,
    this._aiService,
    this._characterNotifier,
  ) : super(null) {
    _recoverState();
  }

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }

  Future<void> _recoverState() async {
    // Wait a microtask to ensure all providers are initialized
    await Future.microtask(() {});
    if (_isDisposed) return;

    final saga = _ref.read(activeSagaProvider);
    final character = _ref.read(activeCharacterProvider);
    if (saga == null || character == null) return;

    final existingProgress = _repository.getProgress(saga.id);
    if (existingProgress != null) {
      final characterAdventures = _advRepository.getAdventuresForCharacter(character.id);
      final adventure = characterAdventures.where((a) => a.id == existingProgress.adventureId).firstOrNull;

      if (adventure != null) {
        state = adventure;
        _ref.read(sagaProgressProvider.notifier).state = existingProgress;
      }
    }
  }

  Future<void> startSaga(Saga saga) async {
    try {
      final character = _ref.read(activeCharacterProvider);
      if (saga.requiredCharacter != null) {
        final reqChar = saga.requiredCharacter!;
        final name = reqChar['name'] as String;

        if (character == null || character.name != name) {
          await _ensureCharacter(reqChar);
          // Re-trigger startSaga on the new notifier after the provider rebuilds
          Future.microtask(() {
            _ref.read(activeSagaAdventureProvider.notifier).startSaga(saga);
          });
          return;
        }
      }

      if (character == null) {
        throw Exception("Please create or select a character before beginning a Saga.");
      }

      final existingProgress = _repository.getProgress(saga.id);
      if (existingProgress != null) {
        final adventure = _advRepository
            .getAdventuresForCharacter(character.id)
            .where((a) => a.id == existingProgress.adventureId)
            .firstOrNull;

        if (adventure != null) {
          state = adventure;
          _ref.read(sagaProgressProvider.notifier).state = existingProgress;
          return;
        } else {
          // Progress exists but adventure is missing for this character
          await _repository.deleteProgress(saga.id);
        }
      }

      // Start New Saga Adventure
      final firstChapter = saga.chapters.first;
      final adventure = Adventure.create(
        characterId: character.id,
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
        character.copyWith(lastPlayedAt: DateTime.now()),
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
    final character = _ref.read(activeCharacterProvider);
    if (state == null || saga == null || progress == null || character == null) return;

    final currentChapter = saga.chapters[progress.currentChapterIndex];
    final inventoryList = character.inventory.isEmpty ? "None" : character.inventory.join(", ");

    // Influence / Override Logic
    String finalAction = action;
    if (saga.id == 'throne_of_bhaal') {
      final inConversationWith = progress.mechanicsState['active_conversation_partner'];
      if (inConversationWith != null) {
        finalAction = "Player says to $inConversationWith: \"$action\"";
      }
    } else if (saga.id == 'legacy_of_blood') {
      final corruption = (progress.mechanicsState['corruption'] ?? progress.mechanicsState['initial_corruption'] ?? 0.1).toDouble();
      if (Random().nextDouble() < corruption) {
        finalAction = await _generateArmorWill(action, character, currentChapter);
      }
    }

    // Saga-specific system message
    String mechanicsContext = "";
    if (saga.id == 'legacy_of_blood') {
      final corruption = progress.mechanicsState['corruption'] ?? progress.mechanicsState['initial_corruption'] ?? 0.1;
      mechanicsContext = """
Armor's Influence (Corruption): $corruption (0.0 to 1.0).
The armor of Bartuc is sentient and malevolent. It craves slaughter and seeks to dominate Norrec's will.
As corruption increases, Norrec's actions and the suggested choices MUST become darker, more violent, and impulsive.
NEVER reveal this numerical value (e.g. $corruption) to the player in your narrative.
""";
    } else if (saga.id == 'night_of_the_full_moon') {
      final courage = progress.mechanicsState['courage'] ?? 0;
      final reputation = progress.mechanicsState['reputation'] ?? 0;
      final moonPhase = progress.mechanicsState['moon_phase'] ?? "Crescent";
      mechanicsContext = """
Current Stats: Courage: $courage, Reputation: $reputation.
Moon Phase: $moonPhase.
Courage represents Little Red's bravery and willingness to fight.
Reputation represents her kindness and honesty.
As the Moon Phase progresses toward 'Full Moon', descriptions should become more eerie and dangerous.

STORY GUIDELINES:
- Prioritize LONGER encounters. Do not rush to the next plot anchor.
- Include riddles, puzzles, or deep conversations that require multiple turns to resolve.
- Allow the player to explore and interact with the environment without forcing them toward the goal.
- NEVER use corruption mechanics for this saga.
- When the player makes a significant moral or brave choice, you MUST include tags like [COURAGE: +1] or [REPUTATION: +1].
- In Chapter 1, if Little Red picks up a class-defining item, you MUST include the tag [CLASS_UPGRADE: ClassName].
  - Sword -> Knight
  - Bow -> Ranger
  - Herbs -> Apothecary
  - Spellbook -> Witch
  - Rosary or Holy Water -> Nun
  - Wrench or Gears -> Mechanic
""";
    } else if (saga.id == 'throne_of_bhaal') {
      final infamy = progress.mechanicsState['infamy'] ?? 0;
      final inConversationWith = progress.mechanicsState['active_conversation_partner'];

      mechanicsContext = """
Current Infamy: $infamy.
Active Conversation: ${inConversationWith ?? 'None'}.

STORY GUIDELINES:
- TONE: Maintain a 'tragicomic' and 'absurd' tone. Bhaal is a god, but currently a confused and amnesiac one.
- AMNESIA: Do NOT hint that the player is important or divine early on. Let the mystery build naturally through the world's reaction to his accidents.
- COMPANIONS: Frequently include gallows-humor commentary from 'The Grinning Skull' (mocking/sarcastic) or 'Cespenar' (fussy/disappointed butler). When a companion speaks, use bold for their name (e.g., **The Grinning Skull:** "Hehe...").
- INFAMY EFFECTS: As Infamy increases, mention Bhaal's shadow acting independently (e.g., tripping people) or the world pulsing with a dark divine rhythm.
- RANDOM ENCOUNTERS: Between plot anchors, introduce randomized, thematic encounters (e.g., meeting travelers, stumbling upon oddities, finding ruins) that enrich the Sword Coast setting.
- CONVERSATIONS: When an NPC speaks to the player and expects a response, you MUST use the tag [CONVERSATION: NPC Name]. If the conversation ends or no immediate response is needed, do NOT include the tag.
- WORLD EVENTS: When the player makes a significant choice or causes a lasting change, use the tag [WORLD_EVENT: Description].
- DIALOGUE: If the player provides speech, narrate their delivery based on the tone (e.g., 'You shrug and say...').
- INFAMY: When Bhaal causes a death, murder, or major disaster, use [INFAMY: +1].
- Provide situational irony—mortals whispering of a 20-foot monster while Bhaal is just a man with cabbage in his hair.
""";
    }

    final globalLore = saga.loreContext != null ? "\nWorld Lore: ${saga.loreContext}" : "";
    final chapterLore = currentChapter.loreContext != null ? "\nChapter Lore: ${currentChapter.loreContext}" : "";
    final knowledge = currentChapter.hiddenKnowledge != null ? "\nHidden Knowledge (Secret): ${currentChapter.hiddenKnowledge}" : "";

    final narrativeHistory = (progress.mechanicsState['narrative_history'] as List<dynamic>?)?.join("\n- ") ?? "None";
    final witnessedAnchors = progress.witnessedAnchors.join("\n- ");

    final narrativeContext = """
Narrative History (Past Significant Events):
- $narrativeHistory

Witnessed Plot Anchors:
- ${witnessedAnchors.isEmpty ? "None" : witnessedAnchors}
""";

    final systemMessage = """
You are a creative storyteller for Grim Fable, currently running a SAGA MODE adventure.
Saga: ${saga.title}
Chapter: ${currentChapter.title}
Protagonist: ${character.name} (Played by the player)

CHAPTER OBJECTIVE (Hidden from player): ${currentChapter.hiddenGoal}
IMPORTANT: When this objective is met, you MUST append the tag [CHAPTER_COMPLETE] to your response.

Lore Lexicon (Important Nouns): ${currentChapter.importantNouns.join(", ")}
Plot Anchors to weave in: ${currentChapter.plotAnchors.join(" | ")}
$globalLore$chapterLore$knowledge
$narrativeContext
$mechanicsContext

Inventory: $inventoryList
Gold: ${character.gold}

Your task is to guide the story through the current chapter's plot anchors.
Keep your responses short, exactly 1 paragraph (3-5 sentences).
Maintain a dark fantasy, gritty, and realistic tone consistent with the setting.
Use third person exclusively.

At the end of your response, you MUST provide exactly 3 short suggested actions for the protagonist, formatted as:
[CHOICES: Choice 1 | Choice 2 | Choice 3]

If a plot anchor is clearly achieved, add the tag [ANCHOR_WITNESSED: Description].
Standard tags apply: [ITEM_GAINED: Name], [GOLD_GAINED: Number], etc.

${saga.id == 'legacy_of_blood' ? "IMPORTANT: When Norrec first dons the armor (usually in Chapter 1), you MUST include the tag [ITEM_GAINED: Bartuc's Armor]." : ""}
${saga.id == 'night_of_the_full_moon' ? "IMPORTANT: If the player meets the Traveling Merchant, offer specific items with prices in [CHOICES]. If they buy something, use [GOLD_REMOVED: X] and [ITEM_GAINED: Name]." : ""}
""";

    final activeAdventure = state;
    if (activeAdventure == null) return;

    final history = activeAdventure.storyHistory.takeLast(5).expand((s) => [
      {'role': 'user', 'content': s.playerInput},
      {'role': 'assistant', 'content': s.aiResponse},
    ]).toList();

    final fullResponse = await _aiService.generateResponse(
      finalAction,
      systemMessage: systemMessage,
      history: history,
      maxTokens: 300,
    );

    if (_isDisposed) return;

    // Process Tags
    final parsed = _parseSagaResponse(fullResponse);
    String processed = await _processSagaTags(parsed.text);

    final newSegment = StorySegment(
      playerInput: finalAction,
      aiResponse: processed,
      recommendedChoices: parsed.choices,
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
      character.copyWith(lastPlayedAt: DateTime.now()),
    );
  }

  Future<String> _generateArmorWill(String originalAction, Character character, dynamic chapter) async {
    final prompt = "The player wanted to: $originalAction. However, the cursed armor of Bartuc is taking control. Generate a short (max 12 words), impulsive, and bloodthirsty action that Norrec performs instead. Start the response with '[ARMOR'S WILL]: '";
    final systemMessage = "You are the malevolent spirit of Bartuc's armor. Norrec Vizharan is your puppet. You crave blood, slaughter, and dominance. Chapter Context: ${chapter.title}";

    try {
      final response = await _aiService.generateResponse(prompt, systemMessage: systemMessage, maxTokens: 50);
      return response.trim();
    } catch (e) {
      return "[ARMOR'S WILL]: Norrec's hand moves against his will, reaching for his blade with a murderous glint in his eyes.";
    }
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
    final newState = Map<String, dynamic>.from(progress.mechanicsState);
    newState.addAll(nextChapter.mechanics);

    final updatedProgress = progress.copyWith(
      currentChapterIndex: nextIndex,
      completedChapterIds: [...progress.completedChapterIds, saga.chapters[progress.currentChapterIndex].id],
      mechanicsState: newState,
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

  _ParsedSagaResponse _parseSagaResponse(String response) {
    final choicesRegex = RegExp(r'\[CHOICES:?\s*(.+?)\]', caseSensitive: false);
    final match = choicesRegex.firstMatch(response);

    if (match != null) {
      final choicesPart = match.group(1)!;
      final choices = _cleanChoices(choicesPart);
      final textWithoutChoices = response.replaceFirst(match.group(0)!, '').trim();
      return _ParsedSagaResponse(textWithoutChoices, choices);
    }

    // Fallback for [CHOICES] tag without colon
    if (response.contains("[CHOICES]")) {
      final parts = response.split("[CHOICES]");
      final text = parts[0].trim();
      final choicesPart = parts.length > 1 ? parts[1].trim() : "";
      final choices = _cleanChoices(choicesPart);
      return _ParsedSagaResponse(text, choices);
    }

    return _ParsedSagaResponse(response, null);
  }

  List<String> _cleanChoices(String response) {
    // Remove introductory text like "Here are your choices:"
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
        .where((e) => e.isNotEmpty && !RegExp(r'^\d+$').hasMatch(e) && e.length > 3)
        .toList();
  }

  Future<String> _processSagaTags(String response) async {
    final character = _ref.read(activeCharacterProvider);
    if (character == null) return response;

    String cleanResponse = await TagProcessor.processInventoryTags(
      response: response,
      character: character,
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
        double current = (progress.mechanicsState['corruption'] ?? progress.mechanicsState['initial_corruption'] ?? 0.1).toDouble();
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
            final step = (chapter.mechanics['corruption_step'] ?? 0.02).toDouble();
            double current = (progress.mechanicsState['corruption'] ?? progress.mechanicsState['initial_corruption'] ?? 0.1).toDouble();
            double next = (current + step).clamp(0.0, 1.0);
            final newState = Map<String, dynamic>.from(progress.mechanicsState);
            newState['corruption'] = next;
            final updatedProgress = progress.copyWith(mechanicsState: newState);
            await _repository.saveProgress(updatedProgress);
            _ref.read(sagaProgressProvider.notifier).state = updatedProgress;
         }
      }
    }

    // For Night of the Full Moon: Courage and Reputation updates
    final courageRegex = RegExp(r"\[COURAGE:\s*([+-]?\d+)\]");
    final repRegex = RegExp(r"\[REPUTATION:\s*([+-]?\d+)\]");
    final infamyRegex = RegExp(r"\[INFAMY:\s*([+-]?\d+)\]");
    final classRegex = RegExp(r"\[CLASS_UPGRADE:\s*(.+?)\]");

    final courageMatch = courageRegex.firstMatch(response);
    final repMatch = repRegex.firstMatch(response);
    final infamyMatch = infamyRegex.firstMatch(response);
    final classMatch = classRegex.firstMatch(response);

    if (courageMatch != null || repMatch != null || infamyMatch != null) {
      final progress = _ref.read(sagaProgressProvider);
      if (progress != null) {
        final newState = Map<String, dynamic>.from(progress.mechanicsState);
        if (courageMatch != null) {
          int delta = int.tryParse(courageMatch.group(1)!) ?? 0;
          newState['courage'] = (newState['courage'] ?? 0) + delta;
          cleanResponse = cleanResponse.replaceAll(courageRegex, '');
        }
        if (repMatch != null) {
          int delta = int.tryParse(repMatch.group(1)!) ?? 0;
          newState['reputation'] = (newState['reputation'] ?? 0) + delta;
          cleanResponse = cleanResponse.replaceAll(repRegex, '');
        }
        if (infamyMatch != null) {
          int delta = int.tryParse(infamyMatch.group(1)!) ?? 0;
          newState['infamy'] = (newState['infamy'] ?? 0) + delta;
          cleanResponse = cleanResponse.replaceAll(infamyRegex, '');
        }
        final updatedProgress = progress.copyWith(mechanicsState: newState);
        await _repository.saveProgress(updatedProgress);
        _ref.read(sagaProgressProvider.notifier).state = updatedProgress;
      }
    }

    if (classMatch != null) {
      final newClass = classMatch.group(1)!;
      await _characterNotifier.updateCharacter(character.copyWith(occupation: newClass));
      cleanResponse = cleanResponse.replaceAll(classRegex, '');
    }

    // Process Conversation tags (currently Throne of Bhaal specific)
    final activeSaga = _ref.read(activeSagaProvider);
    if (activeSaga?.id == 'throne_of_bhaal') {
      final convRegex = RegExp(r"\[CONVERSATION:\s*(.+?)\]");
      final progress = _ref.read(sagaProgressProvider);
      if (progress != null) {
        final newState = Map<String, dynamic>.from(progress.mechanicsState);
        bool changed = false;

        final convMatch = convRegex.firstMatch(response);
        if (convMatch != null) {
          newState['active_conversation_partner'] = convMatch.group(1)!;
          cleanResponse = cleanResponse.replaceAll(convRegex, '');
          changed = true;
        } else if (newState.containsKey('active_conversation_partner')) {
          if (!_detectConversationNLP(cleanResponse)) {
            newState.remove('active_conversation_partner');
            changed = true;
          }
        } else {
          if (_detectConversationNLP(cleanResponse)) {
            newState['active_conversation_partner'] = "NPC";
            changed = true;
          }
        }

        if (changed) {
          final updatedProgress = progress.copyWith(mechanicsState: newState);
          await _repository.saveProgress(updatedProgress);
          _ref.read(sagaProgressProvider.notifier).state = updatedProgress;
        }
      }
    }

    // Process Narrative / World Event tags (Global)
    final narrativeRegex = RegExp(r"\[NARRATIVE:\s*(.+?)\]");
    final worldEventRegex = RegExp(r"\[WORLD_EVENT:\s*(.+?)\]");
    final narrativeMatches = [...narrativeRegex.allMatches(response), ...worldEventRegex.allMatches(response)];

    if (narrativeMatches.isNotEmpty) {
      final progress = _ref.read(sagaProgressProvider);
      if (progress != null) {
        final newState = Map<String, dynamic>.from(progress.mechanicsState);
        // Support both old 'world_events' and new 'narrative_history' for backwards compatibility if needed,
        // but we'll migrate to 'narrative_history'.
        final List<String> history = List<String>.from(newState['narrative_history'] ?? newState['world_events'] ?? []);

        for (final m in narrativeMatches) {
          final event = m.group(1)!;
          if (!history.contains(event)) {
            history.add(event);
          }
        }

        newState['narrative_history'] = history;
        if (newState.containsKey('world_events')) newState.remove('world_events');

        final updatedProgress = progress.copyWith(mechanicsState: newState);
        await _repository.saveProgress(updatedProgress);
        _ref.read(sagaProgressProvider.notifier).state = updatedProgress;
      }
      cleanResponse = cleanResponse.replaceAll(narrativeRegex, '').replaceAll(worldEventRegex, '');
    }

    // Clean up extra whitespace from removed tags
    return cleanResponse.trim();
  }

  bool _detectConversationNLP(String text) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return false;

    // Check if the text ends with a question directed at 'you'
    final hasQuestion = trimmed.endsWith('?');
    final hasYou = trimmed.toLowerCase().contains('you');

    // Check for direct speech markers
    final hasQuotes = trimmed.contains('"') || trimmed.contains("'");
    final dialogueMarkers = ['asks', 'says', 'shouts', 'whispers', 'replies', 'speaks'];
    final hasMarker = dialogueMarkers.any((m) => trimmed.toLowerCase().contains(m));

    // If it has quotes and ends in a question, or has quotes and a dialogue marker, it's likely a conversation
    return (hasQuotes && hasQuestion && hasYou) || (hasQuotes && hasMarker);
  }
}

class _ParsedSagaResponse {
  final String text;
  final List<String>? choices;

  _ParsedSagaResponse(this.text, this.choices);
}
