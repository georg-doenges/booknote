import 'package:flutter/material.dart';

import 'app_scope.dart';
import 'repositories/repositories.dart';
import 'screens/library_screen.dart';
import 'services/services.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Einzige Stelle, die die konkreten Implementierungen wählt.
  final db = await AppDatabase.open();
  final apiKeys = SecureApiKeyStore();

  runApp(
    BooknoteApp(
      books: SqliteBookRepository(db),
      notes: SqliteNoteRepository(db),
      apiKeys: apiKeys,
      transcription: WhisperService(apiKeys: apiKeys),
      covers: FallbackCoverService(
        primary: GoogleBooksCoverService(apiKeys: apiKeys),
        fallback: OpenLibraryCoverService(),
      ),
    ),
  );
}

class BooknoteApp extends StatelessWidget {
  const BooknoteApp({
    super.key,
    required this.books,
    required this.notes,
    required this.apiKeys,
    required this.transcription,
    required this.covers,
  });

  final BookRepository books;
  final NoteRepository notes;
  final ApiKeyStore apiKeys;
  final TranscriptionService transcription;
  final CoverService covers;

  @override
  Widget build(BuildContext context) {
    return AppScope(
      books: books,
      notes: notes,
      apiKeys: apiKeys,
      transcription: transcription,
      covers: covers,
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
