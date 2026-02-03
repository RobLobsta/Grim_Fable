import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../character/character_provider.dart';
import '../adventure/adventure_provider.dart';
import '../../core/services/settings_service.dart';
import '../../shared/widgets/ai_settings_dialog.dart';
import '../../shared/widgets/app_settings_dialog.dart';
import '../../shared/widgets/inventory_dialog.dart';
import '../../shared/widgets/backstory_dialog.dart';

class AdventureSelectionScreen extends ConsumerStatefulWidget {
  const AdventureSelectionScreen({super.key});

  @override
  ConsumerState<AdventureSelectionScreen> createState() => _AdventureSelectionScreenState();
}

class _AdventureSelectionScreenState extends ConsumerState<AdventureSelectionScreen> {
  bool _isStarting = false;
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _continueAdventure() async {
    setState(() {
      _isStarting = true;
    });
    try {
      await ref.read(activeAdventureProvider.notifier).continueLatestAdventure();
      if (mounted) {
        _navigateToAdventure(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isStarting = false;
        });
      }
    }
  }

  void _navigateToAdventure(BuildContext context) {
    context.push('/adventure', extra: false);
  }

  void _navigateToCreation(BuildContext context) {
    context.push('/create-character');
  }

  @override
  Widget build(BuildContext context) {
    final activeCharacter = ref.watch(activeCharacterProvider);
    final allCharacters = ref.watch(charactersProvider);
    final sortedCharacters = allCharacters.where((c) => !c.isSagaCharacter).toList();
    sortedCharacters.sort((a, b) => b.lastPlayedAt.compareTo(a.lastPlayedAt));

    // If current selection is a Saga character, switch to first available adventure character
    if (activeCharacter != null && activeCharacter.isSagaCharacter && sortedCharacters.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(selectedCharacterIdProvider.notifier).state = sortedCharacters.first.id;
      });
    }

    if (_isStarting) {
      return _buildLoadingOverlay();
    }

    return Scaffold(
      body: _buildBackgroundContainer(
        child: Column(
          children: [
            _buildAppBar(context, activeCharacter),
            Expanded(
              child: sortedCharacters.isEmpty
                  ? _buildEmptyState(context)
                  : _buildCharacterPager(sortedCharacters, activeCharacter),
            ),
            if (activeCharacter != null && sortedCharacters.length > 1)
              _buildPageIndicator(sortedCharacters, activeCharacter),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingOverlay() {
    return const Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 20),
            Text(
              'Consulting the fates...',
              style: TextStyle(fontFamily: 'Serif', fontSize: 18),
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
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        children: [
          _AppBarButton(
            icon: Icons.arrow_back,
            onPressed: () => context.pop(),
            tooltip: 'Back to Main Menu',
          ),
          const Spacer(),
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
              const SizedBox(width: 12),
              _AppBarButton(
                icon: Icons.person_add_outlined,
                onPressed: () => _navigateToCreation(context),
                tooltip: 'New Character',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildHeroIcon(),
          const SizedBox(height: 40),
          Text(
            'NO LEGENDS FOUND',
            style: Theme.of(context).textTheme.displaySmall?.copyWith(fontSize: 20),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () => _navigateToCreation(context),
            child: const Text('FORGE FIRST CHARACTER'),
          ),
        ],
      ),
    );
  }

  Widget _buildCharacterPager(List<dynamic> characters, dynamic activeCharacter) {
    return PageView.builder(
      controller: _pageController,
      itemCount: characters.length,
      onPageChanged: (index) {
        ref.read(selectedCharacterIdProvider.notifier).state = characters[index].id;
      },
      itemBuilder: (context, index) {
        final character = characters[index];
        return Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 24.0),
            child: _buildCharacterSection(context, character),
          ),
        );
      },
    );
  }

  Widget _buildCharacterSection(BuildContext context, dynamic activeCharacter) {
    final hasBackstory = activeCharacter.backstory.trim().isNotEmpty;
    final hasApiKey = ref.watch(hfApiKeyProvider).isNotEmpty;

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.03),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.2)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            children: [
              _buildHeroIcon(),
              const SizedBox(height: 32),
              Text(
                activeCharacter.name.toUpperCase(),
                style: GoogleFonts.cinzel(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 4,
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                activeCharacter.occupation.toUpperCase(),
                style: GoogleFonts.grenze(
                  fontSize: 18,
                  letterSpacing: 2,
                  color: Theme.of(context).colorScheme.tertiary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 32),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _ActionButton(
                    icon: Icons.description_outlined,
                    label: 'STORY',
                    onPressed: () => BackstoryDialog.show(context, activeCharacter),
                  ),
                  const SizedBox(width: 16),
                  _ActionButton(
                    icon: Icons.inventory_2_outlined,
                    label: 'GEAR',
                    onPressed: () => InventoryDialog.show(
                      context,
                      activeCharacter.inventory,
                      itemDescriptions: activeCharacter.itemDescriptions,
                      gold: activeCharacter.gold,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 48),
        if (hasBackstory) ...[
          if (ref.watch(hasActiveAdventureProvider))
            ElevatedButton(
              onPressed: hasApiKey ? _continueAdventure : null,
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(280, 70),
                backgroundColor: Theme.of(context).colorScheme.primary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: Text(hasApiKey ? 'CONTINUE ADVENTURE' : 'KEY REQUIRED'),
            )
          else
            ElevatedButton(
              onPressed: hasApiKey ? () => context.push('/new-adventure') : null,
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(280, 70),
                backgroundColor: Theme.of(context).colorScheme.primary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: Text(hasApiKey ? 'NEW ADVENTURE' : 'KEY REQUIRED'),
            ),
        ],
        if (ref.watch(characterAdventuresProvider).any((a) => !a.isActive)) ...[
          const SizedBox(height: 24),
          TextButton.icon(
            onPressed: () => context.push('/history'),
            icon: const Icon(Icons.history_edu, color: Colors.white54, size: 20),
            label: Text(
              'VIEW CHRONICLES',
              style: GoogleFonts.grenze(
                color: Colors.white54,
                fontSize: 16,
                letterSpacing: 2,
                decoration: TextDecoration.underline,
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildHeroIcon() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [
            Theme.of(context).colorScheme.primary.withValues(alpha: 0.2),
            Colors.transparent,
          ],
        ),
        border: Border.all(color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3), width: 1),
      ),
      child: Icon(
        Icons.person_outline,
        size: 64,
        color: Theme.of(context).colorScheme.secondary,
      ),
    );
  }

  Widget _buildPageIndicator(List<dynamic> characters, dynamic activeCharacter) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 40.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(
          characters.length,
          (index) => AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            margin: const EdgeInsets.symmetric(horizontal: 4),
            width: activeCharacter.id == characters[index].id ? 24 : 8,
            height: 8,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(4),
              color: activeCharacter.id == characters[index].id
                  ? Theme.of(context).colorScheme.tertiary
                  : Colors.white24,
            ),
          ),
        ),
      ),
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

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 18),
      label: Text(label, style: const TextStyle(fontSize: 12, letterSpacing: 1)),
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        side: BorderSide(color: Colors.white.withValues(alpha: 0.2)),
        foregroundColor: Colors.white70,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}
