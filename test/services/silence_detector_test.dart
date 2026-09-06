import 'package:booknote/services/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Duration ms(int n) => Duration(milliseconds: n);

  SilenceDetector make() => SilenceDetector(
    speechThresholdDb: -30,
    silence: ms(1200),
    minLength: ms(800),
    noSpeechTimeout: ms(3000),
  );

  test('ohne Sprache: läuft bis zum noSpeechTimeout, dann Stopp', () {
    final d = make();
    expect(d.update(elapsed: ms(1000), db: -55), isFalse);
    expect(d.update(elapsed: ms(2900), db: -55), isFalse);
    expect(d.update(elapsed: ms(3000), db: -55), isTrue);
    expect(d.heardSpeech, isFalse);
  });

  test('stoppt nach Sprache und anschließender Stille', () {
    final d = make();
    expect(d.update(elapsed: ms(200), db: -55), isFalse); // Stille, noch nichts
    expect(d.update(elapsed: ms(400), db: -18), isFalse); // Sprache
    expect(d.heardSpeech, isTrue);
    expect(d.update(elapsed: ms(600), db: -18), isFalse); // Sprache
    expect(d.update(elapsed: ms(1000), db: -50), isFalse); // Stille beginnt
    expect(d.update(elapsed: ms(1800), db: -50), isFalse); // 0,8 s still
    expect(d.update(elapsed: ms(2250), db: -50), isTrue); // 1,25 s → Stopp
  });

  test('neue Sprache setzt das Stille-Fenster zurück', () {
    final d = make();
    d.update(elapsed: ms(400), db: -20); // Sprache
    d.update(elapsed: ms(700), db: -50); // Stille beginnt
    d.update(elapsed: ms(1500), db: -50); // fast lang genug
    expect(d.update(elapsed: ms(1700), db: -15), isFalse); // wieder Sprache
    expect(d.update(elapsed: ms(2400), db: -50), isFalse); // Stille beginnt neu
    expect(d.update(elapsed: ms(3100), db: -50), isFalse); // erst 0,7 s still
    expect(d.update(elapsed: ms(3700), db: -50), isTrue); // 1,3 s still → Stopp
  });

  test('lautes Reden nach noSpeechTimeout verhindert den Abbruch', () {
    final d = make();
    expect(d.update(elapsed: ms(2900), db: -10), isFalse); // spät, aber Sprache
    expect(
      d.update(elapsed: ms(3100), db: -10),
      isFalse,
    ); // kein noSpeech-Stopp
    expect(d.update(elapsed: ms(3300), db: -50), isFalse); // Stille beginnt
    expect(d.update(elapsed: ms(4700), db: -50), isTrue); // 1,4 s still → Stopp
  });

  test('vor minLength wird nie automatisch gestoppt', () {
    final d = SilenceDetector(
      speechThresholdDb: -30,
      silence: ms(200),
      minLength: ms(2000),
      noSpeechTimeout: ms(9000),
    );
    d.update(elapsed: ms(100), db: -10); // sehr früh Sprache
    expect(d.update(elapsed: ms(500), db: -55), isFalse); // still, < minLength
    expect(d.update(elapsed: ms(1900), db: -55), isFalse);
    expect(d.update(elapsed: ms(2100), db: -55), isTrue);
  });

  test('reset() vergisst erkannte Sprache', () {
    final d = make();
    d.update(elapsed: ms(400), db: -10);
    expect(d.heardSpeech, isTrue);
    d.reset();
    expect(d.heardSpeech, isFalse);
  });
}
