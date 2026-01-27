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
    await Future.delayed(const Duration(seconds: 2));
    return "$currentBackstory\n\nHaving recently survived the horrors of the Whispering Woods, they carry new scars and the knowledge of a betrayal that nearly cost them their soul.";
  }
}
