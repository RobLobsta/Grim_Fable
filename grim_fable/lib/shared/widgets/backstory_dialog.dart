import 'package:flutter/material.dart';

import '../../core/models/character.dart';

class BackstoryDialog extends StatelessWidget {
  final String backstory;
  final String occupation;

  const BackstoryDialog({
    super.key,
    required this.backstory,
    required this.occupation,
  });

  static Future<void> show(BuildContext context, Character character) {
    return showDialog(
      context: context,
      builder: (context) => BackstoryDialog(
        backstory: character.backstory,
        occupation: character.occupation,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
        decoration: BoxDecoration(
          color: const Color(0xFFC0C0C0), // Parchment/Silver look
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Theme.of(context).colorScheme.primary, width: 2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.6),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                if (occupation.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Text(
                      occupation.toUpperCase(),
                      style: const TextStyle(
                        fontFamily: 'Serif',
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 2,
                        color: Colors.black54,
                      ),
                    ),
                  ),
                Align(
                  alignment: Alignment.topRight,
                  child: GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: const Padding(
                      padding: EdgeInsets.all(4.0),
                      child: Icon(Icons.close, color: Colors.black54, size: 24),
                    ),
                  ),
                ),
              ],
            ),
            if (occupation.isNotEmpty) const Divider(color: Colors.black26),
            const SizedBox(height: 16),
            Flexible(
              child: SingleChildScrollView(
                child: Text(
                  backstory,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        fontStyle: FontStyle.italic,
                        fontSize: 18,
                        color: Colors.black,
                        height: 1.6,
                      ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
