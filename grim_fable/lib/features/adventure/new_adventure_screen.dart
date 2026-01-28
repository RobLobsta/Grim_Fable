import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../character/character_provider.dart';
import '../adventure/adventure_provider.dart';
import '../../core/services/ai_provider.dart';

class NewAdventureScreen extends ConsumerStatefulWidget {
  const NewAdventureScreen({super.key});

  @override
  ConsumerState<NewAdventureScreen> createState() => _NewAdventureScreenState();
}

class _NewAdventureScreenState extends ConsumerState<NewAdventureScreen> {
  bool _isLoading = true;
  List<String> _suggestions = [];
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadSuggestions();
  }

  Future<void> _loadSuggestions() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final activeCharacter = ref.read(activeCharacterProvider);
      if (activeCharacter == null) throw Exception("No active character found");

      if (activeCharacter.cachedSuggestions.isNotEmpty) {
        if (mounted) {
          setState(() {
            _suggestions = activeCharacter.cachedSuggestions;
            _isLoading = false;
          });
        }
        return;
      }

      final adventures = ref.read(characterAdventuresProvider);
      final summaries = adventures
          .where((a) => !a.isActive && a.storyHistory.isNotEmpty)
          .map((a) => a.storyHistory.last.aiResponse) // Using last response as summary for now
          .toList();

      final aiService = ref.read(aiServiceProvider);
      final suggestions = await aiService.generateAdventureSuggestions(
        activeCharacter.name,
        activeCharacter.backstory,
        summaries,
      );

      // Cache suggestions
      await ref.read(charactersProvider.notifier).updateCharacter(
            activeCharacter.copyWith(cachedSuggestions: suggestions),
          );

      if (mounted) {
        setState(() {
          _suggestions = suggestions;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _startAdventure(String prompt) async {
    setState(() {
      _isLoading = true;
    });
    try {
      final activeCharacter = ref.read(activeCharacterProvider);
      if (activeCharacter != null) {
        // Clear cached suggestions
        await ref.read(charactersProvider.notifier).updateCharacter(
              activeCharacter.copyWith(cachedSuggestions: []),
            );
      }

      await ref.read(activeAdventureProvider.notifier).startNewAdventure(customPrompt: prompt);
      if (mounted) {
        context.pushReplacement('/adventure', extra: true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
        );
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('DIVINE DESTINY'),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              const Color(0xFF0D1117),
              Theme.of(context).colorScheme.primary.withOpacity(0.1),
            ],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 20),
              Text(
                'The fates present several paths...',
                style: Theme.of(context).textTheme.displaySmall?.copyWith(fontSize: 20, fontStyle: FontStyle.italic),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),
              if (_isLoading)
                const Expanded(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 20),
                        Text('Gazing into the void...', style: TextStyle(fontFamily: 'Serif')),
                      ],
                    ),
                  ),
                )
              else if (_error != null)
                Expanded(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('The vision is clouded: $_error', textAlign: TextAlign.center),
                        const SizedBox(height: 20),
                        ElevatedButton(onPressed: _loadSuggestions, child: const Text('RETRY')),
                      ],
                    ),
                  ),
                )
              else
                Expanded(
                  child: ListView.separated(
                    itemCount: _suggestions.length,
                    separatorBuilder: (context, index) => const SizedBox(height: 20),
                    itemBuilder: (context, index) {
                      return ElevatedButton(
                        onPressed: () => _startAdventure(_suggestions[index]),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.all(24),
                          alignment: Alignment.centerLeft,
                        ),
                        child: Text(
                          _suggestions[index],
                          style: const TextStyle(
                            fontSize: 16,
                            height: 1.4,
                            letterSpacing: 0.5,
                          ),
                        ),
                      );
                    },
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
