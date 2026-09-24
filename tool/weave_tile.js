// Erzeugt eine nahtlos kachelbare Gewebe-Textur (Leinwandbindung, „Buchleinen")
// als PNG – Hintergrund für Farbschemata, z.B. `themes/book_cloth.json`
// (`background.fit: "tile"`). Die App zeichnet die Kachel 1 Pixel-zu-1 dp, die
// Fäden sind also weich vergrößert (Feinheit = `--pitch`).
//
// Einmalig: `npm install sharp` in assets/icon (siehe recolor.js); dieses Skript
// nutzt dieselbe Installation.
//
//   node tool/weave_tile.js out.png --warp "#1C4B41" --weft "#10322F"
//
// Optionen: --warp/--weft  mittlere Farbe der senkrechten/waagerechten Fäden
//           --size 128     Kachelkante in Pixeln (Vielfaches von 2 × pitch)
//           --pitch 8      Fadenabstand in Pixeln
//           --jitter 0.05  Helligkeitsstreuung von Faden zu Faden
//           --relief 0.5   0..1, wie stark Rundung und Kreuzungen schattiert sind
//           --slub 0.04    0..0.1, sanfte Unregelmäßigkeit entlang jedes Fadens
//           --seed 7       Zufallsstart (gleicher Wert → gleiche Kachel)
//
// Bei Änderungen an den Farben oder der Textur das Theme mit hochgezählter
// `revision` neu ausliefern (THEMES.md).
const path = require('path');
const sharp = require(path.join(__dirname, '..', 'assets', 'icon', 'node_modules', 'sharp'));

function parseArgs(argv) {
  const out = { _: [] };
  for (let i = 0; i < argv.length; i++) {
    if (argv[i].startsWith('--')) out[argv[i].slice(2)] = argv[++i];
    else out._.push(argv[i]);
  }
  return out;
}

function hex(h) {
  const s = h.replace('#', '');
  return [0, 2, 4].map((i) => parseInt(s.slice(i, i + 2), 16));
}

// Kleiner deterministischer Zufallsgenerator (mulberry32).
function rng(seed) {
  let a = seed >>> 0;
  return () => {
    a = (a + 0x6d2b79f5) >>> 0;
    let t = a;
    t = Math.imul(t ^ (t >>> 15), t | 1);
    t ^= t + Math.imul(t ^ (t >>> 7), t | 61);
    return ((t ^ (t >>> 14)) >>> 0) / 4294967296;
  };
}

