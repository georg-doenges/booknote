import 'dart:convert';
import 'dart:io';

import 'package:booknote/app_scope.dart';
import 'package:booknote/l10n/l10n.dart';
import 'package:booknote/models/models.dart';
import 'package:booknote/repositories/repositories.dart';
import 'package:booknote/screens/book_detail_screen.dart';
import 'package:booknote/screens/book_search_screen.dart';
import 'package:booknote/screens/library_sync_sheet.dart';
import 'package:booknote/screens/library_screen.dart';
import 'package:booknote/screens/recording_screen.dart';
import 'package:booknote/screens/settings_screen.dart';
import 'package:booknote/screens/theme_catalog_screen.dart';
import 'package:booknote/services/services.dart';
import 'package:booknote/widgets/book_edit_dialog.dart';
import 'package:booknote/widgets/note_tile.dart';
import 'package:booknote/widgets/record_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

class _NoTranscription implements TranscriptionService {
  @override
  Future<String> transcribe(String audioPath, {String language = 'de'}) async =>
      '';
}

class _NoCovers implements CoverService {
  @override
  Future<CoverSearchResult> search(String query, {String? language}) async =>
      const CoverSearchResult([]);
}

/// Merkt sich, in welcher Sprache gesucht wurde.
class _RecordingCovers implements CoverService {
  final languages = <String?>[];

  @override
  Future<CoverSearchResult> search(String query, {String? language}) async {
    languages.add(language);
    return const CoverSearchResult([]);
  }
}

/// Baut die App wie `main.dart` (Sprachwahl aus den Einstellungen, sonst
/// Gerätesprache), aber mit Arbeitsspeicher-Ersatz für Datenbank und Netz.
class _Harness {
  late final AppSettings settings;
  late final InMemoryStore store;
  late final CustomThemeStore themes;
  late final LibrarySync sync;
  late final Directory themeDir;
  late final AppDatabase db;
  var _ready = false;

  Future<void> init(WidgetTester tester) async {
    if (_ready) return;
    settings = await AppSettings.load(InMemoryAppSettingsStore());
    store = InMemoryStore();
    themeDir = Directory.systemTemp.createTempSync('booknote_l10n_test_');
    themes = CustomThemeStore(directory: () async => themeDir);
    // SQLite braucht echte (nicht gefälschte) Zeit.
    await tester.runAsync(() async {
      db = await AppDatabase.open(
        path: inMemoryDatabasePath,
        factory: databaseFactoryFfi,
      );
    });
    sync = LibrarySync(LibraryArchive(db), settings);
    _ready = true;
  }

  Future<void> dispose(WidgetTester tester) async {
    await tester.runAsync(() => db.close());
    try {
      themeDir.deleteSync(recursive: true);
    } on FileSystemException {
      // Windows hält Handles kurz; Aufräumen darf still scheitern.
    }
  }

