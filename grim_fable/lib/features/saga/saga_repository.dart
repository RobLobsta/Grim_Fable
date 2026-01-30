import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../core/models/saga.dart';
import '../../core/models/saga_progress.dart';

class SagaRepository {
  static const String _progressBoxName = 'saga_progress';

  Future<void> init() async {
    if (!Hive.isAdapterRegistered(3)) {
      Hive.registerAdapter(SagaProgressAdapter());
    }
    await Hive.openBox<SagaProgress>(_progressBoxName);
  }

  Box<SagaProgress> get _progressBox => Hive.box<SagaProgress>(_progressBoxName);

  Future<List<Saga>> loadSagas() async {
    final AssetManifest manifest = await AssetManifest.loadFromAssetBundle(rootBundle);
    final sagaPaths = manifest.listAssets()
        .where((String key) => key.startsWith('assets/sagas/') && key.endsWith('.json'))
        .toList();

    List<Saga> sagas = [];
    for (String path in sagaPaths) {
      final jsonString = await rootBundle.loadString(path);
      final jsonData = json.decode(jsonString);
      sagas.add(Saga.fromJson(jsonData));
    }
    return sagas;
  }

  SagaProgress? getProgress(String sagaId) {
    return _progressBox.get(sagaId);
  }

  Future<void> saveProgress(SagaProgress progress) async {
    await _progressBox.put(progress.sagaId, progress);
  }

  Future<void> deleteProgress(String sagaId) async {
    await _progressBox.delete(sagaId);
  }
}
