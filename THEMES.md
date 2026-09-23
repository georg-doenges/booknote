# Booknote — Farbschemata (Custom Themes)

Ein Farbschema ist **eine portable JSON-Datei**. Die App bringt selbst keine
mit: Schemata kommen entweder aus dem **Katalog** im GitHub-Repo (in der App:
**Einstellungen → Eigene Farbschemata → Farbschemata laden**) oder aus einer
Datei auf dem Gerät (**… → Aus Datei …**).

Ein Custom-Theme ist **ein fester Look** – es folgt nicht dem Hell/Dunkel des
Systems. Wählt man oben unter „Anzeige" wieder System / Hell / Dunkel, ist es
aus.

## Theme-Katalog

Im Repo liegt der Ordner `themes/` mit den Theme-Dateien, einer `index.json`
(Verzeichnis für die App) und `previews/<id>.png` (Vorschau-Logos). Die App liest
ihn direkt von GitHub (`raw.githubusercontent.com`, Branch `main`, nur lesend,
kein Login; Adresse: `ThemeCatalogService.defaultBaseUrl`). Pro Eintrag zeigt sie:

- **Installieren** – lädt das Schema, speichert es und schaltet es gleich ein.
- **Aktualisieren** – der Katalog hat eine höhere `revision` als die installierte
  Kopie. Ändert nicht, welches Schema gerade aktiv ist.
- **Installiert** – auf dem aktuellen Stand.

Der Katalog braucht Internet; GitHub cached `raw`-Dateien bis zu ~5 Minuten,
eine frisch gepushte Änderung erscheint also mit etwas Verzögerung.

Sicherheit: Themes sind **reine Daten** (Farben, Bilder, ein Schriftname), es wird
nie Code geladen. Vor dem Speichern wird die Datei als Theme geprüft und ihre `id`
muss zum Katalogeintrag passen; Dateipfade im Katalog dürfen nur schlichte
relative Namen sein (kein Schema/Host/`..`), Antworten sind größenbegrenzt
(Katalog 512 KB, Theme 8 MB), und die `id` wird beim Einlesen auf `a-z A-Z 0-9 _ -`
beschränkt, weil sie als Dateiname dient.

### Neues Schema in den Katalog aufnehmen

1. Theme-Datei `themes/<id>.json` anlegen (Format unten). `id` ist hier Pflicht,
   muss dem Dateinamen entsprechen und darf nur `a-z`, `0-9`, `_` enthalten.
   Optional: `description` (eine Zeile für den Katalog) und `revision`.
2. Katalog neu erzeugen (im Projektordner):
   ```bash
   dart run tool/build_theme_index.dart
   ```
   Das schreibt `themes/index.json` und je Theme mit `logo` die Vorschau
   `themes/previews/<id>.png` (aus dem eingebetteten Logo).
3. Committen und auf `main` pushen. Die App sieht es beim nächsten Öffnen des
   Katalogs – kein neues APK nötig.

Der Test `test/themes_catalog_test.dart` schlägt an, wenn `index.json` nicht zu den
Theme-Dateien passt, wenn eine Datei kein gültiges Theme ist oder wenn ein Theme
eine Schrift nennt, die nicht im APK steckt.

### Schema überarbeiten

