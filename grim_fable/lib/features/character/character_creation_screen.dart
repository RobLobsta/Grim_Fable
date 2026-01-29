import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/models/character.dart';
import '../../core/services/ai_provider.dart';
import '../../core/services/settings_service.dart';
import '../../shared/widgets/section_header.dart';
import '../../shared/widgets/ai_settings_dialog.dart';
import '../../core/utils/item_parser.dart';
import 'character_provider.dart';

class CharacterCreationScreen extends ConsumerStatefulWidget {
  const CharacterCreationScreen({super.key});

  @override
  ConsumerState<CharacterCreationScreen> createState() => _CharacterCreationScreenState();
}

class _CharacterCreationScreenState extends ConsumerState<CharacterCreationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _occupationController = TextEditingController();
  final _descriptionController = TextEditingController();
  String _generatedBackstory = '';
  List<String> _generatedItems = [];
  bool _isGenerating = false;

  @override
  void dispose() {
    _nameController.dispose();
    _occupationController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _showBackstoryDialog({bool isReview = false}) {
    showDialog(
      context: context,
      barrierDismissible: isReview,
      builder: (context) => PopScope(
        canPop: isReview,
        child: AlertDialog(
          title: const Text('THY DESTINY REVEALED', style: TextStyle(fontFamily: 'Serif', letterSpacing: 2)),
          content: SingleChildScrollView(
            child: Text(
              _generatedBackstory,
              style: const TextStyle(fontFamily: 'Serif', fontSize: 16, height: 1.6),
            ),
          ),
          actions: [
            if (isReview)
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('CLOSE'),
              )
            else ...[
              TextButton(
                onPressed: () {
                  setState(() {
                    _generatedBackstory = '';
                    _generatedItems = [];
                  });
                  Navigator.pop(context);
                },
                child: const Text('DECLINE', style: TextStyle(color: Colors.redAccent)),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('ACCEPT'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _generateBackstory() async {
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a name first')),
      );
      return;
    }

    if (_occupationController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('A hero must have a trade... enter an occupation')),
      );
      return;
    }

    setState(() {
      _isGenerating = true;
    });

    try {
      final aiService = ref.read(aiServiceProvider);

      // Validate identity first
      final isValid = await aiService.validateIdentity(
        _nameController.text.trim(),
        _occupationController.text.trim(),
      );

      if (!isValid) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('The fates reject this name or occupation. Ensure they are natural and fit this world.')),
          );
          setState(() {
            _isGenerating = false;
          });
        }
        return;
      }

      final fullResponse = await aiService.generateBackstory(
        _nameController.text.trim(),
        _occupationController.text.trim(),
        description: _descriptionController.text.trim(),
      );

      // Parse items and backstory
      final items = ItemParser.parseGainedItems(fullResponse);
      final backstory = ItemParser.cleanText(fullResponse);

      setState(() {
        _generatedBackstory = backstory;
        _generatedItems = items;
      });

      if (mounted) {
        _showBackstoryDialog();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: Theme.of(context).colorScheme.error,
            action: SnackBarAction(
              label: 'SET API KEY',
              onPressed: () => AiSettingsDialog.show(context),
            ),
          ),
        );
      }
    } finally {
      setState(() {
        _isGenerating = false;
      });
    }
  }

  Future<void> _saveCharacter() async {
    if (_formKey.currentState!.validate()) {
      if (_generatedBackstory.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('A LEGEND REQUIRES A PAST')),
        );
        return;
      }

      final character = Character.create(
        name: _nameController.text.trim(),
        occupation: _occupationController.text.trim(),
        backstory: _generatedBackstory,
      ).copyWith(inventory: _generatedItems);

      await ref.read(charactersProvider.notifier).addCharacter(character);

      if (mounted) {
        context.pop();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasApiKey = ref.watch(hfApiKeyProvider).isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        title: const Text('FORGE CHARACTER'),
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
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(32.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SectionHeader(title: 'IDENTITY', icon: Icons.badge_outlined),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _nameController,
                  maxLength: 30,
                  decoration: const InputDecoration(
                    labelText: 'NAME',
                    prefixIcon: Icon(Icons.person_outline),
                    counterStyle: TextStyle(color: Colors.grey, fontSize: 10),
                  ),
                  style: const TextStyle(fontFamily: 'Serif', letterSpacing: 1.2),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'THE NAMELESS CANNOT BE FORGED';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _occupationController,
                  maxLength: 40,
                  decoration: const InputDecoration(
                    labelText: 'OCCUPATION',
                    prefixIcon: Icon(Icons.work_outline),
                    counterStyle: TextStyle(color: Colors.grey, fontSize: 10),
                  ),
                  style: const TextStyle(fontFamily: 'Serif', letterSpacing: 1.2),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'ONE MUST HAVE A PURPOSE IN THIS DARK WORLD';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _descriptionController,
                  maxLength: 100,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'DESCRIPTION (OPTIONAL)',
                    prefixIcon: Icon(Icons.description_outlined),
                    counterStyle: TextStyle(color: Colors.grey, fontSize: 10),
                    hintText: 'e.g., A weary traveler from the north...',
                  ),
                  style: const TextStyle(fontFamily: 'Serif', letterSpacing: 1.2),
                ),
                const SizedBox(height: 60),
                if (_isGenerating)
                  const Center(
                    child: Column(
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 16),
                        Text('CONSULTING THE FATES...', style: TextStyle(fontFamily: 'Serif', letterSpacing: 2, fontSize: 12)),
                      ],
                    ),
                  )
                else if (_generatedBackstory.isEmpty)
                  ElevatedButton.icon(
                    onPressed: hasApiKey ? _generateBackstory : null,
                    icon: Icon(hasApiKey ? Icons.auto_awesome_outlined : Icons.lock_outline),
                    label: Text(hasApiKey ? 'AI DIVINATION' : 'KEY REQUIRED'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 24),
                    ),
                  )
                else
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      ElevatedButton(
                        onPressed: _saveCharacter,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 24),
                          backgroundColor: Theme.of(context).colorScheme.secondary,
                          foregroundColor: Theme.of(context).colorScheme.onSecondary,
                        ),
                        child: const Text('FORGE CHARACTER'),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          TextButton.icon(
                            onPressed: () => _showBackstoryDialog(isReview: true),
                            icon: const Icon(Icons.history_edu, size: 18),
                            label: const Text('REVIEW BACKSTORY', style: TextStyle(fontSize: 12)),
                          ),
                          const SizedBox(width: 16),
                          TextButton.icon(
                            onPressed: () => setState(() {
                              _generatedBackstory = '';
                              _generatedItems = [];
                            }),
                            icon: const Icon(Icons.refresh, size: 18, color: Colors.redAccent),
                            label: const Text('RE-DIVINE', style: TextStyle(fontSize: 12, color: Colors.redAccent)),
                          ),
                        ],
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

}
