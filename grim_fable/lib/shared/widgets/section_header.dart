import 'package:flutter/material.dart';

class SectionHeader extends StatelessWidget {
  final String title;
  final IconData icon;

  const SectionHeader({
    super.key,
    required this.title,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: const Color(0xFF1A237E), size: 24),
        const SizedBox(width: 12),
        Text(
          title,
          style: Theme.of(context).textTheme.displayMedium?.copyWith(
                fontSize: 18,
                letterSpacing: 2,
                color: const Color(0xFFC0C0C0),
              ),
        ),
      ],
    );
  }
}
