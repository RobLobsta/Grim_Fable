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
  Future<String> generateBackstory(String characterName) async {
    const systemMessage = "You are a creative storyteller for a dark fantasy adventure called Grim Fable.";
    final prompt = "Generate a brief, concise, and realistic backstory (exactly 1 paragraph, 3-4 sentences) for a character named $characterName. The tone should be dark fantasy, gritty, mysterious, and evoke a sense of tragedy or ancient secrets.";

    return generateResponse(prompt, systemMessage: systemMessage, maxTokens: 1000);
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
  Future<List<String>> generateAdventureSuggestions(String characterName, String backstory, List<String> pastAdventureSummaries) async {
    const systemMessage = "You are a creative storyteller for Grim Fable.";

    String historyContext = "";
    if (pastAdventureSummaries.isNotEmpty) {
      historyContext = "\nPast Adventures:\n${pastAdventureSummaries.join("\n")}";
    }

    final prompt = """
Character: $characterName
Backstory: $backstory
$historyContext

Based on the character's backstory and past adventures, generate 4 unique, one-line starting prompts (possible next moves) for a new dark fantasy adventure.
Each suggestion MUST be short and concise, exactly 1 line (less than 12 words).
Suggestions should be based on the character's backstory and likely next actions.
Do NOT include "Suggestion X" or numbers. Just the content of the suggestions.
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
