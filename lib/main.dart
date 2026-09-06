import 'package:flutter/material.dart';

import 'app_scope.dart';
import 'repositories/repositories.dart';
import 'screens/library_screen.dart';
import 'services/services.dart';
import 'theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Einzige Stelle, die die konkreten Implementierungen wählt.
  final db = await AppDatabase.open();
  final apiKeys = SecureApiKeyStore();
  final settings = await AppSettings.load(SharedPrefsAppSettingsStore());

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
      settings: settings,
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
    required this.settings,
  });

  final BookRepository books;
  final NoteRepository notes;
  final ApiKeyStore apiKeys;
  final TranscriptionService transcription;
  final CoverService covers;
  final AppSettings settings;

  @override
  Widget build(BuildContext context) {
    return AppScope(
      books: books,
      notes: notes,
      apiKeys: apiKeys,
      transcription: transcription,
      covers: covers,
      settings: settings,
      child: ListenableBuilder(
        listenable: settings,
        builder: (context, _) => MaterialApp(
          title: 'Booknote',
          theme: BooknoteTheme.light(),
          darkTheme: BooknoteTheme.dark(),
          themeMode: settings.themeMode,
          home: const LibraryScreen(),
        ),
      ),
    );
  }
}
