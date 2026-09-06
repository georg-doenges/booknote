# Booknote — Fortschritt & Übergabe

Diese Datei hält fest, was gebaut ist, was fehlt und wo wir gerade stehen,
damit ein anderes Modell (oder Mensch) die Arbeit nahtlos übernehmen kann.
Spezifikation: `PROJECT.md`. Reihenfolge der Bausteine: PROJECT.md, Abschnitt 10.
Ideen für später (nicht jetzt bauen, nur architektonisch offenhalten):
`BACKLOG.md`.

## Umgebung

- Flutter 3.47.2 (stable), Dart 3.13.2. SDK liegt unter `C:\src\flutter`,
  ist **nicht** im PATH → in der Shell vorher `$env:PATH = "C:\src\flutter\bin;$env:PATH"`.
- Android SDK 37 vorhanden. `flutter build apk --debug` läuft durch (Gradle hat
  Platform 34/35 + CMake nachinstalliert). `flutter doctor` meckert trotzdem über
  „license status unknown" → bei Problemen `flutter doctor --android-licenses`.
- Test-Gerät: echtes Android-Gerät per USB (`flutter run`).
- Git: lokal, Branch `main`. Identität repo-lokal gesetzt.

## Architektur-Entscheidungen (getroffen)

- **IDs sind Strings (UUID v4)**, nicht Autoincrement-Integer. Begründung:
  PROJECT.md 4 verlangt Umstellbarkeit für Sync; die Umstellung jetzt ist
  billiger als eine Migration später. Paket `uuid`.
- **`updated_at` zusätzlich zu `created_at`** in Source und Note. Nicht in der
  Spec, aber nötig für spätere Sync-Konfliktauflösung (last-write-wins).
- `Source` ist die generische Entität, `Book` ein dünner Subtyp mit
  `sourceType = book`. `SourceType` ist ein Enum mit `dbValue` für die
  Spalte `source_type` → neue Typen später ohne Schemaänderung.
- Modelle sind unveränderliche Wertobjekte mit `copyWith`, `==`, `hashCode`.
  Keine DB-Details (toMap/fromMap) in den Modellen; das Mapping gehört in die
  SQLite-Implementierung (Schritt 3), damit Supabase später eigenes Mapping hat.
- `Note.pageNumber` liefert den numerischen Teil der Seite (für Sortierung).

## Ordnerstruktur

```
lib/
  models/          Source, SourceType, Book, Note, book_query.dart (filterBooks,
                   distinctAuthors) (+ models.dart Sammel-Export)                 ✅
  repositories/    BookRepository, NoteRepository (Interfaces) ✅, InMemory-Impl ✅,
                   watch_stream.dart (Helfer) ✅
  repositories/sqlite/  AppDatabase (Schema v1), SqliteBook/NoteRepository, Mapper ✅
  app_scope.dart   InheritedWidget, reicht Repositories + Services an die UI      ✅
  theme.dart       BooknoteTheme: Seed → hell/dunkel, Abstände, Komponenten       ✅
  services/        NoteParser + GermanNumberParser ✅, TranscriptionService-Interface
                   + WhisperService ✅, ApiKeyStore (Secure + InMemory) ✅,
                   AppSettings + AppSettingsStore (SharedPrefs + InMemory) ✅,
                   NoteRecorder (Hülle um `record`, m4a im Temp-Dir) ✅,
                   CoverService-Interface + FallbackCoverService,
                   GoogleBooksCoverService, OpenLibraryCoverService ✅
  export/          Exporter-Interface, MarkdownExporter, shareExport (share_plus) ✅
  screens/         LibraryScreen (Grid), RecordingScreen, BookDetailScreen,
                   SettingsScreen, BookSearchScreen (Cover-Auswahl)              ✅
  widgets/         BookCoverTile, NoteTile (+ noteLocationLabel), NoteEditDialog,
                   BookEditDialog (Titel/Autor), RecordButton (geteilt),
                   VoiceInputButton (Mikrofon-Sheet fürs Textfeld),
                   format.dart (Datum)                                           ✅
  main.dart        BooknoteApp → LibraryScreen                                    ✅
test/
  models/          Unit-Tests für das Datenmodell                                 ✅
  repositories/    repository_contract.dart = Vertragstest für JEDE Impl,
                   migration_test.dart (v1 → aktuell)                            ✅
```

