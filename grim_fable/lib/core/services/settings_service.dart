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

class SettingsService {
  static const String _settingsBoxName = 'settings';
  static const String _hfApiKey = 'hf_api_key';
  static const String _temperature = 'temperature';
  static const String _maxTokens = 'max_tokens';

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
}

class SettingsNotifier<T> extends StateNotifier<T> {
  final SettingsService _service;
  final T Function() _getter;
  final Future<void> Function(T) _setter;

  SettingsNotifier(this._service, this._getter, this._setter) : super(_getter());

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
