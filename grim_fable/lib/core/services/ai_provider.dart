import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import 'ai_service.dart';
import 'hf_ai_service.dart';
import 'settings_service.dart';

final dioProvider = Provider((ref) => Dio());

final aiServiceProvider = Provider<AIService>((ref) {
  final apiKey = ref.watch(hfApiKeyProvider);

  if (apiKey.isEmpty) {
    throw Exception("API Key is missing. Please set it in settings.");
  }

  return HuggingFaceAIService(
    dio: ref.watch(dioProvider),
    apiKey: apiKey,
  );
});