## Status pro Baustein (PROJECT.md, Abschnitt 10)

| # | Baustein | Status |
|---|----------|--------|
| 1 | Grundgerüst + Ordnerstruktur + Datenmodell | ✅ auf Gerät getestet |
| 2 | Repository-Interface (`BookRepository`, `NoteRepository`) | ✅ |
| 3 | SQLite-Implementierung | ✅ auf Gerät getestet (Neustart-Persistenz) |
| 4 | WhisperService + NoteParser + ApiKeyStore | ✅ fertig (nur Unit-Tests, noch nicht in der UI) |
| 5 | UI: Library, Recording, BookDetail, Settings | ✅ auf Gerät getestet, Whisper + Parser funktionieren |
| 6 | CoverService (Google Books + Open Library) + Autor + Zeitstempel | ✅ auf Gerät getestet |
| 7 | Markdown-Export | ✅ auf Gerät getestet (Share-Sheet funktioniert) |
| 8 | Feinschliff (Design/Theme, Aufnahme-Flow, …) | 🔄 Baustein A (Theme) fertig, auf Gerät |

### Schritt 8 in Bausteinen

| Baustein | Inhalt | Status |
|----------|--------|--------|
| A | Zentrales `lib/theme.dart`, Dark Mode + Umschalter, SafeArea, Abstände | ✅ auf Gerät |
| B | Buchsuche: ein kombiniertes Feld, Mikrofon im Suchfeld (Sheet, Puls, Auto-Stop) | 🔄 gebaut, wartet auf Gerätetest (mit A) |
| C | Bibliothek nach Titel/Autor durchsuchen & filtern | 🔄 gebaut, wartet auf Gerätetest |
| D | Feinschliff Aufnahme-Flow (Haptik, Kurz-/Langaufnahme, …) | ⬜ (als Nächstes) |
| E | App-Icon, Release-Signierung für Tester | ⬜ |

## Was in Schritt 1 passiert ist

- `flutter create` mit Plattformen android + ios, Org `de.doenges`.
- Android-Label auf „Booknote" gesetzt; iOS `CFBundleDisplayName` ist bereits „Booknote".
- Alle Stufe-1-Abhängigkeiten in `pubspec.yaml` eingetragen (sqflite, path,
  path_provider, uuid, record, http, flutter_secure_storage, share_plus).
  Noch keine davon im Code benutzt.
- Datenmodell in `lib/models/` inkl. Tests.
- Platzhalter-`LibraryScreen`, damit die App auf dem Gerät startet.

## Was in Schritt 2 passiert ist

- `BookRepository` / `NoteRepository` als abstrakte Klassen in `lib/repositories/`.
  Reines CRUD + `watchAll()` / `watchBySource()` als reaktive Streams für die UI.
  Konventionen stehen als Doc-Kommentar im Interface: Repository vergibt IDs und
  Zeitstempel; `update`/`delete` auf unbekannte ID → `EntityNotFoundException`;
  `Book.delete` löscht Notizen kaskadierend; `rawTranscript` ist unveränderlich.
- `NoteSort` (createdAt | page) + `sortNotes()` als gemeinsame Sortierlogik.
- `RepositoryException` / `EntityNotFoundException` als storage-neutrale Fehler.
- `InMemoryBookRepository` / `InMemoryNoteRepository` (gemeinsamer `InMemoryStore`):
  Referenz-Implementierung für Tests und UI-Entwicklung ohne DB.
- `test/repositories/repository_contract.dart`: **Vertragstest**, den jede
  Implementierung bestehen muss. SQLite (Schritt 3) und Supabase (später)
  binden ihn mit einer Zeile ein, siehe `in_memory_repositories_test.dart`.
