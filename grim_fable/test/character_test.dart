import 'package:flutter_test/flutter_test.dart';
import 'package:grim_fable/core/models/character.dart';

void main() {
  group('Character Model Tests', () {
    test('Character.create should initialize with correct values', () {
      final character = Character.create(name: 'Geralt', backstory: 'A monster hunter.');

      expect(character.name, 'Geralt');
      expect(character.backstory, 'A monster hunter.');
      expect(character.id, isNotEmpty);
      expect(character.createdAt, isNotNull);
      expect(character.lastPlayedAt, isNotNull);
    });

    test('copyWith should update fields correctly', () {
      final character = Character.create(name: 'Geralt');
      final updated = character.copyWith(name: 'Geralt of Rivia');

      expect(updated.name, 'Geralt of Rivia');
      expect(updated.id, character.id);
      expect(updated.createdAt, character.createdAt);
    });
  });
}
