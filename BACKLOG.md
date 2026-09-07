# Booknote — Ideen & spätere Ausbaustufen

Nicht jetzt bauen, aber bei Architektur­entscheidungen mitdenken. Arbeitsstand:
`PROGRESS.md`. Grundspezifikation: `PROJECT.md` (Abschnitt 9 = die großen
späteren Stufen). Abgleich-Modell: `SYNC_DESIGN.md`.

Stand: **Stufe 1 ist fertig** (A–D, F1, F2, E-Signierung, Settings-Seite).
Alles hier ist Kür.

---

## Klein / überschaubar

- **App-Icon.** Vom Nutzer bewusst zurückgestellt. `flutter_launcher_icons`
  (dev-dependency), ein Quell-PNG, plattformneutral.
- **Sprache der Cover-Suche konfigurierbar.** Aktuell fest `de`
  (`GoogleBooksCoverService.preferredLanguage`, `OpenLibraryCoverService`).
  Schalter in die Settings-Seite oder aus der Geräte-Locale.
- **Export-Format merken.** Letztes MD/TXT als Default im Export-Sheet, über
  `AppSettings`.
- **„Speichern unter" in einen Ordner** (`.md`/`.txt`/`.json`), zusätzlich zum
  Share-Sheet – über `file_picker` (`getDirectoryPath` / SAF).
- **„Feinheiten"-Runde** – der Nutzer sammelt noch kleinere Punkte.

## Mittel

- **Hilfe-Seite in der App + README im Git-Repo.** Erklärt vor allem den
  **Merge- vs. Master-Abgleich** – das Modell ist mächtig, aber ungewöhnlich
  (eine *weiche* Vorlage repliziert nicht bloß, sondern nimmt lokal Neues des
  Zielgeräts mit auf). Quelle: `SYNC_DESIGN.md`. Kurz-Erklärtexte an den
  UI-Stellen gibt es teils schon.
- **Importierbare Farbschemata.** Der Entwickler stellt Theme-Dateien bereit
  (z.B. „Blau & Gold"), die Nutzer laden. Vorbereitet: `lib/theme.dart` baut
  hell/dunkel aus **einem Seed** in `BooknoteTheme`; `AppSettings` /
  `AppSettingsStore` sind der Andockpunkt für ein `themeId` bzw. eine geladene
  Palette. Offen: Dateiformat (JSON: Seed + optionale Overrides?), Ablageort,
  Auswahl-UI, mitgelieferte Presets.

## Groß (echte spätere Stufen, PROJECT.md §9)

- **Google Drive automatisch.** `google_sign_in` + Drive-API (`appDataFolder`):
  die Bibliotheksdatei selbst finden, abgleichen, zurückschreiben. Kosten:
  OAuth-Consent-Screen, Token-Handling. Bis dahin läuft der Abgleich manuell
  (F2, funktioniert).
- **Cloud-Sync über Supabase.** In `PROJECT.md` 3b als eigentliches Ziel
  genannt. Der Datei-Abgleich blockiert das nicht; Repository-Interfaces sind
  darauf geschnitten.
- **iOS-Distribution** (Apple-Developer-Account). iOS-Build ist seit den neuen
  Paketen (`vibration`, `file_picker`, `shared_preferences`) ungetestet –
  braucht einen Mac (`flutter build ios --no-codesign`). Alle Pakete sind
  plattformneutral, sollte gehen.
- **Cover fotografieren + OCR** → Titel erkennen, Daten füllen. `CoverService`
  ist als Interface darauf vorbereitet (weitere Quelle andockbar).
- **Andere Quellen als Bücher** (YouTube-Videos, Ideen-Notizbücher). `Source`
  ist generisch, `source_type` im Schema vorgesehen.
- **On-device / lokales Whisper.** `TranscriptionService`-Interface daneben.

## Kleinere offene Punkte im Abgleich

- **Zwei gleichzeitige Master-Pushes** ohne Zwischen-Abgleich: der zuletzt
  geschriebene gewinnt, der andere geht verloren (`SYNC_DESIGN.md` §5.3). Ggf.
  `deviceId` + Generation statt nur Integer.
- **Grabstein-GC bei sehr seltenem Abgleich** kann einen alt-gelöschten Eintrag
  wieder auferstehen lassen (`SYNC_DESIGN.md` §6). Abschaltbar; für zwei
  regelmäßig genutzte Geräte irrelevant.
