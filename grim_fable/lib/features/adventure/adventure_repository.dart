import 'package:hive_flutter/hive_flutter.dart';
import '../../core/models/adventure.dart';

class AdventureRepository {
  static const String _boxName = 'adventures';

  Future<void> init() async {
    if (!Hive.isAdapterRegistered(1)) {
      Hive.registerAdapter(StorySegmentAdapter());
    }
    if (!Hive.isAdapterRegistered(2)) {
      Hive.registerAdapter(AdventureAdapter());
    }
    await Hive.openBox<Adventure>(_boxName);
  }

  Box<Adventure> get _box => Hive.box<Adventure>(_boxName);

  List<Adventure> getAdventuresForCharacter(String characterId) {
    return _box.values.where((a) => a.characterId == characterId).toList();
  }

  Adventure? getLatestAdventure(String characterId) {
    final adventures = getAdventuresForCharacter(characterId).where((a) => a.isActive).toList();
    if (adventures.isEmpty) return null;
    adventures.sort((a, b) => b.lastPlayedAt.compareTo(a.lastPlayedAt));
    return adventures.first;
  }

  Future<void> saveAdventure(Adventure adventure) async {
    await _box.put(adventure.id, adventure);
  }

  Future<void> deleteAdventure(String id) async {
    await _box.delete(id);
  }

  Future<void> clear() async {
    await _box.clear();
  }
}
