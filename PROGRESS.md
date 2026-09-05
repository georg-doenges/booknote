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
  repositories/    BookRepository, NoteRepository (Interfaces) ✅, InMemory-Impl ✅,
                   SQLite-Impl (Schritt 3) ⬜
  services/        (Schritt 4/6) WhisperService, NoteParser, CoverService        ⬜
  export/          (Schritt 7) Exporter-Interface + MarkdownExporter             ⬜
  screens/         LibraryScreen (Platzhalter) ✅, Recording/BookDetail/Settings ⬜
  widgets/         wiederverwendbare UI-Komponenten                              ⬜
  main.dart        BooknoteApp → LibraryScreen                                    ✅
test/
  models/          Unit-Tests für das Datenmodell                                 ✅
  repositories/    repository_contract.dart = Vertragstest für JEDE Impl         ✅
```

## Status pro Baustein (PROJECT.md, Abschnitt 10)

| # | Baustein | Status |
|---|----------|--------|
| 1 | Grundgerüst + Ordnerstruktur + Datenmodell | ✅ auf Gerät getestet |
| 2 | Repository-Interface (`BookRepository`, `NoteRepository`) | ✅ fertig, wartet auf OK des Nutzers |
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

## Nächster Schritt

**Schritt 3:** `lib/repositories/sqlite/` mit `AppDatabase` (Öffnen, Schema v1,
Migrations-Hook), `SqliteBookRepository`, `SqliteNoteRepository`. Tabellen
`sources` und `notes` gemäß PROJECT.md 4 (IDs als TEXT/UUID, Zeitstempel als
INTEGER Unix-ms, `updated_at` zusätzlich, FK mit ON DELETE CASCADE).
Vertragstest über `sqflite_common_ffi` auf dem Desktop laufen lassen.

## Offene Punkte / Hinweise

- `record` und `flutter_secure_storage` brauchen später Plattform-Setup
  (Mikrofon-Permission in AndroidManifest/Info.plist, minSdk-Check). Kommt in Schritt 4/5.