- Gelernt: Watch-Streams nicht als `async*` bauen (cancel() blockiert, wenn der
  Generator in `await for` hängt). Stattdessen `watchStream()`-Helfer mit
  StreamController; die SQLite-Impl soll denselben Helfer nutzen.

## Was in Schritt 3 passiert ist

- `AppDatabase.open()` öffnet `booknote.db` im sqflite-Standardverzeichnis
  (plattformneutral). `PRAGMA foreign_keys = ON`, Schema v1, `_onUpgrade` als
  Migrations-Hook (bei Schemaänderung `schemaVersion` erhöhen).
- Tabellen `sources` und `notes` wie geplant; Notizen fallen per
  `ON DELETE CASCADE` mit dem Buch. Indizes auf `notes(source_id, created_at)`
  und `sources(created_at)`.
- Mapping Modell ↔ Zeile in `sqlite_mappers.dart`, nicht in den Modellen.
  Zeitstempel werden über `dbNow()` auf UTC-Millisekunden normalisiert, sonst
  sind Objekte vor/nach dem Speichern nicht `==` (Dart vergleicht auch `isUtc`).
- Seiten-Sortierung passiert in Dart (`sortNotes`), nicht in SQL, damit
  "88f." überall gleich behandelt wird.
- `note.create` prüft in einer Transaktion, ob die Quelle existiert
  (→ `EntityNotFoundException`), statt auf den FK-Fehlertext zu matchen.
- `watchStreamAsync()` für DB-Queries: Änderungen während eines laufenden
  Ladens führen zu genau einem Nachladen.
- Vertragstest läuft über `sqflite_common_ffi` in-memory auf dem Desktop.
- `main.dart` öffnet die DB und reicht die Repositories per `AppScope`
  (InheritedWidget) durch. `LibraryScreen` zeigt vorläufig eine Liste mit
  Testbuch-Anlegen/Löschen, um SQLite auf dem Gerät zu verifizieren.

## Was in Schritt 4 passiert ist

- `NoteParser.parse(raw) → ParsedNote(page, position, text, rawTranscript)`.
  Regelbasiert per Regex auf der kleingeschriebenen Kopie, der Text behält
  Originalschreibung. Erkennt: „Seite"/„auf Seite"/„S.", Ziffern oder
  Zahlwort, „f."/„ff."/„folgende"/„und folgende"/„fortfolgende" (→ f. / ff.),
  Position oben/mitte/mittig/unten/„Zeile N". Satzzeichen zwischen den Teilen
  sind egal. „f" nur als eigenes Wort (sonst „Seite 3 fängt…" kaputt).
  Ohne Seitenangabe am Anfang → alles ist Text, page = null.
- `GermanNumberParser.parse("dreihundertsiebenundvierzig") → 347`
  (bis in die Tausender; „zwölfhundert" geht auch).
- `TranscriptionService` (Interface) + `TranscriptionException(kind, message, cause)`
  mit `TranscriptionErrorKind` (missingApiKey, unauthorized, network,
  rateLimited, invalidAudio, server) → UI kann gezielt reagieren.
- `WhisperService(apiKeys:, client:)`: Multipart-POST, `whisper-1`,
  `language=de`. HTTP-Client injizierbar → Tests mit `MockClient`.
- `ApiKeyStore` (Interface) mit `SecureApiKeyStore` (flutter_secure_storage,
  Android EncryptedSharedPreferences) und `InMemoryApiKeyStore`. Hält auch
  den optionalen Google-Books-Key für Schritt 6.
- Auf dem Gerät ändert sich in diesem Schritt nichts Sichtbares.

## Was in Schritt 5 passiert ist

- `AppScope` reicht jetzt auch `transcription`, `apiKeys` und `parser` durch;
  `main.dart` verdrahtet `SecureApiKeyStore` + `WhisperService`.
- **LibraryScreen:** Grid aus `BookCoverTile` (Cover per `Image.network`,
  sonst Platzhalter mit Titel). Tippen → RecordingScreen, **lange drücken →
  BookDetailScreen**. „+" → Dialog nur mit Titel (Cover-Auswahl kommt in
  Schritt 6), danach direkt in den RecordingScreen. Zahnrad → Settings.
