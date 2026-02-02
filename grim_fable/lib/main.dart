import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'core/utils/theme.dart';
import 'core/utils/router.dart';
import 'features/character/character_repository.dart';
import 'features/character/character_provider.dart';
import 'features/adventure/adventure_repository.dart';
import 'features/adventure/adventure_provider.dart';
import 'features/saga/saga_repository.dart';
import 'features/saga/saga_provider.dart';
import 'core/services/settings_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Hide system navigation bar globally
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

  await Hive.initFlutter();

  final characterRepository = CharacterRepository();
  await characterRepository.init();

  final adventureRepository = AdventureRepository();
  await adventureRepository.init();

  final sagaRepository = SagaRepository();
  await sagaRepository.init();

  final settingsService = SettingsService();
  await settingsService.init();

  runApp(
    ProviderScope(
      overrides: [
        characterRepositoryProvider.overrideWithValue(characterRepository),
        adventureRepositoryProvider.overrideWithValue(adventureRepository),
        sagaRepositoryProvider.overrideWithValue(sagaRepository),
        settingsServiceProvider.overrideWithValue(settingsService),
      ],
      child: const GrimFableApp(),
    ),
  );
}

class GrimFableApp extends ConsumerWidget {
  const GrimFableApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    final uiPreset = ref.watch(uiPresetProvider);

    return MaterialApp.router(
      title: 'Grim Fable',
      debugShowCheckedModeBanner: false,
      theme: GrimFableTheme.getTheme(uiPreset),
      routerConfig: router,
    );
  }
}
