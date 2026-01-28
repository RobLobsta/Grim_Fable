import 'package:dio/dio.dart';
import 'ai_service.dart';

class HuggingFaceAIService implements AIService {
  final Dio _dio;
  final String _modelId;
  final String _apiKey;

  HuggingFaceAIService({
    required Dio dio,
    String modelId = 'meta-llama/Llama-3.1-8B-Instruct',
    String apiKey = '',
  })  : _dio = dio,
        _modelId = modelId,
        _apiKey = apiKey;

  @override
  Future<String> generateResponse(
    String prompt, {
    String? systemMessage,
    List<Map<String, String>>? history,
    double? temperature,
    int? maxTokens,
  }) async {
    if (_apiKey.isEmpty) {
      return "AI Service Error: API Key is missing. Please provide a Hugging Face API key.";
    }

    try {
      final messages = [
        if (systemMessage != null) {'role': 'system', 'content': systemMessage},
        if (history != null) ...history,
        {'role': 'user', 'content': prompt},
      ];

      final response = await _dio.post(
        'https://router.huggingface.co/v1/chat/completions',
        data: {
          'model': _modelId,
          'messages': messages,
          'max_tokens': maxTokens ?? 150,
          'temperature': temperature ?? 0.8,
          'top_p': 0.9,
          'stream': false,
        },
        options: Options(
          headers: {
            'Authorization': 'Bearer $_apiKey',
            'Content-Type': 'application/json',
          },
        ),
      );

      if (response.statusCode == 200) {
        if (response.data != null && response.data['choices'] != null && response.data['choices'].isNotEmpty) {
          return response.data['choices'][0]['message']['content'] ?? "No response generated.";
        }
        throw Exception("Invalid response format from AI service");
      } else {
        throw Exception("AI Service Error: ${response.statusCode} - ${response.statusMessage}");
      }
    } catch (e) {
      if (e is DioException) {
        if (e.response?.statusCode == 401 || e.response?.statusCode == 403) {
          throw Exception("Invalid API Key: Access denied by AI service.");
        }
        final errorMessage = e.response?.data?['error']?['message'] ?? e.message;
        throw Exception("Network Error: $errorMessage");
      }
      rethrow;
    }
  }

  @override
  Future<String> generateBackstory(String characterName, String occupation) async {
    const systemMessage = "You are a creative storyteller for a dark fantasy adventure called Grim Fable.";
    final prompt = """
Generate a compelling and gritty dark fantasy backstory for a character.

Character Name: $characterName
Occupation: $occupation

The backstory must be exactly 3-4 sentences total, covering:
- Origin: Their beginnings and how they became a $occupation.
- Conflict: A pivotal struggle they faced.
- Current State: Their current motivation.

Maintain a dark fantasy, vague, and atmospheric tone. Avoid naming specific locations.
Do NOT use multiple paragraphs. Return ONLY the 3-4 sentences.
""";

    return generateResponse(prompt, systemMessage: systemMessage, maxTokens: 500);
  }

  @override
  Future<String> generateBackstoryUpdate(String currentBackstory, String adventureSummary) async {
    // Repurpose to default to 1 paragraph append for backward compatibility if needed,
    // but preferred way is generateBackstoryAppend.
    return generateBackstoryAppend(currentBackstory, adventureSummary, 1);
  }

  @override
  Future<String> generateBackstoryAppend(String currentBackstory, String adventureSummary, int paragraphs) async {
    const systemMessage = "You are a creative storyteller for Grim Fable.";
    final prompt = """
Current Character Backstory:
$currentBackstory

Recent Adventure Summary:
$adventureSummary

Based on the recent adventure, write exactly $paragraphs paragraph(s) of new backstory to be appended to the character's history.
Maintain a dark fantasy, gritty tone and keep it realistic.
Return ONLY the new paragraph(s).
""";

    return generateResponse(prompt, systemMessage: systemMessage, maxTokens: 1000);
  }

  @override
  Future<String> generateOccupationEvolution(String currentOccupation, String adventureSummary) async {
    const systemMessage = "You are a creative storyteller for Grim Fable.";
    final prompt = """
Character's Current Occupation: $currentOccupation

Recent Adventure Summary:
$adventureSummary

Based on the events of the adventure, decide if the character's occupation has evolved, changed, or stayed the same.
Examples: Squire -> Knight, Thief -> Shadowblade, or stays as Thief if no major growth occurred.
Keep the occupation short (1-3 words).
Return ONLY the occupation name. If it hasn't changed, return the current one.
""";

    final response = await generateResponse(prompt, systemMessage: systemMessage, maxTokens: 20);
    return response.trim().replaceAll('.', '');
  }

  @override
  Future<List<String>> generateAdventureSuggestions(String characterName, String backstory, List<String> pastAdventureSummaries) async {
    const systemMessage = "You are a creative storyteller for Grim Fable.";

    String historyContext = "";
    if (pastAdventureSummaries.isNotEmpty) {
      historyContext = "\nPast Adventures:\n${pastAdventureSummaries.join("\n")}";
    }

    final prompt = """
Character Name: $characterName
Backstory: $backstory
$historyContext

Based on $characterName's backstory and past adventures, generate 4 unique, one-line starting prompts (possible next moves) for a new dark fantasy adventure.
Each suggestion MUST be short and concise, exactly 1 line (less than 12 words), and written in the third person starting with $characterName.
Suggestions should be robust and directly inspired by $characterName's history.
Do NOT include labels like "Suggestion X", bullets, or numbers.
Format your response exactly as follows:
Content 1 | Content 2 | Content 3 | Content 4
""";

    final response = await generateResponse(prompt, systemMessage: systemMessage, maxTokens: 500);

    // Attempt to split by pipe first
    List<String> parts = response.split("|");

    // If no pipe found, attempt to split by newline
    if (parts.length == 1) {
      parts = response.split("\n");
    }

    return parts
        .map((s) => s.trim())
        // Remove common labels like "Suggestion 1:", "1.", "- ", etc.
        .map((s) => s.replaceFirst(RegExp(r'^(Suggestion\s+\d+[:\.\s]*|\d+[:\.\s]+|[-*]\s+)', caseSensitive: false), ''))
        .where((s) => s.isNotEmpty)
        .toList();
  }
}
