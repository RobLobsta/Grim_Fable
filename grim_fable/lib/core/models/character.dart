import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';

part 'character.g.dart';

@HiveType(typeId: 0)
class Character extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String name;

  @HiveField(2)
  final String backstory;

  @HiveField(3)
  final DateTime createdAt;

  @HiveField(4)
  final DateTime lastPlayedAt;

  @HiveField(5)
  final List<String> inventory;

  Character({
    required this.id,
    required this.name,
    this.backstory = '',
    required this.createdAt,
    required this.lastPlayedAt,
    this.inventory = const [],
  });

  factory Character.create({required String name, String backstory = ''}) {
    final now = DateTime.now();
    return Character(
      id: const Uuid().v4(),
      name: name,
      backstory: backstory,
      createdAt: now,
      lastPlayedAt: now,
      inventory: const [],
    );
  }

  Character copyWith({
    String? name,
    String? backstory,
    DateTime? lastPlayedAt,
    List<String>? inventory,
  }) {
    return Character(
      id: id,
      name: name ?? this.name,
      backstory: backstory ?? this.backstory,
      createdAt: createdAt,
      lastPlayedAt: lastPlayedAt ?? this.lastPlayedAt,
      inventory: inventory ?? this.inventory,
    );
  }
}
