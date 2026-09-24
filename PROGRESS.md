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
- Git: Branch `main`, Remote `origin` → `github.com/georg-doenges/booknote`
  (GitHub-CLI `gh`, Login per Device-Flow). Identität repo-lokal gesetzt.

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
  models/          Source, SourceType, Book, Note, Tombstone, LibrarySnapshot,
                   book_query.dart (filterBooks, distinctAuthors)
                   (+ models.dart Sammel-Export)                                  ✅
  repositories/sqlite/  … + LibraryArchive (Snapshot lesen/ersetzen)             ✅
  repositories/    BookRepository, NoteRepository (Interfaces) ✅, InMemory-Impl ✅,
                   watch_stream.dart (Helfer) ✅
  repositories/sqlite/  AppDatabase (Schema v1), SqliteBook/NoteRepository, Mapper ✅
  app_scope.dart   InheritedWidget, reicht Repositories + Services an die UI      ✅
  theme.dart       BooknoteTheme: Seed → hell/dunkel, Abstände, Komponenten       ✅
  services/        NoteParser + GermanNumberParser ✅, TranscriptionService-Interface
                   + WhisperService ✅, ApiKeyStore (Secure + InMemory) ✅,
                   AppSettings + AppSettingsStore (SharedPrefs + InMemory) ✅,
                   SilenceDetector ✅, Haptics (Vibrator, `vibration`) ✅,
                   mergeLibrary + LibrarySync (Geräte-Abgleich) ✅,
                   NoteRecorder (Hülle um `record`, m4a im Temp-Dir) ✅,
                   CoverService-Interface + FallbackCoverService,
                   GoogleBooksCoverService, OpenLibraryCoverService ✅
  export/          Exporter-Interface + ExportRequest, MarkdownExporter,
                   PlainTextExporter, showExportSheet, shareExport (share_plus)  ✅
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
| 8 | Feinschliff (Design/Theme, Aufnahme-Flow, Export, Geräte-Abgleich) | ✅ A–J auf Gerät bestätigt, inkl. Release-Signierung (E) |

### Schritt 8 in Bausteinen

| Baustein | Inhalt | Status |
|----------|--------|--------|
| A | Zentrales `lib/theme.dart`, Dark Mode + Umschalter, SafeArea, Abstände | ✅ auf Gerät bestätigt |
| B | Buchsuche: kombiniertes Feld, Mikrofon-Sheet (Puls, Auto-Stop) | ✅ auf Gerät bestätigt |
| C | Bibliothek nach Titel/Autor durchsuchen & filtern | ✅ auf Gerät bestätigt |
| D | Feinschliff Aufnahme-Flow (Haptik, Kurz-/Langaufnahme, Notiz-Edit, Titel-Edit) | ✅ auf Gerät bestätigt |
| F1 | Export: 3 Ebenen (Buch/Autor/Bibliothek) × Markdown/Text | ✅ auf Gerät bestätigt |
| F2 | Bibliotheksdatei: Grabsteine, additiver Merge, `adoptMaster`, Sichern/Abgleichen | ✅ auf Gerät bestätigt (Master nur logik-getestet – braucht 2. Gerät) |
| E | Release-Signierung | ✅ Keystore angelegt, Release-Build (`0.1.0+23`) mit `apksigner` als echt signiert verifiziert |
| G | Settings-Seite (Darstellung, Aufnahme/Vibration, API-Keys, Abgleich/GC) | ✅ auf Gerät bestätigt |
| H | Eigene Farbschemata (JSON-Import, Hintergrund-Layer, Schrift pro Theme, Theme-Katalog aus GitHub mit Blue Gold + Old Library) | ✅ Import/Themes auf Gerät bestätigt; Katalog (`+26`) noch nicht auf Gerät getestet |
| I | App-Icon (Nutzer-Entwurf) + Theme-Logos | ✅ auf Gerät bestätigt |
| J | Sprache pro Buch (Wahl beim Anlegen) + englischer NoteParser | ✅ auf Gerät bestätigt, nach zwei Korrekturrunden (siehe unten) |

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

## Was in Baustein G (Settings-Seite) passiert ist

- **`SettingsScreen` neu aufgebaut** als aufgeräumte, abschnittsweise Seite
  (`_Section`-Helfer: Titel in Primärfarbe + Erklärtext): **Darstellung**
  (Theme-Modus), **Aufnahme** (`SwitchListTile` Vibration), **API-Schlüssel**
  (OpenAI + Google Books + „Schlüssel speichern"), **Geräte-Abgleich**
  (`SwitchListTile` „Alte Löschungen vergessen" + `DropdownButton` Tage, nur
  wenn an). Alle Schalter außer den Text-Keys speichern sofort.
- **`AppSettings` + Store**: neu `hapticsEnabled` (Default true). `main.dart`
  hält `Haptics.enabled` per Listener mit den Settings synchron.
- Die GC-Felder (`tombstoneGcEnabled`/`Days`) haben jetzt ihre UI; der Merge
  liest sie schon seit F2b aus `AppSettings.sync`.
- Tests: `app_settings_test.dart` um Haptik + GC erweitert. **165 grün**.

## Was in Baustein E (Release-Signierung) passiert ist

- `android/app/build.gradle.kts` liest die Signierung aus `android/key.properties`
  (git-ignoriert). Fehlt die Datei, fällt der Release-Build auf den Debug-Key
  zurück – nichts bricht. `flutter build apk --release` verifiziert (Fallback).
- **`SIGNING.md`**: Schritt-für-Schritt für den Nutzer (Keystore per `keytool`
  anlegen, `key.properties` füllen, `flutter build apk --release`). Passwörter
  wählt der Nutzer selbst.
- App-Icon war zunächst offen (BACKLOG) – inzwischen gebaut, siehe unten.

## Clean Mode, gleich hohe Kacheln, „Buch bearbeiten" — `0.1.0+29`

*Veröffentlichung:* Das APK liegt in den Releases stets unter dem festen Namen
**`booknote.apk`**, damit die README auf
`…/releases/latest/download/booknote.apk` verlinken kann (der Link zeigt immer auf
die neueste Nicht-Pre-Release-Version). Bei jedem Release die Datei so benennen.

Nutzerwunsch nach dem Gerätetest: (1) ein **Clean Mode**, der die Erklärungen
ausblendet (der Standard bleibt: alles erklärt, für neue Nutzer); (2) die zwei
Punkte aus dem BACKLOG („Buch bearbeiten": Sprachwahl nicht zu finden; Kacheln
unterschiedlich hoch).

- **Clean Mode** (Einstellungen → Anzeige, `AppPrefs.cleanMode`, Standard aus,
  gespeichert unter `clean_mode`). Ausgeblendet werden reine Erklärungen, nie
  Beschriftungen, Überschriften, Statusmeldungen, Fehler oder Warnungen:
  Beispiel-/Hilfetexte unter Feldern (Buchsuche, API-Schlüssel, Notiz-Felder),
  Abschnitts-Erklärungen in den Einstellungen, der Hinweis unter der
  Sprach-Auswahl, „Sprich z.B. …", „Tippen zum Aufnehmen" (nur im Ruhezustand)
  und der Hinweis bei langen Aufnahmen, die Erklärung im Menü der
  Aufnahmesprache, die Abgleich-Einleitung samt Hinweisen unter den Knöpfen,
  Einleitung und Beschreibungszeilen im Farbschema-Katalog, „Titel eingeben, um
  Cover zu suchen", die zweite Zeile der leeren Bibliothek („Lege mit + …" →
  nur „Noch keine Bücher."). **Bleibt:** der Schalter samt seinem Satz (sonst
  findet man nicht zurück), die Warnungen und Bestätigungsdialoge des Abgleichs
  (Weich/Hart löscht ggf. Daten), Fehlermeldungen, „Noch keine Notizen …".
