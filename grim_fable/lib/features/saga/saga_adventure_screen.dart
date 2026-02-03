import 'dart:async';
import 'package:flutter/material.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'saga_provider.dart';
import '../../core/models/saga_progress.dart';
import '../character/character_provider.dart';
import '../../shared/widgets/story_segment_widget.dart';
import '../../shared/widgets/night_forest_painter.dart';
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
        // If it's a brand new adventure (created in the last 30 seconds) and it's the first segment,
        // don't mark it as animated so the typewriter effect plays.
        final isVeryNew = DateTime.now().difference(adventure.createdAt).inSeconds < 30;
        final isFirstSegment = i == 0 && adventure.storyHistory.length == 1;

        if (isVeryNew && isFirstSegment) {
          _isTyping = true;
          continue;
        }
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
    final isBhaal = saga.id == 'throne_of_bhaal';
    final isDarkTheme = isFullMoon || isBhaal;

    // Subtle mechanics effects on background color
    final corruption = (progress.mechanicsState['corruption'] ?? 0.0).toDouble();
    final infamy = (progress.mechanicsState['infamy'] ?? 0).toDouble();
    final infamyFactor = (infamy / 15.0).clamp(0.0, 1.0);

    final parchmentColor = isFullMoon
        ? const Color(0xFF0D1B2A) // Dark night forest blue
        : isBhaal
            ? Color.lerp(
                const Color(0xFF1A1A1A), // Dark charcoal
                const Color(0xFF4A0000), // Deep blood-red
                infamyFactor,
              )!
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
              clipBehavior: Clip.antiAlias,
              decoration: isDarkTheme ? _buildNightDecoration() : _buildParchmentDecoration(),
              child: isDarkTheme
                  ? Stack(
                      children: [
                        Container(color: parchmentColor),
                        if (isFullMoon) ...[
                          // Forest background with custom tree silhouettes
                          Positioned.fill(
                            child: Opacity(
                              opacity: 0.4,
                              child: CustomPaint(
                                painter: NightForestPainter(),
                              ),
                            ),
                          ),
                        ],
                        if (isBhaal) ...[
                          // Throne of Bhaal cover art overlay
                          Positioned.fill(
                            child: Opacity(
                              opacity: (infamyFactor * 0.3).clamp(0.0, 0.3),
                              child: Image.asset(
                                saga.coverArtUrl ?? 'assets/sagas/throne_of_bhaal.webp',
                                fit: BoxFit.cover,
                                alignment: Alignment.center,
                              ),
                            ),
                          ),
                        ],
                        // Atmospheric mist/gradient at the bottom to ground the silhouettes
                        Positioned(
                          bottom: 0,
                          left: 0,
                          right: 0,
                          height: 300,
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Colors.transparent,
                                  Colors.black.withValues(alpha: isFullMoon ? 0.6 : 0.4),
                                ],
                              ),
                            ),
                          ),
                        ),
                        _buildHistoryList(adventure, _isLoading, isDarkTheme, saga, progress),
                      ],
                    )
                  : ClipPath(
                      clipper: TatteredEdgeClipper(),
                      child: Container(
                        color: parchmentColor,
                        child: _buildHistoryList(adventure, _isLoading, isDarkTheme, saga, progress),
                      ),
                    ),
            ),
          ),
          _buildInputArea(adventure.isActive, corruption, saga.id, progress),
        ],
      ),
    );
  }

  Widget _buildHistoryList(dynamic adventure, bool isLoading, bool isDarkTheme, dynamic saga, SagaProgress? progress) {
    final inConversation = progress?.mechanicsState['active_conversation_partner'] != null;
    final isBhaal = saga.id == 'throne_of_bhaal';
    final showChoices = !isBhaal || !inConversation;

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(24.0),
      itemCount: adventure.storyHistory.length + (isLoading ? 1 : 0),
      itemBuilder: (context, index) {
        if (index < adventure.storyHistory.length) {
          final segment = adventure.storyHistory[index];
          final isLast = index == adventure.storyHistory.length - 1;
          final isTransition = segment.playerInput.startsWith("Transition to");
          final isStart = index == 0 && segment.playerInput.startsWith("Begin the Saga");

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (isStart) _buildChapterArt(saga.chapters[0]),

              if (index > 0 && !isTransition) _buildPlayerAction(segment.playerInput, isDarkTheme: isDarkTheme),

              if (isTransition) ...[
                _buildChapterTransitionHeader(isDarkTheme: isDarkTheme),
                _buildChapterArtFromTitle(segment.playerInput.replaceFirst("Transition to ", ""), saga),
              ],

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
                  color: isDarkTheme ? Colors.white.withValues(alpha: 0.8) : const Color(0xFF2C2C2C),
                  fontSize: 18,
                  height: 1.5,
                ),
                decoration: const BoxDecoration(color: Colors.transparent),
              ),
              // Recommended choices
              if (isLast && adventure.isActive && !_isTyping && showChoices) ...[
                Builder(builder: (context) {
                  final choices = List<String>.from(segment.recommendedChoices ?? []);
                  if (isBhaal && choices.isEmpty) {
                    choices.add("Keep Moving");
                  }

                  if (choices.isEmpty) return const SizedBox.shrink();

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: 16),
                      ...choices.map((choice) => Padding(
                            padding: const EdgeInsets.only(bottom: 8.0),
                            child: ElevatedButton(
                              onPressed: (_isLoading || _isTyping) ? null : () => _submitAction(action: choice),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: isDarkTheme ? Colors.white.withValues(alpha: 0.05) : const Color(0xFF4A0000).withValues(alpha: 0.1),
                                foregroundColor: isDarkTheme ? const Color(0xFF90E0EF) : const Color(0xFF4A0000),
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  side: BorderSide(color: isDarkTheme ? Colors.white.withValues(alpha: 0.1) : const Color(0xFF4A0000).withValues(alpha: 0.3)),
                                ),
                                elevation: 0,
                              ),
                              child: Text(
                                choice.toUpperCase(),
                                style: GoogleFonts.grenze(fontSize: 14, letterSpacing: 2, fontWeight: FontWeight.bold),
                              ),
                            ),
                          )),
                    ],
                  );
                }),
              ],
              const SizedBox(height: 24),
            ],
          );
        }
        return Center(child: CircularProgressIndicator(color: isDarkTheme ? const Color(0xFF90E0EF) : const Color(0xFF4A0000)));
      },
    );
  }

  Widget _buildChapterArtFromTitle(String title, dynamic saga) {
    final chapter = saga.chapters.where((c) => c.title == title).firstOrNull;
    if (chapter == null) return const SizedBox.shrink();
    return _buildChapterArt(chapter);
  }

  Widget _buildChapterArt(dynamic chapter) {
    final artUrl = chapter.chapterArtUrl;
    if (artUrl == null) return const SizedBox.shrink();

    return Container(
      height: 180,
      margin: const EdgeInsets.only(bottom: 24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        image: DecorationImage(
          image: artUrl.startsWith('assets/') ? AssetImage(artUrl) as ImageProvider : NetworkImage(artUrl) as ImageProvider,
          fit: BoxFit.cover,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
    );
  }

  Widget _buildChapterTransitionHeader({bool isDarkTheme = false}) {
    final color = isDarkTheme ? const Color(0xFF90E0EF) : const Color(0xFF4A0000);
    return Container(
      padding: const EdgeInsets.only(top: 32, bottom: 16),
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

  Widget _buildPlayerAction(String input, {bool isDarkTheme = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      child: Text(
        "> $input",
        style: GoogleFonts.grenze(
          color: isDarkTheme ? const Color(0xFF62929E) : const Color(0xFF4A0000),
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

  Widget _buildInputArea(bool isActive, double corruption, String sagaId, SagaProgress? progress) {
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
    final partner = progress?.mechanicsState['active_conversation_partner'];
    final inConversation = partner != null;
    final isBhaal = sagaId == 'throne_of_bhaal';

    // If Bhaal and NOT in conversation, hide the text input
    final showTextInput = !isBhaal || inConversation;

    String hintText = "What will ${char?.name ?? 'you'} do?";
    if (isOverridden) {
      hintText = "The armor's whispers drown out your thoughts...";
    } else if (sagaId == 'night_of_the_full_moon') {
      hintText = "Guide Little Red through the forest...";
    } else if (isBhaal) {
      hintText = inConversation ? "Say to $partner..." : "Choose an action above...";
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
            if (showTextInput) ...[
              Expanded(
                child: TextField(
                  controller: _controller,
                  enabled: !isOverridden && !_isLoading && !_isTyping,
                  decoration: InputDecoration(
                    hintText: hintText,
                    prefixIcon: isBhaal && inConversation ? const Icon(Icons.chat_bubble_outline, size: 20) : null,
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
            ] else ...[
              Expanded(
                child: Center(
                  child: Text(
                    _isTyping ? "THE FATES ARE SPEAKING..." : "EXPLORATION MODE",
                    style: GoogleFonts.grenze(
                      color: Colors.white.withValues(alpha: 0.3),
                      letterSpacing: 2,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
            ],
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
    final isBhaal = saga.id == 'throne_of_bhaal';
    final isDarkTheme = isFullMoon || isBhaal;
    final primaryColor = isDarkTheme ? const Color(0xFF90E0EF) : const Color(0xFF4A0000);
    final textColor = isDarkTheme ? Colors.white.withValues(alpha: 0.9) : const Color(0xFF2C2C2C);

    showModalBottomSheet(
      context: context,
      backgroundColor: isDarkTheme
          ? (isBhaal ? const Color(0xFF1A1A1A) : const Color(0xFF0D1B2A))
          : const Color(0xFFE5D3B3),
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
              if (saga.id == 'throne_of_bhaal') ...[
                _buildStatChip(
                  Icons.local_fire_department,
                  "INFAMY",
                  progress.mechanicsState['infamy'] ?? 0,
                  Colors.deepOrange,
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
