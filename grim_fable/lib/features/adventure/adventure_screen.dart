import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../shared/widgets/player_action_widget.dart';
import '../../shared/widgets/story_segment_widget.dart';
import 'adventure_provider.dart';
import '../character/character_provider.dart';
import '../../core/services/settings_service.dart';
import '../../shared/widgets/ai_settings_dialog.dart';
import '../../shared/widgets/inventory_dialog.dart';

class AdventureScreen extends ConsumerStatefulWidget {
  const AdventureScreen({super.key});

  @override
  ConsumerState<AdventureScreen> createState() => _AdventureScreenState();
}

class _AdventureScreenState extends ConsumerState<AdventureScreen> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  final GlobalKey<StorySegmentWidgetState> _lastSegmentKey = GlobalKey();
  bool _isLoading = false;
  String? _errorMessage;
  String? _lastFailedAction;
  final Map<int, String> _animatedTexts = {};
  bool _isTyping = false;

  @override
  void initState() {
    super.initState();
    // Initialize animated texts with existing history so they don't re-type on load
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final adventure = ref.read(activeAdventureProvider);
      if (adventure != null) {
        setState(() {
          for (int i = 0; i < adventure.storyHistory.length; i++) {
            // Only mark as animated if it's not the very first prompt of a new adventure
            // or if it's already older than a few seconds.
            // For now, let's just mark everything except the last one as animated.
            if (i < adventure.storyHistory.length - 1) {
              _animatedTexts[i] = adventure.storyHistory[i].aiResponse;
            } else {
              // If it's the last one, only mark as animated if it's not "fresh"
              final segment = adventure.storyHistory[i];
              if (DateTime.now().difference(segment.timestamp).inSeconds > 10) {
                _animatedTexts[i] = segment.aiResponse;
              } else {
                _isTyping = true;
              }
            }
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
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

  Future<void> _showCompleteDialog(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Complete Adventure'),
        content: const Text('This will summarize your journey and update your character\'s backstory. You won\'t be able to continue this specific adventure session.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Complete'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
      try {
        await ref.read(activeAdventureProvider.notifier).completeAdventure();
        if (mounted) {
          context.pop();
        }
      } catch (e) {
        if (mounted) {
          setState(() {
            _errorMessage = "Failed to complete adventure: ${e.toString()}";
          });
        }
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  Future<void> _showApiKeyDialog(BuildContext context) async {
    return AiSettingsDialog.show(context);
  }

  Future<void> _handleContinue() async {
    if (_isLoading || _isTyping) return;

    setState(() {
      _isLoading = true;
      _isTyping = true;
      _errorMessage = null;
      _lastFailedAction = null;
    });

    try {
      await ref.read(activeAdventureProvider.notifier).continueAdventure();
      _scrollToBottom();
    } catch (e) {
      if (mounted) {
        setState(() {
          _isTyping = false;
        });
      }
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _lastFailedAction = "Continue";
        });
        _scrollToBottom();
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _submitAction({String? retryAction}) async {
    final text = retryAction ?? _controller.text.trim();
    if (text.isEmpty || _isLoading || _isTyping) return;

    if (retryAction == null) {
      _controller.clear();
    }

    setState(() {
      _isLoading = true;
      _isTyping = true;
      _errorMessage = null;
      _lastFailedAction = null;
    });

    try {
      await ref.read(activeAdventureProvider.notifier).submitAction(text);
      _scrollToBottom();
    } catch (e) {
      if (mounted) {
        setState(() {
          _isTyping = false;
        });
      }
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _lastFailedAction = text;
        });
        _scrollToBottom();
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
    final adventure = ref.watch(activeAdventureProvider);
    final freeFormInput = ref.watch(freeFormInputProvider);
    final recommendedEnabled = ref.watch(recommendedResponsesProvider);

    // Auto scroll when adventure updates
    ref.listen(activeAdventureProvider, (_, __) => _scrollToBottom());

    if (adventure == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final lastSegment = adventure.storyHistory.isNotEmpty ? adventure.storyHistory.last : null;
    final hasChoicesIfRequired = !recommendedEnabled || (lastSegment?.recommendedChoices != null && lastSegment!.recommendedChoices!.isNotEmpty);
    final isPlayerTurn = adventure.isActive && !_isLoading && !_isTyping && hasChoicesIfRequired;

    return Scaffold(
      appBar: AppBar(
        title: Text(adventure.title),
        actions: [
          if (adventure.isActive)
            IconButton(
              icon: const Icon(Icons.done_all),
              onPressed: () => _showCompleteDialog(context),
              tooltip: 'Complete Adventure',
            ),
        ],
      ),
      body: GestureDetector(
        onDoubleTap: () {
          if (_isTyping && hasChoicesIfRequired) {
            _lastSegmentKey.currentState?.skip();
          }
        },
        behavior: HitTestBehavior.translucent,
        child: Column(
          children: [
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.all(16.0),
                itemCount: adventure.storyHistory.length + (_isLoading ? 1 : 0) + (_errorMessage != null ? 1 : 0),
                itemBuilder: (context, index) {
                  if (index < adventure.storyHistory.length) {
                    final segment = adventure.storyHistory[index];
                    final isLast = index == adventure.storyHistory.length - 1;
                    final previousText = _animatedTexts[index] ?? "";
                    final shouldAnimate = isLast && previousText != segment.aiResponse;
                    final animateFromIndex = (shouldAnimate && segment.aiResponse.startsWith(previousText))
                        ? previousText.length
                        : 0;

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (index > 0) PlayerActionWidget(input: segment.playerInput),
                        StorySegmentWidget(
                          key: isLast ? _lastSegmentKey : null,
                          response: segment.aiResponse,
                          animate: shouldAnimate,
                          animateFromIndex: animateFromIndex,
                          onFinishedTyping: () {
                            if (isLast) {
                              if (mounted) {
                                setState(() {
                                  _animatedTexts[index] = segment.aiResponse;
                                  _isTyping = false;
                                });
                                _scrollToBottom();
                              }
                            }
                          },
                        ),
                        // Only show recommended choices for the last segment when typing is finished
                        if (index == adventure.storyHistory.length - 1 &&
                            segment.recommendedChoices != null &&
                            segment.recommendedChoices!.isNotEmpty &&
                            adventure.isActive &&
                            !_isTyping) ...[
                          const SizedBox(height: 16),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: segment.recommendedChoices!.map((choice) => Padding(
                              padding: const EdgeInsets.only(bottom: 8.0),
                              child: ElevatedButton(
                                onPressed: (_isLoading || _isTyping) ? null : () => _submitAction(retryAction: choice),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                                  foregroundColor: Theme.of(context).colorScheme.secondary,
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    side: BorderSide(color: Theme.of(context).colorScheme.primary.withOpacity(0.3)),
                                  ),
                                  elevation: 0,
                                ),
                                child: Text(
                                  choice.toUpperCase(),
                                  style: const TextStyle(fontSize: 12, letterSpacing: 2, fontWeight: FontWeight.bold),
                                ),
                              ),
                            )).toList(),
                          ),
                        ],
                        const SizedBox(height: 32),
                      ],
                    );
                  }

                if (_isLoading && index == adventure.storyHistory.length) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16.0),
                    child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
                  );
                }

                if (_errorMessage != null && (index == adventure.storyHistory.length || (index == adventure.storyHistory.length + 1 && _isLoading))) {
                  return Container(
                    margin: const EdgeInsets.symmetric(vertical: 16),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.red.withOpacity(0.3)),
                    ),
                    child: Column(
                      children: [
                        Text(
                          "THE FATES ARE CRUEL",
                          style: TextStyle(
                            color: Colors.red[300],
                            fontWeight: FontWeight.bold,
                            letterSpacing: 2,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _errorMessage!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontFamily: 'Serif', color: Colors.white70),
                        ),
                        if (_lastFailedAction != null) ...[
                          const SizedBox(height: 16),
                          Wrap(
                            spacing: 8,
                            children: [
                              ElevatedButton.icon(
                                onPressed: () => _submitAction(retryAction: _lastFailedAction),
                                icon: const Icon(Icons.refresh),
                                label: const Text("RETRY"),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.red[900],
                                  foregroundColor: Colors.white,
                                ),
                              ),
                              OutlinedButton.icon(
                                onPressed: () => _showApiKeyDialog(context),
                                icon: const Icon(Icons.vpn_key),
                                label: const Text("SET API KEY"),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: Colors.white,
                                  side: const BorderSide(color: Colors.white38),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  );
                }

                return const SizedBox.shrink();
              },
            ),
          ),
          if (adventure.isActive)
            if (isPlayerTurn)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.5),
                      blurRadius: 20,
                      offset: const Offset(0, -5),
                    ),
                  ],
                  border: Border(
                    top: BorderSide(color: Theme.of(context).colorScheme.primary.withOpacity(0.3), width: 1),
                  ),
                ),
                child: SafeArea(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8.0),
                        child: Row(
                          children: [
                            const Spacer(),
                            // Only show the continue button when not loading and not typing
                            if (!_isLoading && !_isTyping)
                              Expanded(
                                flex: 2,
                                child: ElevatedButton.icon(
                                  onPressed: (_isLoading || _isTyping) ? null : _handleContinue,
                                  icon: const Icon(Icons.arrow_forward_rounded, size: 16),
                                  label: const Text(
                                    "CONTINUE",
                                    style: TextStyle(
                                      letterSpacing: 2,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.5),
                                    foregroundColor: Theme.of(context).colorScheme.secondary,
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                  ),
                                ),
                              )
                            else
                              const Spacer(flex: 2),
                            Expanded(
                              child: Align(
                                alignment: Alignment.centerRight,
                                child: IconButton(
                                  icon: const Icon(Icons.inventory_2_outlined, color: Color(0xFFC0C0C0)),
                                  onPressed: () {
                                    final character = ref.read(activeCharacterProvider);
                                    if (character != null) {
                                      InventoryDialog.show(context, character.inventory);
                                    }
                                  },
                                  tooltip: 'Inventory',
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (freeFormInput)
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _controller,
                                decoration: InputDecoration(
                                    hintText: _isTyping ? "OBSERVING..." : "WHAT IS THY WILL?",
                                  hintStyle: TextStyle(
                                    color: Theme.of(context).colorScheme.secondary.withOpacity(0.3),
                                    letterSpacing: 2,
                                    fontSize: 12,
                                  ),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(30),
                                    borderSide: BorderSide.none,
                                  ),
                                  filled: true,
                                  fillColor: Colors.black.withOpacity(0.3),
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                                ),
                                style: const TextStyle(fontFamily: 'Serif', fontSize: 16),
                                onSubmitted: (_) => _submitAction(),
                                enabled: !_isLoading && !_isTyping,
                                maxLines: null,
                                textInputAction: TextInputAction.send,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Container(
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.primary,
                                shape: BoxShape.circle,
                              ),
                              child: IconButton(
                                icon: const Icon(Icons.send_rounded),
                                onPressed: (_isLoading || _isTyping) ? null : _submitAction,
                                color: Theme.of(context).colorScheme.secondary,
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
              )
            else
              const SizedBox.shrink()
          else
            Container(
              padding: const EdgeInsets.all(24.0),
              width: double.infinity,
              decoration: BoxDecoration(
                color: const Color(0xFF1A1A1A),
                border: Border(top: BorderSide(color: Colors.grey.withOpacity(0.3), width: 2)),
              ),
              child: const Text(
                "This chronicle has ended.",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Serif',
                  fontStyle: FontStyle.italic,
                  color: Colors.grey,
                  fontSize: 16,
                ),
              ),
            ),
        ],
      ),
    ),
    );
  }
}
