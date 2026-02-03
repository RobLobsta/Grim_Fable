import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
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
      final repo = ref.read(sagaRepositoryProvider);

      for (final saga in sagas) {
        final progress = SagaProgress(
          sagaId: saga.id,
          currentChapterIndex: saga.chapters.length - 1,
          completedChapterIds: saga.chapters.map((c) => c.id).toList(),
          adventureId: 'debug_adventure_${saga.id}_${DateTime.now().millisecondsSinceEpoch}',
          mechanicsState: saga.id == 'legacy_of_blood'
              ? {'corruption': 0.5}
              : {'courage': 10, 'reputation': 10, 'moon_phase': 'Full Moon'},
        );
        await repo.saveProgress(progress);
      }

      ref.invalidate(sagaProgressProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('All Saga chapters unlocked!')),
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
            title: const Text('Unlock All Saga Chapters'),
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
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          stops: const [0.0, 0.5, 1.0],
          colors: [
            Theme.of(context).colorScheme.surface,
            Theme.of(context).colorScheme.primary.withValues(alpha: 0.15),
            Theme.of(context).colorScheme.surface,
          ],
        ),
      ),
      child: SafeArea(child: child),
    );
  }

  Widget _buildAppBar(BuildContext context, dynamic activeCharacter) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Row(
        children: [
          Expanded(
            child: Text(
              'GRIM FABLE',
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
              style: GoogleFonts.cinzel(
                fontSize: 22,
                fontWeight: FontWeight.w900,
                letterSpacing: 6,
                color: const Color(0xFFE0E0E0),
                shadows: [
                  Shadow(
                    color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.5),
                    blurRadius: 10,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _AppBarButton(
                icon: Icons.settings_outlined,
                onPressed: () => AppSettingsDialog.show(context),
                tooltip: 'App Settings',
              ),
              const SizedBox(width: 12),
              _AppBarButton(
                icon: Icons.vpn_key_outlined,
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
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [
            Theme.of(context).colorScheme.primary.withValues(alpha: 0.2),
            Colors.transparent,
          ],
        ),
        border: Border.all(
          color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
          width: 1.5,
        ),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Icon(
            Icons.auto_stories,
            size: 100,
            color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.2),
          ),
          Icon(
            Icons.auto_stories_outlined,
            size: 80,
            color: Theme.of(context).colorScheme.secondary,
          ),
        ],
      ),
    );
  }

  Widget _buildWelcomeSection(BuildContext context) {
    return Column(
      children: [
        Text(
          'BEHOLD, THY FATE',
          style: GoogleFonts.cinzel(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            letterSpacing: 4,
            color: Colors.white,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 12),
        Text(
          'A dark odyssey in the palm of thy hand...',
          style: GoogleFonts.crimsonPro(
            fontSize: 18,
            fontStyle: FontStyle.italic,
            color: Colors.white70,
          ),
        ),
        const SizedBox(height: 64),
        _ModeCard(
          title: 'SAGA MODE',
          subtitle: 'Guided Narrative Experiences',
          icon: Icons.auto_stories,
          onTap: () => context.push('/saga-selection'),
        ),
        const SizedBox(height: 20),
        _ModeCard(
          title: 'ADVENTURE MODE',
          subtitle: 'Forge Your Own Legend',
          icon: Icons.fort,
          onTap: () => context.push('/adventure-selection'),
        ),
      ],
    );
  }
}

class _AppBarButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;
  final String tooltip;

  const _AppBarButton({
    required this.icon,
    required this.onPressed,
    required this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: IconButton(
        icon: Icon(icon, color: const Color(0xFFC0C0C0), size: 20),
        onPressed: onPressed,
        tooltip: tooltip,
        constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
      ),
    );
  }
}

class _ModeCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;

  const _ModeCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.4)),
            gradient: LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [
                Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                Colors.transparent,
              ],
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: Theme.of(context).colorScheme.tertiary, size: 28),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.grenze(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 2,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: GoogleFonts.crimsonPro(
                        fontSize: 14,
                        color: Colors.white60,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios, color: Colors.white24, size: 16),
            ],
          ),
        ),
      ),
    );
  }
}
