import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:grim_fable/main.dart';
import 'package:grim_fable/features/character/character_provider.dart';
import 'package:grim_fable/features/adventure/adventure_provider.dart';
import 'package:grim_fable/core/services/settings_service.dart';
import 'package:mockito/mockito.dart';
import 'mocks.mocks.dart';

void main() {
  testWidgets('Welcome screen smoke test', (WidgetTester tester) async {
    final mockCharacterRepo = MockCharacterRepository();
    final mockAdventureRepo = MockAdventureRepository();
    final mockSettingsService = MockSettingsService();

    when(mockCharacterRepo.init()).thenAnswer((_) async {});
    when(mockCharacterRepo.getAllCharacters()).thenReturn([]);
    when(mockSettingsService.getUiPreset()).thenReturn('Default');
    when(mockSettingsService.getHfApiKey()).thenReturn('');
    when(mockSettingsService.getTemperature()).thenReturn(0.8);
    when(mockSettingsService.getMaxTokens()).thenReturn(150);
    when(mockSettingsService.getRecommendedResponsesEnabled()).thenReturn(true);

    // Build our app and trigger a frame.
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          characterRepositoryProvider.overrideWithValue(mockCharacterRepo),
          adventureRepositoryProvider.overrideWithValue(mockAdventureRepo),
          settingsServiceProvider.overrideWithValue(mockSettingsService),
        ],
        child: const GrimFableApp(),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    // Verify that our welcome message is displayed.
    expect(find.text('GRIM FABLE'), findsOneWidget);
    expect(find.text('Behold, Thy Fate'), findsOneWidget);
  });
}
