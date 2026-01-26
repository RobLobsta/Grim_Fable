import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:grim_fable/main.dart';
import 'package:grim_fable/features/character/character_repository.dart';
import 'package:grim_fable/features/character/character_provider.dart';
import 'package:grim_fable/features/adventure/adventure_repository.dart';
import 'package:grim_fable/features/adventure/adventure_provider.dart';
import 'package:mockito/mockito.dart';
import 'mocks.mocks.dart';

void main() {
  testWidgets('Welcome screen smoke test', (WidgetTester tester) async {
    final mockCharacterRepo = MockCharacterRepository();
    final mockAdventureRepo = MockAdventureRepository();

    when(mockCharacterRepo.getAllCharacters()).thenReturn([]);
    when(mockCharacterRepo.getActiveCharacter()).thenReturn(null);

    // Build our app and trigger a frame.
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          characterRepositoryProvider.overrideWithValue(mockCharacterRepo),
          adventureRepositoryProvider.overrideWithValue(mockAdventureRepo),
        ],
        child: const GrimFableApp(),
      ),
    );

    // Verify that our welcome message is displayed.
    expect(find.text('Welcome to Grim Fable'), findsOneWidget);
    expect(find.text('Your dark adventure awaits...'), findsOneWidget);
    expect(find.text('Begin Journey'), findsOneWidget);
  });
}
