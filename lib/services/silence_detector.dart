/// Entscheidet anhand von dBFS-Pegeln, wann eine **kurze** Sprachaufnahme von
/// selbst enden soll: nach einer Weile Stille (wenn gesprochen wurde) oder wenn
/// gar nichts kommt. Gedacht für die Titel-Eingabe per Sprache (kein Diktat).
///
/// Reine Logik ohne Timer/IO, damit sie testbar ist. Der Aufrufer speist bei
/// jedem Pegel-Tick [update] mit der bisherigen Aufnahmedauer und dem aktuellen
/// Pegel; sobald `true` zurückkommt, sollte die Aufnahme gestoppt werden.
class SilenceDetector {
  SilenceDetector({
    this.speechThresholdDb = -30,
    this.silence = const Duration(milliseconds: 1300),
    this.minLength = const Duration(milliseconds: 900),
    this.noSpeechTimeout = const Duration(seconds: 3),
  });

  /// Pegel (dBFS, negativ) ab dem als „es wird gesprochen" gilt. Höher =
  /// unempfindlicher gegen Raumgeräusche.
  final double speechThresholdDb;

  /// So lange muss es nach der letzten Sprache still sein.
  final Duration silence;

  /// Vor Ablauf dieser Aufnahmedauer wird nie automatisch gestoppt.
  final Duration minLength;

  /// Wurde bis hierhin nichts gesagt, wird abgebrochen.
  final Duration noSpeechTimeout;

  bool _heardSpeech = false;
  Duration? _quietSince;

  bool get heardSpeech => _heardSpeech;

  /// [elapsed] = bisherige Aufnahmedauer, [db] = aktueller Pegel (dBFS).
  bool update({required Duration elapsed, required double db}) {
    if (db >= speechThresholdDb) {
      _heardSpeech = true;
      _quietSince = null;
      return false;
    }
    if (!_heardSpeech) return elapsed >= noSpeechTimeout;
    _quietSince ??= elapsed;
    return elapsed >= minLength && elapsed - _quietSince! >= silence;
  }

  void reset() {
    _heardSpeech = false;
    _quietSince = null;
  }
}
