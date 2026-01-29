import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/character.dart';
import '../../features/home/home_screen.dart';
import '../../features/character/character_creation_screen.dart';
import '../../features/adventure/adventure_screen.dart';
import '../../features/adventure/new_adventure_screen.dart';
import '../../features/adventure/adventure_history_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const HomeScreen(),
      ),
      GoRoute(
        path: '/create-character',
        builder: (context, state) => const CharacterCreationScreen(),
      ),
      GoRoute(
        path: '/adventure',
        builder: (context, state) => AdventureScreen(
          animateFirst: state.extra as bool? ?? false,
        ),
      ),
      GoRoute(
        path: '/new-adventure',
        builder: (context, state) => const NewAdventureScreen(),
      ),
      GoRoute(
        path: '/history',
        builder: (context, state) => const AdventureHistoryScreen(),
      ),
    ],
  );
});
