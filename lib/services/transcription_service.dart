/// Warum die Transkription fehlgeschlagen ist. Die UI bildet daraus eine
/// freundliche Meldung; das Audio bleibt in jedem Fall erhalten.
enum TranscriptionErrorKind {
  /// Kein API-Key hinterlegt → Nutzer zu den Einstellungen schicken.
  missingApiKey,

  /// Key abgelehnt (401/403).
  unauthorized,

  /// Kein Netz, Timeout, DNS.
  network,

  /// Kontingent/Rate-Limit (429).
  rateLimited,

  /// Audiodatei fehlt, ist leer oder wird abgelehnt (400/413).
  invalidAudio,

  /// Alles andere (5xx, unerwartete Antwort).
  server,
}

class TranscriptionException implements Exception {
  const TranscriptionException(
    this.kind,
    this.message, {
    this.status,
    this.cause,
  });

  final TranscriptionErrorKind kind;

  /// Technische Beschreibung für Logs (Englisch). Angezeigt wird sie nicht: Die
  /// UI formuliert die Meldung aus [kind] in der Sprache der App
  /// (`transcriptionErrorText`).
  final String message;

  /// HTTP-Status bei [TranscriptionErrorKind.server], sonst `null`.
  final int? status;

  /// Ursache, z.B. die Fehlermeldung der API – wird zusätzlich angezeigt.
  final Object? cause;

  @override
  String toString() => 'TranscriptionException(${kind.name}): $message';
}

/// Sprache → Text. Stufe 1: OpenAI Whisper (`WhisperService`).
/// Später möglich: lokales/on-device Whisper hinter demselben Interface.
abstract class TranscriptionService {
  /// Transkribiert die Audiodatei unter [audioPath] und liefert den Rohtext.
  Future<String> transcribe(String audioPath, {String language = 'de'});
}
