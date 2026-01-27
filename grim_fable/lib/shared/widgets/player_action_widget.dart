import 'package:flutter/material.dart';

class PlayerActionWidget extends StatelessWidget {
  final String input;

  const PlayerActionWidget({
    super.key,
    required this.input,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16.0),
      child: Row(
        children: [
          Icon(Icons.chevron_right, color: Theme.of(context).colorScheme.tertiary, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              input.toUpperCase(),
              style: const TextStyle(
                color: Color(0xFFE0E0E0),
                fontWeight: FontWeight.bold,
                fontFamily: 'Serif',
                fontSize: 14,
                letterSpacing: 1.2,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
