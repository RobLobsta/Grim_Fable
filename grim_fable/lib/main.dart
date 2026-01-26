import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'core/utils/theme.dart';
import 'core/utils/router.dart';
import 'features/character/character_repository.dart';
import 'features/character/character_provider.dart';
import 'features/adventure/adventure_repository.dart';
import 'features/adventure/adventure_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();

  final characterRepository = CharacterRepository();
  await characterRepository.init();

  final adventureRepository = AdventureRepository();
  await adventureRepository.init();

  runApp(
    ProviderScope(
      overrides: [
        characterRepositoryProvider.overrideWithValue(characterRepository),
        adventureRepositoryProvider.overrideWithValue(adventureRepository),
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

    return MaterialApp.router(
      title: 'Grim Fable',
      debugShowCheckedModeBanner: false,
      theme: GrimFableTheme.darkTheme,
      routerConfig: router,
    );
  }
}