- **RecordingScreen:** Phasen idle/recording/transcribing/error. Großer
  runder Button (tap-to-start/stop), Sekundenzähler, nach dem Stopp
  Whisper → Parser → `notes.create`. Gespeicherte Notizen der Sitzung als
  Liste darunter (neueste hervorgehoben). Bei Fehler: Karte mit Meldung,
  „Erneut versuchen" (Audio bleibt in `_pendingAudio`), „Verwerfen",
  bei fehlendem/abgelehntem Key zusätzlich „API-Key eingeben". Listen-Icon
  oben rechts → BookDetailScreen.
- **BookDetailScreen:** `watchBySource` mit Sortier-Toggle (Seite ↔
  chronologisch), Tippen → `NoteEditDialog` (Seite, Position, Text, Original-
  Transkript aufklappbar), Papierkorb mit Rückfrage, Menü: Umbenennen /
  Buch löschen (mit Rückfrage). Export-Icon vorhanden, aber deaktiviert
  (Schritt 7). FAB „Aufnehmen".
- **SettingsScreen:** OpenAI-Key (maskiert, Auge-Toggle) + optionaler
  Google-Books-Key, Kostenhinweis, Speichern über `ApiKeyStore`.
- **Plattform:** `RECORD_AUDIO` + `INTERNET` im AndroidManifest,
  `NSMicrophoneUsageDescription` in Info.plist. Mikrofon-Prompt kommt über
  `record.hasPermission()` beim ersten Aufnahmestart.
- `NoteRecorder`: AAC-LC/m4a, mono, 96 kbit/s, Datei im Temp-Verzeichnis
  (`path_provider`), wird nach erfolgreichem Speichern gelöscht.

## Was in Schritt 6 passiert ist

- **Schema v2:** `sources.author TEXT` (nullable). Migration in
  `AppDatabase._onUpgrade` (ALTER TABLE), abgesichert durch
  `test/repositories/migration_test.dart`. `Source`/`Book` haben `author`,
  `BookRepository.create` nimmt `author`, `copyWith(clearAuthor:)`.
- **CoverService** (Interface, `search(query) → List<CoverCandidate>`),
  `CoverCandidate(title, author, coverUrl, provider)`, `CoverSearchException`.
  `FallbackCoverService(primary, fallback)`: Fallback bei leerem Ergebnis
  **oder** Fehler der Primärquelle.
- `GoogleBooksCoverService`: Volumes-API, optionaler Key aus `ApiKeyStore`,
  Thumbnails auf https und `zoom=1` umgeschrieben, Untertitel angehängt.
- `OpenLibraryCoverService`: search.json + covers.openlibrary.org (`-M.jpg`).
- **BookSearchScreen:** Titel tippen (Debounce 600 ms) → Trefferliste mit
  Thumbnail, Autor, Quelle. Antippen übernimmt Titel/Autor/Cover.
  „Ohne Cover anlegen" nimmt den getippten Titel. Wird auch aus BookDetail
  für „Cover suchen" benutzt (Titel bleibt dann erhalten, Autor nur gefüllt,
  wenn leer).
- **BookDetail-Menü:** Titel/Autor bearbeiten, Cover suchen, Cover entfernen,
  Buch löschen. AppBar zeigt Autor als Unterzeile.
- **NoteTile:** Datum + Uhrzeit (`formatDateTime`, lokal, `dd.MM.yyyy, HH:mm`)
  klein rechts neben der Fundstelle. Nutzerwunsch.
- **BookCoverTile:** Autor als kleine Zeile unter dem Titel.

## Was nach Schritt 6 noch kam (Sprach-Fix)

