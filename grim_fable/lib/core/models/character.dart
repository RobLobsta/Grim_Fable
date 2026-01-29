import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';

part 'character.g.dart';

@HiveType(typeId: 0)
class Character extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String name;

  @HiveField(2, defaultValue: '')
  final String backstory;

  @HiveField(3)
  final DateTime createdAt;

  @HiveField(4)
  final DateTime lastPlayedAt;

  @HiveField(5, defaultValue: [])
  final List<String> inventory;

  @HiveField(6, defaultValue: [])
  final List<String> cachedSuggestions;

  @HiveField(7, defaultValue: '')
  final String occupation;

  Character({
    required this.id,
    required this.name,
    this.backstory = '',
    required this.createdAt,
    required this.lastPlayedAt,
    this.inventory = const [],
    this.cachedSuggestions = const [],
    this.occupation = '',
  });

  factory Character.create({
    required String name,
    String backstory = '',
    String occupation = '',
  }) {
    final now = DateTime.now();
    return Character(
      id: const Uuid().v4(),
      name: name,
      backstory: backstory,
      createdAt: now,
      lastPlayedAt: now,
      inventory: const [],
      cachedSuggestions: const [],
      occupation: occupation,
    );
  }

  Character copyWith({
    String? name,
    String? backstory,
    DateTime? lastPlayedAt,
    List<String>? inventory,
    List<String>? cachedSuggestions,
    String? occupation,
  }) {
    return Character(
      id: id,
      name: name ?? this.name,
      backstory: backstory ?? this.backstory,
      createdAt: createdAt,
      lastPlayedAt: lastPlayedAt ?? this.lastPlayedAt,
      inventory: inventory ?? this.inventory,
      cachedSuggestions: cachedSuggestions ?? this.cachedSuggestions,
      occupation: occupation ?? this.occupation,
    );
  }
}
