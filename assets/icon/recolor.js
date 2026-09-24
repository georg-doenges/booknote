// Erzeugt Farbvarianten des App-Icons/Logos aus `source.png`, ohne die
// Geometrie anzutasten: jeder Pixel wird den zwei nächsten von vier
// Referenzfarben zugeordnet und dorthin linear verschoben (erhält
// Kanten/Antialiasing exakt). Siehe THEMES.md "App-Icon vs. Theme-Logo".
//
// Einmalig: `npm install sharp` in diesem Ordner (kein Projekt-Dependency,
// nur Build-Tooling). Dann: `node recolor.js`.
//
// Ergebnis-Dateien manuell weiterverarbeiten:
// - default_brown → auf 1024 skalieren als icon_legacy.png, Rahmen
//   wegschneiden + neu zentrieren als icon_foreground.png (Basis für
//   `flutter_launcher_icons`, siehe pubspec.yaml).
// - alle anderen (Themes) → auf 256px verkleinern, als Base64 in das
//   `logo`-Feld der jeweiligen `themes/*.json` einbetten (`themes/index.json` +
//   Vorschauen danach mit `dart run tool/build_theme_index.dart` erneuern).
//   Die Palette hier muss zu `accent`/`surface` des Themes passen.
const sharp = require('sharp');
const path = require('path');

const ICON_DIR = __dirname;
const SRC = path.join(ICON_DIR, 'source.png');

// Referenzfarben, aus `source.png` abgetastet (die vier Flächen des Motivs).
const REF = {
  bg: [8, 24, 48],
  outline: [96, 136, 200],
  accent: [192, 152, 64],
  dark: [24, 8, 0],
};
const REF_LIST = [REF.bg, REF.outline, REF.accent, REF.dark];

function dist2(a, b) {
  const dr = a[0] - b[0], dg = a[1] - b[1], db = a[2] - b[2];
  return dr * dr + dg * dg + db * db;
}
function nearestTwo(p) {
  const d = REF_LIST.map((r) => dist2(p, r));
  let i0 = 0, i1 = 1;
  if (d[1] < d[0]) { i0 = 1; i1 = 0; }
  for (let i = 2; i < d.length; i++) {
    if (d[i] < d[i0]) { i1 = i0; i0 = i; }
    else if (d[i] < d[i1]) { i1 = i; }
  }
  return [i0, i1];
}
function project(p, a, b) {
  const ab = [b[0] - a[0], b[1] - a[1], b[2] - a[2]];
  const ap = [p[0] - a[0], p[1] - a[1], p[2] - a[2]];
  const denom = ab[0] * ab[0] + ab[1] * ab[1] + ab[2] * ab[2] || 1e-6;
  const t = (ap[0] * ab[0] + ap[1] * ab[1] + ap[2] * ab[2]) / denom;
  return Math.max(0, Math.min(1, t));
}
function lerp(a, b, t) {
  return [
    Math.round(a[0] + (b[0] - a[0]) * t),
    Math.round(a[1] + (b[1] - a[1]) * t),
    Math.round(a[2] + (b[2] - a[2]) * t),
  ];
}

async function recolor(srcPath, target, outPath) {
  const targetList = [target.bg, target.outline, target.accent, target.dark];
  const { data, info } = await sharp(srcPath)
    .raw()
    .toBuffer({ resolveWithObject: true });
  const { width, height, channels } = info;
  const out = Buffer.alloc(width * height * channels);
  for (let i = 0; i < width * height; i++) {
    const o = i * channels;
    const p = [data[o], data[o + 1], data[o + 2]];
    const [i0, i1] = nearestTwo(p);
    const t = project(p, REF_LIST[i0], REF_LIST[i1]);
    const c = lerp(targetList[i0], targetList[i1], t);
    out[o] = c[0];
    out[o + 1] = c[1];
    out[o + 2] = c[2];
    if (channels === 4) out[o + 3] = data[o + 3];
  }
  await sharp(out, { raw: { width, height, channels } }).png().toFile(outPath);
}

// bg/outline/accent/dark je Ziel-Farbschema (siehe themes/*.json).
const PALETTES = {
  blue_gold: {
    bg: [0x0e, 0x1a, 0x2c],
    outline: [0x8f, 0xa0, 0xbf],
    accent: [0xbd, 0x9b, 0x5e],
    dark: [0x22, 0x1b, 0x0d],
  },
  default_brown: {
    bg: [0x2e, 0x20, 0x18],
    outline: [0xd9, 0xc3, 0xa3],
    accent: [0xc6, 0x8a, 0x3d],
    dark: [0x1c, 0x0f, 0x08],
  },
  old_library: {
    bg: [0xe3, 0xd2, 0xae],
    outline: [0x3b, 0x2a, 0x18],
    accent: [0x9c, 0x4b, 0x3a],
    dark: [0x24, 0x15, 0x05],
  },
  clean_slate: {
    bg: [0xf1, 0xf4, 0xf7],
    outline: [0x1b, 0x24, 0x30],
    accent: [0x3a, 0x60, 0x88],
    dark: [0x0c, 0x12, 0x1a],
  },
  sundown: {
    bg: [0x2a, 0x12, 0x33],
    outline: [0xf3, 0xb5, 0xcf],
    accent: [0xff, 0x8a, 0x3d],
    dark: [0x14, 0x06, 0x1a],
  },
  book_cloth: {
    bg: [0x14, 0x36, 0x30],
    outline: [0xb9, 0xcb, 0xb8],
    accent: [0xf7, 0x9d, 0x7b],
    dark: [0x08, 0x1e, 0x1a],
  },
  graphite: {
    bg: [0x12, 0x14, 0x17],
    outline: [0x9b, 0xa3, 0xad],
    accent: [0x4f, 0xe3, 0xb8],
    dark: [0x06, 0x08, 0x09],
  },
};

(async () => {
  for (const [name, palette] of Object.entries(PALETTES)) {
    const out = path.join(ICON_DIR, `recolor_${name}.png`);
    await recolor(SRC, palette, out);
    console.log('done:', out);
  }
})();
