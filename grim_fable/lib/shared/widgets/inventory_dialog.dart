import 'package:flutter/material.dart';

class InventoryDialog extends StatelessWidget {
  final List<String> items;
  final int gold;

  const InventoryDialog({super.key, required this.items, this.gold = 0});

  static void show(BuildContext context, List<String> items, {int gold = 0}) {
    showDialog(
      context: context,
      builder: (context) => InventoryDialog(items: items, gold: gold),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFF1A1A1A),
      title: const Text(
        'INVENTORY',
        style: TextStyle(
          fontFamily: 'Serif',
          letterSpacing: 4,
          fontWeight: FontWeight.bold,
          color: Color(0xFFC0C0C0),
        ),
      ),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (items.isEmpty && gold == 0)
              const SizedBox(height: 40)
            else ...[
              if (items.isNotEmpty)
                Flexible(
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: items.length,
                    separatorBuilder: (context, index) => Divider(color: Colors.white.withOpacity(0.1)),
                    itemBuilder: (context, index) {
                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.auto_awesome, size: 16, color: Colors.grey),
                        title: Text(
                          items[index],
                          style: const TextStyle(
                            fontFamily: 'Serif',
                            fontSize: 16,
                            color: Colors.white70,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              if (items.isNotEmpty && gold > 0)
                Divider(color: Colors.white.withOpacity(0.2), height: 32),
              if (gold > 0)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Row(
                    children: [
                      const Text(
                        '🪙',
                        style: TextStyle(fontSize: 20),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        '$gold',
                        style: const TextStyle(
                          fontFamily: 'Serif',
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.amber,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'GOLD COINS',
                        style: TextStyle(
                          fontFamily: 'Serif',
                          fontSize: 12,
                          letterSpacing: 2,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text(
            'CLOSE',
            style: TextStyle(letterSpacing: 2, color: Color(0xFFC0C0C0)),
          ),
        ),
      ],
    );
  }
}
