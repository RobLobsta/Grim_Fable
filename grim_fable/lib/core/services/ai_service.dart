abstract class AIService {
  Future<String> generateResponse(
    String prompt, {
    String? systemMessage,
    List<Map<String, String>>? history,
    double? temperature,
    int? maxTokens,
  });
  Future<String> generateBackstory(String characterName, String occupation);
  Future<String> generateBackstoryUpdate(String currentBackstory, String adventureSummary);
  Future<String> generateBackstoryAppend(String currentBackstory, String adventureSummary, int paragraphs);
  Future<String> generateOccupationEvolution(String currentOccupation, String adventureSummary);
  Future<List<String>> generateAdventureSuggestions(String characterName, String backstory, List<String> pastAdventureSummaries);
}
