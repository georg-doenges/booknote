# Booknote – Übergabe-Prompt für die nächste Session

> Diesen Text als erste Nachricht in eine neue Claude-Code-Session im
> Projektordner `C:\Users\Nutzer\Documents\01_Code_Projects\Booknote` einfügen.

---

Ich arbeite an **Booknote**, einer Flutter-App (Android-first, iOS-fähig) zum
Erfassen von Lesenotizen per Sprache. Die App ist funktional fertig (Stufe 1
laut Spezifikation) und auf meinem Android-Gerät getestet. Du übernimmst von
einer früheren Session. Bitte arbeite so weiter, wie es dort etabliert wurde.

## Lies zuerst, in dieser Reihenfolge

1. `PROGRESS.md` – Stand, Architektur-Entscheidungen, Wunschliste, offene
   Punkte. **Das ist die wichtigste Datei.**
2. `PROJECT.md` – die ursprüngliche Spezifikation.
3. `lib/app_scope.dart` und `lib/main.dart` – dort siehst du, wie alles
   verdrahtet ist (Repositories, Services, Exporter über ein InheritedWidget).
4. Je nach Aufgabe: `lib/repositories/book_repository.dart` +
   `note_repository.dart` (Interfaces), `lib/services/note_parser.dart`,
   `lib/services/cover_service.dart`, `lib/screens/*.dart`.

## Umgebung (steht auch in PROGRESS.md)

- Flutter 3.47.2 unter `C:\src\flutter`, **nicht im PATH**. In PowerShell
  vor jedem Befehl: `$env:PATH = "C:\src\flutter\bin;$env:PATH"`.
- adb liegt unter `$env:LOCALAPPDATA\Android\Sdk\platform-tools`.
- Testgerät: Samsung, Geräte-ID `R3CY60DPEFA` (per `flutter devices` prüfen).
  Installieren und starten ohne interaktives `flutter run`:
  `flutter build apk --debug`, `flutter install -d R3CY60DPEFA --debug`,
  `adb -s R3CY60DPEFA shell am start -n de.doenges.booknote/.MainActivity`.
- Vor jedem Commit: `dart format lib test`, `flutter analyze`, `flutter test`
  (aktuell 114 Tests, alle grün, keine Analyzer-Befunde).

## Arbeitsweise, die ich erwarte

- Schrittweise arbeiten. Nach jedem Baustein: Tests grün, Debug-APK auf dem
  Gerät installiert, kurze Beschreibung, was ich testen soll. Dann auf mein OK
  warten, bevor der nächste große Block beginnt.
- Nach jedem Baustein ein Git-Commit mit aussagekräftiger Nachricht und
  `PROGRESS.md` aktualisieren (Status-Tabelle, „Was in Schritt X passiert
  ist", „Nächster Schritt"). Das Repo ist nur lokal, Branch `main`.
- Architektur nicht aufweichen: UI spricht nur mit den Interfaces
  (`BookRepository`, `NoteRepository`, `TranscriptionService`, `CoverService`,
  `Exporter`, `ApiKeyStore`). Neue Implementierungen müssen den Vertragstest in
  `test/repositories/repository_contract.dart` bestehen. Keine Android-only-
  Pakete, iOS muss baubar bleiben.
- Antworten auf Deutsch, kurz. Dateien mit Pfad nennen.
- Wenn etwas an der Spec oder meinen Wünschen unklar ist: kurz fragen, sonst
  sinnvolle Annahme treffen und im Ergebnis nennen.

## Bekannte Stolpersteine (schon gelöst, nicht neu erfinden)

- Watch-Streams nicht als `async*` bauen (cancel blockiert) → `watch_stream.dart`.
- Zeitstempel vor dem Speichern mit `dbNow()` auf UTC-Millisekunden normalisieren.
- Google Books ohne API-Key läuft schnell in Status 429 (geteiltes
  Anonym-Kontingent). Die App zeigt dann einen Hinweis-Banner; Lösung ist ein
  kostenloser Key in den Einstellungen. Nicht als App-Bug behandeln.
- Bash-Heredocs mit Dart-Code scheitern in dieser Umgebung gelegentlich am
  Quoting; Dateien lieber mit dem Write-Tool oder einem Python-Skript schreiben.

## Was als Nächstes ansteht

Siehe `PROGRESS.md`, Abschnitte „Nächster Schritt" (Schritt 8: Feinschliff)
und „Nutzerwünsche – offen". Meine Priorität, sofern ich nichts anderes sage:

1. Design-Politur (siehe unten), klar und einfach, Material 3.
2. Wunschliste: Autor in der Buchsuche, Mikrofon im Suchfeld, Bibliothek
   filtern/durchsuchen.
3. Feinschliff Aufnahme-Flow, App-Icon, Release-Signierung für Tester.

## Design-Vorgabe

Kein aufwendiges Design. Klar, ruhig, lesbar. Material 3 mit einem
Seed-Farbschema (aktuell `Colors.brown` in `main.dart`), konsistente Abstände,
gute Typografie, Dark Mode soll funktionieren. Der Aufnahme-Button ist das
wichtigste Element. Änderungen zuerst als zentrales `ThemeData` in
`lib/theme.dart` (neu anlegen), nicht als Einzelstyling in den Screens.

Fang bitte damit an, `PROGRESS.md` zu lesen und mir in fünf Sätzen zu
bestätigen, wo wir stehen und was du als Erstes vorschlägst. Noch nichts ändern.
