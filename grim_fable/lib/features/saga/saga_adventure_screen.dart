import 'dart:async';
import 'package:flutter/material.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'saga_provider.dart';
import '../character/character_provider.dart';
import '../../shared/widgets/story_segment_widget.dart';
import '../../shared/widgets/inventory_dialog.dart';
import '../../core/utils/extensions.dart';

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

  Future<void> _submitAction({String? action}) async {
    final text = action ?? _controller.text.trim();
    if (text.isEmpty || _isLoading || _isTyping) return;

    if (action == null) {
      _controller.clear();
    }
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

    final isFullMoon = saga.id == 'night_of_the_full_moon';

    // Subtle corruption effect: parchment turns slightly redder as corruption increases
    final corruption = (progress.mechanicsState['corruption'] ?? 0.0).toDouble();
    final parchmentColor = isFullMoon
        ? const Color(0xFF0D1B2A) // Dark night forest blue
        : Color.lerp(
            const Color(0xFFE5D3B3),
            const Color(0xFF8B0000).withValues(alpha: 0.3),
            corruption,
          ) ??
            const Color(0xFFE5D3B3);

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
              decoration: isFullMoon ? _buildNightDecoration() : _buildParchmentDecoration(),
              child: isFullMoon
                  ? Container(
                      color: parchmentColor,
                      child: _buildHistoryList(adventure, _isLoading, isFullMoon),
                    )
                  : ClipPath(
                      clipper: TatteredEdgeClipper(),
                      child: Container(
                        color: parchmentColor,
                        child: _buildHistoryList(adventure, _isLoading, isFullMoon),
                      ),
                    ),
            ),
          ),
          _buildInputArea(adventure.isActive, corruption, saga.id),
        ],
      ),
    );
  }

  Widget _buildHistoryList(dynamic adventure, bool isLoading, bool isFullMoon) {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(24.0),
      itemCount: adventure.storyHistory.length + (isLoading ? 1 : 0),
      itemBuilder: (context, index) {
        if (index < adventure.storyHistory.length) {
          final segment = adventure.storyHistory[index];
          final isLast = index == adventure.storyHistory.length - 1;
          final isTransition = segment.playerInput.startsWith("Transition to");

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (index > 0 && !isTransition) _buildPlayerAction(segment.playerInput, isFullMoon: isFullMoon),

              if (isTransition) _buildChapterTransitionHeader(isFullMoon: isFullMoon),

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
                  color: isFullMoon ? Colors.white.withValues(alpha: 0.8) : const Color(0xFF2C2C2C),
                  fontSize: 18,
                  height: 1.5,
                ),
                decoration: const BoxDecoration(color: Colors.transparent),
              ),
              // Recommended choices
              if (isLast && segment.recommendedChoices != null && segment.recommendedChoices!.isNotEmpty && adventure.isActive && !_isTyping) ...[
                const SizedBox(height: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: segment.recommendedChoices!
                      .map((choice) => Padding(
                            padding: const EdgeInsets.only(bottom: 8.0),
                            child: ElevatedButton(
                              onPressed: (_isLoading || _isTyping) ? null : () => _submitAction(action: choice),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: isFullMoon ? Colors.white.withValues(alpha: 0.05) : const Color(0xFF4A0000).withValues(alpha: 0.1),
                                foregroundColor: isFullMoon ? const Color(0xFF90E0EF) : const Color(0xFF4A0000),
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  side: BorderSide(color: isFullMoon ? Colors.white.withValues(alpha: 0.1) : const Color(0xFF4A0000).withValues(alpha: 0.3)),
                                ),
                                elevation: 0,
                              ),
                              child: Text(
                                choice.toUpperCase(),
                                style: GoogleFonts.grenze(fontSize: 14, letterSpacing: 2, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ))
                      .toList(),
                ),
              ],
              const SizedBox(height: 24),
            ],
          );
        }
        return Center(child: CircularProgressIndicator(color: isFullMoon ? const Color(0xFF90E0EF) : const Color(0xFF4A0000)));
      },
    );
  }

  Widget _buildChapterTransitionHeader({bool isFullMoon = false}) {
    final color = isFullMoon ? const Color(0xFF90E0EF) : const Color(0xFF4A0000);
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 32),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(child: Divider(color: color, thickness: 1.5)),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  "CHAPTER COMPLETE",
                  style: GoogleFonts.grenze(
                    color: color,
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 4,
                  ),
                ),
              ),
              Expanded(child: Divider(color: color, thickness: 1.5)),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            "THE TALE CONTINUES...",
            style: GoogleFonts.crimsonPro(
              color: color.withValues(alpha: 0.7),
              fontSize: 14,
              fontWeight: FontWeight.bold,
              letterSpacing: 2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlayerAction(String input, {bool isFullMoon = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      child: Text(
        "> $input",
        style: GoogleFonts.grenze(
          color: isFullMoon ? const Color(0xFF62929E) : const Color(0xFF4A0000),
          fontSize: 20,
          fontWeight: FontWeight.bold,
          fontStyle: FontStyle.italic,
        ),
      ),
    );
  }

  BoxDecoration _buildNightDecoration() {
    return BoxDecoration(
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.5),
          blurRadius: 20,
          spreadRadius: 2,
        ),
      ],
    );
  }

  BoxDecoration _buildParchmentDecoration() {
    return BoxDecoration(
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.5),
          blurRadius: 10,
          spreadRadius: 2,
        ),
      ],
    );
  }

  Widget _buildInputArea(bool isActive, double corruption, String sagaId) {
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

    final isOverridden = sagaId == 'legacy_of_blood' && corruption > 0.8;
    final char = ref.read(activeCharacterProvider);

    String hintText = "What will ${char?.name ?? 'you'} do?";
    if (isOverridden) {
      hintText = "The armor's whispers drown out your thoughts...";
    } else if (sagaId == 'night_of_the_full_moon') {
      hintText = "Guide Little Red through the forest...";
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1510),
        border: Border(top: BorderSide(color: Colors.white.withValues(alpha: 0.1))),
      ),
      child: SafeArea(
        child: Row(
          children: [
            IconButton(
              icon: const Icon(Icons.inventory_2_outlined),
              onPressed: () {
                if (char != null) {
                   InventoryDialog.show(context, char.inventory, itemDescriptions: char.itemDescriptions, gold: char.gold);
                }
              },
            ),
            Expanded(
              child: TextField(
                controller: _controller,
                enabled: !isOverridden && !_isLoading && !_isTyping,
                decoration: InputDecoration(
                  hintText: hintText,
                  fillColor: Colors.white.withValues(alpha: 0.05),
                ),
                style: GoogleFonts.crimsonPro(),
                onSubmitted: (_) => _submitAction(),
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(Icons.send_rounded),
              onPressed: isOverridden ? null : _submitAction,
              color: isOverridden ? Colors.grey : Theme.of(context).colorScheme.tertiary,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatChip(IconData icon, String label, dynamic value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Text(
            "$label: $value",
            style: GoogleFonts.grenze(
              color: color.darken(0.2),
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  void _showChronicle(BuildContext context, dynamic saga, dynamic progress) {
    final isFullMoon = saga.id == 'night_of_the_full_moon';
    final primaryColor = isFullMoon ? const Color(0xFF90E0EF) : const Color(0xFF4A0000);
    final textColor = isFullMoon ? Colors.white.withValues(alpha: 0.9) : const Color(0xFF2C2C2C);

    showModalBottomSheet(
      context: context,
      backgroundColor: isFullMoon ? const Color(0xFF0D1B2A) : const Color(0xFFE5D3B3),
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
                  color: primaryColor,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Divider(color: primaryColor),
              const SizedBox(height: 16),
              AutoSizeText(
                "CHAPTER: ${saga.chapters[progress.currentChapterIndex].title.toUpperCase()}",
                style: GoogleFonts.grenze(
                  color: textColor,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 1,
                minFontSize: 14,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),
              if (saga.id == 'legacy_of_blood') ...[
                Builder(builder: (context) {
                  final corruption = (progress.mechanicsState['corruption'] ?? 0.0).toDouble();
                  final displayColor = Color.lerp(Colors.orange, const Color(0xFF4A0000), corruption) ?? Colors.orange;
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "ARMOR'S INFLUENCE: ${(corruption * 100).toInt()}%",
                        style: GoogleFonts.grenze(
                          color: displayColor,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      LinearProgressIndicator(
                        value: corruption,
                        backgroundColor: Colors.black12,
                        color: displayColor,
                        minHeight: 8,
                      ),
                      const SizedBox(height: 16),
                    ],
                  );
                }),
              ],
              if (saga.id == 'night_of_the_full_moon') ...[
                Row(
                  children: [
                    _buildStatChip(Icons.shield, "COURAGE", progress.mechanicsState['courage'] ?? 0, Colors.blueGrey),
                    const SizedBox(width: 12),
                    _buildStatChip(Icons.favorite, "REPUTATION", progress.mechanicsState['reputation'] ?? 0, Colors.teal),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  "MOON PHASE: ${(progress.mechanicsState['moon_phase'] ?? 'Crescent').toString().toUpperCase()}",
                  style: GoogleFonts.grenze(
                    color: textColor,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 16),
              ],
              Text(
                "WITNESSED ANCHORS:",
                style: GoogleFonts.grenze(
                  color: textColor,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Expanded(
                child: ListView.builder(
                  itemCount: progress.witnessedAnchors.length,
                  itemBuilder: (context, index) {
                    return ListTile(
                      leading: Icon(Icons.bookmark, color: primaryColor),
                      title: Text(
                        progress.witnessedAnchors[index],
                        style: GoogleFonts.crimsonPro(color: textColor),
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
