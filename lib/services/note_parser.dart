import 'german_number_parser.dart';

/// Ergebnis des Parsers. Wird vom Aufrufer in eine `Note` überführt.
class ParsedNote {
  const ParsedNote({
    this.page,
    this.position,
    required this.text,
    required this.rawTranscript,
  });

  /// `"47"`, `"88f."`, `"12ff."` oder `null`.
  final String? page;

  /// `"oben"`, `"mitte"`, `"unten"`, `"Zeile 10"` oder `null`.
  final String? position;

  /// Notiztext ohne Seiten-/Positionspräfix. Leer, wenn nur Präfix gesprochen.
  final String text;

  final String rawTranscript;

  @override
  String toString() => 'ParsedNote(page: $page, position: $position, "$text")';
}

/// Regelbasierter Parser für Transkripte (PROJECT.md, Abschnitt 5).
///
/// Konvention: `Seite <Zahl> [folgende|f.|ff.] [oben|mitte|unten|Zeile <Zahl>] , <Text>`
///
/// - Zahlen als Ziffern oder deutsches Zahlwort.
/// - Ohne erkennbare Seitenangabe wird alles als Text übernommen.
/// - Groß-/Kleinschreibung und Satzzeichen zwischen den Teilen sind egal;
///   der Text behält seine Originalschreibung.
class NoteParser {
  const NoteParser();

  static const _w = r'[a-zäöüß]';

  // Seite: "Seite 47", "auf Seite 47", "S. 47", "Seite siebenundvierzig"
  static final _pageRe = RegExp(
    r'^[\s.,;:!?\-–]*(?:auf\s+)?(?:seite|s\.)\s*'
    '(?<num>\\d+|$_w+)',
    caseSensitive: false,
  );

  // Trennzeichen zwischen den Teilen (auch "und", z.B. "Seite 3 und folgende")
  static const _sep = r'[\s.,;:\-–]*';

  static final _followingRe = RegExp(
    '^$_sep(?:(?:und\\s+)?(?<ff>ff|fortfolgende|folgenden|folgende)\\.?|'
    '(?<f>f))\\.?(?!$_w)',
    caseSensitive: false,
  );

  static final _positionRe = RegExp(
    '^$_sep(?:(?<pos>oben|mitte|mittig|unten)|'
    'zeile\\s*(?<line>\\d+|$_w+))(?!$_w)',
    caseSensitive: false,
  );

  static final _leadingSepRe = RegExp('^$_sep');

  ParsedNote parse(String raw) {
    final lower = raw.toLowerCase();
    // Sicherheitsnetz: toLowerCase kann in exotischen Fällen die Länge ändern.
    final source = lower.length == raw.length ? raw : lower;

    final pageMatch = _pageRe.firstMatch(lower);
    if (pageMatch == null) {
      return ParsedNote(text: _cleanText(raw), rawTranscript: raw);
    }

    final numToken = pageMatch.namedGroup('num')!;
    final pageNumber =
        int.tryParse(numToken) ?? GermanNumberParser.parse(numToken);
    if (pageNumber == null) {
      // "Seite" gefolgt von einem Nicht-Zahlwort → keine Seitenangabe.
      return ParsedNote(text: _cleanText(raw), rawTranscript: raw);
    }

    var cursor = pageMatch.end;
    var page = '$pageNumber';

    final ff = _followingRe.firstMatch(lower.substring(cursor));
    if (ff != null) {
      final token = (ff.namedGroup('ff') ?? ff.namedGroup('f'))!.toLowerCase();
      page += (token == 'ff' || token == 'fortfolgende') ? 'ff.' : 'f.';
      cursor += ff.end;
    }

    String? position;
    final pos = _positionRe.firstMatch(lower.substring(cursor));
    if (pos != null) {
      final word = pos.namedGroup('pos');
      if (word != null) {
        position = word == 'mittig' ? 'mitte' : word;
      } else {
        final lineToken = pos.namedGroup('line')!;
        final line =
            int.tryParse(lineToken) ?? GermanNumberParser.parse(lineToken);
        position = line != null ? 'Zeile $line' : null;
      }
      if (position != null) cursor += pos.end;
    }

    final text = _cleanText(source.substring(cursor));
    return ParsedNote(
      page: page,
      position: position,
      text: text,
      rawTranscript: raw,
    );
  }

  /// Entfernt führende Trennzeichen und Leerraum am Ende.
  String _cleanText(String s) => s.replaceFirst(_leadingSepRe, '').trim();
}