- Nutzer fand für „Der Zauberberg" nur englische/niederländische Ausgaben.
  Ursache: Google Books ohne `langRestrict` mischt Sprachen. Jetzt fragt
  `GoogleBooksCoverService` zuerst mit `langRestrict=de` (Feld
  `preferredLanguage`, Default `de`), dann ohne Filter, und führt beide Listen
  zusammen (Dubletten über Titel+Autor raus, deutsche zuerst). Open Library
  bekommt `lang=de`. Sprache ist noch fest `de`; könnte später aus Locale oder
  Settings kommen.

## Google-Books-Kontingent (Diagnose nach Schritt 7)

- Nutzer sah weiterhin nur Open-Library-Treffer. Diagnose per `curl`: Google
  Books antwortet **ohne API-Key mit 429** („Queries per day" des geteilten
  anonymen Projekts erschöpft). Der Fallback hatte den Fehler verschluckt.
- Fix: `CoverService.search` liefert jetzt `CoverSearchResult(candidates,
  warning)`. `FallbackCoverService` setzt `warning`, wenn die Primärquelle
  fehlschlug. `GoogleBooksCoverService` formuliert bei 429/403 einen Hinweis
  auf den kostenlosen Key. `BookSearchScreen` zeigt die Warnung als
  `MaterialBanner` mit Button „Einstellungen".
