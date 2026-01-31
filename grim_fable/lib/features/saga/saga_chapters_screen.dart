import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'saga_provider.dart';
import '../../core/models/saga.dart';
import '../../core/models/saga_progress.dart';

class SagaChaptersScreen extends ConsumerWidget {
  const SagaChaptersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final saga = ref.watch(activeSagaProvider);
    final progress = ref.watch(sagaProgressProvider);

    if (saga == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 250,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  _buildCoverArt(context, saga),
                  const DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black87,
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.all(24),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final chapter = saga.chapters[index];
                  final isUnlocked = _isChapterUnlocked(index, progress);
                  final isCompleted = _isChapterCompleted(chapter.id, progress);

                  if (!isUnlocked) return const SizedBox.shrink();

                  return _buildChapterTile(context, ref, saga, chapter, index, isCompleted);
                },
                childCount: saga.chapters.length,
              ),
            ),
          ),
        ],
      ),
    );
  }

  bool _isChapterUnlocked(int index, SagaProgress? progress) {
    if (index == 0) return true;
    if (progress == null) return false;
    return index <= progress.currentChapterIndex;
  }

  bool _isChapterCompleted(String chapterId, SagaProgress? progress) {
    if (progress == null) return false;
    return progress.completedChapterIds.contains(chapterId);
  }

  Widget _buildChapterTile(
    BuildContext context,
    WidgetRef ref,
    Saga saga,
    SagaChapter chapter,
    int index,
    bool isCompleted,
  ) {
    final artUrl = chapter.chapterArtUrl;
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isCompleted ? Colors.amber.withValues(alpha: 0.3) : Colors.white12,
        ),
        image: artUrl != null
            ? DecorationImage(
                image: artUrl.startsWith('assets/')
                    ? AssetImage(artUrl) as ImageProvider
                    : NetworkImage(artUrl) as ImageProvider,
                fit: BoxFit.cover,
                colorFilter: ColorFilter.mode(
                  Colors.black.withValues(alpha: 0.6),
                  BlendMode.darken,
                ),
              )
            : null,
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
        title: AutoSizeText(
          chapter.title.toUpperCase(),
          style: GoogleFonts.grenze(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
          maxLines: 1,
        ),
        trailing: isCompleted
            ? const Icon(Icons.check_circle, color: Colors.amber)
            : const Icon(Icons.play_arrow_outlined, color: Colors.white70),
        onTap: () async {
          try {
             // In a real app, we might want to jump to a specific chapter.
             // For now, startSaga handles continuing from progress.
             await ref.read(activeSagaAdventureProvider.notifier).startSaga(saga);
             if (context.mounted) {
               context.push('/saga-adventure');
             }
          } catch (e) {
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(e.toString()), backgroundColor: Colors.red.shade900),
              );
            }
          }
        },
      ),
    );
  }

  Widget _buildCoverArt(BuildContext context, Saga saga) {
    if (saga.coverArtUrl == null) return Container(color: Colors.black);

    if (saga.coverArtUrl!.startsWith('assets/')) {
      return Image.asset(saga.coverArtUrl!, fit: BoxFit.cover);
    }
    return Image.network(saga.coverArtUrl!, fit: BoxFit.cover);
  }
}
