# Booknote — Eigene Farbschemata (Custom Themes)

Eine Theme-Datei ist **eine portable JSON-Datei**. Der Nutzer legt sie z.B. in
den Download-Ordner und lädt sie über **Einstellungen → Darstellung → Eigene
Farbschemata → Importieren …**. Mitgelieferte Themes (Assets) stehen dort
ebenfalls; „Blue Gold" und „Tequila Sunrise" sind dabei.

Ein Custom-Theme ist **ein fester Look** – es folgt nicht dem Hell/Dunkel des
Systems. Wählt man wieder System / Hell / Dunkel, ist es aus.

## Format

```jsonc
{
  "format": "booknote-theme",
  "formatVersion": 1,
  "id": "blue_gold",            // optional; sonst aus dem Namen abgeleitet
  "name": "Blue Gold",          // Pflicht, wird in den Einstellungen angezeigt
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

  // Optional: Hintergrund hinter den großen Flächen (AppBar + System-Leisten
  // bleiben undurchsichtig). Fehlt der Block, gibt es keinen Hintergrund.
  "background": {
    "image": "data:image/png;base64,iVBORw0KGgo…",  // Bild IM File eingebettet
    "fit": "cover",     // "cover" (formatfüllend) | "tile" (kacheln)
    "opacity": 1.0,     // 0..1
    "dim": 0.15         // 0..1 – zusätzlicher dunkler Schleier für Kontrast
  },

  // Optional: zum Schema passend eingefärbtes App-Logo, als data-URI direkt
  // im File. Wird nur als Vorschau in der Theme-Liste der Einstellungen
  // gezeigt (statt der abstrakten Farbkachel) – ändert nichts am echten
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
  darauf.
- `onSurfaceVariant` = gedämpfter Text (Datumsangaben, Erklärtexte).

## Wo die Dateien liegen

- Alle Schemata liegen als `<App-Dokumente>/themes/<id>.json` (nicht im Git,
  nicht im Bibliotheks-Abgleich). Alle sind gleichwertig und **löschbar**.
- Die mitgelieferten (`assets/themes/*.json`, im Repo + `pubspec.yaml`) werden
  beim **Erststart einmalig** dorthin kopiert (Marker `.initialized`). Ein
  danach gelöschtes mitgeliefertes Schema holt „… wiederherstellen" in den
  Einstellungen aus den Assets zurück.

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
Theme-Liste der Einstellungen. Alle drei (Braun/Blue Gold/Tequila Sunrise)
sind dieselbe Grafik, nur umgefärbt (`recolor.js`-Ansatz: pro Pixel dem
nächsten von vier Referenzfarben zuordnen und dorthin verschieben – Kanten und
Bézier-Formen bleiben exakt erhalten).

## Später (BACKLOG)

- Theme-File mit *hell + dunkel* in einem (folgt dann optional dem System).
- Auswahl-UI mit größerer Vorschau.
- Echtes Umschalten des Homescreen-Icons pro Theme (`activity-alias` +
  natives Umschalten) – eigener, größerer Baustein.
