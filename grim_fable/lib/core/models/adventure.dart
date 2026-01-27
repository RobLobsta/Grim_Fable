import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';

part 'adventure.g.dart';

@HiveType(typeId: 1)
class StorySegment {
  @HiveField(0)
  final String playerInput;

  @HiveField(1)
  final String aiResponse;

  @HiveField(2)
  final DateTime timestamp;

  @HiveField(3)
  final List<String>? recommendedChoices;

  StorySegment({
    required this.playerInput,
    required this.aiResponse,
    required this.timestamp,
    this.recommendedChoices,
  });
}

@HiveType(typeId: 2)
class Adventure extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String characterId;

  @HiveField(2)
  final String title;

  @HiveField(3)
  final List<StorySegment> storyHistory;

  @HiveField(4)
  final DateTime createdAt;

  @HiveField(5)
  final DateTime lastPlayedAt;

  @HiveField(6)
  final bool isActive;

  Adventure({
    required this.id,
    required this.characterId,
    required this.title,
    required this.storyHistory,
    required this.createdAt,
    required this.lastPlayedAt,
    this.isActive = true,
  });

  factory Adventure.create({required String characterId, String title = 'New Adventure'}) {
    final now = DateTime.now();
    return Adventure(
      id: const Uuid().v4(),
      characterId: characterId,
      title: title,
      storyHistory: [],
      createdAt: now,
      lastPlayedAt: now,
    );
  }

  Adventure copyWith({
    String? title,
    List<StorySegment>? storyHistory,
    DateTime? lastPlayedAt,
    bool? isActive,
  }) {
    return Adventure(
      id: id,
      characterId: characterId,
      title: title ?? this.title,
      storyHistory: storyHistory ?? this.storyHistory,
      createdAt: createdAt,
      lastPlayedAt: lastPlayedAt ?? this.lastPlayedAt,
      isActive: isActive ?? this.isActive,
    );
  }
}
