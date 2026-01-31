import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../character/character_provider.dart';
import '../../shared/widgets/ai_settings_dialog.dart';
import '../../shared/widgets/app_settings_dialog.dart';
import '../saga/saga_provider.dart';
import '../../core/models/saga_progress.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  Future<void> _unlockAllChapters() async {
    try {
      final sagas = await ref.read(sagasProvider.future);
      final lob = sagas.firstWhere((s) => s.id == 'legacy_of_blood');
      final repo = ref.read(sagaRepositoryProvider);

      final progress = SagaProgress(
        sagaId: lob.id,
        currentChapterIndex: lob.chapters.length - 1,
        completedChapterIds: lob.chapters.map((c) => c.id).toList(),
        adventureId: 'debug_adventure_${DateTime.now().millisecondsSinceEpoch}',
        mechanicsState: {'corruption': 0.5},
      );

      await repo.saveProgress(progress);
      ref.invalidate(sagaProgressProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('All Legacy of Blood chapters unlocked!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _showDebugMenu() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.lock_open_outlined),
            title: const Text('Unlock All Legacy of Blood Chapters'),
            onTap: () {
              Navigator.pop(context);
              _unlockAllChapters();
            },
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final activeCharacter = ref.watch(activeCharacterProvider);

    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: _showDebugMenu,
        mini: true,
        backgroundColor: Colors.grey.withValues(alpha: 0.2),
        child: const Icon(Icons.bug_report_outlined, size: 20, color: Colors.white54),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.startFloat,
      body: _buildBackgroundContainer(
        child: Column(
          children: [
            _buildAppBar(context, activeCharacter),
            Expanded(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 24.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildHeroIcon(),
                      const SizedBox(height: 40),
                      _buildWelcomeSection(context),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBackgroundContainer({required Widget child}) {
    return Container(
      decoration: BoxDecoration(
        gradient: RadialGradient(
          center: Alignment.center,
          radius: 1.5,
          colors: [
            Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
            Theme.of(context).colorScheme.surface,
          ],
        ),
      ),
      child: SafeArea(child: child),
    );
  }

  Widget _buildAppBar(BuildContext context, dynamic activeCharacter) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: const Text(
              'GRIM FABLE',
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
              style: TextStyle(
                fontFamily: 'Serif',
                fontSize: 20,
                fontWeight: FontWeight.bold,
                letterSpacing: 4,
                color: Color(0xFFC0C0C0),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(Icons.settings_outlined, color: Color(0xFFC0C0C0)),
                onPressed: () => AppSettingsDialog.show(context),
                tooltip: 'App Settings',
              ),
              IconButton(
                icon: const Icon(Icons.vpn_key_outlined, color: Color(0xFFC0C0C0)),
                onPressed: () => AiSettingsDialog.show(context),
                tooltip: 'AI Settings',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHeroIcon() {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.5), width: 2),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.2),
            blurRadius: 30,
            spreadRadius: 10,
          ),
        ],
      ),
      child: Icon(
        Icons.auto_stories_outlined,
        size: 80,
        color: Theme.of(context).colorScheme.secondary,
      ),
    );
  }

  Widget _buildWelcomeSection(BuildContext context) {
    return Column(
      children: [
        Text(
          'Behold, Thy Fate',
          style: Theme.of(context).textTheme.displayLarge?.copyWith(fontSize: 32),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 12),
        Text(
          'Your dark adventure awaits...',
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontStyle: FontStyle.italic),
        ),
        const SizedBox(height: 60),
        ElevatedButton(
          onPressed: () => context.push('/saga-selection'),
          child: const Text('SAGA MODE'),
        ),
        const SizedBox(height: 16),
        ElevatedButton(
          onPressed: () => context.push('/adventure-selection'),
          child: const Text('ADVENTURE MODE'),
        ),
      ],
    );
  }
}
