class ValidationResult {
  final bool isValid;
  final String? nameError;
  final String? occupationError;

  ValidationResult({required this.isValid, this.nameError, this.occupationError});

  factory ValidationResult.valid() => ValidationResult(isValid: true);
  factory ValidationResult.invalid({String? nameError, String? occupationError}) =>
      ValidationResult(isValid: false, nameError: nameError, occupationError: occupationError);
}

abstract class AIService {
  Future<String> generateResponse(
    String prompt, {
    String? systemMessage,
    List<Map<String, String>>? history,
    double? temperature,
    int? maxTokens,
    double? topP,
    double? frequencyPenalty,
  });
  Future<ValidationResult> validateIdentity(String name, String occupation);
  Future<String> generateBackstory(String characterName, String occupation, {String? description});
  Future<String> generateBackstoryUpdate(String currentBackstory, String adventureSummary);
  Future<String> generateBackstoryAppend(String currentBackstory, String adventureSummary, int sentences);
  Future<String> generateOccupationEvolution(String currentOccupation, String adventureSummary);
  Future<List<String>> generateAdventureSuggestions(String characterName, String backstory, List<String> pastAdventureSummaries);
  Future<int> clarifyGoldAmount(String context);
}
