import 'package:flutter/material.dart';

class InventoryDialog extends StatelessWidget {
  final List<String> items;

  const InventoryDialog({super.key, required this.items});

  static void show(BuildContext context, List<String> items) {
    showDialog(
      context: context,
      builder: (context) => InventoryDialog(items: items),
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
        child: items.isEmpty
            ? const SizedBox(height: 40)
            : ListView.separated(
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
