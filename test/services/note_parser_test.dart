import 'package:booknote/models/app_language.dart';
import 'package:booknote/services/english_number_parser.dart';
import 'package:booknote/services/german_number_parser.dart';
import 'package:booknote/services/note_parser.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('GermanNumberParser', () {
    final cases = <String, int>{
      'null': 0,
      'eins': 1,
      'zwölf': 12,
      'zwanzig': 20,
      'einundzwanzig': 21,
      'siebenundvierzig': 47,
      'dreißig': 30,
      'dreissig': 30,
      'hundert': 100,
      'einhundert': 100,
      'hundertzwei': 102,
      'dreihundertsiebenundvierzig': 347,
      'neunhundertneunundneunzig': 999,
      'tausend': 1000,
      'zweitausendeins': 2001,
      'zwölfhundert': 1200,
      'Siebenundvierzig': 47,
      'sieben und vierzig': 47,
    };
    cases.forEach((word, n) {
      test('$word → $n', () => expect(GermanNumberParser.parse(word), n));
    });

    for (final bad in ['seite', 'undvierzig', 'zehnundzwanzig', '', 'xyz']) {
      test(
        '"$bad" ist keine Zahl',
        () => expect(GermanNumberParser.parse(bad), isNull),
      );
    }
  });

  group('EnglishNumberParser', () {
    final cases = <String, int>{
      'zero': 0,
      'one': 1,
      'twelve': 12,
      'twenty': 20,
      'twenty-one': 21,
      'forty-seven': 47,
      'forty seven': 47,
      'thirty': 30,
      'hundred': 100,
      'one-hundred': 100,
      'hundred-two': 102,
      'three-hundred-and-forty-seven': 347,
      'nine-hundred-and-ninety-nine': 999,
      'thousand': 1000,
      'two-thousand-one': 2001,
      'two-thousand-and-one': 2001,
      'Forty-Seven': 47,
    };
    cases.forEach((word, n) {
      test('$word → $n', () => expect(EnglishNumberParser.parse(word), n));
    });

    for (final bad in ['page', 'andseven', 'tenty', '', 'xyz']) {
      test(
        '"$bad" ist keine Zahl',
        () => expect(EnglishNumberParser.parse(bad), isNull),
      );
    }
  });

  group('NoteParser', () {
    const p = NoteParser();

    void check(
      String raw, {
      String? page,
      String? position,
      required String text,
    }) {
      test(raw, () {
        final r = p.parse(raw);
        expect(r.page, page, reason: 'page');
        expect(r.position, position, reason: 'position');
        expect(r.text, text, reason: 'text');
        expect(r.rawTranscript, raw);
      });
    }

    // Beispiele aus PROJECT.md
    check(
      'Seite 47 oben, hier argumentiert der Autor dass…',
      page: '47',
      position: 'oben',
      text: 'hier argumentiert der Autor dass…',
    );
    check(
      'Seite 12, schöne Metapher über das Meer',
      page: '12',
      text: 'schöne Metapher über das Meer',
    );
    check(
      'Seite 88 folgende Mitte, der Konflikt eskaliert',
      page: '88f.',
      position: 'mitte',
      text: 'der Konflikt eskaliert',
    );

    // Varianten, wie Whisper sie liefert
    check(
      'Seite 47. Oben. Hier steht etwas.',
      page: '47',
      position: 'oben',
      text: 'Hier steht etwas.',
    );
    check(
      'Seite 47, unten: Zitat.',
      page: '47',
      position: 'unten',
      text: 'Zitat.',
    );
    check(
      'seite 3 zeile 10 der Satz',
      page: '3',
      position: 'Zeile 10',
      text: 'der Satz',
    );
    check(
      'Seite 3, Zeile zehn, der Satz',
      page: '3',
      position: 'Zeile 10',
      text: 'der Satz',
    );
    check(
      'Seite siebenundvierzig oben, Text',
      page: '47',
      position: 'oben',
      text: 'Text',
    );
    check('Seite dreihundertzwölf, Text', page: '312', text: 'Text');
    check('Auf Seite 5 steht etwas', page: '5', text: 'steht etwas');
    check('S. 9, kurz', page: '9', text: 'kurz');

    // folgende / f. / ff.
    check('Seite 88f. der Text', page: '88f.', text: 'der Text');
    check('Seite 88 f. der Text', page: '88f.', text: 'der Text');
    check('Seite 88 ff. der Text', page: '88ff.', text: 'der Text');
    check('Seite 88ff der Text', page: '88ff.', text: 'der Text');
    check('Seite 88 und folgende, der Text', page: '88f.', text: 'der Text');
    check('Seite 88 fortfolgende der Text', page: '88ff.', text: 'der Text');
    check('Seite 88 folgenden Seiten', page: '88f.', text: 'Seiten');

    // "f" darf kein Wortanfang sein
    check('Seite 3 fängt gut an', page: '3', text: 'fängt gut an');
    check('Seite 3 Mittelalter', page: '3', text: 'Mittelalter');
    check('Seite 3 obendrein toll', page: '3', text: 'obendrein toll');

    // Nur Präfix, kein Text
    check('Seite 4 oben', page: '4', position: 'oben', text: '');
    check('Seite 4', page: '4', text: '');

    // Keine Seitenangabe → alles ist Text
    check('Das ist nur ein Gedanke.', text: 'Das ist nur ein Gedanke.');
    check('Seite blau, hm', text: 'Seite blau, hm');
    check('Auf der Seite steht nichts', text: 'Auf der Seite steht nichts');
    check('  , hallo ', text: 'hallo');
    check('', text: '');

    // Mittig → mitte
    check('Seite 7 mittig, x', page: '7', position: 'mitte', text: 'x');

    // Seitenangabe nicht am Anfang → kein Präfix
    check(
      'Der Autor sagt auf Seite 5 etwas',
      text: 'Der Autor sagt auf Seite 5 etwas',
    );
  });

  group('NoteParser (Englisch)', () {
    const p = NoteParser();

    void check(
      String raw, {
      String? page,
      String? position,
      required String text,
    }) {
      test(raw, () {
        final r = p.parse(raw, language: AppLanguage.english);
        expect(r.page, page, reason: 'page');
        expect(r.position, position, reason: 'position');
        expect(r.text, text, reason: 'text');
        expect(r.rawTranscript, raw);
      });
    }

    check(
      'Page 47 top, the author argues that…',
      page: '47',
      position: 'top',
      text: 'the author argues that…',
    );
    check(
      'Page 12, a nice metaphor about the sea',
      page: '12',
      text: 'a nice metaphor about the sea',
    );

    // Varianten, wie Whisper sie liefert
    check(
      'Page 47. Top. Here is something.',
      page: '47',
      position: 'top',
      text: 'Here is something.',
    );
    check(
      'Page 47, bottom: quote.',
      page: '47',
      position: 'bottom',
      text: 'quote.',
    );
    check(
      'Page 3, line 10, the sentence',
      page: '3',
      position: 'Line 10',
      text: 'the sentence',
    );
    check(
      'Page forty-seven top, text',
      page: '47',
      position: 'top',
      text: 'text',
    );
    check('Page three-hundred-twelve, text', page: '312', text: 'text');
    check(
      'On page 5 there is something',
      page: '5',
      text: 'there is something',
    );
    check('P. 9, short', page: '9', text: 'short');

    // center/centre → middle
    check('Page 9 center, quote', page: '9', position: 'middle', text: 'quote');
    check('Page 9 centre, quote', page: '9', position: 'middle', text: 'quote');

    // following / ff. – wie im Deutschen gibt es f./ff. auch im englischen
    // Zitierstil, aber gesprochen sagt man "following"/"onwards", nicht die
    // Buchstaben "f"/"ff" (anders als beim deutschen "ff").
    check(
      'Page 88 and following, the plot thickens',
      page: '88ff.',
      text: 'the plot thickens',
    );
    check('Page 88 following page, more text', page: '88f.', text: 'more text');
    check('Page 88 onwards, keep going', page: '88ff.', text: 'keep going');
    check(
      'Page 88 following, the conflict escalates',
      page: '88ff.',
      text: 'the conflict escalates',
    );

    // Wortgrenzen: "bottom"/"top" dürfen kein Wortanfang sein
    check('Page 3 bottomless pit', page: '3', text: 'bottomless pit');
    check('Page 3 topple over', page: '3', text: 'topple over');

    // Nur Präfix, kein Text
    check('Page 4 top', page: '4', position: 'top', text: '');
    check('Page 4', page: '4', text: '');

    // Keine Seitenangabe → alles ist Text
    check('That is just a thought.', text: 'That is just a thought.');
    check('Page blue, hmm', text: 'Page blue, hmm');
    check('On the page it says nothing', text: 'On the page it says nothing');
    check('  , hello ', text: 'hello');
    check('', text: '');

    // Seitenangabe nicht am Anfang → kein Präfix
    check(
      'The author says on page 5 something',
      text: 'The author says on page 5 something',
    );
  });
}
