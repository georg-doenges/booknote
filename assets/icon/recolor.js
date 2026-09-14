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
// - blue_gold / tequila_sunrise → auf ~256px verkleinern, als Base64 in das
//   `logo`-Feld der jeweiligen `assets/themes/*.json` einbetten.
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

// bg/outline/accent/dark je Ziel-Farbschema (siehe assets/themes/*.json).
const PALETTES = {
  blue_gold: {
    bg: [0x0e, 0x1a, 0x2c],
    outline: [0x8f, 0xa0, 0xbf],
    accent: [0xc6, 0xa0, 0x52],
    dark: [0x24, 0x19, 0x00],
  },
  default_brown: {
    bg: [0x2e, 0x20, 0x18],
    outline: [0xd9, 0xc3, 0xa3],
    accent: [0xc6, 0x8a, 0x3d],
    dark: [0x1c, 0x0f, 0x08],
  },
  tequila_sunrise: {
    bg: [0x2a, 0x14, 0x20],
    outline: [0xff, 0xdc, 0xc5],
    accent: [0xff, 0x7a, 0x3d],
    dark: [0x3a, 0x14, 0x00],
  },
};

(async () => {
  for (const [name, palette] of Object.entries(PALETTES)) {
    const out = path.join(ICON_DIR, `recolor_${name}.png`);
    await recolor(SRC, palette, out);
    console.log('done:', out);
  }
})();
