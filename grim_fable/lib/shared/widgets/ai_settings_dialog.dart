import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/services/settings_service.dart';

class AiSettingsDialog extends ConsumerWidget {
  const AiSettingsDialog({super.key});

  static Future<void> show(BuildContext context) {
    return showDialog(
      context: context,
      builder: (context) => const AiSettingsDialog(),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final apiKeyController = TextEditingController(text: ref.watch(hfApiKeyProvider));
    final temperature = ref.watch(temperatureProvider);
    final maxTokens = ref.watch(maxTokensProvider);
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    return StatefulBuilder(
      builder: (context, setState) {
        // We use local state for the sliders to make them smooth,
        // but initialize with current provider values.
        // Actually, since it's a dialog, we can just use local variables
        // and only save when "SAVE" is pressed.
        return _AiSettingsDialogInternal(
          initialApiKey: apiKeyController.text,
          initialTemperature: temperature,
          initialMaxTokens: maxTokens,
          onSave: (apiKey, temp, tokens) async {
            await ref.read(hfApiKeyProvider.notifier).updateValue(apiKey);
            await ref.read(temperatureProvider.notifier).updateValue(temp);
            await ref.read(maxTokensProvider.notifier).updateValue(tokens);
            if (context.mounted) {
              Navigator.of(context).pop();
              scaffoldMessenger.showSnackBar(
                const SnackBar(content: Text('The fates have been updated.')),
              );
            }
          },
        );
      },
    );
  }
}

class _AiSettingsDialogInternal extends StatefulWidget {
  final String initialApiKey;
  final double initialTemperature;
  final int initialMaxTokens;
  final Function(String, double, int) onSave;

  const _AiSettingsDialogInternal({
    required this.initialApiKey,
    required this.initialTemperature,
    required this.initialMaxTokens,
    required this.onSave,
  });

  @override
  State<_AiSettingsDialogInternal> createState() => _AiSettingsDialogInternalState();
}

class _AiSettingsDialogInternalState extends State<_AiSettingsDialogInternal> {
  late TextEditingController _apiKeyController;
  late double _temperature;
  late int _maxTokens;

  @override
  void initState() {
    super.initState();
    _apiKeyController = TextEditingController(text: widget.initialApiKey);
    _temperature = widget.initialTemperature;
    _maxTokens = widget.initialMaxTokens;
  }

  @override
  void dispose() {
    _apiKeyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('AI DIVINATION SETTINGS'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Enter thy Hugging Face API Key to unlock the fates.',
              style: TextStyle(fontFamily: 'Serif', fontSize: 14, color: Colors.white70),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _apiKeyController,
              decoration: const InputDecoration(
                labelText: 'API KEY',
                hintText: 'hf_...',
                border: OutlineInputBorder(),
              ),
              obscureText: true,
              style: const TextStyle(fontFamily: 'Serif'),
            ),
            const SizedBox(height: 24),
            Text(
              'TEMPERATURE: ${_temperature.toStringAsFixed(1)}',
              style: const TextStyle(fontFamily: 'Serif', fontSize: 14, color: Colors.white70),
            ),
            Slider(
              value: _temperature,
              min: 0.0,
              max: 2.0,
              divisions: 20,
              onChanged: (value) {
                setState(() {
                  _temperature = value;
                });
              },
            ),
            const SizedBox(height: 16),
            Text(
              'MAX TOKENS: $_maxTokens',
              style: const TextStyle(fontFamily: 'Serif', fontSize: 14, color: Colors.white70),
            ),
            Slider(
              value: _maxTokens.toDouble(),
              min: 50,
              max: 1000,
              divisions: 19,
              onChanged: (value) {
                setState(() {
                  _maxTokens = value.toInt();
                });
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('CANCEL'),
        ),
        ElevatedButton(
          onPressed: () => widget.onSave(
            _apiKeyController.text.trim(),
            _temperature,
            _maxTokens,
          ),
          child: const Text('SAVE'),
        ),
      ],
    );
  }
}
