abstract class AIService {
  Future<String> generateResponse(
    String prompt, {
    String? systemMessage,
    List<Map<String, String>>? history,
  });
  Future<String> generateBackstory(String characterName);
  Future<String> generateBackstoryUpdate(String currentBackstory, String adventureSummary);
}
