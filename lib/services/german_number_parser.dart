/// Wandelt deutsche Zahlwörter in Zahlen um: „siebenundvierzig" → 47,
/// „dreihundertzwölf" → 312, „zweitausendeins" → 2001.
///
/// Whisper liefert meist Ziffern; das hier ist die Rückfallebene für die
/// Fälle, in denen es das Zahlwort ausschreibt.
class GermanNumberParser {
  GermanNumberParser._();

  static const _units = <String, int>{
    'null': 0,
    'ein': 1,
    'eins': 1,
    'eine': 1,
    'zwei': 2,
    'zwo': 2,
    'drei': 3,
    'vier': 4,
    'fünf': 5,
    'fuenf': 5,
    'sechs': 6,
    'sieben': 7,
    'acht': 8,
    'neun': 9,
    'zehn': 10,
    'elf': 11,
    'zwölf': 12,
    'zwoelf': 12,
    'dreizehn': 13,
    'vierzehn': 14,
    'fünfzehn': 15,
    'fuenfzehn': 15,
    'sechzehn': 16,
    'siebzehn': 17,
    'achtzehn': 18,
    'neunzehn': 19,
  };

  static const _tens = <String, int>{
    'zwanzig': 20,
    'dreißig': 30,
    'dreissig': 30,
    'vierzig': 40,
    'fünfzig': 50,
    'fuenfzig': 50,
    'sechzig': 60,
    'siebzig': 70,
    'achtzig': 80,
    'neunzig': 90,
  };

  /// Gibt die Zahl zurück oder `null`, wenn [word] kein Zahlwort ist.
  /// Groß-/Kleinschreibung und Leerzeichen zwischen Teilen sind egal.
  static int? parse(String word) {
    final w = word.toLowerCase().replaceAll(RegExp(r'[\s\-]'), '');
    if (w.isEmpty) return null;
    return _parse(w);
  }

  static int? _parse(String w) {
    if (w.isEmpty) return null;

    final t = w.indexOf('tausend');
    if (t >= 0) {
      final left = w.substring(0, t);
      final right = w.substring(t + 'tausend'.length);
      final leftVal = left.isEmpty ? 1 : _parseBelowThousand(left);
      if (leftVal == null) return null;
      final rightVal = right.isEmpty ? 0 : _parseBelowThousand(right);
      if (rightVal == null) return null;
      return leftVal * 1000 + rightVal;
    }
    return _parseBelowThousand(w);
  }

  static int? _parseBelowThousand(String w) {
    final h = w.indexOf('hundert');
    if (h >= 0) {
      final left = w.substring(0, h);
      final right = w.substring(h + 'hundert'.length);
      final leftVal = left.isEmpty ? 1 : _units[left];
      // „elfhundert", „neunzehnhundert" sind üblich, deshalb bis 19.
      if (leftVal == null || leftVal > 19) return null;
      final rightVal = right.isEmpty ? 0 : _parseBelowHundred(right);
      if (rightVal == null) return null;
      return leftVal * 100 + rightVal;
    }
    return _parseBelowHundred(w);
  }

  static int? _parseBelowHundred(String w) {
    final direct = _units[w] ?? _tens[w];
    if (direct != null) return direct;

    // „siebenundvierzig" = sieben + und + vierzig
    final und = w.indexOf('und');
    if (und > 0) {
      final unit = _units[w.substring(0, und)];
      final tens = _tens[w.substring(und + 3)];
      if (unit != null && unit >= 1 && unit <= 9 && tens != null) {
        return tens + unit;
      }
    }
    return null;
  }
}
