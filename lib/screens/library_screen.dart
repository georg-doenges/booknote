import 'package:flutter/material.dart';

/// Startbildschirm: Bibliothek als Cover-Grid.
///
/// Schritt 1: nur Platzhalter, damit die App auf dem Gerät startet.
/// Wird in Schritt 5 (UI) mit dem Repository verbunden.
class LibraryScreen extends StatelessWidget {
  const LibraryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Booknote')),
      body: const Center(
        child: Text(
          'Bibliothek – noch leer.\n(Schritt 1: Grundgerüst)',
          textAlign: TextAlign.center,
        ),
      ),
      floatingActionButton: const FloatingActionButton(
        onPressed: null,
        tooltip: 'Neues Buch',
        child: Icon(Icons.add),
      ),
    );
  }
}
