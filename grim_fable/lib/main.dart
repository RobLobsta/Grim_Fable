import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'core/utils/theme.dart';
import 'features/home/home_screen.dart';
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

class GrimFableApp extends StatelessWidget {
  const GrimFableApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Grim Fable',
      debugShowCheckedModeBanner: false,
      theme: GrimFableTheme.darkTheme,
      home: const HomeScreen(),
    );
  }
}
