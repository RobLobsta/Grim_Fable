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
    final apiKey = ref.watch(hfApiKeyProvider);
    final temperature = ref.watch(temperatureProvider);
    final maxTokens = ref.watch(maxTokensProvider);
    final topP = ref.watch(topPProvider);
    final frequencyPenalty = ref.watch(frequencyPenaltyProvider);
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    return _AiSettingsDialogInternal(
      initialApiKey: apiKey,
      initialTemperature: temperature,
      initialMaxTokens: maxTokens,
      initialTopP: topP,
      initialFrequencyPenalty: frequencyPenalty,
      onSave: (apiKey, temp, tokens, topP, freq) async {
        await ref.read(hfApiKeyProvider.notifier).updateValue(apiKey);
        await ref.read(temperatureProvider.notifier).updateValue(temp);
        await ref.read(maxTokensProvider.notifier).updateValue(tokens);
        await ref.read(topPProvider.notifier).updateValue(topP);
        await ref.read(frequencyPenaltyProvider.notifier).updateValue(freq);

        if (context.mounted) {
          Navigator.of(context).pop();
          scaffoldMessenger.showSnackBar(
            const SnackBar(content: Text('The fates have been updated.')),
          );
        }
      },
    );
  }
}

class _AiSettingsDialogInternal extends StatefulWidget {
  final String initialApiKey;
  final double initialTemperature;
  final int initialMaxTokens;
  final double initialTopP;
  final double initialFrequencyPenalty;
  final Function(String, double, int, double, double) onSave;

  const _AiSettingsDialogInternal({
    required this.initialApiKey,
    required this.initialTemperature,
    required this.initialMaxTokens,
    required this.initialTopP,
    required this.initialFrequencyPenalty,
    required this.onSave,
  });

  @override
  State<_AiSettingsDialogInternal> createState() => _AiSettingsDialogInternalState();
}

class _AiSettingsDialogInternalState extends State<_AiSettingsDialogInternal> {
  late TextEditingController _apiKeyController;
  late double _temperature;
  late int _maxTokens;
  late double _topP;
  late double _frequencyPenalty;

  Widget _buildSettingTitle(String label, String helpMessage) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: const TextStyle(fontFamily: 'Serif', fontSize: 14, color: Colors.white70),
        ),
        GestureDetector(
          onTap: () {
            showDialog(
              context: context,
              builder: (context) => AlertDialog(
                title: Text(label),
                content: Text(helpMessage),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('UNDERSTOOD'),
                  ),
                ],
              ),
            );
          },
          child: Transform.translate(
            offset: const Offset(2, -4),
            child: Text(
              '^?',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.tertiary,
              ),
            ),
          ),
        ),
      ],
    );
  }

  @override
  void initState() {
    super.initState();
    _apiKeyController = TextEditingController(text: widget.initialApiKey);
    _temperature = widget.initialTemperature;
    _maxTokens = widget.initialMaxTokens;
    _topP = widget.initialTopP;
    _frequencyPenalty = widget.initialFrequencyPenalty;
  }

  @override
  void dispose() {
    _apiKeyController.dispose();
    super.dispose();
  }

  void _restoreDefaults() {
    setState(() {
      _temperature = 0.8;
      _maxTokens = 150;
      _topP = 0.9;
      _frequencyPenalty = 0.0;
    });
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
            _buildSettingTitle(
              'TEMPERATURE: ${_temperature.toStringAsFixed(1)}',
              'Controls randomness. Higher values make output more creative but less predictable.',
            ),
            Slider(
              value: _temperature.clamp(0.0, 1.0),
              min: 0.0,
              max: 1.0,
              divisions: 10,
              onChanged: (value) {
                setState(() {
                  _temperature = value;
                });
              },
            ),
            const SizedBox(height: 16),
            _buildSettingTitle(
              'MAX TOKENS: $_maxTokens',
              'The maximum length of the generated response.',
            ),
            Slider(
              value: _maxTokens.toDouble().clamp(50, 500),
              min: 50,
              max: 500,
              divisions: 9,
              onChanged: (value) {
                setState(() {
                  _maxTokens = value.toInt();
                });
              },
            ),
            const SizedBox(height: 16),
            _buildSettingTitle(
              'TOP-P: ${_topP.toStringAsFixed(2)}',
              'Also known as nucleus sampling; another way to control the diversity of the response.',
            ),
            Slider(
              value: _topP.clamp(0.0, 1.0),
              min: 0.0,
              max: 1.0,
              divisions: 20,
              onChanged: (value) {
                setState(() {
                  _topP = value;
                });
              },
            ),
            const SizedBox(height: 16),
            _buildSettingTitle(
              'FREQUENCY PENALTY: ${_frequencyPenalty.toStringAsFixed(1)}',
              'Decreases the likelihood of the model repeating the same line verbatim.',
            ),
            Slider(
              value: _frequencyPenalty.clamp(0.0, 2.0),
              min: 0.0,
              max: 2.0,
              divisions: 20,
              onChanged: (value) {
                setState(() {
                  _frequencyPenalty = value;
                });
              },
            ),
            const SizedBox(height: 16),
            Center(
              child: TextButton.icon(
                onPressed: _restoreDefaults,
                icon: const Icon(Icons.refresh, size: 18),
                label: const Text('RESTORE DEFAULTS'),
              ),
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
            _topP,
            _frequencyPenalty,
          ),
          child: const Text('SAVE'),
        ),
      ],
    );
  }
}
