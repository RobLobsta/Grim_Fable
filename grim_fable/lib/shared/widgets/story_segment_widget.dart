import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

class StorySegmentWidget extends StatefulWidget {
  final String response;
  final bool animate;

  const StorySegmentWidget({
    super.key,
    required this.response,
    this.animate = false,
  });

  @override
  State<StorySegmentWidget> createState() => _StorySegmentWidgetState();
}

class _StorySegmentWidgetState extends State<StorySegmentWidget> {
  late String _displayResponse;
  Timer? _timer;
  int _currentIndex = 0;
  bool _isAnimating = false;

  @override
  void initState() {
    super.initState();
    if (widget.animate) {
      _displayResponse = "";
      _isAnimating = true;
      _startTyping();
    } else {
      _displayResponse = widget.response;
      _isAnimating = false;
    }
  }

  @override
  void didUpdateWidget(StorySegmentWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.response != oldWidget.response && widget.animate) {
      _timer?.cancel();
      _displayResponse = "";
      _currentIndex = 0;
      _isAnimating = true;
      _startTyping();
    } else if (!widget.animate) {
      _timer?.cancel();
      _displayResponse = widget.response;
      _isAnimating = false;
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startTyping() {
    _timer = Timer.periodic(const Duration(milliseconds: 20), (timer) {
      if (_currentIndex < widget.response.length) {
        if (mounted) {
          setState(() {
            _displayResponse = widget.response.substring(0, _currentIndex + 1);
            _currentIndex++;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _isAnimating = false;
          });
        }
        _timer?.cancel();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Theme.of(context).colorScheme.primary.withOpacity(0.2)),
      ),
      child: MarkdownBody(
        data: _displayResponse,
        styleSheet: MarkdownStyleSheet(
          p: Theme.of(context).textTheme.bodyLarge?.copyWith(
                height: 1.8,
                fontSize: 17,
                color: Theme.of(context).colorScheme.secondary,
              ),
        ),
      ),
    );
  }
}
