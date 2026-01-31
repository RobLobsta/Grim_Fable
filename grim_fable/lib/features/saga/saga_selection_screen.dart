import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
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
      margin: const EdgeInsets.only(bottom: 32),
      clipBehavior: Clip.antiAlias,
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () {
          ref.read(selectedSagaIdProvider.notifier).state = saga.id;
          context.push('/saga-chapters');
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Hero Image
            AspectRatio(
              aspectRatio: 16 / 9,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  _buildCoverArt(context, saga),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withValues(alpha: 0.8),
                        ],
                      ),
                    ),
                  ),
                  const Positioned(
                    bottom: 16,
                    left: 16,
                    right: 16,
                    child: SizedBox.shrink(),
                  ),
                ],
              ),
            ),
            // Saga Details
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    saga.description,
                    style: GoogleFonts.crimsonPro(
                      fontSize: 16,
                      color: Colors.white70,
                      height: 1.4,
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${saga.chapters.length} CHAPTERS',
                        style: GoogleFonts.crimsonPro(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1,
                          color: Colors.white54,
                        ),
                      ),
                      Text(
                        'ENTER THE SAGA',
                        style: GoogleFonts.grenze(
                          color: Colors.amber,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1,
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

  Widget _buildCoverArt(BuildContext context, Saga saga) {
    if (saga.coverArtUrl == null) {
      return _buildPlaceholderCover(context, saga);
    }

    if (saga.coverArtUrl!.startsWith('assets/')) {
      return Image.asset(
        saga.coverArtUrl!,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => _buildPlaceholderCover(context, saga),
      );
    }

    return Image.network(
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
    );
  }

  Widget _buildPlaceholderCover(BuildContext context, Saga saga) {
    return Container(
      color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
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
