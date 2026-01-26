import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/models/character.dart';
import '../../core/services/ai_provider.dart';
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
        Navigator.of(context).pop();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Character'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Identity',
                style: Theme.of(context).textTheme.displayLarge?.copyWith(fontSize: 24),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Character Name',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.person),
                ),
                style: const TextStyle(fontFamily: 'Serif'),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 32),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Backstory',
                    style: Theme.of(context).textTheme.displayLarge?.copyWith(fontSize: 24),
                  ),
                  if (_isGenerating)
                    const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  else
                    TextButton.icon(
                      onPressed: _generateBackstory,
                      icon: const Icon(Icons.auto_awesome),
                      label: const Text('AI Generate'),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _backstoryController,
                maxLines: 10,
                decoration: const InputDecoration(
                  hintText: 'Describe your character\'s origins...',
                ),
                style: const TextStyle(fontFamily: 'Serif', fontSize: 16, height: 1.5),
              ),
              const SizedBox(height: 40),
              ElevatedButton(
                onPressed: _saveCharacter,
                child: const Text('Forge Legend'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
