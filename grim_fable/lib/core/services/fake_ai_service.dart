import 'ai_service.dart';

class FakeAIService implements AIService {
  @override
  Future<String> generateResponse(
    String prompt, {
    String? systemMessage,
    List<Map<String, String>>? history,
    double? temperature,
    int? maxTokens,
  }) async {
    await Future.delayed(const Duration(seconds: 2));
    return "The mist swirls around your feet as you stand before the ancient iron gates. A chill wind carries the scent of damp earth and decay. You feel as if a thousand unseen eyes are watching you from the shadows of the twisted trees.";
  }

  @override
  Future<String> generateBackstory(String characterName) async {
    await Future.delayed(const Duration(seconds: 2));
    return "$characterName was born under a blood-red moon in the dying village of Oakhaven. After the Great Blight took their family, they wandered the scorched wastes, guided by whispers from a locket that shouldn't be able to speak.\n\nNow, they seek the Shattered Throne, carrying a burden of guilt and a blade forged from star-fallen iron, hoping to find redemption or at least a meaningful end to their suffering.";
  }

  @override
  Future<String> generateBackstoryUpdate(String currentBackstory, String adventureSummary) async {
    return generateBackstoryAppend(currentBackstory, adventureSummary, 1);
  }

  @override
  Future<String> generateBackstoryAppend(String currentBackstory, String adventureSummary, int paragraphs) async {
    await Future.delayed(const Duration(seconds: 2));
    return "After the events of this journey, they learned that the shadows are not just outside, but within. They found a new purpose in the darkness.";
  }

  @override
  Future<List<String>> generateAdventureSuggestions(String characterName, String backstory, List<String> pastAdventureSummaries) async {
    await Future.delayed(const Duration(seconds: 2));
    return [
      "Investigate the strange lights appearing in the ruins of the Old Watchtower.",
      "Seek out the hermit who claims to have a map to the Sunken City.",
      "Defend the village from the spectral riders that appear at every full moon."
    ];
  }
}
