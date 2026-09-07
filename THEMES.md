# Booknote — Eigene Farbschemata (Custom Themes)

Eine Theme-Datei ist **eine portable JSON-Datei**. Der Nutzer legt sie z.B. in
den Download-Ordner und lädt sie über **Einstellungen → Darstellung → Eigene
Farbschemata → Importieren …**. Mitgelieferte Themes (Assets) stehen dort
ebenfalls; „Blue Gold" ist das erste.

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
  }
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

## Später (BACKLOG)

- Theme-File mit *hell + dunkel* in einem (folgt dann optional dem System).
- Auswahl-UI mit größerer Vorschau.
