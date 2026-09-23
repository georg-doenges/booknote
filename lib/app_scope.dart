import 'package:flutter/widgets.dart';

import 'export/export.dart';
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
    required this.settings,
    required this.customThemes,
    required this.themeCatalog,
    required this.librarySync,
    this.parser = const NoteParser(),
    this.exporters = const [MarkdownExporter(), PlainTextExporter()],
    required super.child,
  });

  final BookRepository books;
  final NoteRepository notes;
  final TranscriptionService transcription;
  final ApiKeyStore apiKeys;
  final CoverService covers;

  /// App-Einstellungen (Theme-Modus etc.), von der UI les- und schreibbar.
  final AppSettings settings;

  /// Installierte Farbschemata (THEMES.md).
  final CustomThemeStore customThemes;

  /// Katalog weiterer Farbschemata im GitHub-Repo (THEMES.md).
  final ThemeCatalogService themeCatalog;

  /// Bibliotheksdatei sichern / zwischen Geräten abgleichen (SYNC_DESIGN.md).
  final LibrarySync librarySync;

  final NoteParser parser;

  /// Verfügbare Export-Formate; die UI lässt den Nutzer wählen. Erstes = Default.
  final List<Exporter> exporters;

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
      settings != old.settings ||
      customThemes != old.customThemes ||
      themeCatalog != old.themeCatalog ||
      librarySync != old.librarySync ||
      parser != old.parser ||
      exporters != old.exporters;
}
