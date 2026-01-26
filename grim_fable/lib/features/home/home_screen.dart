import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../character/character_provider.dart';
import '../character/character_creation_screen.dart';
import '../adventure/adventure_provider.dart';
import '../adventure/adventure_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  bool _isStarting = false;

  Future<void> _startNewAdventure() async {
    setState(() {
      _isStarting = true;
    });
    try {
      await ref.read(activeAdventureProvider.notifier).startNewAdventure();
      if (mounted) {
        _navigateToAdventure(context);
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
    } finally {
      if (mounted) {
        setState(() {
          _isStarting = false;
        });
      }
    }
  }

  void _navigateToAdventure(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => const AdventureScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final activeCharacter = ref.watch(activeCharacterProvider);

    if (_isStarting) {
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

    return Scaffold(
      appBar: AppBar(
        title: const Text('Grim Fable'),
        actions: [
          if (activeCharacter != null)
            IconButton(
              icon: const Icon(Icons.person_add),
              onPressed: () => _navigateToCreation(context),
              tooltip: 'New Character',
            ),
        ],
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.book_sharp,
                size: 100,
                color: Color(0xFFC0C0C0),
              ),
              const SizedBox(height: 20),
              if (activeCharacter == null) ...[
                Text(
                  'Welcome to Grim Fable',
                  style: Theme.of(context).textTheme.displayLarge?.copyWith(fontSize: 32),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 10),
                Text(
                  'Your dark adventure awaits...',
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                const SizedBox(height: 40),
                ElevatedButton(
                  onPressed: () => _navigateToCreation(context),
                  child: const Text('Begin Journey'),
                ),
              ] else ...[
                Text(
                  activeCharacter.name,
                  style: Theme.of(context).textTheme.displayLarge?.copyWith(fontSize: 40),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A1A1A),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFF1A237E), width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.5),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  constraints: const BoxConstraints(maxHeight: 250),
                  child: SingleChildScrollView(
                    child: Text(
                      activeCharacter.backstory,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            fontStyle: FontStyle.italic,
                            fontSize: 16,
                          ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
                const SizedBox(height: 40),
                ElevatedButton(
                  onPressed: _continueAdventure,
                  child: const Text('Continue Adventure'),
                ),
                const SizedBox(height: 16),
                OutlinedButton(
                  onPressed: _startNewAdventure,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFFC0C0C0),
                    side: const BorderSide(color: Color(0xFFC0C0C0)),
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  ),
                  child: const Text('New Adventure'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _navigateToCreation(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => const CharacterCreationScreen()),
    );
  }
}
