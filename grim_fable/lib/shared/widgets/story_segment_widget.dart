import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

class StorySegmentWidget extends StatefulWidget {
  final String response;
  final bool animate;
  final int animateFromIndex;
  final VoidCallback? onFinishedTyping;
  final VoidCallback? onProgress;
  final TextStyle? textStyle;
  final BoxDecoration? decoration;

  const StorySegmentWidget({
    super.key,
    required this.response,
    this.animate = false,
    this.animateFromIndex = 0,
    this.onFinishedTyping,
    this.onProgress,
    this.textStyle,
    this.decoration,
  });

  @override
  State<StorySegmentWidget> createState() => StorySegmentWidgetState();
}

class StorySegmentWidgetState extends State<StorySegmentWidget> with SingleTickerProviderStateMixin {
  late String _displayResponse;
  late AnimationController _controller;
  int _currentIndex = 0;
  bool _isAnimating = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: (widget.response.length - widget.animateFromIndex) * 20),
    )..addListener(_updateText);

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
    if (widget.response != oldWidget.response) {
      _controller.duration = Duration(milliseconds: (widget.response.length - widget.animateFromIndex) * 20);
      if (widget.animate) {
        _controller.stop();
        _currentIndex = widget.animateFromIndex;
        _displayResponse = widget.response.substring(0, _currentIndex);
        _isAnimating = true;
        _startTyping();
      } else {
        _controller.stop();
        _displayResponse = widget.response;
        _isAnimating = false;
        if (widget.onFinishedTyping != null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            widget.onFinishedTyping?.call();
          });
        }
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _startTyping() {
    _controller.reset();
    _controller.forward().then((_) {
      if (mounted && _isAnimating) {
        setState(() {
          _isAnimating = false;
        });
        widget.onFinishedTyping?.call();
      }
    });
  }

  void _updateText() {
    final newIndex = widget.animateFromIndex + ((widget.response.length - widget.animateFromIndex) * _controller.value).floor();
    if (newIndex != _currentIndex && newIndex <= widget.response.length) {
      setState(() {
        _currentIndex = newIndex;
        _displayResponse = widget.response.substring(0, _currentIndex);
      });
      widget.onProgress?.call();
    }
  }

  void skip() {
    if (_isAnimating) {
      _controller.stop();
      if (mounted) {
        setState(() {
          _displayResponse = widget.response;
          _currentIndex = widget.response.length;
          _isAnimating = false;
        });
        widget.onFinishedTyping?.call();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final defaultDecoration = BoxDecoration(
      color: Theme.of(context).colorScheme.surface,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.2)),
    );

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: widget.decoration ?? defaultDecoration,
      child: MarkdownBody(
        data: _displayResponse,
        styleSheet: MarkdownStyleSheet(
          p: widget.textStyle ??
              Theme.of(context).textTheme.bodyLarge?.copyWith(
                    height: 1.8,
                    fontSize: 17,
                    color: Theme.of(context).colorScheme.secondary,
                  ),
        ),
      ),
    );
  }
}
