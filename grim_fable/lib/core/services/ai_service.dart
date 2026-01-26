abstract class AIService {
  Future<String> generateResponse(String prompt);
  Future<String> generateBackstory(String characterName);
  Future<String> generateBackstoryUpdate(String currentBackstory, String adventureSummary);
}
