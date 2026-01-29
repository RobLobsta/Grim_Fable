import 'package:flutter/material.dart';

class SectionHeader extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget? trailing;

  const SectionHeader({
    super.key,
    required this.title,
    required this.icon,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: Theme.of(context).colorScheme.tertiary, size: 24),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            title,
            style: Theme.of(context).textTheme.displayMedium?.copyWith(
                  fontSize: 18,
                  letterSpacing: 2,
                  color: const Color(0xFFC0C0C0),
                ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        if (trailing != null) trailing!,
      ],
    );
  }
}
