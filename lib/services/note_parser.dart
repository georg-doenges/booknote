import '../models/app_language.dart';
import 'english_number_parser.dart';
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

  /// `"oben"`, `"mitte"`, `"unten"`, `"Zeile 10"` (oder die englischen
  /// Entsprechungen `"top"`, `"middle"`, `"bottom"`, `"Line 10"`) oder `null`.
  final String? position;

  /// Notiztext ohne Seiten-/Positionspräfix. Leer, wenn nur Präfix gesprochen.
  final String text;

  final String rawTranscript;

  @override
  String toString() => 'ParsedNote(page: $page, position: $position, "$text")';
}

/// Regelbasierter Parser für Transkripte (PROJECT.md, Abschnitt 5).
///
/// Deutsch: `Seite <Zahl> [folgende|f.|ff.] [oben|mitte|unten|Zeile <Zahl>] , <Text>`
/// Englisch: `page <Zahl> [following|ff.] [top|middle|bottom|line <Zahl>] , <Text>`
///
/// [language] wählt das Regelwerk (Standard: Deutsch) – passend zur
/// tatsächlichen Aufnahmesprache (Buch-Vorgabe oder Übersteuerung im
/// `RecordingScreen`), die auch Whisper steuert.
///
/// - Zahlen als Ziffern oder Zahlwort (ein zusammenhängendes Wort).
/// - Ohne erkennbare Seitenangabe wird alles als Text übernommen.
/// - Groß-/Kleinschreibung und Satzzeichen zwischen den Teilen sind egal;
///   der Text behält seine Originalschreibung.
class NoteParser {
  const NoteParser();

  ParsedNote parse(String raw, {AppLanguage language = AppLanguage.german}) =>
      language == AppLanguage.english ? _parseEnglish(raw) : _parseGerman(raw);

  // ---- Deutsch ----

  static const _wDe = r'[a-zäöüß]';

  // Seite: "Seite 47", "auf Seite 47", "S. 47", "Seite siebenundvierzig"
  static final _pageReDe = RegExp(
    r'^[\s.,;:!?\-–]*(?:auf\s+)?(?:seite|s\.)\s*'
    '(?<num>\\d+|$_wDe+)',
    caseSensitive: false,
  );

  // Trennzeichen zwischen den Teilen (auch "und", z.B. "Seite 3 und folgende")
  static const _sepDe = r'[\s.,;:\-–]*';

  static final _followingReDe = RegExp(
    '^$_sepDe(?:(?:und\\s+)?(?<ff>ff|fortfolgende|folgenden|folgende)\\.?|'
    '(?<f>f))\\.?(?!$_wDe)',
    caseSensitive: false,
  );

  static final _positionReDe = RegExp(
    '^$_sepDe(?:(?<pos>oben|mitte|mittig|unten)|'
    'zeile\\s*(?<line>\\d+|$_wDe+))(?!$_wDe)',
    caseSensitive: false,
  );

  static final _leadingSepReDe = RegExp('^$_sepDe');

  ParsedNote _parseGerman(String raw) {
    final lower = raw.toLowerCase();
    // Sicherheitsnetz: toLowerCase kann in exotischen Fällen die Länge ändern.
    final source = lower.length == raw.length ? raw : lower;

    final pageMatch = _pageReDe.firstMatch(lower);
    if (pageMatch == null) {
      return ParsedNote(text: _cleanTextDe(raw), rawTranscript: raw);
    }

    final numToken = pageMatch.namedGroup('num')!;
    final pageNumber =
        int.tryParse(numToken) ?? GermanNumberParser.parse(numToken);
    if (pageNumber == null) {
      // "Seite" gefolgt von einem Nicht-Zahlwort → keine Seitenangabe.
      return ParsedNote(text: _cleanTextDe(raw), rawTranscript: raw);
    }

    var cursor = pageMatch.end;
    var page = '$pageNumber';

    final ff = _followingReDe.firstMatch(lower.substring(cursor));
    if (ff != null) {
      final token = (ff.namedGroup('ff') ?? ff.namedGroup('f'))!.toLowerCase();
      page += (token == 'ff' || token == 'fortfolgende') ? 'ff.' : 'f.';
      cursor += ff.end;
    }

    String? position;
    final pos = _positionReDe.firstMatch(lower.substring(cursor));
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

    final text = _cleanTextDe(source.substring(cursor));
    return ParsedNote(
      page: page,
      position: position,
      text: text,
      rawTranscript: raw,
    );
  }

  /// Entfernt führende Trennzeichen und Leerraum am Ende.
  String _cleanTextDe(String s) => s.replaceFirst(_leadingSepReDe, '').trim();

  // ---- Englisch ----

  static const _wEn = r'[a-z\-]';

  // Seite: "page 47", "on page 47", "p. 47", "page forty-seven"
  static final _pageReEn = RegExp(
    r'^[\s.,;:!?\-–]*(?:on\s+)?(?:page|p\.)\s*'
    '(?<num>\\d+|$_wEn+)',
    caseSensitive: false,
  );

  static const _sepEn = r'[\s.,;:\-–]*';

  // "and following", "following page(s)", "onwards" – f./ff. gibt es auch im
  // englischen Zitierstil, deshalb dasselbe Suffix wie im Deutschen.
  static final _followingReEn = RegExp(
    '^$_sepEn(?:and\\s+)?(?:the\\s+)?'
    '(?:following\\s+(?<pl>pages)|following\\s+(?<sg>page)|'
    '(?<bare>following|onwards|onward))\\.?(?!$_wEn)',
    caseSensitive: false,
  );

  static final _positionReEn = RegExp(
    '^$_sepEn(?:(?<pos>top|middle|center|centre|bottom)|'
    'line\\s*(?<line>\\d+|$_wEn+))(?!$_wEn)',
    caseSensitive: false,
  );

  static final _leadingSepReEn = RegExp('^$_sepEn');

  ParsedNote _parseEnglish(String raw) {
    final lower = raw.toLowerCase();
    final source = lower.length == raw.length ? raw : lower;

    final pageMatch = _pageReEn.firstMatch(lower);
    if (pageMatch == null) {
      return ParsedNote(text: _cleanTextEn(raw), rawTranscript: raw);
    }

    final numToken = pageMatch.namedGroup('num')!;
    final pageNumber =
        int.tryParse(numToken) ?? EnglishNumberParser.parse(numToken);
    if (pageNumber == null) {
      return ParsedNote(text: _cleanTextEn(raw), rawTranscript: raw);
    }

    var cursor = pageMatch.end;
    var page = '$pageNumber';

    final ff = _followingReEn.firstMatch(lower.substring(cursor));
    if (ff != null) {
      final plural =
          ff.namedGroup('pl') != null || ff.namedGroup('bare') != null;
      page += plural ? 'ff.' : 'f.';
      cursor += ff.end;
    }

    String? position;
    final pos = _positionReEn.firstMatch(lower.substring(cursor));
    if (pos != null) {
      final word = pos.namedGroup('pos');
      if (word != null) {
        position = (word == 'center' || word == 'centre') ? 'middle' : word;
      } else {
        final lineToken = pos.namedGroup('line')!;
        final line =
            int.tryParse(lineToken) ?? EnglishNumberParser.parse(lineToken);
        position = line != null ? 'Line $line' : null;
      }
      if (position != null) cursor += pos.end;
    }

    final text = _cleanTextEn(source.substring(cursor));
    return ParsedNote(
      page: page,
      position: position,
      text: text,
      rawTranscript: raw,
    );
  }

  String _cleanTextEn(String s) => s.replaceFirst(_leadingSepReEn, '').trim();
}
