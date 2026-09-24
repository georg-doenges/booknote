import 'package:flutter/widgets.dart';

import 'export/export.dart';
import 'repositories/repositories.dart';
import 'services/services.dart';

/// Stellt Repositories und Services dem Widget-Baum zur Verfügung.
///
/// Bewusst ein schlichtes InheritedWidget statt eines DI-Frameworks: Die App
/// hat wenige Abhängigkeiten, und `main.dart` bleibt die einzige Stelle, die
/// entscheidet, welche Implementierung (SQLite, später Supabase) läuft.
///
/// Zugleich ein `InheritedNotifier` der [AppSettings]: Wer `AppScope.of(context)`
/// aufruft, baut bei jeder Änderung der Einstellungen neu – so wirken z.B. der
/// Clean Mode ([CleanModeContext.cleanMode]) und die Sprache sofort auf jeder
/// offenen Seite, ohne dass sie sich selbst anmelden muss.
class AppScope extends InheritedNotifier<AppSettings> {
  const AppScope({
    super.key,
    required this.books,
    required this.notes,
    required this.transcription,
    required this.apiKeys,
    required this.covers,
    required AppSettings settings,
    required this.customThemes,
    required this.themeCatalog,
    required this.librarySync,
    this.parser = const NoteParser(),
    this.exporters = const [MarkdownExporter(), PlainTextExporter()],
    required super.child,
  }) : super(notifier: settings);

  final BookRepository books;
  final NoteRepository notes;
  final TranscriptionService transcription;
  final ApiKeyStore apiKeys;
  final CoverService covers;

  /// App-Einstellungen (Theme-Modus etc.), von der UI les- und schreibbar.
  AppSettings get settings => notifier!;

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
  bool updateShouldNotify(AppScope oldWidget) =>
      super.updateShouldNotify(oldWidget) ||
      books != oldWidget.books ||
      notes != oldWidget.notes ||
      transcription != oldWidget.transcription ||
      apiKeys != oldWidget.apiKeys ||
      covers != oldWidget.covers ||
      customThemes != oldWidget.customThemes ||
      themeCatalog != oldWidget.themeCatalog ||
      librarySync != oldWidget.librarySync ||
      parser != oldWidget.parser ||
      exporters != oldWidget.exporters;
}

/// Clean Mode ([AppSettings.cleanMode]) für Widgets: Erklärtexte und Hinweise
/// nur zeigen, solange er aus ist. Hängt den Aufrufer an den [AppScope] und baut
/// damit beim Umschalten sofort neu.
extension CleanModeContext on BuildContext {
  bool get cleanMode =>
      // Ohne AppScope (z.B. ein Widget für sich allein in einem Test) gilt der
      // Normalfall: Erklärungen zeigen.
      dependOnInheritedWidgetOfExactType<AppScope>()?.settings.cleanMode ??
      false;

  /// [text] – oder `null` im Clean Mode. Für Parameter wie `helperText`,
  /// `subtitle` oder `caption`, die bei `null` einfach entfallen.
  String? explain(String text) => cleanMode ? null : text;
}

/// Ein Erklärungsblock (Hinweis, Einleitung, Beispiel), der im Clean Mode ganz
/// entfällt – samt seiner eigenen Abstände, deshalb gehört das [child] samt
/// `Padding`/`SizedBox` hierhinein.
class Explanation extends StatelessWidget {
  const Explanation({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) =>
      context.cleanMode ? const SizedBox.shrink() : child;
}
