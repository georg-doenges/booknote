# Booknote — Ideen & spätere Ausbaustufen

Nicht jetzt bauen, aber bei Architektur­entscheidungen mitdenken. Arbeitsstand:
`PROGRESS.md`. Grundspezifikation: `PROJECT.md` (Abschnitt 9 = die großen
späteren Stufen). Abgleich-Modell: `SYNC_DESIGN.md`.

Stand: **Stufe 1 ist fertig** (A–D, F1, F2, E-Signierung, Settings-Seite,
Custom-Themes). Alles hier ist Kür.

---

## Klein / überschaubar

- ~~**App-Icon.**~~ → erledigt: Nutzer-Entwurf (`assets/icon/source.png`) via
  `flutter_launcher_icons`, Android adaptiv + iOS. Braune Systemfarben als
  Standard; Blue Gold/Old Library tragen ihr eigenes Logo im Theme-File
  (siehe THEMES.md „App-Icon vs. Theme-Logo").
- ~~Sprache der Cover-Suche konfigurierbar~~ → erledigt, später vereinfacht: die
  Cover-Suche folgt der Sprache des Buchs (eine Sprachwahl statt zwei).
- ~~„Speichern unter" in einen Ordner~~ → erledigt (`FilePicker.saveFile` im
  Export- und im Sync-Sheet).
- **Export-Format merken.** Letztes MD/TXT als Default im Export-Sheet, über
  `AppSettings`.
- ~~**Whisper-Parsing auch auf Englisch.**~~ → erledigt: `NoteParser.parse(raw,
  language:)` mit eigenem englischen Regelwerk + `EnglishNumberParser`
  (`page 47`, `top/middle/bottom`, `line 10`, `following`/`onwards` → f./ff.).
  `RecordingScreen` reicht `settings.recordingLanguage` durch.
- ~~**Sprache pro Buch** statt global~~ → erledigt: `Source.language` (Schema
  v4, Default Deutsch), Sprachwahl beim Anlegen und in „Buch bearbeiten",
  `RecordingScreen` startet damit und kann für die laufende Aufnahme
  übersteuern (ohne die Sprache des Buchs zu ändern).
  `Note.language` speichert die tatsächlich genutzte Sprache je Notiz (steuert
  „S." vs. „p." bei der Seitenangabe).
- **Weitere Sprachen.** Die App ist dreisprachig (de/en/fr, `lib/l10n/*.arb`);
  eine weitere Sprache braucht eine `.arb`-Datei, einen `AppLanguage`-Eintrag und –
  für Aufnahmen – Regeln im `NoteParser` (+ Zahlwort-Parser). **Niederländisch
  (Flämisch)** liegt nahe, falls die Testerin es braucht. Ebenso eine
  `README.fr.md`.
- **„Feinheiten"-Runde** – der Nutzer sammelt noch kleinere Punkte. Vorgemerkt
  für die **nächste Code-Änderung** (Gerätetest 24.09.2026) – beide sind in
  `0.1.0+29` umgesetzt (siehe PROGRESS.md):
  - ~~**„Buch bearbeiten": Sprachwahl nicht zu finden.**~~ → sichtbarer Stift +
    Sprache in der Kopfzeile der Buch-Details, kein Autofokus mehr im Dialog.
  - ~~**Kacheln der Bibliothek wirken unterschiedlich hoch.**~~ → fester Platz
    für den Text unter dem Cover (die Cover-Fläche war `Expanded` und wurde von
    der Zeilenzahl beeinflusst), dazu Kartenfläche, Zellen 3:4, ruhigerer
    Platzhalter. Erste (unvollständige) Analyse: Alle Zellen sind
    exakt gleich hoch (`CoverGridDelegate`), aber der Rahmen ist so dezent, dass
    das Auge das Bild misst: Ein Cover mit anderem Seitenverhältnis füllt die
    2:3-Fläche unter `BoxFit.contain` nur zum Teil, der Platzhalter ohne Cover
    füllt sie ganz und wirkt daher am längsten. Wunsch: **alle gleich hoch,
    ruhig**. Ideen: (a) sichtbare, gleichmäßige Fläche hinter jedem Cover
    (`surfaceContainerLow`) plus etwas kräftigerer Rahmen, damit jede Kachel als
    gleiches Rechteck gelesen wird; (b) Zellen insgesamt niedriger (z. B. 3:4
    statt 2:3, wie vom Nutzer vorgeschlagen) – weniger ungenutzter Platz bei
    Covern, die nicht sehr hoch sind; (c) Platzhalter mit kleinerer Schrift, weil der Titel darunter ohnehin
    steht. Am Gerät mit echten Covern ausprobieren.

## Mittel

- **Hilfe-Seite in der App + README im Git-Repo.** Erklärt vor allem den
  **Merge- vs. Master-Abgleich** – das Modell ist mächtig, aber ungewöhnlich
  (eine *weiche* Vorlage repliziert nicht bloß, sondern nimmt lokal Neues des
  Zielgeräts mit auf). Quelle: `SYNC_DESIGN.md`. Kurz-Erklärtexte an den
  UI-Stellen gibt es teils schon.
- ~~**Importierbare Farbschemata.**~~ → erledigt: `CustomTheme` +
  `CustomThemeStore`, JSON-Import in den Einstellungen, Hintergrund-Layer in
  Struktur + Rendering angelegt. Format: `THEMES.md`. **Offen:**
  - ~~**Theme-Repository auf GitHub.**~~ → erledigt als **Theme-Katalog**:
    Ordner `themes/` im booknote-Repo (+ `index.json`, per
    `dart run tool/build_theme_index.dart` erzeugt), in der App „Farbschemata
    laden" mit Installieren/Aktualisieren. Blue Gold und Old Library stecken
    nicht mehr im APK. **Offen:** ein eigenes Theme-Repo, falls andere Schemata
    beisteuern sollen (Adresse steht nur in `ThemeCatalogService.defaultBaseUrl`).
  - **Schriften nachladbar.** Ein Katalog-Theme kann keine neue Schrift
    mitbringen (nur Schriften aus dem APK, aktuell Tinos). Ginge über Schrift-
    Dateien im Katalog + `FontLoader`; kostet ~0,5 MB pro Schnitt pro Download.
  - **Theme-File mit hell + dunkel in einem** – folgt dann optional dem System.
    Aktuell ist ein Custom-Theme ein fester Look.
  - Auswahl-UI mit größerer Vorschau.
  - **Echtes Homescreen-Icon pro Theme.** Bisher trägt nur die Theme-Datei ein
    eingefärbtes Logo (Vorschau in den Einstellungen) – das App-Icon selbst
    bleibt Braun (System-Standard), weil Android das nicht einfach zur
    Laufzeit umschaltet. Ginge über mehrere `<activity-alias>`-Einträge im
    Manifest + natives Umschalten per `PackageManager`, launcherabhängig.
    Eigener, größerer Baustein.
- **Eigener In-App-Dateibrowser für Importe.** Der Android-Systemwähler
  (SAF/DocumentsUI) bestimmt Anzeige *und* Ansicht: Nicht-JSON-Dateien werden
  nur **ausgegraut** (nicht ausgeblendet), und Liste vs. Kacheln lässt sich
  nicht vorgeben. Der Filter wirkt (nur JSON wählbar). „Aufgeräumter" ginge nur
  mit einem eigenen, auf einen Ordner beschränkten Browser – mit
  Scoped-Storage-Aufwand (`ACTION_OPEN_DOCUMENT_TREE` + `DocumentFile` oder ein
  SAF-Paket). Rein kosmetisch. Betrifft Theme- und Bibliotheks-Import.

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
