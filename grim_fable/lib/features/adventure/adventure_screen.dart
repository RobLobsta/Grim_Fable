import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'adventure_provider.dart';

class AdventureScreen extends ConsumerStatefulWidget {
  const AdventureScreen({super.key});

  @override
  ConsumerState<AdventureScreen> createState() => _AdventureScreenState();
}

class _AdventureScreenState extends ConsumerState<AdventureScreen> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  bool _isLoading = false;

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
      });
      try {
        await ref.read(activeAdventureProvider.notifier).completeAdventure();
        if (mounted) {
          Navigator.of(context).pop();
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

  Future<void> _submitAction() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _isLoading) return;

    _controller.clear();
    setState(() {
      _isLoading = true;
    });

    try {
      await ref.read(activeAdventureProvider.notifier).submitAction(text);
      _scrollToBottom();
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
              itemCount: adventure.storyHistory.length + (_isLoading ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == adventure.storyHistory.length) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16.0),
                    child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
                  );
                }

                final segment = adventure.storyHistory[index];
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (index > 0) // Don't show the initial "Starting journey" input
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                        child: Text(
                          "> ${segment.playerInput}",
                          style: const TextStyle(
                            color: Color(0xFFC0C0C0),
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Serif',
                            fontSize: 16,
                          ),
                        ),
                      ),
                    MarkdownBody(
                      data: segment.aiResponse,
                      styleSheet: MarkdownStyleSheet(
                        p: Theme.of(context).textTheme.bodyLarge?.copyWith(height: 1.5),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                );
              },
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            decoration: BoxDecoration(
              color: const Color(0xFF0D1117),
              border: Border(top: BorderSide(color: const Color(0xFF1A237E).withOpacity(0.5), width: 2)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: const InputDecoration(
                      hintText: "What do you do?",
                      border: InputBorder.none,
                      filled: false,
                    ),
                    style: const TextStyle(fontFamily: 'Serif', fontSize: 16),
                    onSubmitted: (_) => _submitAction(),
                    enabled: !_isLoading,
                    maxLines: null,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: _isLoading ? null : _submitAction,
                  color: Theme.of(context).colorScheme.secondary,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
