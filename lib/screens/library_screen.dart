import 'package:flutter/material.dart';

import '../app_scope.dart';
import '../models/models.dart';

/// Startbildschirm: Bibliothek als Cover-Grid.
///
/// Schritt 3: zeigt nur die Anzahl der Bücher aus der Datenbank, um die
/// SQLite-Anbindung auf dem Gerät zu verifizieren. Der Plus-Button legt
/// testweise ein Buch mit Zeitstempel-Titel an. Das eigentliche Grid und
/// der Anlege-Dialog kommen in Schritt 5.
class LibraryScreen extends StatelessWidget {
  const LibraryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final scope = AppScope.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Booknote')),
      body: StreamBuilder<List<Book>>(
        stream: scope.books.watchAll(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Fehler: ${snapshot.error}'));
          }
          final books = snapshot.data;
          if (books == null) {
            return const Center(child: CircularProgressIndicator());
          }
          if (books.isEmpty) {
            return const Center(
              child: Text(
                'Bibliothek – noch leer.\n(Schritt 3: SQLite angebunden)',
                textAlign: TextAlign.center,
              ),
            );
          }
          return ListView(
            children: [
              for (final b in books)
                ListTile(
                  leading: const Icon(Icons.book_outlined),
                  title: Text(b.title),
                  subtitle: Text(b.createdAt.toLocal().toString()),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline),
                    onPressed: () => scope.books.delete(b.id),
                  ),
                ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => scope.books.create(
          title: 'Testbuch ${TimeOfDay.now().format(context)}',
        ),
        tooltip: 'Testbuch anlegen',
        child: const Icon(Icons.add),
      ),
    );
  }
}
