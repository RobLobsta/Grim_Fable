import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

class StorySegmentWidget extends StatelessWidget {
  final String response;

  const StorySegmentWidget({
    super.key,
    required this.response,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF161B22),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF1A237E).withOpacity(0.2)),
      ),
      child: MarkdownBody(
        data: response,
        styleSheet: MarkdownStyleSheet(
          p: Theme.of(context).textTheme.bodyLarge?.copyWith(
                height: 1.8,
                fontSize: 17,
                color: const Color(0xFFC0C0C0),
              ),
        ),
      ),
    );
  }
}
