import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/services/settings_service.dart';

class AppSettingsDialog extends ConsumerWidget {
  const AppSettingsDialog({super.key});

  static Future<void> show(BuildContext context) {
    return showDialog(
      context: context,
      builder: (context) => const AppSettingsDialog(),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final uiPreset = ref.watch(uiPresetProvider);
    final recommendedResponses = ref.watch(recommendedResponsesProvider);
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    return AlertDialog(
      title: const Text('APP SETTINGS'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'UI THEME PRESET',
              style: TextStyle(fontFamily: 'Serif', fontSize: 14, color: Colors.white70),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: uiPreset,
              items: ['Default', 'Abyssal', 'Blood', 'Emerald'].map((preset) {
                return DropdownMenuItem(
                  value: preset,
                  child: Text(preset, style: const TextStyle(fontFamily: 'Serif')),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  ref.read(uiPresetProvider.notifier).updateValue(value);
                }
              },
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'RECOMMENDED ACTIONS',
                        style: TextStyle(fontFamily: 'Serif', fontSize: 14, color: Colors.white70),
                      ),
                      Text(
                        'Show AI-suggested choices',
                        style: TextStyle(fontSize: 12, color: Colors.white38),
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: recommendedResponses,
                  onChanged: (value) {
                    ref.read(recommendedResponsesProvider.notifier).updateValue(value);
                  },
                ),
              ],
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('CLOSE'),
        ),
      ],
    );
  }
}
