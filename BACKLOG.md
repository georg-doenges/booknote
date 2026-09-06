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

## Export & Abgleich zwischen Geräten

Empfehlung: als **Baustein F** bündeln (Details/Entscheidung offen, siehe
PROGRESS.md „Nächster Schritt").

- **Ganze Bibliothek exportieren** (Markdown), nicht nur ein einzelnes Buch –
  optional gefiltert auf den aktuell gewählten Autor. Als Sammel-Datei oder
  Zip pro Buch, über den Share-Sheet.
- **Lokal speichern**, nicht nur Share-Sheet (`.md`/`.txt` in einen gewählten
  Ordner).
- **TXT-Format** neben Markdown. `Exporter` ist schon ein Interface
  (`formatName`, `export(book, notes) → ExportResult`); `PlainTextExporter`
  tritt einfach daneben. UI: Formatauswahl vor dem Export.
- **Bibliotheks-Datei im eigenen JSON-Format** (alle Quellen + alle Notizen mit
  ihren UUIDs, `createdAt`, `updatedAt`) zum Export **und Import**.
- **Vereinigungs-Abgleich (maximalistisch, Nutzerwunsch):** Beim Import einer
  solchen Datei werden App und Datei **zusammengeführt**, nicht die Schnittmenge
  gebildet: jeder Eintrag, der in einer der beiden Seiten existiert, ist danach
  in beiden. Bei einem Eintrag, den beide Seiten kennen, gewinnt der mit dem
  neueren `updatedAt` (last-write-wins pro Feld). **Keine** Löschungen werden
  übertragen. Nach dem Merge wird die Datei neu geschrieben → beide Seiten
  konvergieren zur Vereinigung.
  - **Machbar, weil die Architektur es vorbereitet:** IDs sind UUID v4
    (geräteübergreifend eindeutig, keine Kollision zwischen Telefon/Tablet),
    jede Quelle und Notiz hat `updatedAt`, die UI spricht nur mit den
    Repository-Interfaces. Der Merge ist reine, testbare Logik über einer
    Bulk-Import-Methode am Repository (oder einem `LibrarySync`-Service).
- **Google Drive automatisch** (späterer Schritt, der aufwändige Teil):
  `google_sign_in` + Drive-API (`appDataFolder`), die eine JSON-Bibliotheks-
  datei automatisch findet, den Vereinigungs-Abgleich fährt und zurückschreibt.
  Setup-Kosten: OAuth-Consent-Screen, Tokens. **Bis dahin geht der Abgleich
  manuell**: Datei exportieren → per Drive/Mail/USB aufs andere Gerät →
  importieren. PROJECT.md 3b nennt als Ziel-Sync eigentlich Supabase; der
  Vereinigungs-Abgleich über eine Datei ist die einfachere, für eine private
  App ausreichende Variante und blockiert Supabase nicht.

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
- „Feinheiten"-Runde am Ende (Nutzer sammelt kleinere Punkte).
