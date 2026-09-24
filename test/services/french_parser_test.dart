import 'package:booknote/models/models.dart';
import 'package:booknote/services/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('FrenchNumberParser', () {
    final cases = <String, int>{
      'zéro': 0,
      'un': 1,
      'une': 1,
      'douze': 12,
      'seize': 16,
      'dix-sept': 17,
      'dix-neuf': 19,
      'vingt': 20,
      'vingt et un': 21,
      'vingt-deux': 22,
      'trente': 30,
      'trente et un': 31,
      'quarante-sept': 47,
      'quarante sept': 47,
      'cinquante-trois': 53,
      'soixante': 60,
      'soixante et un': 61,
      'soixante-dix': 70,
      'soixante et onze': 71,
      'soixante-dix-sept': 77,
      'quatre-vingts': 80,
      'quatre-vingt-un': 81,
      'quatre-vingt-quatre': 84,
      'quatre-vingt-dix': 90,
      'quatre-vingt-dix-sept': 97,
      'quatre-vingt-dix-neuf': 99,
      // Belgisch/Schweizerisch
      'septante': 70,
      'septante-cinq': 75,
      'huitante': 80,
      'octante-deux': 82,
      'nonante': 90,
      'nonante-neuf': 99,
      'cent': 100,
      'cent un': 101,
      'cent vingt': 120,
      'deux cents': 200,
      'deux cent trois': 203,
      'trois cent douze': 312,
      'neuf cent quatre-vingt-dix-neuf': 999,
      'mille': 1000,
      'deux mille un': 2001,
      'mille deux cent quarante-sept': 1247,
      'Quarante-Sept': 47,
    };
    cases.forEach((word, n) {
      test('$word → $n', () => expect(FrenchNumberParser.parse(word), n));
    });

    for (final bad in [
      'page',
      'quarante-quarante',
      'un-dix',
      '',
      'xyz',
      'et',
    ]) {
      test(
        '"$bad" ist keine Zahl',
        () => expect(FrenchNumberParser.parse(bad), isNull),
      );
    }
  });

  group('NoteParser (Französisch)', () {
    const p = NoteParser();

    void check(
      String raw, {
      String? page,
      String? position,
      required String text,
    }) {
      test(raw, () {
        final r = p.parse(raw, language: AppLanguage.french);
        expect(r.page, page, reason: 'page');
        expect(r.position, position, reason: 'position');
        expect(r.text, text, reason: 'text');
        expect(r.rawTranscript, raw);
      });
    }

    check(
      'Page 47 en haut, ici l’auteur soutient que…',
      page: '47',
      position: 'haut',
      text: 'ici l’auteur soutient que…',
    );
    check(
      'Page 12, une belle métaphore sur la mer',
      page: '12',
      text: 'une belle métaphore sur la mer',
    );

    // Varianten, wie Whisper sie liefert
    check(
      'Page 47. En haut. Voici quelque chose.',
      page: '47',
      position: 'haut',
      text: 'Voici quelque chose.',
    );
    check(
      'Page 47, en bas : citation.',
      page: '47',
      position: 'bas',
      text: 'citation.',
    );
    check(
      'Page 3, ligne 10, la phrase',
      page: '3',
      position: 'Ligne 10',
      text: 'la phrase',
    );
    check(
      'Page quarante-sept en haut, texte',
      page: '47',
      position: 'haut',
      text: 'texte',
    );
    check('Page quatre-vingt-dix-sept, texte', page: '97', text: 'texte');
    check('Page nonante-neuf, texte', page: '99', text: 'texte');
    check(
      'À la page 5 il y a quelque chose',
      page: '5',
      text: 'il y a quelque chose',
    );
    check('A la page 5, court', page: '5', text: 'court');
    check('P. 9, court', page: '9', text: 'court');

    // Position: mehrere Schreibweisen
    check(
      'Page 9 au milieu, citation',
      page: '9',
      position: 'milieu',
      text: 'citation',
    );
    check(
      'Page 9 milieu, citation',
      page: '9',
      position: 'milieu',
      text: 'citation',
    );
    check(
      'Page 9 au centre, citation',
      page: '9',
      position: 'milieu',
      text: 'citation',
    );
    check(
      'Page 9 tout en haut, citation',
      page: '9',
      position: 'haut',
      text: 'citation',
    );
    check('Page 9 bas, citation', page: '9', position: 'bas', text: 'citation');

    // et suivantes / sq. / sqq. → f. / ff.
    check(
      'Page 88 et suivantes, l’intrigue se corse',
      page: '88ff.',
      text: 'l’intrigue se corse',
    );
    check('Page 88 et suivante, la suite', page: '88f.', text: 'la suite');
    check('Page 88 sqq., la suite', page: '88ff.', text: 'la suite');
    check('Page 88 sq., la suite', page: '88f.', text: 'la suite');
    check(
      'Page 88 et suivantes en bas, fin',
      page: '88ff.',
      position: 'bas',
      text: 'fin',
    );

    // Wortgrenzen: Positions-/Folgewörter nur als ganze Wörter
    check(
      'Page 3 bassesse du personnage',
      page: '3',
      text: 'bassesse du personnage',
    );
    check(
      'Page 3 hauteur de la falaise',
      page: '3',
      text: 'hauteur de la falaise',
    );
    check('Page 3 faut le noter', page: '3', text: 'faut le noter');
    check('Page 3 centrale nucléaire', page: '3', text: 'centrale nucléaire');

    // Kein Seitenpräfix → alles ist Text
    check('Juste une pensée.', text: 'Juste une pensée.');
    check('Page bleue, hm', text: 'Page bleue, hm');
    check('Sur la page il n’y a rien', text: 'Sur la page il n’y a rien');
    check('  , bonjour ', text: 'bonjour');
    check('', text: '');
    check(
      'L’auteur dit à la page 5 quelque chose',
      text: 'L’auteur dit à la page 5 quelque chose',
    );
  });
}
