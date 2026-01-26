import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

void main() {
  runApp(
    const ProviderScope(
      child: GrimFableApp(),
    ),
  );
}

class GrimFableApp extends StatelessWidget {
  const GrimFableApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Grim Fable',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1A237E), // Dark Blue
          brightness: Brightness.dark,
          primary: const Color(0xFF1A237E),
          secondary: const Color(0xFFC0C0C0), // Silver
          surface: const Color(0xFF121212),
        ),
        scaffoldBackgroundColor: const Color(0xFF0D1117), // Very dark blue/black
        textTheme: const TextTheme(
          displayLarge: TextStyle(
            color: Color(0xFFE0E0E0), // Light silver
            fontFamily: 'Serif',
            fontWeight: FontWeight.bold,
          ),
          bodyLarge: TextStyle(
            color: Color(0xFFC0C0C0), // Silver
            fontSize: 18,
            fontFamily: 'Serif',
          ),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF1A237E),
          foregroundColor: Color(0xFFC0C0C0),
        ),
      ),
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Grim Fable'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.book_sharp,
              size: 100,
              color: Color(0xFFC0C0C0),
            ),
            const SizedBox(height: 20),
            Text(
              'Welcome to Grim Fable',
              style: Theme.of(context).textTheme.displayLarge?.copyWith(fontSize: 32),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            Text(
              'Your dark adventure awaits...',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 40),
            ElevatedButton(
              onPressed: () {
                // To be implemented in Feature 1.1
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1A237E),
                foregroundColor: const Color(0xFFC0C0C0),
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              ),
              child: const Text('Begin Journey'),
            ),
          ],
        ),
      ),
    );
  }
}
