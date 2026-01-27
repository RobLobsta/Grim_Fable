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
        final errorMessage = e.response?.data?['error']?['message'] ?? e.message;
        throw Exception("Network Error: $errorMessage");
      }
      rethrow;
    }
  }

  @override
  Future<String> generateBackstory(String characterName) async {
    const systemMessage = "You are a creative storyteller for a dark fantasy adventure called Grim Fable.";
    final prompt = "Generate a dark, compelling, and realistic backstory (3-4 paragraphs) for a character named $characterName. The tone should be dark fantasy, gritty, mysterious, and evoke a sense of tragedy or ancient secrets.";

    return generateResponse(prompt, systemMessage: systemMessage, maxTokens: 500);
  }

  @override
  Future<String> generateBackstoryUpdate(String currentBackstory, String adventureSummary) async {
    const systemMessage = "You are a creative storyteller for Grim Fable.";
    final prompt = """
Current Character Backstory:
$currentBackstory

Recent Adventure Summary:
$adventureSummary

Update the character's backstory to include the essence of this recent adventure.
Maintain a dark fantasy, gritty tone and keep it realistic.
The updated backstory should be around 3-4 paragraphs in total.
""";

    return generateResponse(prompt, systemMessage: systemMessage, maxTokens: 500);
  }
}
