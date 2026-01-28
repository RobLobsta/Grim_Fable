import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:grim_fable/features/character/character_creation_screen.dart';
import 'package:grim_fable/core/services/ai_provider.dart';
import 'package:grim_fable/core/services/settings_service.dart';
import 'package:mockito/mockito.dart';
import 'mocks.mocks.dart';

void main() {
  testWidgets('Character Creation Screen Test', (WidgetTester tester) async {
    final mockAiService = MockAIService();
    final mockSettingsService = MockSettingsService();

    when(mockAiService.generateBackstory(any)).thenAnswer((_) async => "Test Hero was born in a storm.");
    when(mockSettingsService.getHfApiKey()).thenReturn('fake-key');

    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => const Scaffold(body: Text('Home')),
        ),
        GoRoute(
          path: '/create',
          builder: (context, state) => const CharacterCreationScreen(),
        ),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          aiServiceProvider.overrideWithValue(mockAiService),
          settingsServiceProvider.overrideWithValue(mockSettingsService),
        ],
        child: MaterialApp.router(
          routerConfig: router,
        ),
      ),
    );

    router.push('/create');
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    expect(find.text('FORGE CHARACTER'), findsOneWidget);
    expect(find.text('NAME'), findsOneWidget);

    // Enter name
    await tester.enterText(find.byType(TextFormField).first, 'Test Hero');

    // Tap AI Generate
    await tester.tap(find.text('AI DIVINATION'));
    await tester.pump(); // Start generating

    // Since MockAIService has a 2-second delay, we need to pump with duration
    await tester.pump(const Duration(seconds: 3));

    // Verify backstory is filled
    final backstoryField = find.byType(TextFormField).last;
    final TextFormField widget = tester.widget(backstoryField);
    expect(widget.controller?.text, contains('Test Hero'));
  });
}
