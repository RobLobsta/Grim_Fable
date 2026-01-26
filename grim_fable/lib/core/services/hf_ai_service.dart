import 'package:dio/dio.dart';
import 'ai_service.dart';

class HuggingFaceAIService implements AIService {
  final Dio _dio;
  final String _modelId;
  final String _apiKey;

  HuggingFaceAIService({
    required Dio dio,
    String modelId = 'mistralai/Mistral-7B-Instruct-v0.2',
    String apiKey = '',
  })  : _dio = dio,
        _modelId = modelId,
        _apiKey = apiKey;

  @override
  Future<String> generateResponse(String prompt) async {
    if (_apiKey.isEmpty) {
      return "AI Service Error: API Key is missing. Please provide a Hugging Face API key.";
    }

    try {
      final response = await _dio.post(
        'https://api-inference.huggingface.co/models/$_modelId',
        data: {
          'inputs': prompt,
          'parameters': {
            'max_new_tokens': 300,
            'temperature': 0.7,
            'top_p': 0.9,
            'return_full_text': false,
          },
        },
        options: Options(
          headers: {
            'Authorization': 'Bearer $_apiKey',
            'Content-Type': 'application/json',
          },
        ),
      );

      if (response.statusCode == 200) {
        if (response.data is List && response.data.isNotEmpty) {
          return response.data[0]['generated_text'] ?? "No response generated.";
        }
        throw Exception("Invalid response format from AI service");
      } else {
        throw Exception("AI Service Error: ${response.statusCode} - ${response.statusMessage}");
      }
    } catch (e) {
      if (e is DioException) {
        throw Exception("Network Error: ${e.message}");
      }
      rethrow;
    }
  }

  @override
  Future<String> generateBackstory(String characterName) async {
    final prompt = """
<s>[INST] You are a creative storyteller for a dark fantasy adventure called Grim Fable.
Generate a dark, compelling backstory (2 paragraphs) for a character named $characterName.
The tone should be gritty, mysterious, and evoke a sense of tragedy or ancient secrets.
[/INST]
""";
    return generateResponse(prompt);
  }

  @override
  Future<String> generateBackstoryUpdate(String currentBackstory, String adventureSummary) async {
    final prompt = """
<s>[INST] You are a creative storyteller for Grim Fable.
Current Character Backstory:
$currentBackstory

Recent Adventure Summary:
$adventureSummary

Update the character's backstory to include the essence of this recent adventure.
Keep it concise (2-3 paragraphs) and maintain the dark fantasy tone.
[/INST]
""";
    return generateResponse(prompt);
  }
}
