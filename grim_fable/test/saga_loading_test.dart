import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:grim_fable/features/saga/saga_selection_screen.dart';
import 'package:grim_fable/features/saga/saga_provider.dart';
import 'package:grim_fable/core/models/saga.dart';
import 'package:mockito/mockito.dart';
import 'mocks.mocks.dart';

void main() {
  testWidgets('Saga selection screen should load sagas successfully', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1000, 2000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final mockSagaRepo = MockSagaRepository();

    final testSaga = Saga(
      id: 'test_saga',
      title: 'The Eternal Frost',
      series: 'Tales of the North',
      description: 'A cold adventure.',
      chapters: [],
    );

    when(mockSagaRepo.init()).thenAnswer((_) async {});
    when(mockSagaRepo.loadSagas()).thenAnswer((_) async => [testSaga]);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sagaRepositoryProvider.overrideWithValue(mockSagaRepo),
        ],
        child: const MaterialApp(
          home: SagaSelectionScreen(),
        ),
      ),
    );

    // Initial loading state
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    await tester.pumpAndSettle();

    // Verify title is changed to THE LIBRARY
    expect(find.text('THE LIBRARY'), findsOneWidget);

    // Verify saga card is displayed
    expect(find.text('A cold adventure.'), findsOneWidget);
  });
}