async function main() {
  const args = parseArgs(process.argv.slice(2));
  const outPath = args._[0];
  if (!outPath || !args.warp || !args.weft) {
    console.error('Aufruf: node tool/weave_tile.js out.png --warp "#RRGGBB" --weft "#RRGGBB"');
    process.exit(1);
  }
  const size = parseInt(args.size || '128', 10);
  const P = parseInt(args.pitch || '8', 10);
  const jitter = parseFloat(args.jitter || '0.05');
  const relief = parseFloat(args.relief || '0.5');
  const slub = parseFloat(args.slub || '0.04');
  const rand = rng(parseInt(args.seed || '7', 10));
  if (size % (2 * P) !== 0) throw new Error('size muss ein Vielfaches von 2*pitch sein.');

  const warp = hex(args.warp);
  const weft = hex(args.weft);
  const n = size / P; // Fäden je Richtung
  // Je Faden ein eigener Helligkeitsfaktor und eine leichte Farbabweichung.
  const tone = (count) =>
    Array.from({ length: count }, () => ({
      k: 1 + (rand() * 2 - 1) * jitter,
      dr: (rand() * 2 - 1) * 2,
      dg: (rand() * 2 - 1) * 2,
      db: (rand() * 2 - 1) * 2,
    }));
  const warpTone = tone(n);
  const weftTone = tone(n);
  // Verdickungen/Verdünnungen entlang des Fadens: ganze Perioden je Kachel, damit
  // die Kachel nahtlos bleibt.
  const slubs = () =>
    Array.from({ length: n }, () => ({
      periods: 2 + Math.floor(rand() * 3),
      phase: rand() * Math.PI * 2,
    }));
  const warpSlub = slubs();
  const weftSlub = slubs();
  // Fasern: feine Längsstreifen je Faden (ändern sich entlang des Fadens nicht).
  const fibre = (count) =>
    Array.from({ length: count * P }, () => (rand() * 2 - 1) * 0.025);
  const warpFibre = fibre(n);
  const weftFibre = fibre(n);

  const buf = Buffer.alloc(size * size * 3);
  for (let y = 0; y < size; y++) {
    for (let x = 0; x < size; x++) {
      const cx = Math.floor(x / P);
      const cy = Math.floor(y / P);
      const u = x % P;
      const v = y % P;
      const warpOver = (cx + cy) % 2 === 0; // senkrechter Faden liegt oben

      const across = warpOver ? u : v;
      const along = warpOver ? v : u;
      const idx = warpOver ? cx : cy;
      const base = warpOver ? warp : weft;
      const t = warpOver ? warpTone[idx] : weftTone[idx];
      const fib = (warpOver ? warpFibre : weftFibre)[idx * P + across];

      // Querschnitt des Fadens: rund, Licht von links oben.
      const s = ((across + 0.5) / P) * 2 - 1; // -1 … 1
      const round = Math.sqrt(Math.max(0, 1 - 0.85 * s * s));
      const light = 1 - 0.09 * relief * 2 * s; // linke/obere Seite heller
      // Längs: an den Kreuzungen im leichten Schatten (weich, sonst wirkt jede
      // Kreuzung wie ein eigener Klotz).
      const a = (along + 0.5) / P;
      const hump = Math.pow(Math.sin(Math.PI * a), 0.55);
      const shade =
        (1 - relief * 0.4 + relief * 0.4 * round) *
        (1 - relief * 0.3 + relief * 0.3 * hump) *
        light;
      // Sanfte Unregelmäßigkeit entlang des Fadens (über die ganze Kachel).
      const sl = (warpOver ? warpSlub : weftSlub)[idx];
      const pos = (warpOver ? y : x) / size;
      const slubK = 1 + slub * Math.sin(2 * Math.PI * sl.periods * pos + sl.phase);

      const grain = (rand() * 2 - 1) * 0.012;
      const k = shade * slubK * t.k * (1 + fib + grain);
      const o = (y * size + x) * 3;
      buf[o] = clamp(base[0] * k + t.dr);
      buf[o + 1] = clamp(base[1] * k + t.dg);
      buf[o + 2] = clamp(base[2] * k + t.db);
    }
  }
  await sharp(buf, { raw: { width: size, height: size, channels: 3 } })
    .png({ compressionLevel: 9 })
    .toFile(outPath);
  console.log('geschrieben:', outPath);

  // Kennzahlen fürs Theme: `surface` = mittlere Farbe; Text muss auch auf dem
  // hellsten Texel noch gut lesbar sein (siehe THEMES.md, „Hintergrund-Muster").
  const sum = [0, 0, 0];
  let lightest = 0;
  let darkest = 0;
  let maxL = -1;
  let minL = 1e9;
  for (let i = 0; i < size * size; i++) {
    const [r, g, b] = [buf[i * 3], buf[i * 3 + 1], buf[i * 3 + 2]];
    sum[0] += r;
    sum[1] += g;
    sum[2] += b;
    const l = 0.2126 * r + 0.7152 * g + 0.0722 * b;
    if (l > maxL) { maxL = l; lightest = i; }
    if (l < minL) { minL = l; darkest = i; }
  }
  const h = (i) => '#' + [0, 1, 2].map((c) => buf[i * 3 + c].toString(16).padStart(2, '0')).join('').toUpperCase();
  const mean = sum.map((s) => Math.round(s / (size * size)));
  console.log('mittlere Farbe (→ surface):', '#' + mean.map((c) => c.toString(16).padStart(2, '0')).join('').toUpperCase());
  console.log('hellster Texel:', h(lightest), ' dunkelster Texel:', h(darkest));
}

function clamp(v) {
  return Math.max(0, Math.min(255, Math.round(v)));
}

main();
