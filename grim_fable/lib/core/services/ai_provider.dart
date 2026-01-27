import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import 'ai_service.dart';
import 'hf_ai_service.dart';
import 'fake_ai_service.dart';
import 'settings_service.dart';

final dioProvider = Provider((ref) => Dio());

// Set this to true to use the real API
const bool useRealAI = true;

final aiServiceProvider = Provider<AIService>((ref) {
  final apiKey = ref.watch(hfApiKeyProvider);

  if (useRealAI && apiKey.isNotEmpty) {
    return HuggingFaceAIService(
      dio: ref.watch(dioProvider),
      apiKey: apiKey,
    );
  } else {
    return FakeAIService();
  }
});
