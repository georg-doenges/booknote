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

## Settings-Seite (dediziert, clean)

Der Nutzer will die Hauptflächen schlank halten und **alle** detaillierten
Optionen auf **einer** klaren, verständlichen Seite bündeln, erreichbar über
einen „Einstellungen"-Knopf. Wenn diese Seite gebaut wird, gehört dort hinein:

- Theme-Modus (System/Hell/Dunkel) – wandert vom jetzigen Ort (`SettingsScreen`)
  hierher bzw. wird Teil davon.
- API-Keys (OpenAI, Google Books) – schon da, würden hier eingegliedert.
- **Vibration an/aus** (Aufnahme-Haptik).
- **Grabstein-Aufräumen (GC): an/aus + Anzahl Tage** (Default 120), siehe
  `SYNC_DESIGN.md` §6. Die Felder (`tombstoneGcEnabled`, `tombstoneGcDays`)
  kommen schon mit F2 in `AppSettings`; hier fehlt nur die UI.
- Export-Format merken (letztes MD/TXT als Default).
- Sprache der Cover-Suche (aktuell fest `de`).
- Später: Theme-Import (s.o.), Google-Drive-Konto verbinden.

Struktur: übersichtliche Abschnitte mit Erklärtext, keine kryptischen Schalter.

## Export & Abgleich zwischen Geräten

Volle Spezifikation: **`SYNC_DESIGN.md`**. In Baustein F2 gebaut wird der
manuelle Weg (Datei per Share-Sheet raus, per `file_picker` rein, Merge bzw.
Master, Grabsteine, GC-Felder). Deferred bleibt:

- ~~Ganze Bibliothek exportieren, 3 Ebenen~~ / ~~TXT-Format~~ → Baustein F1
  (erledigt).
- **„Speichern unter" in einen Ordner** (`.md`/`.txt`/`.json`), nicht nur
  Share-Sheet – über `file_picker` / SAF.
- **Google Drive automatisch:** `google_sign_in` + Drive-API (`appDataFolder`),
  die die Bibliotheksdatei selbst findet, abgleicht und zurückschreibt.
  Setup-Kosten: OAuth-Consent-Screen, Tokens. Bis dahin manuell (F2).
- **Zwei gleichzeitige Master-Pushes** ohne Zwischen-Abgleich: der zuletzt
  geschriebene gewinnt, der andere geht verloren (`SYNC_DESIGN.md` §5). Ggf.
  `deviceId` + Generation statt nur Integer.
- **Grabstein-GC-UI** – die Logik + `AppSettings`-Felder kommen mit F2, nur die
  Schalter (an/aus, Tage) fehlen → Settings-Seite (s.o.).
- PROJECT.md 3b nennt als Ziel-Sync Supabase; der Datei-Abgleich ist die
  einfachere, ausreichende Variante und blockiert Supabase nicht.

## Hilfe / Doku

- **Hilfe-Seite in der App** und ein **README im Git-Repo**, die vor allem den
  **Merge- vs. Master-Abgleich** erklären. Das Modell ist mächtig, aber
  ungewöhnlich und nicht intuitiv (besonders: eine weiche Vorlage repliziert
  nicht bloß, sondern nimmt lokal Neues des Zielgeräts noch mit auf). Quelle:
  `SYNC_DESIGN.md`. Kurzfassung gehört an die Stellen, wo die Funktionen
  auftauchen (teils schon als Hinweistext vorhanden).

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
