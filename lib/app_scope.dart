import 'package:flutter/widgets.dart';

import 'repositories/repositories.dart';
import 'services/services.dart';

/// Stellt Repositories und Services dem Widget-Baum zur Verfügung.
///
/// Bewusst ein schlichtes InheritedWidget statt eines DI-Frameworks: Die App
/// hat wenige Abhängigkeiten, und `main.dart` bleibt die einzige Stelle, die
/// entscheidet, welche Implementierung (SQLite, später Supabase) läuft.
class AppScope extends InheritedWidget {
  const AppScope({
    super.key,
    required this.books,
    required this.notes,
    required this.transcription,
    required this.apiKeys,
    required this.covers,
    this.parser = const NoteParser(),
    required super.child,
  });

  final BookRepository books;
  final NoteRepository notes;
  final TranscriptionService transcription;
  final ApiKeyStore apiKeys;
  final CoverService covers;
  final NoteParser parser;

  static AppScope of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<AppScope>();
    assert(scope != null, 'AppScope fehlt über diesem Widget');
    return scope!;
  }

  @override
  bool updateShouldNotify(AppScope old) =>
      books != old.books ||
      notes != old.notes ||
      transcription != old.transcription ||
      apiKeys != old.apiKeys ||
      covers != old.covers ||
      parser != old.parser;
}
