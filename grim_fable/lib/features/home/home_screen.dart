import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../character/character_provider.dart';
import '../adventure/adventure_provider.dart';
import '../../core/services/settings_service.dart';
import '../../shared/widgets/ai_settings_dialog.dart';
import '../../shared/widgets/app_settings_dialog.dart';
import '../../shared/widgets/inventory_dialog.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  bool _isStarting = false;
  bool _isSelectionMode = false;
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

  Future<void> _startNewAdventure() async {
    setState(() {
      _isStarting = true;
    });
    try {
      await ref.read(activeAdventureProvider.notifier).startNewAdventure();
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
    context.push('/adventure');
  }

  @override
  Widget build(BuildContext context) {
    final activeCharacter = ref.watch(activeCharacterProvider);

    if (_isStarting) {
      return _buildLoadingOverlay();
    }

    if (!_isSelectionMode) {
      return _buildWelcomeView(context, activeCharacter);
    }

    return _buildSelectionView(context, activeCharacter);
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

  Widget _buildWelcomeView(BuildContext context, dynamic activeCharacter) {
    return Scaffold(
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

  Widget _buildSelectionView(BuildContext context, dynamic activeCharacter) {
    final allCharacters = ref.watch(charactersProvider);
    final sortedCharacters = [...allCharacters];
    sortedCharacters.sort((a, b) => b.lastPlayedAt.compareTo(a.lastPlayedAt));

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

  Widget _buildBackgroundContainer({required Widget child}) {
    return Container(
      decoration: BoxDecoration(
        gradient: RadialGradient(
          center: Alignment.center,
          radius: 1.5,
          colors: [
            Theme.of(context).colorScheme.primary.withOpacity(0.1),
            Theme.of(context).colorScheme.background,
          ],
        ),
      ),
      child: SafeArea(child: child),
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
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildHeroIcon(),
                const SizedBox(height: 40),
                _buildCharacterSection(context, character),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildPageIndicator(List<dynamic> characters, dynamic activeCharacter) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(
          characters.length,
          (index) => Container(
            margin: const EdgeInsets.symmetric(horizontal: 4),
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: activeCharacter.id == characters[index].id
                  ? Theme.of(context).colorScheme.secondary
                  : Theme.of(context).colorScheme.secondary.withOpacity(0.2),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar(BuildContext context, dynamic activeCharacter) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          GestureDetector(
            onTap: () => setState(() => _isSelectionMode = false),
            child: const Text(
              'GRIM FABLE',
              style: TextStyle(
                fontFamily: 'Serif',
                fontSize: 20,
                fontWeight: FontWeight.bold,
                letterSpacing: 4,
                color: Color(0xFFC0C0C0),
              ),
            ),
          ),
          Row(
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
              if (_isSelectionMode)
                IconButton(
                  icon: const Icon(Icons.person_add_outlined, color: Color(0xFFC0C0C0)),
                  onPressed: () => _navigateToCreation(context),
                  tooltip: 'New Character',
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
        border: Border.all(color: Theme.of(context).colorScheme.primary.withOpacity(0.5), width: 2),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.primary.withOpacity(0.2),
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
          onPressed: () => setState(() => _isSelectionMode = true),
          child: const Text('ADVENTURE MODE'),
        ),
      ],
    );
  }

  Widget _buildCharacterSection(BuildContext context, dynamic activeCharacter) {
    final hasBackstory = activeCharacter.backstory.trim().isNotEmpty;

    return Column(
      children: [
        Text(
          activeCharacter.name.toUpperCase(),
          style: Theme.of(context).textTheme.displayLarge?.copyWith(
                fontSize: 36,
                letterSpacing: 2,
              ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 24),
        _buildBackstoryCard(context, activeCharacter.backstory),
        Align(
          alignment: Alignment.centerRight,
          child: Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: IconButton(
              icon: const Icon(Icons.inventory_2_outlined, color: Color(0xFFC0C0C0), size: 32),
              onPressed: () => InventoryDialog.show(context, activeCharacter.inventory),
              tooltip: 'Inventory',
            ),
          ),
        ),
        const SizedBox(height: 60),
        if (hasBackstory) ...[
          if (ref.watch(hasActiveAdventureProvider))
            ElevatedButton(
              onPressed: _continueAdventure,
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(260, 60),
              ),
              child: const Text('CONTINUE ADVENTURE'),
            )
          else
            ElevatedButton(
              onPressed: () => context.push('/new-adventure'),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(260, 60),
              ),
              child: const Text('NEW ADVENTURE'),
            ),
        ] else ...[
          const Text(
            "Forge a backstory to begin adventures.",
            style: TextStyle(fontStyle: FontStyle.italic, color: Colors.grey),
          ),
          const SizedBox(height: 12),
          TextButton.icon(
            onPressed: () => context.push('/create-character'), // Or a dedicated edit screen if we had one
            icon: const Icon(Icons.auto_awesome, size: 16),
            label: const Text("FORGE BACKSTORY"),
          ),
        ],
        const SizedBox(height: 24),
        TextButton.icon(
          onPressed: () => context.push('/history'),
          icon: const Icon(Icons.history_edu, color: Color(0xFFC0C0C0), size: 20),
          label: const Text(
            'VIEW CHRONICLES',
            style: TextStyle(
              color: Color(0xFFC0C0C0),
              fontFamily: 'Serif',
              fontSize: 14,
              letterSpacing: 2,
              decoration: TextDecoration.underline,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBackstoryCard(BuildContext context, String backstory) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFFC0C0C0), // Silver/Light background for parchment look
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Theme.of(context).colorScheme.primary, width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.6),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      constraints: const BoxConstraints(maxHeight: 250),
      child: Column(
        children: [
          const Icon(Icons.format_quote, color: Colors.black54, size: 32),
          Expanded(
            child: SingleChildScrollView(
              child: Text(
                backstory,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      fontStyle: FontStyle.italic,
                      fontSize: 16,
                      color: Colors.black, // Black text for better contrast on silver
                    ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _navigateToCreation(BuildContext context) {
    context.push('/create-character');
  }
}
