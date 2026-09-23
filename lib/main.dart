import 'package:flutter/material.dart';

import 'app_scope.dart';
import 'models/models.dart';
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
  Haptics.enabled = settings.hapticsEnabled;
  settings.addListener(() => Haptics.enabled = settings.hapticsEnabled);

  final customThemes = CustomThemeStore();
  await customThemes.refresh();

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
      customThemes: customThemes,
      themeCatalog: ThemeCatalogService(),
      librarySync: LibrarySync(LibraryArchive(db), settings),
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
    required this.customThemes,
    required this.themeCatalog,
    required this.librarySync,
  });

  final BookRepository books;
  final NoteRepository notes;
  final ApiKeyStore apiKeys;
  final TranscriptionService transcription;
  final CoverService covers;
  final AppSettings settings;
  final CustomThemeStore customThemes;
  final ThemeCatalogService themeCatalog;
  final LibrarySync librarySync;

  @override
  Widget build(BuildContext context) {
    return AppScope(
      books: books,
      notes: notes,
      apiKeys: apiKeys,
      transcription: transcription,
      covers: covers,
      settings: settings,
      customThemes: customThemes,
      themeCatalog: themeCatalog,
      librarySync: librarySync,
      child: ListenableBuilder(
        listenable: Listenable.merge([settings, customThemes]),
        builder: (context, _) {
          final custom = customThemes.byId(settings.activeCustomThemeId);
          final ThemeData theme = custom != null
              ? BooknoteTheme.custom(custom)
              : BooknoteTheme.light();
          final background = custom?.background;

          return MaterialApp(
            title: 'Booknote',
            theme: theme,
            darkTheme: custom != null ? theme : BooknoteTheme.dark(),
            themeMode: custom != null ? ThemeMode.light : settings.themeMode,
            builder: background != null && background.hasImage
                ? (context, child) =>
                      _ThemeBackground(background: background, child: child!)
                : null,
            home: const LibraryScreen(),
          );
        },
      ),
    );
  }
}

/// Zeichnet das Hintergrundbild eines Custom-Themes hinter den App-Inhalten.
/// AppBar und System-Leisten bleiben undurchsichtig (eigene Flächenfarbe).
class _ThemeBackground extends StatelessWidget {
  const _ThemeBackground({required this.background, required this.child});

  final ThemeBackground background;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Stack(
      children: [
        Positioned.fill(child: ColoredBox(color: scheme.surface)),
        Positioned.fill(
          child: Opacity(
            opacity: background.opacity,
            child: background.tile
                ? Image.memory(
                    background.imageBytes!,
                    repeat: ImageRepeat.repeat,
                    filterQuality: FilterQuality.medium,
                  )
                : Image.memory(
                    background.imageBytes!,
                    fit: BoxFit.cover,
                    filterQuality: FilterQuality.medium,
                  ),
          ),
        ),
        if (background.dim > 0)
          Positioned.fill(
            child: ColoredBox(
              color: Colors.black.withValues(alpha: background.dim),
            ),
          ),
        Positioned.fill(child: child),
      ],
    );
  }
}
