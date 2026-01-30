import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

final settingsServiceProvider = Provider((ref) => SettingsService());

final hfApiKeyProvider = StateNotifierProvider<SettingsNotifier<String>, String>((ref) {
  final service = ref.watch(settingsServiceProvider);
  return SettingsNotifier(service, service.getHfApiKey, service.setHfApiKey);
});

final temperatureProvider = StateNotifierProvider<SettingsNotifier<double>, double>((ref) {
  final service = ref.watch(settingsServiceProvider);
  return SettingsNotifier(service, service.getTemperature, service.setTemperature);
});

final maxTokensProvider = StateNotifierProvider<SettingsNotifier<int>, int>((ref) {
  final service = ref.watch(settingsServiceProvider);
  return SettingsNotifier(service, service.getMaxTokens, service.setMaxTokens);
});

final topPProvider = StateNotifierProvider<SettingsNotifier<double>, double>((ref) {
  final service = ref.watch(settingsServiceProvider);
  return SettingsNotifier(service, service.getTopP, service.setTopP);
});

final frequencyPenaltyProvider = StateNotifierProvider<SettingsNotifier<double>, double>((ref) {
  final service = ref.watch(settingsServiceProvider);
  return SettingsNotifier(service, service.getFrequencyPenalty, service.setFrequencyPenalty);
});

final uiPresetProvider = StateNotifierProvider<SettingsNotifier<String>, String>((ref) {
  final service = ref.watch(settingsServiceProvider);
  return SettingsNotifier(service, service.getUiPreset, service.setUiPreset);
});

final recommendedResponsesProvider = StateNotifierProvider<SettingsNotifier<bool>, bool>((ref) {
  final service = ref.watch(settingsServiceProvider);
  return SettingsNotifier(service, service.getRecommendedResponsesEnabled, service.setRecommendedResponsesEnabled);
});

final freeFormInputProvider = StateNotifierProvider<SettingsNotifier<bool>, bool>((ref) {
  final service = ref.watch(settingsServiceProvider);
  return SettingsNotifier(service, service.getFreeFormInputEnabled, service.setFreeFormInputEnabled);
});

class SettingsService {
  static const String _settingsBoxName = 'settings';
  static const String _hfApiKey = 'hf_api_key';
  static const String _temperature = 'temperature';
  static const String _maxTokens = 'max_tokens';
  static const String _topP = 'top_p';
  static const String _frequencyPenalty = 'frequency_penalty';
  static const String _uiPreset = 'ui_preset';
  static const String _recommendedResponses = 'recommended_responses';
  static const String _freeFormInput = 'free_form_input';

  Future<void> init() async {
    await Hive.openBox(_settingsBoxName);
  }

  String getHfApiKey() {
    final box = Hive.box(_settingsBoxName);
    return box.get(_hfApiKey, defaultValue: '') as String;
  }

  Future<void> setHfApiKey(String key) async {
    final box = Hive.box(_settingsBoxName);
    await box.put(_hfApiKey, key);
  }

  double getTemperature() {
    final box = Hive.box(_settingsBoxName);
    return box.get(_temperature, defaultValue: 0.8) as double;
  }

  Future<void> setTemperature(double value) async {
    final box = Hive.box(_settingsBoxName);
    await box.put(_temperature, value);
  }

  int getMaxTokens() {
    final box = Hive.box(_settingsBoxName);
    return box.get(_maxTokens, defaultValue: 150) as int;
  }

  Future<void> setMaxTokens(int value) async {
    final box = Hive.box(_settingsBoxName);
    await box.put(_maxTokens, value);
  }

  double getTopP() {
    final box = Hive.box(_settingsBoxName);
    return box.get(_topP, defaultValue: 0.9) as double;
  }

  Future<void> setTopP(double value) async {
    final box = Hive.box(_settingsBoxName);
    await box.put(_topP, value);
  }

  double getFrequencyPenalty() {
    final box = Hive.box(_settingsBoxName);
    return box.get(_frequencyPenalty, defaultValue: 0.0) as double;
  }

  Future<void> setFrequencyPenalty(double value) async {
    final box = Hive.box(_settingsBoxName);
    await box.put(_frequencyPenalty, value);
  }

  String getUiPreset() {
    final box = Hive.box(_settingsBoxName);
    return box.get(_uiPreset, defaultValue: 'Default') as String;
  }

  Future<void> setUiPreset(String value) async {
    final box = Hive.box(_settingsBoxName);
    await box.put(_uiPreset, value);
  }

  bool getRecommendedResponsesEnabled() {
    final box = Hive.box(_settingsBoxName);
    return box.get(_recommendedResponses, defaultValue: true) as bool;
  }

  Future<void> setRecommendedResponsesEnabled(bool value) async {
    final box = Hive.box(_settingsBoxName);
    await box.put(_recommendedResponses, value);
  }

  bool getFreeFormInputEnabled() {
    final box = Hive.box(_settingsBoxName);
    return box.get(_freeFormInput, defaultValue: true) as bool;
  }

  Future<void> setFreeFormInputEnabled(bool value) async {
    final box = Hive.box(_settingsBoxName);
    await box.put(_freeFormInput, value);
  }
}

class SettingsNotifier<T> extends StateNotifier<T> {
  final Future<void> Function(T) _setter;

  SettingsNotifier(SettingsService service, T Function() getter, this._setter) : super(getter());

  Future<void> updateValue(T value) async {
    await _setter(value);
    state = value;
  }

  // Keep this for backward compatibility if needed, or use updateValue
  Future<void> setApiKey(String key) async {
    if (state is String) {
      await updateValue(key as T);
    }
  }
}
