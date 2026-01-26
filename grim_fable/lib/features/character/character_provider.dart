import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'character_repository.dart';
import '../../core/models/character.dart';

final characterRepositoryProvider = Provider((ref) => CharacterRepository());

final charactersProvider = StateNotifierProvider<CharacterNotifier, List<Character>>((ref) {
  final repository = ref.watch(characterRepositoryProvider);
  return CharacterNotifier(repository);
});

class CharacterNotifier extends StateNotifier<List<Character>> {
  final CharacterRepository _repository;

  CharacterNotifier(this._repository) : super([]) {
    _loadCharacters();
  }

  void _loadCharacters() {
    state = _repository.getAllCharacters();
  }

  Future<void> addCharacter(Character character) async {
    await _repository.saveCharacter(character);
    _loadCharacters();
  }

  Future<void> updateCharacter(Character character) async {
    await _repository.saveCharacter(character);
    _loadCharacters();
  }

  Future<void> deleteCharacter(String id) async {
    await _repository.deleteCharacter(id);
    _loadCharacters();
  }
}

final activeCharacterProvider = StateProvider<Character?>((ref) {
  final characters = ref.watch(charactersProvider);
  if (characters.isEmpty) return null;
  // Sort by last played and return the first
  final sorted = [...characters];
  sorted.sort((a, b) => b.lastPlayedAt.compareTo(a.lastPlayedAt));
  return sorted.first;
});
