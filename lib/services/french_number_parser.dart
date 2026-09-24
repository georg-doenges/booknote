/// Wandelt französische Zahlwörter in Zahlen um: „quarante-sept" → 47,
/// „quatre-vingt-dix-sept" → 97, „trois cent douze" → 312, „deux mille un" → 2001.
///
/// Wie [GermanNumberParser]: Rückfallebene für den Fall, dass ein Zahlwort
/// ausgeschrieben statt in Ziffern transkribiert wird (Whisper liefert bei
/// Seitenzahlen fast immer Ziffern). Belgische Formen „septante" (70) und
/// „nonante" (90) werden ebenso verstanden wie „huitante"/„octante" (80).
/// Leerzeichen, Bindestriche, Akzente und das „et" („vingt et un") sind egal.
class FrenchNumberParser {
  FrenchNumberParser._();

  // Ohne Akzente, ohne Trennzeichen – die Eingabe wird vorher genauso
  // normalisiert.
  static const _units = <String, int>{
    'zero': 0,
    'un': 1,
    'une': 1,
    'deux': 2,
    'trois': 3,
    'quatre': 4,
    'cinq': 5,
    'six': 6,
    'sept': 7,
    'huit': 8,
    'neuf': 9,
    'dix': 10,
    'onze': 11,
    'douze': 12,
    'treize': 13,
    'quatorze': 14,
    'quinze': 15,
    'seize': 16,
    'dixsept': 17,
    'dixhuit': 18,
    'dixneuf': 19,
  };

  /// Zehner mit dem größten erlaubten Rest (9 bzw. 19: „soixante-dix-sept",
  /// „quatre-vingt-dix-neuf"). Längere Schlüssel zuerst, damit „quatrevingts"
  /// nicht als „quatrevingt" + „s" gelesen wird.
  static const _tens = <(String, int, int)>[
    ('quatrevingts', 80, 0),
    ('quatrevingt', 80, 19),
    ('soixante', 60, 19),
    ('cinquante', 50, 9),
    ('quarante', 40, 9),
    ('trente', 30, 9),
    ('vingt', 20, 9),
    ('septante', 70, 9),
    ('huitante', 80, 9),
    ('octante', 80, 9),
    ('nonante', 90, 9),
  ];

  /// Gibt die Zahl zurück oder `null`, wenn [word] kein Zahlwort ist.
  static int? parse(String word) {
    final w = _normalize(word);
    if (w.isEmpty) return null;
    return _parse(w);
  }

  static String _normalize(String s) => s
      .toLowerCase()
      .replaceAll(RegExp(r'[\s\-]'), '')
      .replaceAll(RegExp('[éèêë]'), 'e')
      .replaceAll(RegExp('[àâ]'), 'a')
      .replaceAll(RegExp('[îï]'), 'i')
      .replaceAll(RegExp('[ôö]'), 'o')
      .replaceAll(RegExp('[ûùü]'), 'u')
      .replaceAll('ç', 'c')
      .replaceAll('œ', 'oe');

  static int? _parse(String w) {
    final t = w.indexOf('mille');
    if (t >= 0) {
      final left = w.substring(0, t);
      final right = _stripEt(w.substring(t + 'mille'.length));
      final leftVal = left.isEmpty ? 1 : _parseBelowThousand(left);
      if (leftVal == null) return null;
      final rightVal = right.isEmpty ? 0 : _parseBelowThousand(right);
      if (rightVal == null) return null;
      return leftVal * 1000 + rightVal;
    }
    return _parseBelowThousand(w);
  }

  static int? _parseBelowThousand(String w) {
    final h = w.indexOf('cent');
    if (h >= 0) {
      final left = w.substring(0, h);
      var right = w.substring(h + 'cent'.length);
      if (right.startsWith('s')) right = right.substring(1); // „deux cents"
      right = _stripEt(right);
      final leftVal = left.isEmpty ? 1 : _units[left];
      if (leftVal == null || leftVal < 1 || leftVal > 9) return null;
      final rightVal = right.isEmpty ? 0 : _parseBelowHundred(right);
      if (rightVal == null) return null;
      return leftVal * 100 + rightVal;
    }
    return _parseBelowHundred(w);
  }

  static int? _parseBelowHundred(String w) {
    final direct = _units[w];
    if (direct != null) return direct;

    for (final (name, value, maxRest) in _tens) {
      if (w == name) return value;
      if (!w.startsWith(name) || maxRest == 0) continue;
      final unit = _units[_stripEt(w.substring(name.length))];
      if (unit != null && unit >= 1 && unit <= maxRest) return value + unit;
    }
    return null;
  }

  /// „vingt et un" → nach dem Entfernen der Leerzeichen „vingtetun".
  static String _stripEt(String w) => w.startsWith('et') ? w.substring(2) : w;
}
