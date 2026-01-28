import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

class StorySegmentWidget extends StatefulWidget {
  final String response;
  final bool animate;
  final int animateFromIndex;
  final VoidCallback? onFinishedTyping;

  const StorySegmentWidget({
    super.key,
    required this.response,
    this.animate = false,
    this.animateFromIndex = 0,
    this.onFinishedTyping,
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
      _currentIndex = widget.animateFromIndex;
      _displayResponse = widget.response.substring(0, _currentIndex);
      _isAnimating = true;
      _startTyping();
    } else {
      _displayResponse = widget.response;
      _isAnimating = false;
      if (widget.onFinishedTyping != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          widget.onFinishedTyping?.call();
        });
      }
    }
  }

  @override
  void didUpdateWidget(StorySegmentWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.response != oldWidget.response && widget.animate) {
      _timer?.cancel();
      _currentIndex = widget.animateFromIndex;
      _displayResponse = widget.response.substring(0, _currentIndex);
      _isAnimating = true;
      _startTyping();
    } else if (widget.response != oldWidget.response && !widget.animate) {
      _timer?.cancel();
      _displayResponse = widget.response;
      _isAnimating = false;
      if (widget.onFinishedTyping != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          widget.onFinishedTyping?.call();
        });
      }
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
          widget.onFinishedTyping?.call();
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
