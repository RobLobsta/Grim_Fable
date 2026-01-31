class Saga {
  final String id;
  final String title;
  final String series;
  final String description;
  final String? coverArtUrl;
  final String? loreContext;
  final Map<String, dynamic>? requiredCharacter;
  final List<SagaChapter> chapters;
  final Map<String, dynamic> metadata;

  Saga({
    required this.id,
    required this.title,
    required this.series,
    required this.description,
    this.coverArtUrl,
    this.loreContext,
    this.requiredCharacter,
    required this.chapters,
    this.metadata = const {},
  });

  factory Saga.fromJson(Map<String, dynamic> json) {
    return Saga(
      id: json['id'] as String,
      title: json['title'] as String,
      series: json['series'] as String,
      description: json['description'] as String,
      coverArtUrl: json['coverArtUrl'] as String?,
      loreContext: json['loreContext'] as String?,
      requiredCharacter: json['requiredCharacter'] as Map<String, dynamic>?,
      chapters: (json['chapters'] as List<dynamic>)
          .map((e) => SagaChapter.fromJson(e as Map<String, dynamic>))
          .toList(),
      metadata: json['metadata'] as Map<String, dynamic>? ?? {},
    );
  }
}

class SagaChapter {
  final String id;
  final String title;
  final String startingPrompt;
  final String? chapterArtUrl;
  final String? loreContext;
  final String? hiddenKnowledge;
  final List<String> plotAnchors;
  final List<String> importantNouns;
  final String hiddenGoal;
  final Map<String, dynamic> mechanics;

  SagaChapter({
    required this.id,
    required this.title,
    required this.startingPrompt,
    this.chapterArtUrl,
    this.loreContext,
    this.hiddenKnowledge,
    required this.plotAnchors,
    required this.importantNouns,
    required this.hiddenGoal,
    this.mechanics = const {},
  });

  factory SagaChapter.fromJson(Map<String, dynamic> json) {
    return SagaChapter(
      id: json['id'] as String,
      title: json['title'] as String,
      startingPrompt: json['startingPrompt'] as String,
      chapterArtUrl: json['chapterArtUrl'] as String?,
      loreContext: json['loreContext'] as String?,
      hiddenKnowledge: json['hiddenKnowledge'] as String?,
      plotAnchors: List<String>.from(json['plotAnchors'] as List),
      importantNouns: List<String>.from(json['importantNouns'] as List),
      hiddenGoal: json['hiddenGoal'] as String,
      mechanics: json['mechanics'] as Map<String, dynamic>? ?? {},
    );
  }
}
