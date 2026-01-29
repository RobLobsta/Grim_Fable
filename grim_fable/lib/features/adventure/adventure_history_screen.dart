import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'adventure_provider.dart';
import '../../core/models/adventure.dart';

class AdventureHistoryScreen extends ConsumerWidget {
  const AdventureHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final adventures = ref.watch(characterAdventuresProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('THE CHRONICLES'),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              const Color(0xFF0D1117),
              Theme.of(context).colorScheme.primary.withOpacity(0.1),
            ],
          ),
        ),
        child: adventures.isEmpty
          ? const Center(
              child: Text(
                'No chronicles yet...',
                style: TextStyle(fontFamily: 'Serif', fontSize: 18),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: adventures.length,
              itemBuilder: (context, index) {
                final adventure = adventures[index];
                final date = DateFormat('MMM dd, yyyy').format(adventure.lastPlayedAt);

                return Card(
                  margin: const EdgeInsets.only(bottom: 20),
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(16),
                    title: Text(
                      adventure.title,
                      style: const TextStyle(
                        fontFamily: 'Serif',
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFE0E0E0),
                      ),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 8),
                        Text(
                          'Last played: $date',
                          style: TextStyle(
                            fontFamily: 'Serif',
                            color: Colors.grey[400],
                          ),
                        ),
                        Text(
                          adventure.isActive ? 'Active' : 'Completed',
                          style: TextStyle(
                            fontFamily: 'Serif',
                            color: adventure.isActive ? Colors.green : Colors.blueGrey,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    trailing: const Icon(Icons.chevron_right, color: Color(0xFFC0C0C0)),
                    onTap: () {
                      ref.read(activeAdventureProvider.notifier).loadAdventure(adventure);
                      context.push('/adventure');
                    },
                  ),
                );
              },
            ),
      ),
    );
  }
}
