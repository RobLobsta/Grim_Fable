import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/models/character.dart';
import '../../core/services/ai_provider.dart';
import '../../core/services/settings_service.dart';
import '../../shared/widgets/section_header.dart';
import '../../shared/widgets/ai_settings_dialog.dart';
import '../../shared/widgets/inventory_dialog.dart';
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
  Map<String, String> _itemDescriptions = {};
  int _generatedGold = 0;
  bool _isGenerating = false;
  bool _backstoryAccepted = false;
  String? _nameError;
  String? _occupationError;

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
          backgroundColor: const Color(0xFF1A1A2E),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
            side: BorderSide(color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.5)),
          ),
          title: Text(
            'THY DESTINY REVEALED',
            style: GoogleFonts.cinzel(letterSpacing: 2, fontWeight: FontWeight.bold, fontSize: 20),
          ),
          content: SingleChildScrollView(
            child: Text(
              _generatedBackstory,
              style: GoogleFonts.crimsonPro(fontSize: 18, height: 1.6, color: Colors.white.withValues(alpha: 0.9)),
            ),
          ),
          actions: [
            if (isReview)
              TextButton(
                onPressed: () => context.pop(),
                child: Text('CLOSE', style: GoogleFonts.grenze(letterSpacing: 2)),
              )
            else ...[
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    _generatedBackstory = '';
                    _generatedItems = [];
                    _itemDescriptions = {};
                    _generatedGold = 0;
                    _backstoryAccepted = false;
                  });
                  context.pop();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  foregroundColor: Colors.redAccent,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  side: const BorderSide(color: Colors.redAccent, width: 1),
                  elevation: 0,
                ),
                child: Text('DECLINE', style: GoogleFonts.grenze(letterSpacing: 2, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    _backstoryAccepted = true;
                  });
                  context.pop();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: Text('ACCEPT', style: GoogleFonts.grenze(letterSpacing: 2, fontWeight: FontWeight.bold)),
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

    HapticFeedback.mediumImpact();
    try {
      final aiService = ref.read(aiServiceProvider);

      // Validate identity first
      final validation = await aiService.validateIdentity(
        _nameController.text.trim(),
        _occupationController.text.trim(),
      );

      setState(() {
        _nameError = validation.nameError;
        _occupationError = validation.occupationError;
      });

      if (!validation.isValid) {
        if (mounted) {
          String message = 'The fates reject this identity.';
          if (validation.nameError != null && validation.occupationError != null) {
            message = 'Both name and occupation are rejected.';
          } else if (validation.nameError != null) {
            message = 'The name is rejected: ${validation.nameError}';
          } else if (validation.occupationError != null) {
            message = 'The occupation is rejected: ${validation.occupationError}';
          }

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(message),
              backgroundColor: Colors.red.shade900,
            ),
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
      final initialItems = ItemParser.parseGainedItems(fullResponse);
      final backstory = ItemParser.cleanText(fullResponse);
      final gold = GoldParser.parseInitialGold(fullResponse);

      // Verify items and get descriptions
      final verifiedItemsMap = await aiService.verifyItems(initialItems, _occupationController.text.trim());

      setState(() {
        _generatedBackstory = backstory;
        _generatedItems = verifiedItemsMap.keys.toList();
        _itemDescriptions = verifiedItemsMap;
        _generatedGold = gold;
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
        gold: _generatedGold,
        itemDescriptions: _itemDescriptions,
      ).copyWith(inventory: _generatedItems);

      HapticFeedback.heavyImpact();
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
        title: Text('FORGE CHARACTER', style: GoogleFonts.cinzel(letterSpacing: 4, fontWeight: FontWeight.bold)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: Container(
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
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(32.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SectionHeader(
                  title: 'IDENTITY',
                  icon: Icons.badge_outlined,
                  trailing: (_generatedBackstory.isNotEmpty) ? Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.refresh, color: Colors.redAccent, size: 20),
                        onPressed: () {
                          setState(() {
                            _generatedBackstory = '';
                            _generatedItems = [];
                            _itemDescriptions = {};
                            _generatedGold = 0;
                            _backstoryAccepted = false;
                          });
                        },
                        tooltip: 'Re-divine',
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 20),
                        onPressed: () {
                          setState(() {
                            _nameController.clear();
                            _occupationController.clear();
                            _descriptionController.clear();
                            _generatedBackstory = '';
                            _generatedItems = [];
                            _itemDescriptions = {};
                            _generatedGold = 0;
                            _backstoryAccepted = false;
                            _nameError = null;
                            _occupationError = null;
                          });
                        },
                        tooltip: 'Reset Identity',
                      ),
                    ],
                  ) : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _nameController,
                  maxLength: 30,
                  enabled: !_backstoryAccepted,
                  readOnly: _backstoryAccepted,
                  onChanged: (value) {
                    if (_nameError != null) {
                      setState(() => _nameError = null);
                    }
                  },
                  decoration: InputDecoration(
                    labelText: 'NAME',
                    errorText: _nameError,
                    prefixIcon: const Icon(Icons.person_outline),
                    counterStyle: const TextStyle(color: Colors.grey, fontSize: 10),
                    fillColor: _backstoryAccepted ? Colors.white.withValues(alpha: 0.05) : Colors.white.withValues(alpha: 0.02),
                    filled: true,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  style: GoogleFonts.grenze(fontSize: 18, letterSpacing: 1.2),
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
                  enabled: !_backstoryAccepted,
                  readOnly: _backstoryAccepted,
                  onChanged: (value) {
                    if (_occupationError != null) {
                      setState(() => _occupationError = null);
                    }
                  },
                  decoration: InputDecoration(
                    labelText: 'OCCUPATION',
                    errorText: _occupationError,
                    prefixIcon: const Icon(Icons.work_outline),
                    counterStyle: const TextStyle(color: Colors.grey, fontSize: 10),
                    fillColor: _backstoryAccepted ? Colors.white.withValues(alpha: 0.05) : Colors.white.withValues(alpha: 0.02),
                    filled: true,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  style: GoogleFonts.grenze(fontSize: 18, letterSpacing: 1.2),
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
                  enabled: !_backstoryAccepted,
                  readOnly: _backstoryAccepted,
                  decoration: InputDecoration(
                    labelText: 'DESCRIPTION (OPTIONAL)',
                    prefixIcon: const Icon(Icons.description_outlined),
                    counterStyle: const TextStyle(color: Colors.grey, fontSize: 10),
                    hintText: 'e.g., A weary traveler from the north...',
                    fillColor: _backstoryAccepted ? Colors.white.withValues(alpha: 0.05) : Colors.white.withValues(alpha: 0.02),
                    filled: true,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  style: GoogleFonts.grenze(fontSize: 18, letterSpacing: 1.2),
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
                else if (_generatedBackstory.isEmpty || !_backstoryAccepted)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      ElevatedButton.icon(
                        onPressed: hasApiKey ? _generateBackstory : null,
                        icon: Icon(hasApiKey ? Icons.auto_awesome_outlined : Icons.lock_outline, size: 24),
                        label: Text(hasApiKey ? 'AI DIVINATION' : 'KEY REQUIRED'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 24),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                      ),
                    ],
                  )
                else
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      ElevatedButton(
                        onPressed: _saveCharacter,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 24),
                          backgroundColor: Theme.of(context).colorScheme.tertiary,
                          foregroundColor: Colors.black,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        child: Text('FORGE CHARACTER', style: GoogleFonts.cinzel(fontWeight: FontWeight.bold, letterSpacing: 2)),
                      ),
                      const SizedBox(height: 16),
                      Wrap(
                        alignment: WrapAlignment.center,
                        spacing: 16,
                        runSpacing: 8,
                        children: [
                          ElevatedButton.icon(
                            onPressed: () => _showBackstoryDialog(isReview: true),
                            icon: const Icon(Icons.history_edu, size: 18, color: Color(0xFFC0C0C0)),
                            label: const Text('REVIEW BACKSTORY', style: TextStyle(fontSize: 12, color: Color(0xFFC0C0C0))),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.black,
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            ),
                          ),
                          ElevatedButton.icon(
                            onPressed: () {
                              InventoryDialog.show(
                                context,
                                _generatedItems,
                                itemDescriptions: _itemDescriptions,
                                gold: _generatedGold,
                              );
                            },
                            icon: const Icon(Icons.inventory_2_outlined, size: 18, color: Color(0xFFC0C0C0)),
                            label: const Text('INITIAL EQUIPMENT', style: TextStyle(fontSize: 12, color: Color(0xFFC0C0C0))),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.black,
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            ),
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
