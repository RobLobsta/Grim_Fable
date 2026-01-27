import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../shared/widgets/player_action_widget.dart';
import '../../shared/widgets/story_segment_widget.dart';
import 'adventure_provider.dart';
import '../../core/services/settings_service.dart';

class AdventureScreen extends ConsumerStatefulWidget {
  const AdventureScreen({super.key});

  @override
  ConsumerState<AdventureScreen> createState() => _AdventureScreenState();
}

class _AdventureScreenState extends ConsumerState<AdventureScreen> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  bool _isLoading = false;
  String? _errorMessage;
  String? _lastFailedAction;

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

  Future<void> _submitAction({String? retryAction}) async {
    final text = retryAction ?? _controller.text.trim();
    if (text.isEmpty || _isLoading) return;

    if (retryAction == null) {
      _controller.clear();
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _lastFailedAction = null;
    });

    try {
      await ref.read(activeAdventureProvider.notifier).submitAction(text);
      _scrollToBottom();
    } catch (e) {
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

    // Auto scroll when adventure updates
    ref.listen(activeAdventureProvider, (_, __) => _scrollToBottom());

    if (adventure == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

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
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16.0),
              itemCount: adventure.storyHistory.length + (_isLoading ? 1 : 0) + (_errorMessage != null ? 1 : 0),
              itemBuilder: (context, index) {
                if (index < adventure.storyHistory.length) {
                  final segment = adventure.storyHistory[index];
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (index > 0) PlayerActionWidget(input: segment.playerInput),
                      StorySegmentWidget(response: segment.aiResponse),
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
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
              decoration: BoxDecoration(
                color: const Color(0xFF161B22),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.5),
                    blurRadius: 20,
                    offset: const Offset(0, -5),
                  ),
                ],
                border: Border(
                  top: BorderSide(color: const Color(0xFF1A237E).withOpacity(0.3), width: 1),
                ),
              ),
              child: SafeArea(
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _controller,
                        decoration: InputDecoration(
                          hintText: "WHAT IS THY WILL?",
                          hintStyle: TextStyle(
                            color: const Color(0xFFC0C0C0).withOpacity(0.3),
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
                        enabled: !_isLoading,
                        maxLines: null,
                        textInputAction: TextInputAction.send,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      decoration: const BoxDecoration(
                        color: Color(0xFF1A237E),
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.send_rounded),
                        onPressed: _isLoading ? null : _submitAction,
                        color: const Color(0xFFC0C0C0),
                      ),
                    ),
                  ],
                ),
              ),
            )
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
    );
  }
}