Änderung in der Theme-Datei machen, **`revision` hochzählen** (sonst bietet die App
kein „Aktualisieren" an), Skript erneut laufen lassen, pushen.

## Format

```jsonc
{
  "format": "booknote-theme",
  "formatVersion": 1,
  "id": "blue_gold",            // optional; sonst aus dem Namen abgeleitet.
                                // Im Katalog Pflicht (= Dateiname ohne .json)
  "name": "Blue Gold",          // Pflicht, wird in den Einstellungen angezeigt
  "description": "Nachtblau mit goldenem Akzent.",  // optional, nur Katalog-Zeile
  "revision": 2,                // optional (Standard 1): Inhaltsstand, bei jeder
                                // Änderung hochzählen → „Aktualisieren" im Katalog
  "brightness": "dark",         // "dark" | "light" – Grundhelligkeit
  "seed": "#C6A052",            // Basis-Farbton; daraus wird das Schema erzeugt

  // Optional: einzelne Material-Rollen überschreiben. Nur die genannten Rollen
  // ändern sich, der Rest kommt aus dem Seed.
  "colors": {
    "primary": "#C6A052",
    "onPrimary": "#241900",
    "surface": "#0E1A2C",
    "onSurface": "#CBA95E",
    "onSurfaceVariant": "#8C7E58",
    "surfaceContainerLow": "#13223A",
    "surfaceContainerHighest": "#213656",
    "outline": "#3C4D68",
    "error": "#EBA7A7"
    // … weitere erlaubte Rollen siehe unten
  },

  // Optional: Schriftfamilie für die ganze App, solange dieses Theme aktiv
  // ist. Anders als Bild/Logo unten wird hier keine Datei eingebettet – nur
  // ein Name, den die App bereits mitbringt (aktuell: "Tinos", siehe unten).
  // Unbekannter Name: Flutter fällt lautlos auf die Systemschrift zurück.
  "font": "Tinos",

  // Optional: Hintergrund hinter den großen Flächen (AppBar + System-Leisten
  // bleiben undurchsichtig). Fehlt der Block, gibt es keinen Hintergrund.
  "background": {
    "image": "data:image/png;base64,iVBORw0KGgo…",  // Bild IM File eingebettet
    "fit": "cover",     // "cover" (formatfüllend) | "tile" (kacheln)
    "opacity": 1.0,     // 0..1
    "dim": 0.15         // 0..1 – zusätzlicher dunkler Schleier für Kontrast
  },

  // Optional: zum Schema passend eingefärbtes App-Logo, als data-URI direkt
  // im File. Wird als Vorschau in der Liste der installierten Schemata und im
  // Katalog gezeigt (statt der abstrakten Farbkachel) – ändert nichts am echten
  // App-Icon, das kann Android nicht pro Theme umschalten.
  "logo": "data:image/png;base64,iVBORw0KGgo…"
}
```

### Erlaubte `colors`-Rollen

`primary`, `onPrimary`, `primaryContainer`, `onPrimaryContainer`,
`secondary`, `onSecondary`, `secondaryContainer`, `onSecondaryContainer`,
`tertiary`, `onTertiary`, `tertiaryContainer`, `onTertiaryContainer`,
`error`, `onError`, `errorContainer`, `onErrorContainer`,
`surface`, `onSurface`, `onSurfaceVariant`,
`surfaceContainerLowest`, `surfaceContainerLow`, `surfaceContainer`,
`surfaceContainerHigh`, `surfaceContainerHighest`,
`outline`, `outlineVariant`, `inverseSurface`, `onInverseSurface`,
`inversePrimary`, `shadow`, `scrim`.

Farben als `#RRGGBB` oder `#AARRGGBB`.

### Faustregeln

- `surface` = die große Hintergrundfläche; `onSurface` = Text darauf. Kontrast
  muss stimmen.
- `surfaceContainerLow` = Kartenfläche (Notizen); etwas heller/dunkler als
  `surface`.
- `primary` = Akzent (Aufnahme-Button, Titel, Häkchen); `onPrimary` = Text/Icon
  darauf. Einen Akzent, der sichtbar sein soll, hier setzen – `tertiary` taucht in
  der App kaum auf.
- `onSurfaceVariant` = gedämpfter Text (Datumsangaben, Erklärtexte).
- `error` klar vom `primary` unterscheidbar wählen.

## Wo die Dateien liegen

- Installierte Schemata liegen auf dem Gerät als `<App-Dokumente>/themes/<id>.json`
  (nicht im Git, nicht im Bibliotheks-Abgleich). Alle sind gleichwertig und
  **löschbar** (Papierkorb neben dem aktiven Schema); aus dem Katalog lassen sie
  sich jederzeit wieder holen.
- Frühere App-Versionen brachten „Blue Gold" und „Old Library" im APK mit und
  kopierten sie beim Erststart in diesen Ordner. Solche Kopien bleiben liegen
  (harmlos); der Katalog bietet dafür „Aktualisieren" an, sobald er eine höhere
  `revision` hat.
- Der Katalog-Ordner im Repo heißt `themes/` (nicht `assets/`), weil die Dateien
  bewusst **nicht** im APK stecken.

## App-Icon vs. Theme-Logo

Das echte App-Icon (Homescreen) ist **eine** statische Android/iOS-Ressource
(`assets/icon/icon_legacy.png` + `icon_foreground.png`, via
`flutter_launcher_icons`) und lässt sich nicht einfach zur Laufzeit pro
gewähltem Theme austauschen – dafür bräuchte es mehrere `<activity-alias>`-
Einträge im Manifest plus natives Umschalten per `PackageManager`, mit
launcherabhängigen Eigenheiten. Deshalb: das App-Icon trägt das **braune
Standard-Farbschema** (System/Hell/Dunkel), unabhängig vom gewählten
Custom-Theme. Jedes Custom-Theme kann stattdessen sein eigenes, passend
eingefärbtes Logo im `logo`-Feld mitbringen – sichtbar als Vorschau in der
Liste der installierten Schemata und im Katalog (dort als `previews/<id>.png`).
Alle drei (Braun/Blue Gold/Old Library) sind dieselbe Grafik, nur umgefärbt
(`assets/icon/recolor.js`: pro Pixel dem nächsten von vier Referenzfarben
zuordnen und dorthin verschieben – Kanten und Bézier-Formen bleiben exakt
erhalten).

## Schriftart pro Theme

Anders als Bild/Logo (data-URI im File) wird bei `font` **kein** Dateiinhalt
eingebettet, sondern nur ein Name – die Schrift muss schon im APK stecken
(`pubspec.yaml` → `flutter.fonts`), weil Schriftdateien zu groß sind, um sie in
jedes Theme-File zu packen. **Ein Schema aus dem Katalog kann also keine neue
Schrift mitbringen;** dafür braucht es ein App-Update. Aktuell im APK:
**Tinos** (Google, [SIL Open Font License 1.1](assets/fonts/OFL.txt), metrisch
mit Times New Roman kompatibel; `assets/fonts/Tinos-*.ttf`), genutzt vom
„Old Library"-Theme. Ein Theme mit unbekanntem `font`-Namen verliert dadurch
nichts – die App fällt lautlos auf die Systemschrift zurück (der Test
`themes_catalog_test.dart` fängt das für Katalog-Themes vorher ab).

## Später (BACKLOG)

- Theme-File mit *hell + dunkel* in einem (folgt dann optional dem System).
- Schriften nachladbar machen (Schrift als Datei im Katalog + `FontLoader`) –
  bisher nur Schriften aus dem APK.
- Echtes Umschalten des Homescreen-Icons pro Theme (`activity-alias` +
  natives Umschalten) – eigener, größerer Baustein.
