import 'package:flutter/widgets.dart';

import 'repositories/repositories.dart';

/// Stellt die Repositories dem Widget-Baum zur Verfügung.
///
/// Bewusst ein schlichtes InheritedWidget statt eines DI-Frameworks: Die App
/// hat wenige Abhängigkeiten, und `main.dart` bleibt die einzige Stelle, die
/// entscheidet, welche Implementierung (SQLite, später Supabase) läuft.
class AppScope extends InheritedWidget {
  const AppScope({
    super.key,
    required this.books,
    required this.notes,
    required super.child,
  });

  final BookRepository books;
  final NoteRepository notes;

  static AppScope of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<AppScope>();
    assert(scope != null, 'AppScope fehlt über diesem Widget');
    return scope!;
  }

  @override
  bool updateShouldNotify(AppScope old) =>
      books != old.books || notes != old.notes;
}
