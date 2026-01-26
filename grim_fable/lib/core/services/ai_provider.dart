import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import 'ai_service.dart';
import 'hf_ai_service.dart';
import 'fake_ai_service.dart';

final dioProvider = Provider((ref) => Dio());

// Set this to true to use the real API
const bool useRealAI = false;
const String hfApiKey = ''; // User should provide this

final aiServiceProvider = Provider<AIService>((ref) {
  if (useRealAI && hfApiKey.isNotEmpty) {
    return HuggingFaceAIService(
      dio: ref.watch(dioProvider),
      apiKey: hfApiKey,
    );
  } else {
    return FakeAIService();
  }
});
