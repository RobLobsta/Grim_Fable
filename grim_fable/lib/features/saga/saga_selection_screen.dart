import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:google_fonts/google_fonts.dart';
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
        child: SizedBox(
          height: 180,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Cover Art
              SizedBox(
                width: 140,
                child: saga.coverArtUrl != null
                    ? Image.network(
                        saga.coverArtUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => _buildPlaceholderCover(context, saga),
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return Container(
                            color: Colors.black26,
                            child: const Center(child: CircularProgressIndicator()),
                          );
                        },
                      )
                    : _buildPlaceholderCover(context, saga),
              ),
              // Saga Details
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        saga.series.toUpperCase(),
                        style: GoogleFonts.crimsonPro(
                          fontSize: 10,
                          letterSpacing: 2,
                          color: Theme.of(context).colorScheme.tertiary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      AutoSizeText(
                        saga.title.toUpperCase(),
                        style: GoogleFonts.grenze(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          height: 1.1,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      Expanded(
                        child: Text(
                          saga.description,
                          style: GoogleFonts.crimsonPro(
                            fontSize: 14,
                            color: Colors.white70,
                          ),
                          maxLines: 4,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '${saga.chapters.length} CHAPTERS',
                            style: GoogleFonts.crimsonPro(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1,
                              color: Colors.white54,
                            ),
                          ),
                          Text(
                            'RELIVE THE STORY',
                            style: GoogleFonts.grenze(
                              color: Colors.amber,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPlaceholderCover(BuildContext context, Saga saga) {
    return Container(
      color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.book, size: 40, color: Colors.white24),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Text(
                saga.title,
                textAlign: TextAlign.center,
                style: GoogleFonts.grenze(fontSize: 12, color: Colors.white54),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
