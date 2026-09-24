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
   Optional: `description` (eine Zeile für den Katalog, am besten je Sprache
   `de`/`en`/`fr`) und `revision`. Ein Schema mit Bild (`logo`, `background`)
   bekommt es per Skript eingebettet (siehe unten).
2. Katalog neu erzeugen (im Projektordner):
   ```bash
   dart run tool/build_theme_index.dart
   ```
   Das schreibt `themes/index.json` und je Theme mit `logo` die Vorschau
   `themes/previews/<id>.png` (aus dem eingebetteten Logo). Im Index steht die
   Beschreibung doppelt: `description` als **einfacher Text** (deutsch) und
   `descriptions` je Sprache. Das ist Absicht: Apps bis 0.1.0+26 lesen
   `description` nur als Text – ein Sprach-Objekt dort würde ihren Katalog
   unbrauchbar machen. Neuere Apps nehmen `descriptions`. (In der Theme-Datei
   selbst darf `description` weiter ein Objekt sein; der Index-Bau übersetzt.)
3. Committen und auf `main` pushen. Die App sieht es beim nächsten Öffnen des
   Katalogs – kein neues APK nötig.

Der Test `test/themes_catalog_test.dart` schlägt an, wenn `index.json` nicht zu den
Theme-Dateien passt, wenn eine Datei kein gültiges Theme ist oder wenn ein Theme
eine Schrift nennt, die nicht im APK steckt.

### Aktueller Katalog

| Schema | Look | Besonderheit |
|---|---|---|
| Blue Gold | Nachtblau, mattes Altgold | Schrift Tinos, Logo in Altgold |
| Old Library | Pergament, Leder, Bordeaux | Schrift Tinos |
| Clean Slate | Weiß, feine Grautöne, Stahlblau | luftig; alle Flächen bewusst neutral |
| Sundown | Pflaumenviolett, Orange, Pink | Farbe auf den großen Flächen |
| Book Cloth | Flaschengrünes Buchleinen, Koralle | Gewebe-Hintergrund (Kachel) |
| Graphite | Neutrales Dunkelgrau, Mintgrün | für alle, die Braun nicht mögen |

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
  "description": {              // optional, nur Katalog-Zeile: ein Text für alle
    "de": "Nachtblau mit goldenem Akzent.",   // Sprachen oder je Sprache (de/en/fr);
    "en": "Midnight blue with a golden accent.",  // fehlt die App-Sprache, gilt
    "fr": "Bleu nuit avec un accent doré."        // English, sonst Deutsch
  },
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

### Rezepte (aus den ersten Katalog-Schemata)

- **Luftig/„clean":** *alle* `surfaceContainer*`-Rollen ausdrücklich als
  Neutralgrau setzen (sonst mischt Material 3 Farbe hinein), Karten kaum dunkler
  als `surface`, `outlineVariant` sehr hell (Trennlinien), aber `outline` auf ca.
  3:1 zu `surface`, weil Eingabefelder ihn als Rahmen nutzen. Nur **ein** Akzent.
  Abstände und Layout kann ein Schema nicht ändern – Weißraum entsteht nur über
  Farben.
- **Kräftig, aber lesbar:** die Farbe auf die *großen* Flächen legen (`surface`,
  Karten), nicht nur auf Akzente – Tequila Sunrise scheiterte daran, dass sie zu
  spärlich saß. Dafür ein tiefer Grund mit hellem Text (Kontrast ≥ 7:1).
- **Kontrast:** `test/themes_catalog_test.dart` prüft für jedes Katalog-Schema
  die wichtigen Text-/Flächenpaare (WCAG ≥ 4,5:1, Fließtext ≥ 7:1). Ein neues
  Schema, das daran scheitert, ist zu schwach lesbar.

## Hintergrund-Muster (Kachel)

`background` mit `"fit": "tile"` wiederholt ein kleines PNG. Die App zeichnet die
Kachel **1 Pixel = 1 dp** und vergrößert sie auf dem Handy weich (2,5–3,5×); feine
Muster brauchen deshalb keine hohe Auflösung, wirken aber weich. Das Bild liegt als
data-URI in der Theme-Datei (Limit 8 MB, sinnvoll sind < 100 KB).

Für Gewebe gibt es einen Generator: `node tool/weave_tile.js out.png --warp
"#RRGGBB" --weft "#RRGGBB" …` (Leinwandbindung, Fadenabstand, Streuung,
`--seed` für Wiederholbarkeit; nutzt das `sharp` aus `assets/icon`). Book Cloth
entstand mit `--pitch 5 --size 120 --warp "#173F37" --weft "#123530"
--jitter 0.08 --relief 0.6 --slub 0.05 --seed 11`. Regeln:

- `surface` des Themes = mittlere Farbe der Kachel (das Skript nennt sie), damit
  die undurchsichtige AppBar zum Muster passt.
- Text steht teils direkt auf dem Muster (Einstellungen): der **hellste Texel**
  muss noch ≥ 7:1 zu `onSurface` und ≥ 4,5:1 zu `onSurfaceVariant` haben (das
  Skript nennt hellsten und dunkelsten Texel).
- Karten und Dialoge sind deckend (`surfaceContainer*`), das Muster stört dort nie.
- Nach jeder Änderung `revision` hochzählen.

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
Alle (Braun und jedes Katalog-Schema) sind dieselbe Grafik, nur umgefärbt
(`assets/icon/recolor.js`: pro Pixel dem nächsten von vier Referenzfarben
zuordnen und dorthin verschieben – Kanten und Bézier-Formen bleiben exakt
erhalten). Für ein neues Schema dort eine Palette (`bg`/`outline`/`accent`/`dark`)
eintragen, `node recolor.js` laufen lassen, das Ergebnis auf 256 px verkleinern
und als data-URI in `logo` einbetten.

## Schriftart pro Theme

Anders als Bild/Logo (data-URI im File) wird bei `font` **kein** Dateiinhalt
eingebettet, sondern nur ein Name – die Schrift muss schon im APK stecken
(`pubspec.yaml` → `flutter.fonts`), weil Schriftdateien zu groß sind, um sie in
jedes Theme-File zu packen. **Ein Schema aus dem Katalog kann also keine neue
Schrift mitbringen;** dafür braucht es ein App-Update. Aktuell im APK:
**Tinos** (Google, [SIL Open Font License 1.1](assets/fonts/OFL.txt), metrisch
mit Times New Roman kompatibel; `assets/fonts/Tinos-*.ttf`), genutzt vom
„Old Library"- und „Blue Gold"-Theme. Ein Theme mit unbekanntem `font`-Namen verliert dadurch
nichts – die App fällt lautlos auf die Systemschrift zurück (der Test
`themes_catalog_test.dart` fängt das für Katalog-Themes vorher ab).

## Später (BACKLOG)

- Theme-File mit *hell + dunkel* in einem (folgt dann optional dem System).
- Schriften nachladbar machen (Schrift als Datei im Katalog + `FontLoader`) –
  bisher nur Schriften aus dem APK.
- Echtes Umschalten des Homescreen-Icons pro Theme (`activity-alias` +
  natives Umschalten) – eigener, größerer Baustein.
