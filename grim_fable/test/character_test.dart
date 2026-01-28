import 'package:flutter_test/flutter_test.dart';
import 'package:grim_fable/core/models/character.dart';

void main() {
  group('Character Model Tests', () {
    test('Character.create should initialize with correct values', () {
      final character = Character.create(
        name: 'Geralt',
        backstory: 'A monster hunter.',
        occupation: 'Witcher',
      );

      expect(character.name, 'Geralt');
      expect(character.backstory, 'A monster hunter.');
      expect(character.occupation, 'Witcher');
      expect(character.id, isNotEmpty);
      expect(character.createdAt, isNotNull);
      expect(character.lastPlayedAt, isNotNull);
    });

    test('copyWith should update fields correctly', () {
      final character = Character.create(name: 'Geralt', occupation: 'Witcher');
      final updated = character.copyWith(name: 'Geralt of Rivia', occupation: 'Monster Hunter');

      expect(updated.name, 'Geralt of Rivia');
      expect(updated.occupation, 'Monster Hunter');
      expect(updated.id, character.id);
      expect(updated.createdAt, character.createdAt);
    });
  });
}
