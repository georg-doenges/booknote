/// Wandelt englische Zahlwörter in Zahlen um: „forty-seven" → 47,
/// „three-hundred-and-twelve" → 312, „two-thousand-one" → 2001.
///
/// Wie [GermanNumberParser]: Rückfallebene für den Fall, dass ein Zahlwort
/// ausgeschrieben statt in Ziffern transkribiert wird. Bei Englisch tut
/// Whisper das schon selbst fast immer – trotzdem als Fallback vorhanden.
/// Erkennt nur ein zusammenhängendes Wort (mit oder ohne Bindestrich); die im
/// Englischen übliche Schreibung mit Leerzeichen („forty seven") kann der
/// Parser nicht von zwei getrennten Wörtern im übrigen Satz unterscheiden.
class EnglishNumberParser {
  EnglishNumberParser._();

  static const _units = <String, int>{
    'zero': 0,
    'one': 1,
    'two': 2,
    'three': 3,
    'four': 4,
    'five': 5,
    'six': 6,
    'seven': 7,
    'eight': 8,
    'nine': 9,
    'ten': 10,
    'eleven': 11,
    'twelve': 12,
    'thirteen': 13,
    'fourteen': 14,
    'fifteen': 15,
    'sixteen': 16,
    'seventeen': 17,
    'eighteen': 18,
    'nineteen': 19,
  };

  static const _tens = <String, int>{
    'twenty': 20,
    'thirty': 30,
    'forty': 40,
    'fifty': 50,
    'sixty': 60,
    'seventy': 70,
    'eighty': 80,
    'ninety': 90,
  };

  /// Gibt die Zahl zurück oder `null`, wenn [word] kein Zahlwort ist.
  /// Groß-/Kleinschreibung, Leerzeichen und Bindestriche zwischen Teilen sind
  /// egal.
  static int? parse(String word) {
    final w = word.toLowerCase().replaceAll(RegExp(r'[\s\-]'), '');
    if (w.isEmpty) return null;
    return _parse(w);
  }

  static int? _parse(String w) {
    if (w.isEmpty) return null;

    final t = w.indexOf('thousand');
    if (t >= 0) {
      final left = w.substring(0, t);
      final right = _stripAnd(w.substring(t + 'thousand'.length));
      final leftVal = left.isEmpty ? 1 : _parseBelowThousand(left);
      if (leftVal == null) return null;
      final rightVal = right.isEmpty ? 0 : _parseBelowThousand(right);
      if (rightVal == null) return null;
      return leftVal * 1000 + rightVal;
    }
    return _parseBelowThousand(w);
  }

  static int? _parseBelowThousand(String w) {
    final h = w.indexOf('hundred');
    if (h >= 0) {
      final left = w.substring(0, h);
      final right = _stripAnd(w.substring(h + 'hundred'.length));
      final leftVal = left.isEmpty ? 1 : _units[left];
      if (leftVal == null || leftVal > 9) return null;
      final rightVal = right.isEmpty ? 0 : _parseBelowHundred(right);
      if (rightVal == null) return null;
      return leftVal * 100 + rightVal;
    }
    return _parseBelowHundred(w);
  }

  static int? _parseBelowHundred(String w) {
    final direct = _units[w] ?? _tens[w];
    if (direct != null) return direct;

    // „fortyseven" = forty + seven (anders als im Deutschen steht die Zehnerstelle vorn).
    for (final tens in _tens.entries) {
      if (w.startsWith(tens.key)) {
        final unit = _units[w.substring(tens.key.length)];
        if (unit != null && unit >= 1 && unit <= 9) return tens.value + unit;
      }
    }
    return null;
  }

  static String _stripAnd(String w) => w.startsWith('and') ? w.substring(3) : w;
}
