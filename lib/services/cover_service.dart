/// Ein Suchtreffer bei der Cover-/Metadaten-Suche.
class CoverCandidate {
  const CoverCandidate({
    required this.title,
    this.author,
    this.coverUrl,
    required this.provider,
  });

  final String title;

  /// Autor(en), bereits als ein String zusammengefasst.
  final String? author;

  /// `null`, wenn der Treffer kein Bild hat (Titel/Autor trotzdem nützlich).
  final String? coverUrl;

  /// Name der Quelle, z.B. "Google Books" – für die Anzeige.
  final String provider;

  @override
  String toString() =>
      'CoverCandidate($provider: "$title", $author, $coverUrl)';
}

class CoverSearchException implements Exception {
  const CoverSearchException(this.message, [this.cause]);
  final String message;
  final Object? cause;

  @override
  String toString() => 'CoverSearchException: $message';
}

/// Sucht Cover und Metadaten zu einem Buchtitel.
///
/// Stufe 1: Google Books mit Open Library als Fallback (siehe
/// [FallbackCoverService]). Später andockbar: „Cover fotografieren + OCR"
/// als weitere Implementierung, ohne dass der Anlege-Flow sich ändert.
abstract class CoverService {
  /// Liefert bis zu ~10 Treffer, beste zuerst. Leere Liste = nichts gefunden.
  /// Wirft [CoverSearchException] bei Netzwerk-/API-Fehlern.
  Future<List<CoverCandidate>> search(String query);
}

/// Fragt [primary]; wenn das leer bleibt **oder fehlschlägt**, [fallback].
/// Schlagen beide fehl, wird der Fehler der Primärquelle geworfen.
class FallbackCoverService implements CoverService {
  const FallbackCoverService({required this.primary, required this.fallback});

  final CoverService primary;
  final CoverService fallback;

  @override
  Future<List<CoverCandidate>> search(String query) async {
    CoverSearchException? primaryError;
    try {
      final result = await primary.search(query);
      if (result.isNotEmpty) return result;
    } on CoverSearchException catch (e) {
      primaryError = e;
    }
    try {
      return await fallback.search(query);
    } on CoverSearchException {
      if (primaryError != null) throw primaryError;
      rethrow;
    }
  }
}
