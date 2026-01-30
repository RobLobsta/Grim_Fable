import 'package:hive/hive.dart';

part 'saga_progress.g.dart';

@HiveType(typeId: 3)
class SagaProgress extends HiveObject {
  @HiveField(0)
  final String sagaId;

  @HiveField(1)
  final int currentChapterIndex;

  @HiveField(2)
  final List<String> completedChapterIds;

  @HiveField(3)
  final List<String> witnessedAnchors;

  @HiveField(4)
  final String adventureId;

  @HiveField(5)
  final Map<String, dynamic> mechanicsState;

  SagaProgress({
    required this.sagaId,
    required this.currentChapterIndex,
    this.completedChapterIds = const [],
    this.witnessedAnchors = const [],
    required this.adventureId,
    this.mechanicsState = const {},
  });

  SagaProgress copyWith({
    int? currentChapterIndex,
    List<String>? completedChapterIds,
    List<String>? witnessedAnchors,
    Map<String, dynamic>? mechanicsState,
  }) {
    return SagaProgress(
      sagaId: sagaId,
      currentChapterIndex: currentChapterIndex ?? this.currentChapterIndex,
      completedChapterIds: completedChapterIds ?? this.completedChapterIds,
      witnessedAnchors: witnessedAnchors ?? this.witnessedAnchors,
      adventureId: adventureId,
      mechanicsState: mechanicsState ?? this.mechanicsState,
    );
  }
}
