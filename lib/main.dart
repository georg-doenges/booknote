import 'package:flutter/material.dart';

import 'app_scope.dart';
import 'repositories/repositories.dart';
import 'screens/library_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Einzige Stelle, die die konkrete Storage-Implementierung wählt.
  final db = await AppDatabase.open();
  final books = SqliteBookRepository(db);
  final notes = SqliteNoteRepository(db);

  runApp(BooknoteApp(books: books, notes: notes));
}

class BooknoteApp extends StatelessWidget {
  const BooknoteApp({super.key, required this.books, required this.notes});

  final BookRepository books;
  final NoteRepository notes;

  @override
  Widget build(BuildContext context) {
    return AppScope(
      books: books,
      notes: notes,
      child: MaterialApp(
        title: 'Booknote',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.brown),
          useMaterial3: true,
        ),
        home: const LibraryScreen(),
      ),
    );
  }
}
