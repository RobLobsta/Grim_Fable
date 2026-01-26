import 'package:hive_flutter/hive_flutter.dart';
import '../../core/models/character.dart';

class CharacterRepository {
  static const String _boxName = 'characters';

  Future<void> init() async {
    if (!Hive.isAdapterRegistered(0)) {
      Hive.registerAdapter(CharacterAdapter());
    }
    await Hive.openBox<Character>(_boxName);
  }

  Box<Character> get _box => Hive.box<Character>(_boxName);

  List<Character> getAllCharacters() {
    return _box.values.toList();
  }

  Character? getActiveCharacter() {
    if (_box.isEmpty) return null;
    // For MVP, we might just return the last played character
    final characters = getAllCharacters();
    characters.sort((a, b) => b.lastPlayedAt.compareTo(a.lastPlayedAt));
    return characters.first;
  }

  Future<void> saveCharacter(Character character) async {
    await _box.put(character.id, character);
  }

  Future<void> deleteCharacter(String id) async {
    await _box.delete(id);
  }

  Future<void> clear() async {
    await _box.clear();
  }
}
