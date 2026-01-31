import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/home/home_screen.dart';
import '../../features/character/character_creation_screen.dart';
import '../../features/adventure/adventure_screen.dart';
import '../../features/adventure/new_adventure_screen.dart';
import '../../features/adventure/adventure_history_screen.dart';
import '../../features/adventure/adventure_selection_screen.dart';
import '../../features/saga/saga_selection_screen.dart';
import '../../features/saga/saga_adventure_screen.dart';
import '../../features/saga/saga_chapters_screen.dart';

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
        path: '/adventure-selection',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const AdventureSelectionScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return SlideTransition(
              position: animation.drive(
                Tween<Offset>(
                  begin: const Offset(-1, 0),
                  end: Offset.zero,
                ).chain(CurveTween(curve: Curves.easeInOut)),
              ),
              child: child,
            );
          },
        ),
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
      GoRoute(
        path: '/saga-selection',
        builder: (context, state) => const SagaSelectionScreen(),
      ),
      GoRoute(
        path: '/saga-adventure',
        builder: (context, state) => const SagaAdventureScreen(),
      ),
      GoRoute(
        path: '/saga-chapters',
        builder: (context, state) => const SagaChaptersScreen(),
      ),
    ],
  );
});
