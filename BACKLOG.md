# Booknote — Ideen & spätere Ausbaustufen

Sammelstelle für Wünsche, die **nicht** jetzt gebaut werden, aber bei
Architektur­entscheidungen mitgedacht werden sollen. Der aktuelle Arbeitsstand
steht in `PROGRESS.md`, die Grundspezifikation in `PROJECT.md` (Abschnitt 9
listet die großen späteren Stufen: Cloud-Sync, iOS-Distribution, Cover
fotografieren, andere Quellen, weitere Exportformate, lokales Whisper).

## Themes / Erscheinungsbild

- **Importierbare Farbschemata.** Der Entwickler stellt fertige Theme-Dateien
  bereit (z.B. „Blau & Gold"), die Nutzer laden können. Es soll eine Datei
  geben, die ein Theme beschreibt und zur Laufzeit geladen wird.
  - Konsequenz für jetzt: `lib/theme.dart` erzeugt hell/dunkel aus **einem
    Seed** und kapselt alles in `BooknoteTheme`. `AppSettings` spricht bereits
    in `themeMode` (nicht in einem Bool) und ist über `AppSettingsStore`
    austauschbar. Ein späterer `themeId` / eine geladene Palette kann dort
    andocken, ohne die Screens anzufassen.
  - Offen: Dateiformat (JSON mit Seed + optionalen Overrides?), Ablageort,
    Auswahl-UI in den Einstellungen, mitgelieferte Presets.

## Export (BookDetail → Zitate teilen)

- **Lokal speichern**, nicht nur über den Share-Sheet. Zusätzliche Option, die
  die `.md`/`.txt`-Datei in einen vom Nutzer gewählten Ordner schreibt.
- **TXT-Format** neben Markdown anbieten. Der `Exporter` ist bereits ein
  Interface (`formatName`, `export(book, notes) → ExportResult`); ein
  `PlainTextExporter` tritt einfach daneben. UI: Formatauswahl vor dem Export.

## Cover-Suche

- Sprache der Cover-Suche konfigurierbar machen (aktuell fest `de`, siehe
  PROGRESS.md „Sprach-Fix"). Kandidat für die Einstellungen oder aus der
  Geräte-Locale.

## Aus den Nutzertests (Details in PROGRESS.md)

- Bibliothek nach Autor/Titel filtern und durchsuchen (Baustein C).
- Buchsuche per Sprache: Mikrofon im Suchfeld (Baustein B).
- Feinschliff Aufnahme-Flow: Haptik, Rückfrage bei sehr kurzer Aufnahme,
  Hinweis bei sehr langer Aufnahme, letzte Notiz direkt im RecordingScreen
  bearbeiten (Baustein D).
- App-Icon, Release-Signierung für Tester (Baustein E).
