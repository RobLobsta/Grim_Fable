import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'saga_provider.dart';
import '../character/character_provider.dart';
import '../../shared/widgets/story_segment_widget.dart';
import '../../shared/widgets/player_action_widget.dart';
import '../../shared/widgets/inventory_dialog.dart';

class SagaAdventureScreen extends ConsumerStatefulWidget {
  const SagaAdventureScreen({super.key});

  @override
  ConsumerState<SagaAdventureScreen> createState() => _SagaAdventureScreenState();
}

class _SagaAdventureScreenState extends ConsumerState<SagaAdventureScreen> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  bool _isLoading = false;
  bool _isTyping = false;
  final Map<int, String> _animatedTexts = {};

  @override
  void initState() {
    super.initState();
    final adventure = ref.read(activeSagaAdventureProvider);
    if (adventure != null) {
      for (int i = 0; i < adventure.storyHistory.length; i++) {
        _animatedTexts[i] = adventure.storyHistory[i].aiResponse;
      }
    }
    WidgetsBinding.instance.addPostFrameCallback((_) => _jumpToBottom());
  }

  void _jumpToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _submitAction() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _isLoading || _isTyping) return;

    _controller.clear();
    setState(() {
      _isLoading = true;
      _isTyping = true;
    });

    try {
      await ref.read(activeSagaAdventureProvider.notifier).submitSagaAction(text);
      _scrollToBottom();
    } catch (e) {
      if (mounted) {
        setState(() {
          _isTyping = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final saga = ref.watch(activeSagaProvider);
    final adventure = ref.watch(activeSagaAdventureProvider);
    final progress = ref.watch(sagaProgressProvider);

    if (saga == null || adventure == null || progress == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: const Color(0xFF1A1510),
      appBar: AppBar(
        title: Text(saga.title.toUpperCase(), style: GoogleFonts.grenze(letterSpacing: 2)),
        actions: [
          IconButton(
            icon: const Icon(Icons.history_edu),
            onPressed: () => _showChronicle(context, saga, progress),
            tooltip: 'The Chronicle',
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: _buildParchmentDecoration(),
              child: ClipPath(
                clipper: TatteredEdgeClipper(),
                child: Container(
                  color: const Color(0xFFE5D3B3),
                  child: ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(24.0),
                    itemCount: adventure.storyHistory.length + (_isLoading ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index < adventure.storyHistory.length) {
                        final segment = adventure.storyHistory[index];
                        final isLast = index == adventure.storyHistory.length - 1;
                        final isTransition = segment.playerInput.startsWith("Transition to");

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            if (index > 0 && !isTransition)
                               _buildPlayerAction(segment.playerInput),

                            StorySegmentWidget(
                              response: segment.aiResponse,
                              animate: isLast && _animatedTexts[index] == null,
                              onProgress: _scrollToBottom,
                              onFinishedTyping: () {
                                if (isLast && mounted) {
                                  setState(() {
                                    _animatedTexts[index] = segment.aiResponse;
                                    _isTyping = false;
                                  });
                                  _scrollToBottom();
                                }
                              },
                              // Custom text style for parchment
                              textStyle: GoogleFonts.crimsonPro(
                                color: const Color(0xFF2C2C2C),
                                fontSize: 18,
                                height: 1.5,
                              ),
                              decoration: const BoxDecoration(color: Colors.transparent),
                            ),
                            const SizedBox(height: 24),
                          ],
                        );
                      }
                      return const Center(child: CircularProgressIndicator(color: Color(0xFF4A0000)));
                    },
                  ),
                ),
              ),
            ),
          ),
          _buildInputArea(adventure.isActive),
        ],
      ),
    );
  }

  Widget _buildPlayerAction(String input) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      child: Text(
        "> $input",
        style: GoogleFonts.grenze(
          color: const Color(0xFF4A0000),
          fontSize: 20,
          fontWeight: FontWeight.bold,
          fontStyle: FontStyle.italic,
        ),
      ),
    );
  }

  BoxDecoration _buildParchmentDecoration() {
    return BoxDecoration(
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.5),
          blurRadius: 10,
          spreadRadius: 2,
        ),
      ],
    );
  }

  Widget _buildInputArea(bool isActive) {
    if (!isActive) {
      return Container(
        padding: const EdgeInsets.all(24),
        color: const Color(0xFF1A1510),
        child: ElevatedButton(
          onPressed: () => context.pop(),
          child: const Text("CONCLUDE THIS SAGA"),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1510),
        border: Border(top: BorderSide(color: Colors.white.withOpacity(0.1))),
      ),
      child: SafeArea(
        child: Row(
          children: [
            IconButton(
              icon: const Icon(Icons.inventory_2_outlined),
              onPressed: () {
                final char = ref.read(activeCharacterProvider);
                if (char != null) {
                   InventoryDialog.show(context, char.inventory, itemDescriptions: char.itemDescriptions, gold: char.gold);
                }
              },
            ),
            Expanded(
              child: TextField(
                controller: _controller,
                decoration: InputDecoration(
                  hintText: "What will Norrec do?",
                  fillColor: Colors.white.withOpacity(0.05),
                ),
                style: GoogleFonts.crimsonPro(),
                onSubmitted: (_) => _submitAction(),
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(Icons.send_rounded),
              onPressed: _submitAction,
              color: Theme.of(context).colorScheme.tertiary,
            ),
          ],
        ),
      ),
    );
  }

  void _showChronicle(BuildContext context, dynamic saga, dynamic progress) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFFE5D3B3),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "THE CHRONICLE",
                style: GoogleFonts.grenze(
                  color: const Color(0xFF4A0000),
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Divider(color: Color(0xFF4A0000)),
              const SizedBox(height: 16),
              Text(
                "CHAPTER: ${saga.chapters[progress.currentChapterIndex].title}",
                style: GoogleFonts.grenze(
                  color: const Color(0xFF2C2C2C),
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              if (saga.id == 'legacy_of_blood') ...[
                Text(
                  "ARMOR'S INFLUENCE: ${(progress.mechanicsState['corruption'] ?? 0.1 * 100).toInt()}%",
                  style: GoogleFonts.grenze(
                    color: const Color(0xFF4A0000),
                    fontSize: 18,
                  ),
                ),
                LinearProgressIndicator(
                  value: progress.mechanicsState['corruption'] ?? 0.1,
                  backgroundColor: Colors.black12,
                  color: const Color(0xFF4A0000),
                ),
                const SizedBox(height: 16),
              ],
              Text(
                "WITNESSED ANCHORS:",
                style: GoogleFonts.grenze(
                  color: const Color(0xFF2C2C2C),
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Expanded(
                child: ListView.builder(
                  itemCount: progress.witnessedAnchors.length,
                  itemBuilder: (context, index) {
                    return ListTile(
                      leading: const Icon(Icons.bookmark, color: Color(0xFF4A0000)),
                      title: Text(
                        progress.witnessedAnchors[index],
                        style: GoogleFonts.crimsonPro(color: const Color(0xFF2C2C2C)),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class TatteredEdgeClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    var path = Path();
    path.lineTo(0, size.height);

    // Bottom edge
    for (double i = 0; i <= size.width; i += 10) {
      path.lineTo(i, size.height - (i % 20 == 0 ? 5 : 0));
    }

    path.lineTo(size.width, 0);

    // Top edge
    for (double i = size.width; i >= 0; i -= 10) {
      path.lineTo(i, (i % 20 == 0 ? 5 : 0));
    }

    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}
