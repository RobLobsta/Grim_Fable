import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/models/character.dart';
import '../../core/services/ai_provider.dart';
import '../../core/services/settings_service.dart';
import '../../shared/widgets/section_header.dart';
import 'character_provider.dart';

class CharacterCreationScreen extends ConsumerStatefulWidget {
  const CharacterCreationScreen({super.key});

  @override
  ConsumerState<CharacterCreationScreen> createState() => _CharacterCreationScreenState();
}

class _CharacterCreationScreenState extends ConsumerState<CharacterCreationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _backstoryController = TextEditingController();
  bool _isGenerating = false;

  @override
  void dispose() {
    _nameController.dispose();
    _backstoryController.dispose();
    super.dispose();
  }

  Future<void> _showApiKeyDialog(BuildContext context) async {
    final controller = TextEditingController(text: ref.read(hfApiKeyProvider));
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('AI DIVINATION SETTINGS'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Enter thy Hugging Face API Key to unlock the fates.',
              style: TextStyle(fontFamily: 'Serif', fontSize: 14, color: Colors.white70),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              decoration: const InputDecoration(
                labelText: 'API KEY',
                hintText: 'hf_...',
                border: OutlineInputBorder(),
              ),
              obscureText: true,
              style: const TextStyle(fontFamily: 'Serif'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('CANCEL'),
          ),
          ElevatedButton(
            onPressed: () async {
              await ref.read(hfApiKeyProvider.notifier).setApiKey(controller.text.trim());
              if (context.mounted) {
                Navigator.of(context).pop();
                scaffoldMessenger.showSnackBar(
                  const SnackBar(content: Text('The fates have been updated.')),
                );
              }
            },
            child: const Text('SAVE'),
          ),
        ],
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

    setState(() {
      _isGenerating = true;
    });

    try {
      final aiService = ref.read(aiServiceProvider);
      final backstory = await aiService.generateBackstory(_nameController.text.trim());
      setState(() {
        _backstoryController.text = backstory;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: Theme.of(context).colorScheme.error,
            action: SnackBarAction(
              label: 'SET API KEY',
              onPressed: () => _showApiKeyDialog(context),
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
      final character = Character.create(
        name: _nameController.text.trim(),
        backstory: _backstoryController.text.trim(),
      );

      await ref.read(charactersProvider.notifier).addCharacter(character);
      if (mounted) {
        context.pop();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
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
              const Color(0xFF1A237E).withOpacity(0.05),
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
                const SizedBox(height: 48),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const SectionHeader(title: 'BACKSTORY', icon: Icons.history_edu),
                    if (_isGenerating)
                      const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFFC0C0C0)),
                      )
                    else
                      TextButton.icon(
                        onPressed: _generateBackstory,
                        icon: const Icon(Icons.auto_awesome_outlined, size: 18),
                        label: const Text(
                          'AI DIVINATION',
                          style: TextStyle(letterSpacing: 1.2, fontSize: 12),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _backstoryController,
                  maxLines: 8,
                  maxLength: 1000,
                  decoration: const InputDecoration(
                    hintText: 'Describe the events that shaped this soul...',
                    alignLabelWithHint: true,
                    counterStyle: TextStyle(color: Colors.grey, fontSize: 10),
                  ),
                  style: const TextStyle(fontFamily: 'Serif', fontSize: 16, height: 1.6),
                ),
                const SizedBox(height: 60),
                ElevatedButton(
                  onPressed: _saveCharacter,
                  child: const Text('FORGE LEGEND'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

}