- **Technik:** `AppScope` ist jetzt ein `InheritedNotifier<AppSettings>` – wer
  `AppScope.of(context)` aufruft, baut bei jeder Einstellungsänderung neu, der
  Schalter wirkt also sofort auf jeder offenen Seite. `context.cleanMode` /
  `context.explain(text)` (→ `null` im Clean Mode, für `helperText`/`subtitle`/
  `caption`) und das Widget `Explanation` (Block samt Abständen) in
  `lib/app_scope.dart`; ohne `AppScope` (z.B. ein Widget für sich im Test) gilt
  der Normalfall. Neue Texte: `settingsCleanMode(Sub)`, `libraryEmptyShort`.
  README (en/de): ein Satz dazu.
- **Kacheln gleich hoch.** Erste Vermutung (Cover mit anderem Seitenverhältnis
  unter `BoxFit.contain`) war nur ein Nebeneffekt. **Eigentliche Ursache** (am
  Gerät gefunden): Die Cover-Fläche ist `Expanded` und bekam, was der Text
  darunter übrig ließ – drei Zeilen (2× Titel + Autor) drückten sie kleiner als
  zwei; `BookCoverTile` gibt dem Text jetzt einen **festen Platz**
  (`textBlockHeight`). Dazu, weiter sinnvoll: gefüllte Kartenfläche
  (`surfaceContainerLow`) hinter jedem Cover und kräftigerer Rahmen (Alpha 0,3),
  Zellen niedriger (Cover-Fläche **3:4** statt 2:3), zurückhaltender Platzhalter
  (kleineres Icon, `labelMedium`, max. 4 Zeilen). Der Test misst jetzt die
  Cover-Fläche selbst; der erste Test maß nur die Zelle und hätte den Fehler nie
  gefunden.
