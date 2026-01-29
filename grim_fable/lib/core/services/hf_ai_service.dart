import 'package:dio/dio.dart';
import 'ai_service.dart';
import '../utils/equipment_data.dart';

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
    double? topP,
    double? frequencyPenalty,
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
          'top_p': topP ?? 0.9,
          'frequency_penalty': frequencyPenalty ?? 0.0,
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
  Future<ValidationResult> validateIdentity(String name, String occupation) async {
    const systemMessage = "You are a validator for a dark fantasy RPG called Grim Fable.";
    final prompt = """
Determine if the following name and occupation are valid for a dark fantasy setting.

Character Name: $name
Occupation: $occupation

Rules for Name:
- Must be natural sounding for a dark fantasy setting.
- Must be capitalized.
- Must NOT include numbers or special characters (except apostrophes or hyphens for names like Mal'Lo).
- Must NOT be offensive or modern.
- Accept: Jan, Mal'Lo, Fanglehorn.
- Reject: 89, J8+>, Pussy Fucker, Elon Musk.

Rules for Occupation:
- Must be valid for a dark fantasy setting (similar to medieval/renaissance fantasy).
- Valid: chef, blacksmith, farmer, fighter, cleric, necromancer, alchemist, barbarian.
- Invalid: scientist, pilot, mechanic, modern soldier, or nonsensical gibberish (gx7kilr).

Format your response EXACTLY as follows:
VALID: Both are valid.
OR
INVALID_NAME: [Reason why the name is invalid]
OR
INVALID_OCCUPATION: [Reason why the occupation is invalid]
OR
INVALID_BOTH: [Reason for name] | [Reason for occupation]

Return ONLY the specified format.
""";

    final response = await generateResponse(prompt, systemMessage: systemMessage, maxTokens: 100, temperature: 0.0);
    final result = response.trim().toUpperCase();

    if (result.contains('VALID:')) {
      return ValidationResult.valid();
    }

    String? nameError;
    String? occupationError;

    if (result.contains('INVALID_BOTH:')) {
      final content = result.replaceFirst('INVALID_BOTH:', '').trim();
      final parts = content.split('|');
      nameError = parts[0].trim();
      occupationError = parts.length > 1 ? parts[1].trim() : "Invalid occupation";
    } else if (result.contains('INVALID_NAME:')) {
      nameError = result.replaceFirst('INVALID_NAME:', '').trim();
    } else if (result.contains('INVALID_OCCUPATION:')) {
      occupationError = result.replaceFirst('INVALID_OCCUPATION:', '').trim();
    } else if (result.contains('INVALID')) {
      nameError = "The fates reject this identity.";
    } else {
      // Fallback for unexpected success-like responses
      return ValidationResult.valid();
    }

    return ValidationResult.invalid(nameError: nameError, occupationError: occupationError);
  }

  @override
  Future<String> generateBackstory(String characterName, String occupation, {String? description}) async {
    const systemMessage = "You are a creative storyteller for a dark fantasy adventure called Grim Fable. Always write in the third person.";

    String descriptionPart = "";
    if (description != null && description.trim().isNotEmpty) {
      descriptionPart = "\nUse this description as a guide: $description";
    }

    final suggestedItems = EquipmentData.getStartingEquipment(occupation);
    final itemsExample = suggestedItems.map((e) => '"$e"').join(", ");

    final prompt = """
Generate a compelling, natural, and realistic dark fantasy backstory for a character.
The character should be a normal person with a normal occupation, avoiding overused "mysterious brooding figure" tropes.

Character Name: $characterName
Occupation: $occupation
$descriptionPart

Pay approximately 30% attention to the optional description—you may incorporate it or ignore it at your discretion.

The backstory must be exactly 3-4 SHORTER sentences total, covering:
- Origin: Their humble beginnings and how they became a $occupation.
- Conflict: A realistic struggle they faced in their daily life.
- Current State: Why they are setting out on an adventure now.

Use third person exclusively. Do NOT use "I" or "my".

Also, provide a list of 2-4 starting items that this character would realistically possess based on their occupation and backstory.
I suggest these items: $itemsExample. You may use them or similar grounded items.
Also include a plausible number of gold coins they start with (typically 1-10).

Format the items and gold using tags at the end of the backstory:
[ITEM_GAINED: Item Name]
[GOLD: Number]

Maintain a gritty, grounded dark fantasy tone. Avoid naming specific locations.
Do NOT use multiple paragraphs. Return ONLY the 3-4 sentences followed by the tags.
""";

    return generateResponse(prompt, systemMessage: systemMessage, maxTokens: 500);
  }

  @override
  Future<String> generateBackstoryUpdate(String currentBackstory, String adventureSummary) async {
    // Repurpose to default to 2 sentences append for backward compatibility if needed,
    // but preferred way is generateBackstoryAppend.
    return generateBackstoryAppend(currentBackstory, adventureSummary, 2);
  }

  @override
  Future<String> generateBackstoryAppend(String currentBackstory, String adventureSummary, int sentences) async {
    const systemMessage = "You are a creative storyteller for Grim Fable. Always write in the third person.";
    final prompt = """
Current Character Backstory:
$currentBackstory

Recent Adventure Summary:
$adventureSummary

Based on the recent adventure, write exactly $sentences short sentences of new backstory to be appended to the character's history.
The sentences should briefly summarize the adventure and its impact on the character.
Maintain a dark fantasy, gritty tone and keep it realistic.
Use third person exclusively.
Return ONLY the new sentences.
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
    const systemMessage = "You are a creative storyteller for Grim Fable. Always write in the third person.";

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

  @override
  Future<int> clarifyGoldAmount(String context) async {
    const systemMessage = "You are a precise assistant for a dark fantasy RPG. Your job is to quantify ambiguous gold amounts.";
    final prompt = """
In the following story context, the character has gained or lost an unspecified amount of "gold" or "coins".
Based on the situation, determine a plausible, small number of gold coins that fits the narrative (typically 1-10).

Story Context:
$context

Return ONLY the numerical value of the gold (e.g., '5' or '-3' if lost). Do not include any other text.
""";

    final response = await generateResponse(prompt, systemMessage: systemMessage, maxTokens: 10, temperature: 0.3);
    final cleanResponse = response.trim().replaceAll(RegExp(r'[^0-9-]'), '');
    return int.tryParse(cleanResponse) ?? 0;
  }

  @override
  Future<Map<String, String>> verifyItems(List<String> items, String occupation) async {
    const systemMessage = "You are an equipment validator for a dark fantasy RPG.";
    final itemsList = items.join(", ");
    final prompt = """
Verify if the following items are valid starting equipment for a character with the occupation: $occupation.
Items: $itemsList

For each item, determine if it's a valid, grounded item for a dark fantasy setting.
If an item is invalid (e.g., modern, magical but too powerful for a starter, or nonsensical), replace it with a more suitable item for a $occupation.
For each valid (or replaced) item, provide a short one-line description.

Format your response EXACTLY as follows:
[Item Name]: [One-line description]
[Item Name]: [One-line description]
...

Return ONLY the list. Do not include any introductory or concluding text.
""";

    final response = await generateResponse(prompt, systemMessage: systemMessage, maxTokens: 500, temperature: 0.3);
    final Map<String, String> verifiedItems = {};

    final lines = response.split('\n');
    for (var line in lines) {
      if (line.contains(':')) {
        final parts = line.split(':');
        final name = parts[0].trim().replaceAll(RegExp(r'^[-*•]\s*'), ''); // Remove bullets
        final description = parts.sublist(1).join(':').trim();
        if (name.isNotEmpty && description.isNotEmpty) {
          verifiedItems[name] = description;
        }
      }
    }

    return verifiedItems;
  }

  @override
  Future<({String title, String mainGoal})> generateAdventureTitleAndGoal(String characterName, String backstory, String startingPrompt) async {
    const systemMessage = "You are a creative storyteller for Grim Fable.";
    final prompt = """
Character: $characterName
Backstory: $backstory
Adventure Start: $startingPrompt

Based on the character and the start of the adventure, generate a thematic title and a secret main goal that would resolve the immediate conflict.

Format your response EXACTLY as follows:
Title: [Thematic Title]
Goal: [Short description of the main goal]
""";

    final response = await generateResponse(prompt, systemMessage: systemMessage, maxTokens: 200, temperature: 0.7);

    String title = "New Adventure";
    String mainGoal = "Survive and find a way forward.";

    final titleMatch = RegExp(r"Title:\s*(.+)", caseSensitive: false).firstMatch(response);
    final goalMatch = RegExp(r"Goal:\s*(.+)", caseSensitive: false).firstMatch(response);

    if (titleMatch != null) {
      title = titleMatch.group(1)!.trim();
    }
    if (goalMatch != null) {
      mainGoal = goalMatch.group(1)!.trim();
    }

    return (title: title, mainGoal: mainGoal);
  }
}
