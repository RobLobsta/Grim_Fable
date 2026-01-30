import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'saga_provider.dart';
import '../../core/models/saga.dart';

class SagaSelectionScreen extends ConsumerWidget {
  const SagaSelectionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sagasAsync = ref.watch(sagasProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('THE LIBRARY'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: sagasAsync.when(
        data: (sagas) => ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: sagas.length,
          itemBuilder: (context, index) {
            final saga = sagas[index];
            return _buildSagaCard(context, ref, saga);
          },
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error loading sagas: $err')),
      ),
    );
  }

  Widget _buildSagaCard(BuildContext context, WidgetRef ref, Saga saga) {
    return Card(
      margin: const EdgeInsets.only(bottom: 24),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () async {
          ref.read(selectedSagaIdProvider.notifier).state = saga.id;
          await ref.read(activeSagaAdventureProvider.notifier).startSaga(saga);
          if (context.mounted) {
            context.push('/saga-adventure');
          }
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 120,
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Theme.of(context).colorScheme.primary,
                    Theme.of(context).colorScheme.surface,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      saga.series.toUpperCase(),
                      style: const TextStyle(
                        fontSize: 12,
                        letterSpacing: 4,
                        color: Colors.white70,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      saga.title.toUpperCase(),
                      style: Theme.of(context).textTheme.displayMedium?.copyWith(
                            color: Colors.white,
                            letterSpacing: 2,
                          ),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    saga.description,
                    style: Theme.of(context).textTheme.bodyMedium,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${saga.chapters.length} CHAPTERS',
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1,
                        ),
                      ),
                      const Text(
                        'RELIVE THE STORY',
                        style: TextStyle(
                          color: Colors.amber,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