- **„Buch bearbeiten":** Zwei Gründe, warum die Sprachwahl nicht zu finden war:
  Der Dialog öffnete mit Autofokus und Tastatur, die sie verdeckte (kein
  Autofokus mehr, Dialog scrollbar) – und der Menüpunkt hinter ⋮ hieß „Titel /
  Autor bearbeiten", ohne die Sprache zu nennen. Jetzt steht in der Kopfzeile der
  Buch-Details **Autor · Sprache** und ein **sichtbarer Stift** in der AppBar
  („Titel, Autor, Sprache bearbeiten"); der Menüpunkt hinter ⋮ entfällt. Neben
  vier Symbolen blieb für den Titel in der AppBar kein Platz (nur die ersten
  Buchstaben) – deshalb steht die AppBar nur noch aus Pfeil und Symbolen, und
  Titel (zwei Zeilen, `titleLarge`) samt „Autor · Sprache" darunter im Inhalt
  (`_BookHeader`).
- **Aufnahme-Screen im Clean Mode:** Der Aufnahme-Knopf saß links, weil die Spalte
  ohne die breiten Hinweistexte nur so breit war wie ihr breitestes Element und
  im Scroll-Bereich links ausgerichtet wird. Jetzt `minWidth` = volle Breite.
  Lehre: Ein „Element ausblenden" kann Layout ändern, das an ihm hing.
- **Prüfung:** `flutter analyze` sauber; Debug-Build läuft. Neue Tests
  (`localized_screens_test`: Clean Mode je Bildschirm, Autofokus;
  `app_settings_test`; `book_cover_tile_test`: gleiche Höhe, Kartenfläche, 3:4)
  **geschrieben, aber nicht ausgeführt** (Smart App Control blockiert
  `flutter_tester.exe`) – ebenso wenig am Gerät gesehen.

## Vier neue Katalog-Schemata, Blue Gold matter (nur Repo, keine neue App)

Nutzerwunsch: weitere Schemata zum Ausprobieren, um den Katalog-Weg mit der
bestehenden Installation zu testen – ein „cleanes" mit viel Weiß, ein kräftigeres
(Tequila Sunrise war zu spärlich), Muster als Idee.

- **Neu in `themes/`:** *Clean Slate* (hell: Weiß, neutrale Grautöne, ein
  Stahlblau `#3A6088` als einziger, ruhiger Akzent; alle `surfaceContainer*`
  ausdrücklich neutral), *Sundown* (Pflaumenviolett, Orange, Pink; Farbe auf den
  großen Flächen), *Book Cloth* (flaschengrünes Leinen mit Koralle; **Gewebe als
  Hintergrund-Kachel**, `fit: tile`), *Graphite* (neutrales Dunkelgrau, Mintgrün).
  Jeweils Beschreibung de/en/fr, eingefärbtes Logo (Vorschau im Katalog),
  `revision: 1`, nur Systemschrift.
- **Blue Gold: mattes Altgold** statt grellem Gelb: `#C6A052` (Sättigung 50 %) →
  `#BD9B5E` (42 %, Ton bleibt warm), passend Text, Container und Logo; dazu die
  Serifenschrift **Tinos** wie bei Old Library (`font`, steckt schon im APK).
  `revision: 3` → die Apps bieten „Aktualisieren" an.
- **Webmuster:** `tool/weave_tile.js` erzeugt eine nahtlose Leinwandbindung
  (120 × 120 px, Fadenabstand 5, Fäden leicht verschieden getönt, Längsstreifen,
  sanfte Unregelmäßigkeit; wiederholbar per `--seed`). Erster Wurf sah wie ein
  Schachbrett aus (Kette/Schuss zu verschieden, jede Kreuzung ein Klotz) – dann
  Farben angeglichen, Kreuzungen weicher, Fadenabstand feiner. `surface` = mittlere
  Kachelfarbe (`#13352F`); hellster Texel `#194A41` hält Fließtext ≥ 7:1.
- **Katalog-Index abwärtskompatibel:** Die veröffentlichte +26 liest `description`
  nur als Text; ein Sprach-Objekt (wie es der Index seit dem Mehrsprachigkeits-
  Umbau hatte) hätte dort den Katalog kaputt gemacht. `index.json` trägt deshalb
  `description` (deutscher Text) **und** `descriptions` (de/en/fr);
  `ThemeCatalogEntry.fromJson` bevorzugt `descriptions`.
- **Prüfung:** Kontrast-Skript über alle Katalog-Themes (Text-/Flächenpaare,
  WCAG); neue Schemata bestehen alle. Vorbestehend knapp: Blue Gold `outline`
  2,0:1 zu `surface` (Rahmen der Eingabefelder), Old Library `tertiary` 4,3:1
  (nur der lange Aufnahme-Hinweis) – nicht angefasst. Dauerhafte Tests in
  `themes_catalog_test.dart` (Charakter der Schemata, Altgold-Bereich, Kontrast,
  Index-Kompatibilität) und `theme_catalog_service_test.dart` – **geschrieben,
  aber nicht ausgeführt** (Smart App Control blockiert `flutter_tester.exe`).
  `flutter analyze` sauber, `dart run tool/build_theme_index.dart` läuft.
- **Offen:** nicht committet/gepusht (Repo ist öffentlich, Nutzer entscheidet);
  am Gerät noch nicht gesehen – ob das Leinen in echt zu unruhig ist, zeigt erst
  das Handy (Stellschrauben: `--pitch`, `--relief`, `--jitter`, oder `opacity`
  im Theme).

## Cover ohne Beschnitt, Mehrsprachigkeit (de/en/fr) — `0.1.0+27`

Anlass: Gerätetest auf einem neuen Handy. (1) Ein Google-Books-Cover („Der
Zauberberg") war oben und unten stark abgeschnitten; (2) die erste Testerin
spricht Englisch bzw. Französisch/Flämisch – die App war rein deutsch.

**Cover nie beschneiden.** Neues `FramedCover`: `BoxFit.contain` statt `cover`,
übrige Fläche behält die Hintergrundfarbe, dazu ein dezenter Rahmen in der
Schriftfarbe (`onSurface`, alpha 0,22 – passt in jedes Schema). Gilt für die
Kacheln der Bibliothek und die Trefferliste der Buchsuche. Die Kacheln sind
höher: `CoverGridDelegate` gibt der Cover-Fläche in jeder Zelle das Hochformat
2:3 (vorher ~0,82:1) und rechnet die Textzeilen darunter aus der Systemschrift
ein. Beim Testen fiel auf: Der Platzhalter für Bücher ohne Cover lief bei sehr
langen Titeln in schmalen Spalten über (`Flexible` ergänzt).

**Drei Sprachen: Deutsch, English, Français.** Flutters `gen-l10n`
(`l10n.yaml`, `lib/l10n/app_{de,en,fr}.arb`, 197 Texte je Sprache, Vorlage
Deutsch), Zugriff über `context.l10n`.
- *Sprache der App:* neu unter Einstellungen → App-Sprache („Wie das Gerät" /
  Deutsch / English / Français), gespeichert in `AppPrefs.uiLanguage`. Ohne
  Wahl gilt die Gerätesprache; ist sie keine der drei (z.B. Niederländisch),
  fällt die App auf **English** zurück (`resolveAppLocale`), nicht auf Deutsch.
- *Aufnahme-/Buchsprache* ist jetzt ebenfalls dreisprachig: `AppLanguage.french`
  (Whisper `fr`, Cover-Suche, Präfix „p."), neuer `FrenchNumberParser`
  („quarante-sept", „quatre-vingt-dix-sept", belgisch „septante"/„nonante") und
  ein französischer Regelsatz im `NoteParser` („page 47 en haut", „ligne 10",
  „et suivantes"/„sq."/„sqq." → f./ff.). Die Sprache des Buchs startet beim
  Anlegen mit der App-Sprache; wie die Sprachebenen bedient werden, steht im
  nächsten Abschnitt.
- *Fehlermeldungen der Services* sind keine deutschen Texte mehr, sondern
  Typen (`TranscriptionErrorKind`, `CoverSearchErrorKind`, `ThemeCatalogErrorKind`,
  `CustomThemeErrorKind`, `LibraryFileErrorKind` + Status/Name/Ursache); die UI
  formuliert sie in `lib/l10n/l10n.dart` in der Sprache der App.
  `CoverSearchResult.warning` ist dafür ein `CoverSearchException?`.
- *Exporte:* `ExportLabels` (Überschriften, Platzhalter, Datumsformat) im
  `ExportRequest`, Vorgabe Deutsch (bestehende Ausgaben unverändert); der
  Export-Sheet übergibt die Sprache der App. Der Seitenpräfix („S."/„p.")
  richtet sich weiter nach der Sprache der Notiz.
- *Datum:* Deutsch wie gehabt numerisch, English/Français mit Monatsname
  (`Sep 5, 2026, 7:26 PM` / `5 sept. 2026, 19:26`) – nie Tag/Monat verwechselbar.
- *Systemdialoge* („Speichern unter", Dateiwähler) bekommen ihren Titel
  übersetzt übergeben; die Spracheingabe für Buchtitel nutzt jetzt die
  Buch-/Suchsprache statt fest Deutsch.
- *Theme-Katalog:* `description` darf ein Text oder je Sprache `de/en/fr` sein.
- *README:* Hauptdatei jetzt **englisch** (Tester), `README.de.md` deutsch,
  gegenseitig verlinkt. Französische Übersetzungen bitte von einem
  Muttersprachler gegenlesen lassen.
- Tests: 404 grün (vorher 270). Neu: französische Zahlwörter/Notizen (80),
  ARB-Konsistenz (gleiche Schlüssel und Platzhalter in allen drei Dateien,
  keine ASCII-Apostrophe, französische Typografie), Fehlertexte in allen
  Sprachen, Sprachauflösung, Screen-Smoke-Tests (Bibliothek, Buch anlegen,
  Einstellungen inkl. Sprachwechsel, Aufnahme-Screen, Katalog, Notiz-Kachel)
  je Sprache über die Gerätesprache, plus Cover-/Raster-Tests.
  Auf Gerät noch nicht getestet.

### Sprachebenen: lokal statt global erkennbar (Usability-Durchgang)

Es gibt drei Sprachen-Ebenen; der Nutzer soll auf einen Blick sehen, auf welcher
er gerade ist, ohne dass ihm das Konzept erklärt wird. Grundsatz: **Was nur ein
Buch oder eine Aufnahme betrifft, steht beschriftet im Inhalt der Seite – nie
als Symbol in der AppBar.** Dort erwartet man App-weite Dinge; das alte
Übersetzen-Symbol („🌐 DE ▾") sah an zwei Stellen gleich aus, meinte aber
verschiedenes und zeigte seinen Zweck nur als Tooltip (auf dem Handy unsichtbar).

| Ebene | Wo | Wie |
|---|---|---|
| App (global) | Einstellungen → **App-Sprache** | Auswahlliste; einzige globale Sprachwahl |
| Buch | Neues Buch (Suchseite) und „Buch bearbeiten" | Überschrift **„Sprache dieses Buchs"** + Chips `Deutsch / English / Français`, Hinweis „Für Aufnahmen und Cover-Suche. Lässt sich später ändern." |
| Aufnahme (nur jetzt) | Aufnahme-Screen, Kopfzeile über dem Knopf | Schaltfläche **„Aufnahmesprache: Deutsch ▾"**; das Menü beginnt mit „Nur für jetzt. Sprache des Buchs: …". Weicht die Wahl vom Buch ab, ist sie farbig hervorgehoben; der Beispielsatz darunter wechselt mit |

- Neue Widgets: `LanguageChoice` (Chips, bricht bei mehr Sprachen um),
  `RecordingLanguageChip`. `LanguageMenuButton` ist entfernt.
- **Cover-Suche folgt der Sprache des Buchs** – die eigene, global gespeicherte
  Cover-Sprache (`coverSearchLanguage`, AppBar der Suchseite) entfällt: sie stand
  neben der Buchsprache auf derselben Seite und war global, sah aber lokal aus.
  Beim Wechsel der Buchsprache wird neu gesucht; „Cover ändern" nutzt die
  Sprache des Buchs (`BookSearchScreen.bookLanguage`). Ein alter Wert `lang_cover`
  wird beim nächsten Speichern der Einstellungen aufgeräumt.
- **Sprache des Buchs ist jetzt nachträglich änderbar** („Buch bearbeiten",
  auch per langem Druck auf den Titel im Aufnahme-Screen). Vorher ging das
  nicht, und `BookRepository.update` hätte sie auch nicht gespeichert – beide
  Repositories schreiben jetzt `language`. Im Aufnahme-Screen stellt die Änderung
  die laufende Aufnahmesprache gleich mit um. Bereits gespeicherte Notizen
  behalten ihre eigene Sprache.
- Tests geschrieben (`localized_screens_test`, `repository_contract`,
  `app_settings_test`), **aber nicht ausgeführt**: Windows Smart App Control
  blockiert seit dem 24.09.2026 Flutters `flutter_tester.exe` (unsigniert;
  Ereignis 3077 im CodeIntegrity-Log), alle 27 Testdateien scheitern schon beim
  Laden. `flutter analyze` ist sauber, der Debug-Build läuft.

## Theme-Katalog aus GitHub, Themes raus aus dem APK — `0.1.0+26`

Nutzerwunsch: Farbschemata als „Gimmick" nach und nach im Repo erweitern und
direkt aus der App laden können; Blue Gold und Old Library sollen selbst über
diesen Weg kommen (Funktion gleich mit getestet).

- **Katalog im Repo:** `themes/` (Theme-Dateien, `index.json`,
  `previews/<id>.png`). `tool/build_theme_index.dart` erzeugt Index + Vorschauen
  aus den Theme-Dateien (`dart run tool/build_theme_index.dart`). Neue Felder im
  Theme-Format: `revision` (Inhaltsstand, Basis für „Aktualisieren") und
  `description` (Katalogzeile). Blue Gold und Old Library sind auf `revision: 2`
  – so bekommen Geräte mit alter, logo-loser Kopie („Stolperstein" unten) ein
  „Aktualisieren".
- **App:** `ThemeCatalogService` (HTTP, `raw.githubusercontent.com/…/themes/`,
  Timeout, Größenlimits, nur schlichte relative Dateipfade, `id` muss zur Datei
  passen) und `ThemeCatalogScreen` („Farbschemata laden": Installieren →
  laden, speichern, einschalten; Aktualisieren ändert das aktive Schema nicht;
  Fehlerzustand mit „Erneut versuchen"). Einstiegsbutton in den Einstellungen,
  „Importieren …" heißt jetzt „Aus Datei …". `ThemeSwatch` ist jetzt eine
  gemeinsame Kachel für die Liste der installierten Schemata und den Katalog
  (Logo, sonst Farbkachel) – beide sehen gleich aus.
- **Aus dem APK entfernt:** `assets/themes/`, `_bundledAssets`, Erststart-Kopie,
  „… wiederherstellen". `CustomThemeStore` liest nur noch den Themes-Ordner
  (Verzeichnis injizierbar → testbar). Auf frischen Geräten ist die Liste leer,
  bis man aus dem Katalog lädt (braucht Internet).
- **Schrift:** Tinos bleibt im APK (Themes können keine Schrift mitbringen);
  `assets/fonts/OFL.txt` (SIL OFL 1.1, aus `googlefonts/tinos`) ergänzt.
- **Härtung, weil jetzt Dateien aus dem Netz kommen:** `CustomTheme.id` wird auf
  `A-Za-z0-9_-` beschränkt (dient als Dateiname; `../x` in einer fremden Datei
  würde sonst aus dem Themes-Ordner ausbrechen); `CustomThemeStore.import`
  dekodiert UTF-8 richtig (vorher `String.fromCharCodes` → Umlaute im Namen
  wurden zerstört).
- **Kleinigkeiten aus der Status-Runde:** README/THEMES.md sprachen noch von
  „Einstellungen → Darstellung" (gibt es seit der Trennung nicht mehr), der
  Releases-Link im README ist jetzt absolut, Lizenztext für Tinos liegt bei.
- **README:** aufmunternder Hinweis auf Farbschemata gleich am Anfang plus
  kurzes Kapitel „Farbschemata laden".
- **Tests:** 270 grün (vorher 235): Katalog-Dienst (Index, unsichere Einträge,
  Fehler, Timeout, Größenlimit), Store (Import/Update/Löschen/Umlaute/Pfadtrick),
  Widget-Test des Katalog-Screens (Installieren/Aktualisieren/Fehler/Retry) und
  ein Repo-Test, der `themes/index.json` gegen die Theme-Dateien prüft und dass
  jede genannte Schrift im APK deklariert ist. Auf Gerät noch nicht getestet.

## Settings-Trennung, Old-Library-Theme, Schrift pro Theme, README — `0.1.0+24`/`+25`

**Settings-Screen:** „Darstellung" in zwei eigenständige `_Section`s
aufgeteilt – **Anzeige** (System/Hell/Dunkel) und **Eigene Farbschemata** –,
jede mit eigenem Erklärtext. Vorher ein gemeinsamer Block, in dem nicht klar
war, dass beides sich gegenseitig ausschließt.

**„Old Library" ersetzt „Tequila Sunrise"** (`assets/themes/old_library.json`,
`CustomThemeStore._bundledAssets`): helles Pergament/Leder-Farbschema, Logo
wie gehabt per `recolor.js` erzeugt (neue Palette `old_library` dort).
Erster Entwurf hatte den Bordeaux-Ton (`#9C4B3A`) nur auf `tertiary` gelegt –
in Material 3 eine kaum sichtbare Rolle. Nutzer-Feedback („Akzent nicht
gefunden") → Farben getauscht: Bordeaux ist jetzt `primary` (Aufnahme-Button,
Titel, Häkchen), das Leder-Braun `secondary`. `error` bewusst auf einen davon
klar unterscheidbaren Rotton gelegt.

**Schrift pro Theme, neu:** `CustomTheme.fontFamily` (JSON-Feld `font`, nur
ein Name – anders als `logo`/`background` keine eingebettete Datei, dafür zu
groß). `BooknoteTheme._themeFrom` reicht ihn als `ThemeData.fontFamily`
durch, wirkt dadurch appweit ohne Screen-Anpassungen. Erste Nutzung:
**Tinos** (Google, SIL OFL 1.1, metrisch zu Times New Roman kompatibel;
`assets/fonts/Tinos-*.ttf`, ~2,2 MB, von `github.com/google/fonts`
heruntergeladen) für „Old Library". Unbekannter `font`-Name → stille
Rückfalllösung auf die Systemschrift.

**Stolperstein dokumentiert** (`THEMES.md`): mitgelieferte Theme-Dateien
werden nur **einmalig beim Erststart** aufs Gerät kopiert – Änderungen an der
Asset-Datei (z.B. ein neu ergänztes `logo`-Feld) erreichen ein schon
initialisiertes Gerät nie automatisch. Einzige Auffrischung: löschen +
„… wiederherstellen".

**README neu geschrieben** (vorher Flutter-Boilerplate): jetzt eine
Tester-Anleitung – ganz einfache Übersicht zuerst (Kernnutzen, ein Satz),
dann APK-Installation, dann eine laienfreundliche Schritt-für-Schritt-
Anleitung für den eigenen OpenAI-API-Key (Link, Hinweis auf ~5 $ Guthaben,
Konto selbst kostenlos/Nutzung kostenpflichtig). Geräte-Abgleich bewusst nur
als ein Bullet-Punkt mit Verweis auf `SYNC_DESIGN.md`, nicht ausführlich
erklärt – zu komplex für den Einstieg.

235 Tests grün, `flutter analyze` sauber. Auf Gerät installiert
(`0.1.0+25`), vom Nutzer freigegeben.

## Testrunde: Aufnahme-Button, Sprachwahl-Platzierung — `0.1.0+22`/`+23`

Zwei Korrekturen aus dem Gerätetest der vorigen Runde.

**Aufnahme-Button verrutschte** (neu seit dem Overflow-Fix): die zentrierte
Spalte im `RecordingScreen` ändert ihre Gesamthöhe je nach Phase (Leerlauf mit
Hinweistext + „Alle Notizen"-Button, Aufnahme mit Timer, Transkribieren fast
leer) – da die ganze Spalte zentriert wird, wanderte der Button mit. Fix: die
Blöcke unter dem Button (Timer, Lang-Aufnahme-Hinweis, Erstnutzer-Tipp,
„Alle Notizen") stecken jetzt in `Visibility(maintainSize: true, …)` – sie
belegen **immer** denselben Platz, werden nur ein-/ausgeblendet. Gesamthöhe
bleibt phasenunabhängig konstant, Button bewegt sich nicht mehr.

**Sprachwahl beim Buch-Anlegen** – zwei Anläufe:
1. Erst ein extra Dialog nach der Cover-Auswahl + eine prominente
   Sprachauswahl auf dem `RecordingScreen` (nur beim ersten Aufruf via
   `justCreated`-Flag). Nutzer-Feedback: der Dialog ist ein überflüssiger
   Extra-Schritt, und die prominente Auswahl blieb fälschlich für *jede*
   Notiz derselben Sitzung sichtbar statt nur einmalig.
2. Beides zurückgebaut. Stattdessen: `BookSearchScreen` (Titel-/Autor-Eingabe,
   `newBook`-Flag default `true`) zeigt direkt unter dem Titelfeld „Sprache
   für Aufnahmen zu diesem Buch" (`SegmentedButton<AppLanguage>`, Deutsch
   vorbelegt) – bei „Cover suchen" für ein bestehendes Buch
   (`BookDetailScreen._changeCover`, `newBook: false`) nicht. `BookSearchResult`
   trägt jetzt `language` zurück an `LibraryScreen._addBook`, das direkt an
   `books.create(language:)` reicht. `showBookLanguageDialog` +
   `book_language_dialog.dart` wieder entfernt; `RecordingScreen.justCreated`
   ebenfalls – dort bleibt nur die kleine AppBar-Sprachauswahl für die
   gelegentliche Einzelaufnahme-Übersteuerung.

232 Tests grün (unverändert – reine Screen-Verdrahtung, keine Logikänderung),
`flutter analyze` sauber. Beide Punkte auf dem Gerät bestätigt.

## App-Icon, Theme-Logos, Sprache pro Buch, Englisch-Parser — `0.1.0+21`

Vier Punkte aus einer Session: der Nutzer hat mit ChatGPT ein Icon-Motiv
erstellt (aufgeschlagenes Buch + goldener Notizzettel, Navy/Messing/Gold) und
als PNG geliefert; dazu drei Testrunden-Rückmeldungen.

**App-Icon** (`assets/icon/source.png`, 1254×1254, vom Nutzer geliefert):
- `assets/icon/icon_legacy.png` (volles Motiv, Rahmen) + `icon_foreground.png`
  (Motiv ohne Rahmen, neu zentriert, für Androids adaptives Icon) via
  `flutter_launcher_icons` (neue Dev-Dependency). Border wird beim Zuschnitt
  entfernt (Diagonal-Scan gegen die Eckenrundung, nicht nur den geraden Rand).
  `adaptive_icon_foreground` bleibt **full-bleed** – Android/das Paket legen
  selbst 16 % Sicherheitsrand an; doppelt geschrumpft sah es zu klein aus.
- Auf Gerät bestätigt: Icon erscheint korrekt in Kachel-Vorschau (Task-Switcher),
  Daten beim Reinstall erhalten.

**Theme-Logos** (Nutzerwunsch: Icon soll die Farben des aktiven Skins tragen):
- Android kann das echte Homescreen-Icon nicht ohne Weiteres pro In-App-Theme
  umschalten (bräuchte `<activity-alias>` + natives `PackageManager`-Umschalten,
  launcherabhängig) → als eigener, größerer Punkt ins BACKLOG. Stattdessen:
  **das App-Icon-Motiv wird pixelgenau umgefärbt** (`assets/icon/recolor.js`:
  jeder Pixel wird den zwei nächsten von vier Referenzfarben zugeordnet und
  dorthin linear verschoben – Geometrie/Antialiasing bleiben exakt erhalten,
  nur der Farbton ändert sich).
  - **Braun** (Marken-Standard, kein Custom-Theme aktiv) → das echte App-Icon.
  - **Blue Gold** / **Tequila Sunrise** → je ein neues `logo`-Feld in der
    Theme-JSON (Base64, wie `background.image`), als Vorschau in der
    Farbschema-Liste der Einstellungen (`_Swatch` zeigt das Logo statt der
    abstrakten Farbkachel, wenn eins da ist).
  - `CustomTheme.logoBytes` + `decodeDataUri()`-Hilfsfunktion (auch von
    `ThemeBackground.fromJson` genutzt).

**Sprache pro Buch** (`Source.language`, Schema v4, Default Deutsch):
- Dialog beim Anlegen eines Buchs (`showBookLanguageDialog`, neu in
  `library_screen.dart`), bevor `books.create(..., language:)` läuft.
- `RecordingScreen` startet mit `_book.language`; das Sprachmenü in der AppBar
  übersteuert nur die aktuelle Sitzung (lokaler State), ohne die Buch-Vorgabe
  zu ändern – beim nächsten Öffnen gilt wieder sie.
- `Note.language` speichert, in welcher Sprache **diese** Notiz tatsächlich
  aufgenommen wurde (kann von der Buch-Vorgabe abweichen). Steuert „S." vs.
  „p." bei der Seitenangabe (`pagePrefix()` in `widgets/format.dart`,
  genutzt von `noteLocationLabel` + beiden Exportern).
- `AppSettings.recordingLanguage` (global) ersatzlos entfernt – überflüssig,
  seit die Sprache am Buch hängt. `coverSearchLanguage` bleibt (unabhängiges
  Setting für die Cover-Suche).
- `LibrarySnapshot` (Sync-Datei) trägt `language` für Sources und Notes mit;
  fehlt es (alte Datei), gilt Deutsch.

**Englischer NoteParser** (`EnglishNumberParser` + `NoteParser._parseEnglish`):
- Eigenes Regelwerk: `page 47`, `on page 5`, `p. 9`, Zahlwörter als ein
  zusammenhängendes/mit Bindestrich verbundenes Wort (`forty-seven`).
  `top`/`middle`/`center`/`centre`/`bottom`, `line 10`. `following`/`following
  page(s)`/`onwards` → f./ff. (im Englischen wie im Deutschen ein gültiges
  Zitierkürzel). Bekannte Lücke: unverbundene Zahlwörter mit Leerzeichen
  („forty seven") erkennt der Satz-Parser nicht (der einzelne Zahlwort-Parser
  schon) – in der Praxis unkritisch, da Whisper englische Zahlen fast immer zu
  Ziffern normalisiert.
- German-Pfad unverändert (eigene Methode `_parseGerman`, keine gemeinsame
  Logik erzwungen – die deutsche „f."/„ff."-Unterscheidung nach *Wortlaut*,
  nicht nach Regel-Gruppe, wollte ich nicht anfassen).

Vor dem Aufspielen zusätzlich geprüft: `flutter build apk --release` läuft
sauber durch (fällt mangels Keystore auf Debug-Signierung zurück) – die
Release-Pipeline selbst (R8/Minifizierung) ist also unabhängig vom Keystore
schon mal verifiziert.

232 Tests grün (u.a. neue Gruppen für `EnglishNumberParser`,
„NoteParser (Englisch)", `note_tile_test.dart`, Sprache in
`repository_contract.dart` + `migration_test.dart`), `flutter analyze` sauber.
Schema-Migration v3→v4 auf dem echten Gerät gefahren (Daten erhalten).

## Eigene Farbschemata (Custom Themes) — `0.1.0+18`

Nutzerwunsch: ladbare Farbschemata, unaufdringlich in den Einstellungen, als
Erstes „Blue Gold" (nach dem Screenshot einer anderen App: Navy + Messing/Gold).

- **`CustomTheme` + `ThemeBackground`** (`models/custom_theme.dart`): eine
  portable JSON-Datei (`format: booknote-theme`, `formatVersion: 1`), `seed` +
  optionale Overrides einzelner Material-Rollen (Whitelist ~30 Rollen, alles
  andere wird ignoriert) + optionaler `background` (Bild als data-URI
  eingebettet). Format-Doku: `THEMES.md`.
- **`CustomThemeStore`** (`services/`, `ChangeNotifier`): **alle** Themes liegen
  als `<App-Dokumente>/themes/<id>.json` und sind gleichwertig – auch die
  mitgelieferten lassen sich löschen. `assets/themes/*.json` werden beim
  Erststart einmalig dorthin kopiert (Marker `.initialized`). `restorable` +
  `restore(id)` holen ein gelöschtes mitgeliefertes Schema aus den Assets
  zurück. Nach ID entdoppelt. Import validiert und schreibt die Datei.
- **`BooknoteTheme.custom(CustomTheme)`** (`theme.dart`): Schema aus dem Seed,
  dann die gesetzten Rollen per `ColorScheme.copyWith`. Ein Custom-Theme ist
  **ein fester Look** – folgt nicht System-Hell/Dunkel (v1; „hell + dunkel in
  einem File" steht im BACKLOG).
- **Hintergrund-Layer** ist in Datenstruktur **und** Rendering angelegt
  (`_ThemeBackground` in `main.dart`: Fläche → Bild (cover/tile) → optionaler
  Dim-Schleier → Inhalt; Scaffold wird bei Bild transparent, AppBar/Leisten
  bleiben deckend). „Blue Gold" nutzt keinen Hintergrund – ein Theme mit Bild
  liefe aber ohne weitere Änderung.
- **`AppPrefs.activeCustomThemeId`**: aktives Custom-Theme; System/Hell/Dunkel
  wählen setzt es auf `null`. UI in `SettingsScreen` → Darstellung:
  Segment-Umschalter (leer, wenn Custom aktiv) + Liste „Eigene Farbschemata"
  (RadioGroup, Swatch-Vorschau) + „Importieren …" + Mülleimer fürs **aktive**
  Schema + „… wiederherstellen" je fehlendem mitgelieferten Schema.
- **`assets/themes/blue_gold.json`** mitgeliefert.

Gerätetest 1 (`0.1.0+17`, Daten erhalten): 1 Cover beim Start, 2 „x Notizen"
ohne Overflow, 3 Notiz-Badges, 5 „Blue Gold" an/aus, 6 Import einer eigenen
Datei (`sepia.json`): alles **bestätigt**.

Nachbesserung (`0.1.0+18`), aus Gerätetest 1:

- **Alle Schemata löschbar, auch mitgelieferte.** Vorher war „Blue Gold" fest;
  der Nutzer wollte „alles unter Eigene Farbschemata muss löschbar sein". Jetzt
  wird `blue_gold` beim Erststart in `<docs>/themes/` kopiert und ist wie jedes
  importierte Schema löschbar. Fehlt ein mitgeliefertes Schema, erscheint
  „„Blue Gold" wiederherstellen". `CustomTheme.builtIn` entfernt.
  Auf Gerät bestätigt (Liste zeigt Blue Gold + Sepia, beide löschbar,
  Wiederherstellen erscheint nur bei Lücke, Daten erhalten).
- **Punkt 4 (Dateiwähler):** bleibt. Der Android-Systemwähler (SAF/DocumentsUI)
  bestimmt Anzeige *und* Ansicht (Liste/Kacheln) – eine App kann Fremdformate
  nur **sperren** (passiert, ausgegraut), nicht ausblenden, und die Ansicht
  nicht vorgeben. Echtes Ausblenden bräuchte einen eigenen In-App-Dateibrowser
  (Scoped Storage). → BACKLOG, rein kosmetisch.
- 7/8 (Neustart-Persistenz, kaputte Datei) vom Nutzer nicht geprüft, als ok
  angenommen.
- 173 Tests grün, `flutter analyze` sauber.

Offen (BACKLOG): Theme-Repository auf GitHub mit `themes/`-Unterordner zum
Herunterladen/Teilen (auch „Blue Gold"); „Blue Gold" dann evtl. aus dem
App-Bundle lösen.

## Testrunden-Korrekturen (Cover-Cache, Overflow, Badges, Dateifilter)

- **Cover erschienen erst nach Umweg** → `cached_network_image` (Platten-Cache,
  zuverlässige Anzeige, offline). Ersetzt `Image.network` in `BookCoverTile`
  und der Trefferliste der Buchsuche.
- **„6.6 px overflow" im RecordingScreen** → der zentrale Bereich ist jetzt
  `LayoutBuilder` → `SingleChildScrollView` → `ConstrainedBox(minHeight)` →
  `IntrinsicHeight` → `Column`: zentriert, scrollt bei Bedarf, läuft nie über.
- **Notiz-Zahl auf den Kacheln** → `NoteRepository.watchCounts()`
  (`Stream<Map<sourceId,int>>`, SQLite `GROUP BY` + InMemory), `LibraryScreen`
  reicht sie an `BookCoverTile.noteCount` durch → kleines Badge oben rechts,
  bei 0 nichts. Vertragstest erweitert.
- **Dateiwähler** beim Abgleich: `pickFiles(FileType.custom, ['json'])` mit
  Fallback auf `FileType.any`, falls das Gerät den JSON-MIME-Typ nicht kennt
  (`PlatformException`). Die `saveFile`-Dialoge filtern nicht mehr (bei
  „Neu anlegen" wenig sinnvoll). Google Drives eigener Wähler ignoriert
  MIME-Filter ohnehin – nur der lokale Speicher lässt sich einschränken.
- 168 Tests grün.

## Sprache (Whisper + Cover) + „Speichern unter"

- **`AppLanguage` neu** (`models/`, Enum `german`/`english`, ISO-Code + Label,
  erweiterbar). **`AppSettings` auf ein `AppPrefs`-Wertobjekt umgestellt**
  (`load()`/`save(AppPrefs)` statt N Getter/Setter-Paare; `==`/`hashCode` für
  den Notify-Guard). Neu darin: `recordingLanguage`, `coverSearchLanguage`
  (Default `german`).
- **`LanguageMenuButton`** (`widgets/`): kompaktes AppBar-Menü „DE ▾" (kein
  Kippschalter). Im **RecordingScreen** (steuert `transcribe(language:)`) und in
  der **BookSearchScreen** (steuert `covers.search(query, language:)`, löst
  Suche neu aus).
- **`CoverService.search`** hat jetzt `{String? language}`; alle Impls +
  `FallbackCoverService` reichen es durch (`language ?? preferredLanguage`).
- **„Speichern unter"**: `saveExportToFile` (`share_export.dart`) und
  `LibrarySync.saveToFile` über `FilePicker.saveFile` (System-Dialog, schreibt
  auch nach Drive). Export-Sheet und Sync-Sheet haben jetzt je **[Teilen] /
  [Speichern]**.
- Tests: `app_settings_test.dart` neu (AppPrefs), `cover_service_test.dart`
  (+Sprache). 166 grün, analyze sauber.

## Vorlage: weich / hart (Nutzerwunsch)

- **„Als Vorlage setzen"** hat jetzt eine Auswahl: **weich** (Default,
  `adoptMaster` – Löschungen wirken, lokal Neues bleibt) oder **hart**
  (`replaceWith(datei)` – Zielgeräte werden exakt gesetzt, Grabsteine werden
  dabei verworfen). Neues Feld `LibrarySnapshot.masterHard` (JSON, Default
  false). `LibrarySync.setAsMaster({required hard})`, `pickAndMerge`
  verzweigt auf `incoming.masterHard`.
- Sheet: Rückfrage-Dialog mit `RadioGroup` weich/hart + kurzer Erklärung
  („nur so werden Löschungen übertragen …"). Ergebnis-SnackBar sagt
  „weiche/harte Vorlage übernommen".
- `SYNC_DESIGN.md` §5 mit Tabelle weich/hart. **166 Tests grün.**
- BACKLOG: Hilfe-Seite in der App + README im Git-Repo (Merge/Master
  erklären – ist ungewöhnlich).

## Merge-Modell überarbeitet (Nutzerentscheidung) + weitere Korrekturen

- **`mergeLibrary` ist jetzt rein additiv:** Vereinigung aller lebenden Einträge,
  bei Inhaltskonflikt neuerer `updatedAt`. **Löschungen werden im Merge nicht
  mehr übertragen** – Grabsteine werden nur mitgeführt (und fallen weg, wenn der
  Eintrag wieder lebt). Der frühere „neuester Fakt inkl. Löschung gewinnt"-Ansatz
  war dem Nutzer zu riskant.
- **Neu `adoptMaster(local, master)`:** nur hier wirken Löschungen. Master-Live
  gewinnt (auch gegen neueren lokalen Stand), Master-Grabsteine werden
  angewendet, lokal Neues (dem Master unbekannt) bleibt. `pickAndMerge` ruft im
  Master-Kurzschluss jetzt `adoptMaster` statt `replaceWith(incoming)`.
- `SYNC_DESIGN.md` §4/§5 entsprechend neu.
- **Bestätigungen:** Export und Bibliothek-Sichern zeigen jetzt eine SnackBar
  („… exportiert: <Datei>", „Bibliotheksdatei gesichert."), das Sheet schließt
  sich dabei. (Nutzer hatte mehrfach gedrückt, weil keine Rückmeldung kam.)
- **Buchtitel korrigieren:** langer Druck auf den Titel im `RecordingScreen`
  öffnet den `BookEditDialog` (unauffällig, selten gebraucht). `RecordingScreen`
  hält den Buchtitel jetzt in `_book` statt `widget.book`.
- **Merge/Master-Texte** im Sync-Sheet an das additive Modell angepasst
  („Löschungen werden hier nicht übertragen" / „Nur so werden Löschungen
  übertragen").
- **163 Tests grün** (`library_merge_test` neu für additiv + `adoptMaster`).

## Was in Baustein F2b + Testrunden-Korrekturen passiert ist

- **Gerät löschte bei `adb install -r` die Daten**, weil `versionCode` (aus
  `pubspec` `+N`) gleich blieb → Samsung behandelte es als Neuinstallation.
  **Fix: `+N` bei jedem Gerät-Build hochzählen** (jetzt `+10`). Danach bleiben DB
  **und** Secure-Storage-Keys erhalten (verifiziert). Steht in `HANDOFF.md`.
- **„Als Vorlage (Master) setzen"** (`LibrarySync.setAsMaster`): `masterGeneration
  + 1`, unveränderten lokalen Stand als Datei, lokal festhalten. **Master-
  Kurzschluss** im Abgleich: `incoming.masterGeneration >
  lastConsumedMasterGeneration` → `replaceWith(incoming)` statt Merge.
- **`AppSettings` → `SyncSettings`** (`lastConsumedMasterGeneration`,
  `tombstoneGcEnabled` Default true, `tombstoneGcDays` Default 120); `LibrarySync`
  bekommt `AppSettings`, der Merge liest GC daraus. UI für die GC-Schalter →
  Settings-Seite (BACKLOG).
- **Sync-Sheet neu**: drei klar benannte Aktionen mit Erklärtext –
  *Sichern* / *Abgleichen (zusammenführen)* / *Als Vorlage (Master) setzen*
  (mit Rückfrage). Ergebnis unterscheidet „Zusammengeführt" vs. „Vorlage
  übernommen". (Nutzerwunsch: sichtbar machen, was welche Option bedeutet.)
- **`file_picker` filtert auf `.json`** (`FileType.custom`).
- **`SilenceDetector`**: Schwelle -35 → -30 (unempfindlicher gegen Raum-
  geräusche), neuer `noSpeechTimeout` (Default 3 s) – vorher stoppte es zu
  früh, wenn nichts gesagt wurde. Silence-Fenster nach dem Sprechen bleibt bei
  1,3 s (vom Nutzer als gut bestätigt).
- **`RecordingScreen`**: das dezente AppBar-Icon ist raus; stattdessen ein
  sichtbarer `OutlinedButton` „N Notizen zu diesem Buch" unter dem Status,
  der zur Notizübersicht führt (`_AllNotesButton`, live-Zahl).
- **`BookDetailScreen`**: Export-Icon-Tooltip jetzt „Exportieren (Buch, Autor
  oder Bibliothek)" – die Funktion war da, nur unklar benannt.
- **162 Tests grün** (`silence_detector_test`, `app_settings_test` angepasst),
  analyze sauber.

## Was in Baustein F2a (Bibliotheksdatei, Grabsteine, Abgleich) passiert ist

Spezifikation: `SYNC_DESIGN.md`.

- **Schema v3:** Tabellen `tombstones` (entity_id, entity_type, deleted_at) und
  `meta` (key/value, hält `master_generation`). Migration v2→v3
  (`_createSyncTables`), `AppDatabase.getMeta/setMeta`.
- **`delete` schreibt Grabsteine** in einer Transaktion mit der Zeilenlöschung:
  `SqliteNoteRepository` einen, `SqliteBookRepository` einen fürs Buch + je
  einen für jede kaskadiert gelöschte Notiz. `InMemoryStore` führt zur Parität
  eine `tombstones`-Map.
- **`Tombstone` / `TombstoneEntityType`** und **`LibrarySnapshot`** (alle
  Quellen + Notizen + Grabsteine + `masterGeneration`) neu in `lib/models/`.
  `LibrarySnapshot` kann JSON (`booknote-library.json`, `formatVersion 1`) lesen
  (mit Formatprüfung → `LibraryFileException`) und schreiben.
- **`mergeLibrary(a, b, {now, gcEnabled, gcDays})`** (`lib/services/`, rein):
  „neuester Fakt gewinnt", Löschung schlägt Gleichstand, Waisen-Notizen raus,
  GC alter Grabsteine (Default an, 120 Tage), `masterGeneration = max`.
  **Master-Kurzschluss ist noch nicht dabei** (F2b).
- **`LibraryArchive`** (`lib/repositories/sqlite/`): `readSnapshot()` /
  `replaceWith(snapshot)` (transaktionales „alles ersetzen").
- **`LibrarySync`** (`lib/services/`): `save()` (Datei schreiben + Share-Sheet),
  `pickAndMerge()` (Datei via `file_picker` wählen → parsen → mergen →
  `replaceWith`), `shareSnapshot()` (gemischten Stand zurückteilen).
  In `AppScope` als `librarySync`.
- **UI:** Bibliothek-Overflow-Menü → „Bibliothek sichern / abgleichen …" öffnet
  `showLibrarySyncSheet` (Sichern / Aus Datei abgleichen → Ergebnis mit Zahlen +
  „aktualisierte Datei sichern").
- **Android:** `file_picker` zieht `flutter_plugin_android_lifecycle`, das
  `compileSdk ≥ 36` verlangt. `android/build.gradle.kts` hebt jedes
  Plugin-Modul im `subprojects`-Block auf 36; `app/build.gradle.kts` nutzt
  `maxOf(flutter.compileSdkVersion, 36)`. `VIBRATE`-Permission (von der
  Haptik-Runde) ist schon drin.
- **Neue Pakete:** `file_picker`. **Tests:** `library_snapshot_test.dart`,
  `library_merge_test.dart`, `library_archive_test.dart`, `migration_test`
  (v3), `sqlite_repositories_test` (Tabellen). **161 grün**, analyze sauber.

## Was in Baustein F1 (Export in 3 Ebenen, Markdown + Text) passiert ist

- **`Exporter`-Interface umgebaut:** `export(ExportRequest) → ExportResult`.
  `ExportRequest` = Liste von `ExportBook(book, notes)` + optionaler
  `collectionTitle` (`null` → genau ein Buch; sonst „Bibliothek" oder ein
  Autorname) + `includeTimestamps`. `ExportRequest.single(book, notes)` als
  Kurzform.
- **`MarkdownExporter`** rendert jetzt Einzelbuch (`#`/`##`) **und** Sammlung
  (`#` Titel, je Buch `##`/`###`). **`PlainTextExporter` neu** – gleiche
  Gliederung ohne Markdown-Zeichen, `formatName`/`fileExtension`/`mimeType`.
- `AppScope.exporter` → **`AppScope.exporters`** (`List<Exporter>`,
  Default `[Markdown, Text]`, erstes = Vorauswahl).
- **`showExportSheet(context, {initialScope, book?, author?})`** in
  `lib/export/export_sheet.dart`: Bottom-Sheet mit Ebenen-Radios (dieses Buch /
  alle eines Autors / ganze Bibliothek) und Format-Umschalter, lädt die Notizen
  selbst und teilt über den Share-Sheet. Sammlungen werden nach Buchtitel
  sortiert.
- **Vorauswahl je Kontext:** `BookDetailScreen` → „dieses Buch" (Autor als
  Option, falls vorhanden). `LibraryScreen` → Overflow-Menü „Exportieren …",
  Vorauswahl „ganze Bibliothek" bzw. „dieser Autor", wenn ein Autor-Chip aktiv
  ist. (Einstellungen sind vom Icon ins selbe Overflow-Menü gewandert.)
- Tests: `markdown_exporter_test.dart` erweitert (Sammlung),
  `plain_text_exporter_test.dart` neu. **142 grün**, analyze sauber.

## Was in Baustein D (Feinschliff Aufnahme-Flow) passiert ist

- **Haptik**: zunächst `HapticFeedback` – auf dem Testgerät (Samsung) **nicht
  spürbar**, weil `performHapticFeedback` die (dort abgeschaltete)
  System-Touch-Vibration respektiert. Umgestellt auf das Paket `vibration`
  (plattformneutral) über `lib/services/haptics.dart` (`Haptics.recordStart` /
  `recordStop` / `saved`, greift direkt den Vibrator, verschluckt Fehler still).
  `VIBRATE`-Permission im AndroidManifest. Genutzt im `RecordingScreen` und im
  Sprach-Sheet.
- **Sehr kurze Aufnahme (< 1 s):** `RecordingScreen` misst die echte Dauer über
  `_recordStartedAt` und fragt vor dem Transkribieren nach
  („Verwerfen" / „Transkribieren"). Spart versehentliche Whisper-Aufrufe.
- **Lange Aufnahme:** ab 90 s ein dezenter Hinweis unter dem Sekundenzähler
  (kein Auto-Stopp – die Notiz kann bewusst lang sein).
- **Letzte Notiz direkt bearbeiten:** die Notizen in der Sitzungsliste des
  `RecordingScreen` sind jetzt antippbar → `showNoteEditDialog` →
  `notes.update`, und die lokale Liste wird mitgeführt.
- Konstanten `_minNoteRecording` / `_longRecordingHint` oben im
  `recording_screen.dart`. Keine neuen Tests (UI/Haptik über schon getestete
  Services). **138 grün**, analyze sauber.

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

Stufe 1 ist im Kern fertig: A–D + F auf dem Gerät bestätigt (Master nur
logik-/testgetestet). Offen sind nur noch **E (Release-Signierung)** und die
**Settings-Seite** (Vibration- und GC-Schalter haben noch keine UI).

**Baustein F2 (Bibliotheksdatei + Geräte-Abgleich):** volle Spezifikation in
**`SYNC_DESIGN.md`** (mit dem Nutzer abgestimmt). Kurz:

- Klar getrennt vom **Abzug** (F1, MD/TXT, nur raus): die **Bibliotheksdatei**
  `booknote-library.json` ist die bidirektionale Sync-Grundlage mit Grabsteinen.
- **Schema v3:** Tabelle `tombstones`; `delete` schreibt Grabsteine mit.
- **`mergeLibrary`** (reine Funktion): „neuester Fakt gewinnt" – eine Löschung
  ist ein Fakt mit `deletedAt`. Löschung schlägt Bearbeitung bei Gleichstand.
- **„Als Master setzen"**: `masterGeneration` hochzählen; ein Gerät mit
  `datei.masterGeneration > lastConsumed` **ersetzt** seine DB komplett (kein
  Merge).
- **GC**: `AppSettings.tombstoneGcEnabled` (Default an) / `tombstoneGcDays`
  (Default 120); Merge verwirft alte Grabsteine. UI dafür → Settings-Seite
  (BACKLOG).
- Ohne Drive: „Sichern"/„Als Master setzen" über Share-Sheet, „Abgleichen"
  über `file_picker`, danach Hinweis „aktualisierte Datei sichern".
- **F2a ist gebaut** (siehe oben). **F2b (als Nächstes):** Master-Kurzschluss
  in `LibrarySync` (vergleicht `incoming.masterGeneration` mit
  `AppSettings.lastConsumedMasterGeneration` → bei größer: `replaceWith` statt
  Merge), Button „Als Master setzen" im Sync-Sheet, GC-Felder
  (`tombstoneGcEnabled` Default true, `tombstoneGcDays` Default 120) in
  `AppSettings` – Merge liest sie dann daraus statt aus den Default-Parametern.

**Baustein E (Weitergabe an Tester) – nach F:** Nur die
**Release-Signing-Konfiguration** (`key.properties` + `build.gradle`).
**App-Icon** hebt sich der Nutzer für später auf (BACKLOG).

Danach die „Feinheiten"-Runde des Nutzers und die Punkte in `BACKLOG.md`
(u.a. die dedizierte **Settings-Seite**, die alle Optionen bündelt).

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