  Future<void> pump(
    WidgetTester tester,
    Widget home, {
    http.Client? catalogClient,
    CoverService? covers,
  }) async {
    await init(tester);
    await tester.pumpWidget(
      AppScope(
        books: InMemoryBookRepository(store),
        notes: InMemoryNoteRepository(store),
        apiKeys: InMemoryApiKeyStore(),
        transcription: _NoTranscription(),
        covers: covers ?? _NoCovers(),
        settings: settings,
        customThemes: themes,
        themeCatalog: ThemeCatalogService(
          client:
              catalogClient ?? MockClient((_) async => http.Response('', 404)),
        ),
        librarySync: sync,
        child: ListenableBuilder(
          listenable: settings,
          builder: (context, _) => MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            locale: settings.uiLanguage?.locale,
            localeListResolutionCallback: resolveAppLocale,
            home: home,
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();
  }
}

void main() {
  setUpAll(sqfliteFfiInit);

  void deviceLanguage(WidgetTester tester, List<Locale> locales) {
    tester.platformDispatcher.localesTestValue = locales;
    addTearDown(tester.platformDispatcher.clearLocalesTestValue);
  }

  group('Bibliothek folgt der Gerätesprache', () {
    final cases = {
      const Locale('de', 'DE'): ('Noch keine Bücher.', 'Suchen'),
      const Locale('en', 'GB'): ('No books yet.', 'Search'),
      const Locale('fr', 'BE'): ('Aucun livre pour l’instant.', 'Rechercher'),
      // nicht unterstützt → English
      const Locale('nl', 'BE'): ('No books yet.', 'Search'),
    };
    for (final entry in cases.entries) {
      testWidgets('${entry.key}', (tester) async {
        final h = _Harness();
        deviceLanguage(tester, [entry.key]);
        await h.pump(tester, const LibraryScreen());

        final (empty, searchTooltip) = entry.value;
        expect(find.textContaining(empty), findsOneWidget);
        expect(find.byTooltip(searchTooltip), findsOneWidget);
        await h.dispose(tester);
      });
    }
  });

  testWidgets('Bibliothek mit Buch: Menü in der Sprache der App', (
    tester,
  ) async {
    final h = _Harness();
    deviceLanguage(tester, [const Locale('fr')]);
    await h.init(tester);
    await InMemoryBookRepository(h.store)
        .create(title: 'La Montagne magique', author: 'Thomas Mann');
    await h.pump(tester, const LibraryScreen());

    // Titel steht im Platzhalter-Cover und unter der Kachel.
    expect(find.text('La Montagne magique'), findsWidgets);
    await tester.tap(find.byType(PopupMenuButton<String>));
    await tester.pumpAndSettle();
    expect(find.text('Exporter …'), findsOneWidget);
    expect(
      find.text('Sauvegarder / synchroniser la bibliothèque …'),
      findsOneWidget,
    );
    expect(find.text('Paramètres'), findsOneWidget);
    await h.dispose(tester);
  });

  group('Buch anlegen: Sprache des Buchs startet mit der App-Sprache', () {
    final cases = {
      const Locale('de'): AppLanguage.german,
      const Locale('en'): AppLanguage.english,
      const Locale('fr'): AppLanguage.french,
      const Locale('nl'): AppLanguage.english,
    };
    for (final entry in cases.entries) {
      testWidgets('${entry.key} → ${entry.value.code}', (tester) async {
        final h = _Harness();
        deviceLanguage(tester, [entry.key]);
        await h.pump(tester, const BookSearchScreen());

        // alle drei Sprachen zur Wahl, mit Eigennamen – genau eine gewählt
        final chips = tester
            .widgetList<ChoiceChip>(find.byType(ChoiceChip))
            .toList();
        expect(chips.map((c) => (c.label as Text).data), [
          for (final l in AppLanguage.values) l.label,
        ]);
        expect(
          [
            for (final c in chips)
              if (c.selected) (c.label as Text).data,
          ],
          [entry.value.label],
        );
        await h.dispose(tester);
      });
    }

    testWidgets('Wahl des Nutzers bleibt und geht als Ergebnis zurück', (
      tester,
    ) async {
      final h = _Harness();
      deviceLanguage(tester, [const Locale('en')]);
      BookSearchResult? result;
      await h.pump(
        tester,
        Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () async => result = await Navigator.of(context)
                  .push<BookSearchResult>(
                    MaterialPageRoute(builder: (_) => const BookSearchScreen()),
                  ),
              child: const Text('open'),
            ),
          ),
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Français'));
      await tester.pump();
      await tester.enterText(find.byType(TextField), 'Le Grand Meaulnes');
      await tester.tap(find.text('Add without cover'));
      await tester.pumpAndSettle();

      expect(result?.title, 'Le Grand Meaulnes');
      expect(result?.language, AppLanguage.french);
      await h.dispose(tester);
    });
  });

  testWidgets('Einstellungen: App-Sprache wählen schaltet die Oberfläche um', (
    tester,
  ) async {
    final h = _Harness();
    deviceLanguage(tester, [const Locale('de')]);
    await h.pump(tester, const SettingsScreen());
    await tester.pumpAndSettle();

    expect(find.text('Einstellungen'), findsOneWidget);
    // Die einzige globale Sprachwahl sagt schon im Titel, dass sie die App
    // betrifft – die Aufnahmesprache steht am Buch.
    expect(find.text('App-Sprache'), findsOneWidget);
    expect(find.text('Wie das Gerät'), findsOneWidget);

    await tester.tap(find.text('Wie das Gerät'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Français').last);
    await tester.pumpAndSettle();

    expect(h.settings.uiLanguage, AppLanguage.french);
    expect(find.text('Paramètres'), findsOneWidget);
    expect(find.text('Langue de l’appli'), findsOneWidget);
    expect(find.text('Einstellungen'), findsNothing);

    // zurück auf „wie das Gerät" → Deutsch
    await tester.tap(find.text('Français').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Comme l’appareil').last);
    await tester.pumpAndSettle();
    expect(h.settings.uiLanguage, isNull);
    expect(find.text('Einstellungen'), findsOneWidget);
    await h.dispose(tester);
  });

  testWidgets('Einstellungen zeigen eine gespeicherte Sprachwahl an', (
    tester,
  ) async {
    final h = _Harness();
    deviceLanguage(tester, [const Locale('de')]);
    await h.init(tester);
    await h.settings.setUiLanguage(AppLanguage.english);
    await h.pump(tester, const SettingsScreen());
    await tester.pumpAndSettle();

    expect(find.text('Settings'), findsOneWidget);
    expect(find.text('English'), findsOneWidget);
    await h.dispose(tester);
  });

  testWidgets('Farbschema-Katalog: Beschreibung in der Sprache der App', (
    tester,
  ) async {
    final h = _Harness();
    deviceLanguage(tester, [const Locale('fr')]);
    final client = MockClient((request) async {
      // Bytes statt String: `Response(String)` kodiert ohne Charset als Latin-1.
      return http.Response.bytes(
        utf8.encode(
          jsonEncode({
            'format': 'booknote-theme-index',
            'formatVersion': 1,
            'themes': [
              {
                'id': 'aurora',
                'name': 'Aurora',
                'brightness': 'light',
                'file': 'aurora.json',
                'description': {
                  'de': 'Polarlicht.',
                  'en': 'Northern lights.',
                  'fr': 'Aurore boréale.',
                },
              },
            ],
          }),
        ),
        200,
      );
    });
    await h.init(tester);
    await h.pump(
      tester,
      ThemeCatalogScreen(
        service: ThemeCatalogService(client: client),
        store: h.themes,
        settings: h.settings,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Clair · Aurore boréale.'), findsOneWidget);
    expect(find.text('Installer'), findsOneWidget);
    expect(find.text('Charger des thèmes'), findsOneWidget);
    await h.dispose(tester);
  });

  group('Aufnahme-Screen', () {
    // Der Beispielsatz im Erst-Hinweis ist der gesprochene Satz: er folgt der
    // Sprache des Buchs, der Rahmen („Sag z.B.:") der Sprache der App.
    final cases = {
      (const Locale('de'), AppLanguage.german): (
        'Tippen zum Aufnehmen',
        'Sprich z.B.: „Seite 47 oben, hier argumentiert der Autor, dass …“',
        'Aufnahmesprache: Deutsch',
      ),
      (const Locale('en'), AppLanguage.french): (
        'Tap to record',
        'Say e.g.: “Page 47 en haut, ici l’auteur soutient que …”',
        'Recording language: Français',
      ),
      (const Locale('fr'), AppLanguage.english): (
        'Appuie pour enregistrer',
        'Dis par ex. : « Page 47 top, here the author argues that … »',
        // geschütztes Leerzeichen vor dem Doppelpunkt
        'Langue d’enregistrement : English',
      ),
    };
    for (final entry in cases.entries) {
      final (locale, bookLanguage) = entry.key;
      final (status, hint, chipLabel) = entry.value;
      testWidgets('App ${locale.languageCode}, Buch ${bookLanguage.code}', (
        tester,
      ) async {
        final h = _Harness();
        deviceLanguage(tester, [locale]);
        await h.init(tester);
        final book = await InMemoryBookRepository(h.store)
            .create(title: 'Buch', language: bookLanguage);
        await h.pump(tester, RecordingScreen(book: book));
        await tester.pumpAndSettle();

        expect(find.text(status), findsOneWidget);
        expect(find.text(hint), findsOneWidget);
        // Die Sprachwahl zeigt die Sprache des Buchs, beschriftet in der
        // Sprache der App.
        expect(find.text(chipLabel), findsOneWidget);
        await h.dispose(tester);
      });
    }
  });

  group('Lokale Sprachwahl ist als solche erkennbar', () {
    /// Symbol der Sprachwahl – darf nie in der AppBar stehen, dort erwartet
    /// man Einstellungen, die für die ganze App gelten.
    final translateInAppBar = find.descendant(
      of: find.byType(AppBar),
      matching: find.byIcon(Icons.translate),
    );

    testWidgets('Aufnahme: beschriftet im Inhalt, gilt nur für jetzt', (
      tester,
    ) async {
      final h = _Harness();
      deviceLanguage(tester, [const Locale('de')]);
      await h.init(tester);
      final books = InMemoryBookRepository(h.store);
      final book = await books.create(title: 'Buch');
      await h.pump(tester, RecordingScreen(book: book));
      await tester.pumpAndSettle();

      expect(translateInAppBar, findsNothing);
      expect(find.text('Aufnahmesprache: Deutsch'), findsOneWidget);

      await tester.tap(find.text('Aufnahmesprache: Deutsch'));
      await tester.pumpAndSettle();
      // Das Menü sagt, dass die Wahl nur jetzt gilt, und nennt die Buchsprache.
      expect(
        find.text('Nur für jetzt. Sprache des Buchs: Deutsch'),
        findsOneWidget,
      );
      for (final l in AppLanguage.values) {
        expect(find.text(l.label), findsOneWidget);
      }

      await tester.tap(find.text('English'));
      await tester.pumpAndSettle();
      expect(find.text('Aufnahmesprache: English'), findsOneWidget);
      // Rückmeldung: der Beispielsatz wechselt mit.
      expect(
        find.text('Sprich z.B.: „Page 47 top, here the author argues that …“'),
        findsOneWidget,
      );
      // Das Buch selbst bleibt unverändert.
      expect((await books.getById(book.id))!.language, AppLanguage.german);
      await h.dispose(tester);
    });

    testWidgets('Aufnahme: „Buch bearbeiten" ändert die Sprache des Buchs', (
      tester,
    ) async {
      final h = _Harness();
      deviceLanguage(tester, [const Locale('de')]);
      await h.init(tester);
      final books = InMemoryBookRepository(h.store);
      final book = await books.create(title: 'Buch');
      await h.pump(tester, RecordingScreen(book: book));
      await tester.pumpAndSettle();

      await tester.longPress(find.text('Buch'));
      await tester.pumpAndSettle();
      expect(find.text('Sprache dieses Buchs'), findsOneWidget);
      expect(
        find.text('Gilt für neue Aufnahmen und die Cover-Suche.'),
        findsOneWidget,
      );
      await tester.tap(find.widgetWithText(ChoiceChip, 'Français'));
      await tester.pump();
      await tester.tap(find.text('Speichern'));
      await tester.pumpAndSettle();

      expect((await books.getById(book.id))!.language, AppLanguage.french);
      // Wer die Buchsprache ändert, nimmt ab jetzt in ihr auf.
      expect(find.text('Aufnahmesprache: Français'), findsOneWidget);
      await h.dispose(tester);
    });

    testWidgets('Buchsuche: eine Wahl im Inhalt, die Cover-Suche folgt ihr', (
      tester,
    ) async {
      final h = _Harness();
      deviceLanguage(tester, [const Locale('de')]);
      final covers = _RecordingCovers();
      await h.pump(tester, const BookSearchScreen(), covers: covers);

      expect(translateInAppBar, findsNothing);
      expect(find.text('Sprache dieses Buchs'), findsOneWidget);
      expect(
        find.text('Für Aufnahmen und Cover-Suche. Lässt sich später ändern.'),
        findsOneWidget,
      );

      await tester.enterText(find.byType(TextField), 'Zauberberg');
      await tester.tap(find.text('English'));
      await tester.pump();
      expect(covers.languages, ['en']);

      await tester.tap(find.text('Français'));
      await tester.pump();
      expect(covers.languages, ['en', 'fr']);
      await h.dispose(tester);
    });

    testWidgets('Cover wechseln: keine Sprachwahl, Suche in Buchsprache', (
      tester,
    ) async {
      final h = _Harness();
      deviceLanguage(tester, [const Locale('de')]);
      final covers = _RecordingCovers();
      await h.pump(
        tester,
        const BookSearchScreen(
          initialQuery: 'La Montagne magique',
          allowWithoutCover: false,
          newBook: false,
          bookLanguage: AppLanguage.french,
        ),
        covers: covers,
      );

      expect(find.byType(ChoiceChip), findsNothing);
      expect(translateInAppBar, findsNothing);
      expect(covers.languages, ['fr']);
      await h.dispose(tester);
    });
  });

  group('Notiz-Kachel', () {
    final created = DateTime(2026, 9, 5, 19, 26);
    Note note(AppLanguage language) => Note(
      id: 'n',
      sourceId: 'b',
      page: '47',
      position: 'top',
      text: 'hello',
      rawTranscript: 'hello',
      language: language,
      createdAt: created,
      updatedAt: created,
    );

    for (final entry in {
      const Locale('de'): ('S. 47 (top)', '05.09.2026, 19:26'),
      const Locale('en'): ('p. 47 (top)', 'Sep 5, 2026'),
      const Locale('fr'): ('p. 47 (top)', 'sept'),
    }.entries) {
      testWidgets(
        '${entry.key}: Seitenpräfix nach Notiz-, Datum nach App-Sprache',
        (tester) async {
          final h = _Harness();
          deviceLanguage(tester, [entry.key]);
          // Präfix hängt an der Sprache der Notiz, das Datum an der der App.
          final language = entry.key.languageCode == 'de'
              ? AppLanguage.german
              : AppLanguage.english;
          await h.pump(tester, Scaffold(body: NoteTile(note: note(language))));
          await tester.pumpAndSettle();

          final (label, date) = entry.value;
          expect(find.text(label), findsOneWidget);
          expect(find.textContaining(date), findsOneWidget);
          await h.dispose(tester);
        },
      );
    }

    testWidgets('ohne Text: Platzhalter in der Sprache der App', (
      tester,
    ) async {
      final h = _Harness();
      deviceLanguage(tester, [const Locale('en')]);
      final empty = note(AppLanguage.english)
          .copyWith(text: '', clearPage: true, clearPosition: true);
      await h.pump(tester, Scaffold(body: NoteTile(note: empty)));
      await tester.pumpAndSettle();
      expect(find.text('(no text recognised)'), findsOneWidget);
      expect(find.text('No page'), findsOneWidget);
      await h.dispose(tester);
    });
  });

  testWidgets('Buch-Details: Sprache in der Kopfzeile, sichtbarer Stift '
      'ändert sie', (tester) async {
    final h = _Harness();
    deviceLanguage(tester, [const Locale('de')]);
    await h.init(tester);
    final books = InMemoryBookRepository(h.store);
    final book = await books.create(
      title: 'Buch',
      author: 'Autorin',
      language: AppLanguage.french,
    );
    await h.pump(tester, BookDetailScreen(bookId: book.id));
    await tester.pumpAndSettle();

    expect(find.text('Autorin · Français'), findsOneWidget);
    // Der Stift steht offen in der Leiste (nicht hinter ⋮) und sagt, was er tut.
    await tester.tap(find.byTooltip('Titel, Autor, Sprache bearbeiten'));
    await tester.pumpAndSettle();
    expect(find.text('Sprache dieses Buchs'), findsOneWidget);

    await tester.tap(find.widgetWithText(ChoiceChip, 'English'));
    await tester.pump();
    await tester.tap(find.text('Speichern'));
    await tester.pumpAndSettle();

    expect((await books.getById(book.id))!.language, AppLanguage.english);
    expect(find.text('Autorin · English'), findsOneWidget);
    await h.dispose(tester);
  });

  group('Clean Mode', () {
    final de = lookupAppLocalizations(const Locale('de'));

    Future<void> setClean(
      WidgetTester tester,
      _Harness h, {
      required bool on,
    }) async {
      await h.settings.setCleanMode(on);
      await tester.pumpAndSettle();
    }

    testWidgets('Einstellungen: der Schalter blendet Erklärungen aus und ein', (
      tester,
    ) async {
      final h = _Harness();
      deviceLanguage(tester, [const Locale('de')]);
      await h.pump(tester, const SettingsScreen());
      await tester.pumpAndSettle();

      expect(find.text(de.settingsLanguageCaption), findsOneWidget);
      expect(find.text(de.settingsSyncCaption), findsOneWidget);

      await tester.tap(find.widgetWithText(SwitchListTile, 'Clean Mode'));
      await tester.pumpAndSettle();
      expect(h.settings.cleanMode, isTrue);
      expect(find.text(de.settingsLanguageCaption), findsNothing);
      expect(find.text(de.settingsSyncCaption), findsNothing);
      // Überschriften und Bedienelemente bleiben, der Schalter behält seinen
      // Satz (er erklärt, wie man zurückkommt).
      expect(find.text('App-Sprache'), findsOneWidget);
      expect(find.text('Anzeige'), findsOneWidget);
      expect(find.text(de.settingsCleanModeSub), findsOneWidget);

      await tester.tap(find.widgetWithText(SwitchListTile, 'Clean Mode'));
      await tester.pumpAndSettle();
      expect(h.settings.cleanMode, isFalse);
      expect(find.text(de.settingsLanguageCaption), findsOneWidget);
      await h.dispose(tester);
    });

    testWidgets('Aufnahme: ohne Anleitung; Aufnahmesprache und Menü bleiben', (
      tester,
    ) async {
      final h = _Harness();
      deviceLanguage(tester, [const Locale('de')]);
      await h.init(tester);
      final book = await InMemoryBookRepository(h.store).create(title: 'Buch');
      await h.pump(tester, RecordingScreen(book: book));
      await tester.pumpAndSettle();
      expect(find.text('Tippen zum Aufnehmen'), findsOneWidget);
      expect(find.textContaining('Sprich z.B.'), findsOneWidget);

      await setClean(tester, h, on: true);
      expect(find.text('Tippen zum Aufnehmen'), findsNothing);
      expect(find.textContaining('Sprich z.B.'), findsNothing);
      expect(find.text('Aufnahmesprache: Deutsch'), findsOneWidget);

      await tester.tap(find.text('Aufnahmesprache: Deutsch'));
      await tester.pumpAndSettle();
      expect(find.textContaining('Nur für jetzt'), findsNothing);
      for (final l in AppLanguage.values) {
        expect(find.text(l.label), findsOneWidget);
      }
      await h.dispose(tester);
    });

    for (final clean in [false, true]) {
      testWidgets('Aufnahme (Clean Mode ${clean ? 'an' : 'aus'}): der Knopf '
          'bleibt in der Mitte', (tester) async {
        final h = _Harness();
        deviceLanguage(tester, [const Locale('de')]);
        await h.init(tester);
        await h.settings.setCleanMode(clean);
        final book = await InMemoryBookRepository(h.store)
            .create(title: 'Buch');
        await h.pump(tester, RecordingScreen(book: book));
        await tester.pumpAndSettle();

        // Ohne die breiten Hinweistexte war die Spalte nur so breit wie ihr
        // breitestes Element und saß links.
        final button = tester.getCenter(find.byType(RecordButton));
        final screen = tester.getSize(find.byType(Scaffold));
        expect(button.dx, closeTo(screen.width / 2, 1));
        await h.dispose(tester);
      });
    }

    testWidgets('Buchsuche: ohne Beispiele und Hinweise, Sprachwahl bleibt', (
      tester,
    ) async {
      final h = _Harness();
      deviceLanguage(tester, [const Locale('de')]);
      await h.pump(tester, const BookSearchScreen());
      expect(find.text(de.searchFieldHelper), findsOneWidget);
      expect(find.text(de.bookLanguageHintNew), findsOneWidget);
      expect(find.text(de.searchEnterTitle), findsOneWidget);

      await setClean(tester, h, on: true);
      expect(find.text(de.searchFieldHelper), findsNothing);
      expect(find.text(de.bookLanguageHintNew), findsNothing);
      expect(find.text(de.searchEnterTitle), findsNothing);
      expect(find.text('Sprache dieses Buchs'), findsOneWidget);
      expect(find.byType(ChoiceChip), findsNWidgets(3));
      await h.dispose(tester);
    });

    testWidgets('leere Bibliothek: kurzer Satz statt Anleitung', (
      tester,
    ) async {
      final h = _Harness();
      deviceLanguage(tester, [const Locale('de')]);
      await h.pump(tester, const LibraryScreen());
      expect(find.textContaining('Lege mit'), findsOneWidget);

      await setClean(tester, h, on: true);
      expect(find.textContaining('Lege mit'), findsNothing);
      expect(find.text('Noch keine Bücher.'), findsOneWidget);
      await h.dispose(tester);
    });

    testWidgets(
      'Buch bearbeiten: kein Autofokus, Hinweis nur ohne Clean Mode',
      (tester) async {
        final h = _Harness();
        deviceLanguage(tester, [const Locale('de')]);
        await h.init(tester);
        final book = await InMemoryBookRepository(h.store)
            .create(title: 'Buch');
        await h.pump(
          tester,
          Builder(
            builder: (context) => Scaffold(
              body: TextButton(
                onPressed: () => showBookEditDialog(context, book),
                child: const Text('open'),
              ),
            ),
          ),
        );
        await tester.tap(find.text('open'));
        await tester.pumpAndSettle();

        // Sonst öffnet sich die Tastatur und verdeckt die Sprachwahl unten.
        expect(
          tester.widget<TextField>(find.byType(TextField).first).autofocus,
          isFalse,
        );
        expect(find.text('Sprache dieses Buchs'), findsOneWidget);
        expect(find.text(de.bookLanguageHintEdit), findsOneWidget);

        await setClean(tester, h, on: true);
        expect(find.text('Sprache dieses Buchs'), findsOneWidget);
        expect(find.text(de.bookLanguageHintEdit), findsNothing);
        await h.dispose(tester);
      },
    );

    testWidgets('Abgleich: ohne Erklärtexte, die Knöpfe bleiben', (
      tester,
    ) async {
      final h = _Harness();
      deviceLanguage(tester, [const Locale('de')]);
      await h.pump(
        tester,
        Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () => showLibrarySyncSheet(context),
              child: const Text('open'),
            ),
          ),
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      expect(find.text(de.syncIntro), findsOneWidget);
      expect(find.text(de.syncMergeHint), findsOneWidget);
      expect(find.text(de.syncMasterHint), findsOneWidget);

      await setClean(tester, h, on: true);
      expect(find.text(de.syncIntro), findsNothing);
      expect(find.text(de.syncFileHint), findsNothing);
      expect(find.text(de.syncMergeHint), findsNothing);
      expect(find.text(de.syncMasterHint), findsNothing);
      expect(find.text(de.syncMerge), findsOneWidget);
      expect(find.text(de.syncMaster), findsOneWidget);
      await h.dispose(tester);
    });

    testWidgets('Farbschema-Katalog: nur Hell/Dunkel, ohne Einleitung', (
      tester,
    ) async {
      final h = _Harness();
      deviceLanguage(tester, [const Locale('de')]);
      final client = MockClient((request) async {
        return http.Response.bytes(
          utf8.encode(
            jsonEncode({
              'format': 'booknote-theme-index',
              'formatVersion': 1,
              'themes': [
                {
                  'id': 'aurora',
                  'name': 'Aurora',
                  'brightness': 'light',
                  'file': 'aurora.json',
                  'description': 'Polarlicht.',
                },
              ],
            }),
          ),
          200,
        );
      });
      await h.init(tester);
      await h.pump(
        tester,
        ThemeCatalogScreen(
          service: ThemeCatalogService(client: client),
          store: h.themes,
          settings: h.settings,
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Hell · Polarlicht.'), findsOneWidget);
      expect(find.text(de.catIntro), findsOneWidget);

      await setClean(tester, h, on: true);
      expect(find.text('Hell'), findsOneWidget);
      expect(find.textContaining('Polarlicht'), findsNothing);
      expect(find.text(de.catIntro), findsNothing);
      expect(find.text('Installieren'), findsOneWidget);
      await h.dispose(tester);
    });
  });
}
