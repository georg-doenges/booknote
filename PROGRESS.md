# Booknote — Fortschritt & Übergabe

Diese Datei hält fest, was gebaut ist, was fehlt und wo wir gerade stehen,
damit ein anderes Modell (oder Mensch) die Arbeit nahtlos übernehmen kann.
Spezifikation: `PROJECT.md`. Reihenfolge der Bausteine: PROJECT.md, Abschnitt 10.

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
  models/          Source, SourceType, Book, Note (+ models.dart Sammel-Export)   ✅
  repositories/    (Schritt 2/3) abstrakte Interfaces + SQLite-Implementierung   ⬜
  services/        (Schritt 4/6) WhisperService, NoteParser, CoverService        ⬜
  export/          (Schritt 7) Exporter-Interface + MarkdownExporter             ⬜
  screens/         LibraryScreen (Platzhalter) ✅, Recording/BookDetail/Settings ⬜
  widgets/         wiederverwendbare UI-Komponenten                              ⬜
  main.dart        BooknoteApp → LibraryScreen                                    ✅
test/
  models/          Unit-Tests für das Datenmodell                                 ✅
```

## Status pro Baustein (PROJECT.md, Abschnitt 10)

| # | Baustein | Status |
|---|----------|--------|
| 1 | Grundgerüst + Ordnerstruktur + Datenmodell | ✅ fertig, wartet auf OK des Nutzers |
| 2 | Repository-Interface (`BookRepository`, `NoteRepository`) | ⬜ |
| 3 | SQLite-Implementierung | ⬜ |
| 4 | WhisperService + NoteParser | ⬜ |
| 5 | UI: Library, Recording, BookDetail, Settings | ⬜ (Library nur Platzhalter) |
| 6 | CoverService (Google Books + Open Library) | ⬜ |
| 7 | Markdown-Export | ⬜ |
| 8 | Feinschliff Aufnahme-Flow | ⬜ |

## Was in Schritt 1 passiert ist

- `flutter create` mit Plattformen android + ios, Org `de.doenges`.
- Android-Label auf „Booknote" gesetzt; iOS `CFBundleDisplayName` ist bereits „Booknote".
- Alle Stufe-1-Abhängigkeiten in `pubspec.yaml` eingetragen (sqflite, path,
  path_provider, uuid, record, http, flutter_secure_storage, share_plus).
  Noch keine davon im Code benutzt.
- Datenmodell in `lib/models/` inkl. Tests.
- Platzhalter-`LibraryScreen`, damit die App auf dem Gerät startet.

## Nächster Schritt

**Schritt 2:** `lib/repositories/book_repository.dart` und
`note_repository.dart` als abstrakte Interfaces (reine CRUD-Methoden, keine
SQLite-Details, Futures/Streams so schneiden, dass Supabase dasselbe Interface
erfüllen kann). Danach Schritt 3: `sqlite_*_repository.dart` + Schema/Migration.

## Offene Punkte / Hinweise

- `record` und `flutter_secure_storage` brauchen später Plattform-Setup
  (Mikrofon-Permission in AndroidManifest/Info.plist, minSdk-Check). Kommt in Schritt 4/5.
