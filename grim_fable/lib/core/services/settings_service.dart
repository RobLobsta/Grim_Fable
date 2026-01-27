import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

final settingsServiceProvider = Provider((ref) => SettingsService());

final hfApiKeyProvider = StateNotifierProvider<SettingsNotifier, String>((ref) {
  final service = ref.watch(settingsServiceProvider);
  return SettingsNotifier(service);
});

class SettingsService {
  static const String _settingsBoxName = 'settings';
  static const String _hfApiKey = 'hf_api_key';

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
}

class SettingsNotifier extends StateNotifier<String> {
  final SettingsService _service;

  SettingsNotifier(this._service) : super(_service.getHfApiKey());

  Future<void> setApiKey(String key) async {
    await _service.setHfApiKey(key);
    state = key;
  }
}
