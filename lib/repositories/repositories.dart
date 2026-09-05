/// Sammel-Export der Datenzugriffsschicht.
///
/// UI und Services importieren nur diese Datei und arbeiten ausschließlich
/// gegen [BookRepository] / [NoteRepository]. Welche Implementierung dahinter
/// steckt (SQLite, In-Memory, später Supabase), entscheidet `main.dart`.
library;

export 'book_repository.dart';
export 'in_memory_repositories.dart';
export 'note_repository.dart';
export 'repository_exceptions.dart';
export 'sqlite/app_database.dart';
export 'sqlite/sqlite_book_repository.dart';
export 'sqlite/sqlite_note_repository.dart';