- **Nutzer muss einen Google-Books-API-Key anlegen** (Google Cloud Console →
  Projekt → „Books API" aktivieren → API-Key, keine Kreditkarte) und in den
  Einstellungen eintragen. Erst dann greift die Sprachbevorzugung sinnvoll.

## Was in Schritt 7 passiert ist

- `Exporter` (Interface: `formatName`, `export(book, notes) → ExportResult`),
  reine Funktion ohne I/O. `ExportResult(fileName, mimeType, content)`.
- `MarkdownExporter` gemäß PROJECT.md 8: `# Titel`, `*Autor*`, `## Notizen`
  nach Seite sortiert, `## Ohne Seitenangabe` chronologisch. Zeitstempel
  hinten kursiv (`includeTimestamps`, Default an). Zeilenumbrüche im Text
  werden zu Leerzeichen. `safeFileName()` für den Dateinamen.
- `shareExport(result)`: schreibt nach `<temp>/exports/<name>.md` und öffnet
  den System-Share-Sheet über `share_plus` (`SharePlus.instance.share`).
- `AppScope.exporter` (Default `MarkdownExporter`); Export-Icon im
  BookDetail aktiv.

## Was in Baustein A (Theme/Design) passiert ist

- **`lib/theme.dart` neu:** `BooknoteTheme` als Namespace (`abstract final class`).
  Ein Seed (`0xFF6D4C41`, warmes Braun) → `ColorScheme.fromSeed` für hell **und**
  dunkel. Abstands-Konstanten `gap4..gap24`, `screenPadding`, `cardRadius`.
  Komponenten-Themes: flache AppBar (linksbündig, Fläche = `surface`), flache
  Karten (`elevation 0`, `surfaceContainerLow`, Radius 12), Eingabefelder appweit
  mit `OutlineInputBorder`, SnackBars `floating`, Divider als Haarlinie.
- **`main.dart`:** `theme` / `darkTheme` / `themeMode: ThemeMode.system`. Damit
  folgt die App jetzt dem System-Hell/Dunkel (vorher nur hell verdrahtet).
- **Screens/Widgets auf das Theme umgestellt:** rohe Zahlen → `BooknoteTheme.gapN`;
  redundantes `border: OutlineInputBorder()` aus den Feldern entfernt (kommt jetzt
  aus dem Theme); gedämpfter Text `scheme.outline` → `scheme.onSurfaceVariant`
  (bessere Lesbarkeit, v.a. im Dark Mode). Betrifft `library_screen`,
  `recording_screen`, `settings_screen`, `book_search_screen`, `book_cover_tile`,
  `note_tile`, `note_edit_dialog`, `book_edit_dialog`.
- **Aufnahme-Button** (`recording_screen`): größer (184), sitzt in einem
  farbigen Ring (`primaryContainer` / bei Aufnahme `errorContainer`),
  `AnimatedContainer` für weichen Zustandswechsel, Sekundenzähler mit
  Tabellenziffern.
- **Tests:** `test/theme_test.dart` (hell/dunkel, Rahmen, `themeMode`).
- Nicht angefasst: App-weite Schriftart, Icon, konkreter Aufnahme-Flow (Baustein D).

### Nachbesserung nach dem ersten Test (gleicher Commit-Block)

- **Theme-Umschalter in den Einstellungen.** Neu: `lib/services/app_settings.dart`
  mit `AppSettingsStore` (Interface), `SharedPrefsAppSettingsStore` (produktiv,
  neues Paket `shared_preferences`), `InMemoryAppSettingsStore` (Tests) und
  `AppSettings extends ChangeNotifier` (hält den Stand, schreibt durch). `main.dart`
  lädt `AppSettings` beim Start, `AppScope` reicht es durch, `MaterialApp` liegt in
  einem `ListenableBuilder` → Wechsel wirkt sofort. `SettingsScreen` hat oben einen
  `SegmentedButton` System / Hell / Dunkel. Auswahl wird persistiert.
  Tests: `test/services/app_settings_test.dart`. Gesamt **125 grün**.
- **System-Navigationsleiste verdeckt nichts mehr.** `RecordingScreen` (Fehlerkarte
  „Erneut versuchen") und `SettingsScreen` in `SafeArea(top: false)`; die Listen in
  `LibraryScreen`, `BookDetailScreen`, `BookSearchScreen` haben unten
  `MediaQuery.paddingOf(context).bottom` (+ `BooknoteTheme.fabSafeBottom` wo ein FAB
  sitzt) als Scroll-Abstand.
- **`BACKLOG.md` neu:** Sammelstelle für Wünsche „für später". Aktuell drin:
  importierbare Farbschemata (Theme-Datei laden), Export lokal speichern,
  Export als TXT. Deshalb ist die Theme-Schicht bewusst über einen Seed +
  `BooknoteTheme` + `AppSettings` gekapselt.

## Was in Baustein C (Bibliothek durchsuchen/filtern) passiert ist

- **`lib/models/book_query.dart` neu:** `filterBooks(books, {query, author})`
  (Freitext auf Titel **oder** Autor, Teilstring, case-insensitiv; plus
  optionaler exakter Autor) und `distinctAuthors(books)` (sortiert, ohne
  Dubletten/Leere). Reine Funktionen, getestet in
  `test/models/book_query_test.dart`. Repository bleibt unangetastet – die
  Bibliothek lädt weiter alle Bücher und filtert in Dart.
- **`LibraryScreen` ist jetzt `StatefulWidget`:** Lupe in der AppBar → AppBar
  wird zum Suchfeld (Zurück-Pfeil beendet, „×" leert). Darunter eine
  horizontale **`FilterChip`-Leiste** mit „Alle" + je einem Autor, aber nur
  wenn ≥ 2 Autoren vorhanden sind. Suche und Autorfilter wirken zusammen.
  Kein Treffer → Hinweis mit „Filter zurücksetzen". Grid/Empty-States in
  eigene kleine Widgets ausgelagert (`_BookGrid`, `_AuthorFilterBar`,
  `_EmptyHint`).
- **138 Tests grün**, analyze sauber.

## Was in Baustein B (Buchsuche mit Autor + Mikrofon) passiert ist

- **Ein kombiniertes Suchfeld** (Nutzerentscheidung): Titel und Autor im selben
  Feld als Freitext. Kein zweites Feld, kein Autor/Titel-Splitter. Google Books
  bekommt den Text schon 1:1 als `q=` (`GoogleBooksCoverService` unverändert),
  Freitext wie „Zauberberg Mann" trifft gut. `BookSearchScreen` zeigt jetzt
  `helperText: z.B. „Zauberberg Mann"`.
- **`lib/widgets/voice_input_button.dart` neu:** `VoiceInputButton` – kleines
  Mikrofon-Icon fürs Textfeld. Tippen öffnet ein **Bottom-Sheet** mit einem
  großen Aufnahme-Button (`RecordButton`, s.u.), der während der Aufnahme
  **pulsiert**. Stoppen: drauftippen **oder** automatisch nach ~1,3 s Stille
  (erst nachdem gesprochen wurde; Sicherheits-Limit 20 s). Dann
  `TranscriptionService.transcribe` → Sheet gibt den Rohtext zurück. **Kein**
  `NoteParser` (Suchtext). Fehler bleiben im Sheet mit „Nochmal" /
  „Einstellungen" (bei fehlendem/abgelehntem Key).
- **`lib/widgets/record_button.dart` neu:** `RecordButton` – der große runde
  Button, aus `recording_screen.dart` herausgezogen und geteilt (Aufnahme-Flow
  **und** Sprach-Sheet). Zustände `idle` / `recording` / `busy`, skaliert mit
  `size`.
- **`lib/services/silence_detector.dart` neu:** `SilenceDetector` – reine Logik
  „wann von selbst stoppen" (dBFS-Pegel rein, bool raus). `NoteRecorder`
  bekam `amplitudeDbfs()` (Stream des Pegels). Tests:
  `test/services/silence_detector_test.dart`.
- `BookSearchScreen.suffixIcon` ist `[VoiceInputButton, Such-IconButton]`;
  Spracheingabe schreibt ins Feld und löst die Suche aus.
- **130 Tests grün**, analyze sauber. Sheet/Recorder wie beim `RecordingScreen`
  nur auf dem Gerät verifizierbar.

## Nutzerwünsche (aus dem Test nach Schritt 5)

| Wunsch | Status |
|--------|--------|
| Datum/Uhrzeit klein an jeder Notiz | ✅ Schritt 6 |
| Autor optional eingeben, später aus DB (Google Books) vorbefüllt | ✅ Schritt 6 (Suche liefert Autor, Dialog zum Bearbeiten) |
| Notizen nach Seite oder Datum sortieren | ✅ war schon da (Icon oben rechts in der Notizliste) |
| Notizen bearbeiten | ✅ war schon da (Notiz antippen) |

## Nutzerwünsche (nach Schritt 6) – offen, für später

| Wunsch | Idee / Notiz |
|--------|--------------|
| Buchsuche: Autor optional angeben | ✅ Baustein B: ein kombiniertes Freitextfeld (Titel + Autor), Google-Books-Freitext. |
| Buchsuche per Sprache (Mikrofon rechts im Suchfeld) | ✅ Baustein B: `VoiceInputButton`, Ergebnis → Suchfeld, kein Autor/Titel-Splitter. |
| Bibliothek nach Autor filtern | ✅ Baustein C: `FilterChip`-Leiste (ab 2 Autoren). |
| Bibliothek nach Titel durchsuchen | ✅ Baustein C: Lupe → Suchfeld in der AppBar, Filter in Dart. |
| Sprache der Cover-Suche konfigurierbar | `BACKLOG.md`. Aktuell fest `de`, siehe Sprach-Fix. |

## Nächster Schritt

Bausteine A + B + C warten auf den gemeinsamen Gerätetest (Light/Dark auf allen
Screens, Theme-Umschalter, Navigationsleiste verdeckt nichts, Mikrofon-Sheet in
der Buchsuche mit Puls + Auto-Stop, Bibliothek durchsuchen/filtern).
**Gerät war beim Bauen von C abgesteckt – die Debug-APK ist gebaut, aber noch
nicht installiert** (`flutter install -d <ID> --debug`).

**Baustein D (Feinschliff Aufnahme-Flow):** Haptik beim Start/Stopp, Rückfrage
bzw. Verwerfen bei sehr kurzer Aufnahme (< 1 s), Hinweis bei sehr langer
Aufnahme, letzte Notiz direkt im `RecordingScreen` bearbeiten. Der große
`RecordButton` und `SilenceDetector` aus Baustein B sind wiederverwendbar.

Danach E (App-Icon, Release-Signierung). Ideen „für später" in `BACKLOG.md`.

~~**Schritt 7:** `lib/export/exporter.dart` (Interface `Exporter` mit
`export(Book, List<Note>) → ExportResult(fileName, mimeType, bytes)`),
`MarkdownExporter` gemäß PROJECT.md 8 (Abschnitt „Ohne Seitenangabe",
Sortierung nach Seite, Autor in Kopfzeile), Datei in Temp-Dir schreiben und
über `share_plus` teilen. Export-Icon im BookDetail aktivieren. Unit-Tests
für das Markdown. Danach Schritt 8 (Feinschliff Aufnahme-Flow).~~ (erledigt)

~~**Schritt 6:** `CoverService`-Interface + `GoogleBooksCoverSource` +
`OpenLibraryCoverSource` (Fallback), Ergebnisliste mit Cover-Thumbnails im
„Neues Buch"-Dialog zur Auswahl; optional Cover eines bestehenden Buchs im
BookDetail ändern. Google-Books-Key aus `ApiKeyStore` nutzen, wenn vorhanden.
Danach Schritt 7 (Markdown-Export, Share-Sheet) und 8 (Feinschliff).~~ (erledigt)

~~**Schritt 5 (UI):** Reihenfolge innerhalb des Schritts:
1. SettingsScreen (OpenAI-Key eingeben/ändern, Kostenhinweis) – nötig, um
   Whisper überhaupt testen zu können.
2. RecordingScreen: `record`-Package (m4a/AAC), Mikrofon-Permission in
   AndroidManifest + Info.plist, tap-to-start/stop, Transkribieren → Parser →
   `notes.create`, Feedback-Karte, mehrere Aufnahmen pro Sitzung, Audio bei
   Fehler behalten.
3. LibraryScreen als Cover-Grid + „Neues Buch"-Dialog (vorerst nur Titel,
   Cover-Auswahl kommt in Schritt 6).
4. BookDetailScreen (Liste, Sortierung, bearbeiten, löschen).
Services über `AppScope` durchreichen (TranscriptionService, ApiKeyStore, NoteParser).~~ (erledigt)

~~**Schritt 4:** `lib/services/note_parser.dart` (regelbasiert, deutsche
Zahlwörter, "folgende"/"f."/"ff.", Positionen) und
`lib/services/whisper_service.dart` (Multipart-POST an OpenAI, `language=de`),
dazu `api_key_store.dart` über `flutter_secure_storage`. Parser mit vielen
Unit-Tests. Audio-Aufnahme (`record`) + Mikrofon-Permissions folgen mit der
RecordingScreen-UI in Schritt 5.~~ (erledigt)

~~**Schritt 3:** `lib/repositories/sqlite/` mit `AppDatabase` (Öffnen, Schema v1,
Migrations-Hook), `SqliteBookRepository`, `SqliteNoteRepository`. Tabellen
`sources` und `notes` gemäß PROJECT.md 4 (IDs als TEXT/UUID, Zeitstempel als
INTEGER Unix-ms, `updated_at` zusätzlich, FK mit ON DELETE CASCADE).
Vertragstest über `sqflite_common_ffi` auf dem Desktop laufen lassen.~~ (erledigt)

## Offene Punkte / Hinweise

- Plattform-Setup für `record`/`flutter_secure_storage` ist erledigt (Schritt 5).
- Whisper auf dem Gerät mit echtem Key getestet: funktioniert, Parser trifft.
- Cover-Suche auf dem Gerät getestet, funktioniert. Sprachbias siehe oben.
- Share-Sheet-Export auf dem Gerät getestet, funktioniert.
- Google-Books-Key des Nutzers steht noch aus (siehe Diagnose oben).
- Übergabe an nächste Session: `HANDOFF.md` (Prompt zum Einfügen).
