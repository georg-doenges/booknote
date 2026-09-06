import 'package:vibration/vibration.dart';

/// Kurze, spürbare Signale für die wichtigen Momente im Aufnahme-Flow.
///
/// Bewusst der Vibrator statt Flutters `HapticFeedback`: letzteres respektiert
/// die System-Touch-Vibration, die auf manchen Geräten (u.a. Samsung) ab Werk
/// aus ist – dann bleibt das Feedback unbemerkt. Fehler/kein Vibrator werden
/// still verschluckt.
abstract final class Haptics {
  static bool? _hasVibrator;

  /// Vom Nutzer abschaltbar (Einstellungen). `main.dart` hält das mit
  /// `AppSettings.hapticsEnabled` synchron.
  static bool enabled = true;

  /// Aufnahme beginnt.
  static Future<void> recordStart() => _buzz(50);

  /// Aufnahme endet.
  static Future<void> recordStop() => _buzz(50);

  /// Notiz gespeichert (kürzer, unaufdringlicher).
  static Future<void> saved() => _buzz(18);

  static Future<void> _buzz(int ms) async {
    if (!enabled) return;
    try {
      _hasVibrator ??= await Vibration.hasVibrator();
      if (_hasVibrator != true) return;
      await Vibration.vibrate(duration: ms);
    } catch (_) {
      // Plattform ohne Vibrator-Unterstützung → ignorieren.
    }
  }
}
