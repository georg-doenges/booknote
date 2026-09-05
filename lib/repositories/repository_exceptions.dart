/// Basisklasse für Fehler aus der Datenzugriffsschicht.
///
/// Implementierungen (SQLite, später Supabase) übersetzen ihre internen
/// Fehler in diese Typen, damit die UI keine Storage-Details kennen muss.
class RepositoryException implements Exception {
  const RepositoryException(this.message, [this.cause]);

  final String message;
  final Object? cause;

  @override
  String toString() =>
      'RepositoryException: $message${cause == null ? '' : ' ($cause)'}';
}

/// Eine Entität mit der angegebenen ID existiert nicht.
class EntityNotFoundException extends RepositoryException {
  EntityNotFoundException(this.entity, this.id)
    : super('$entity mit ID "$id" nicht gefunden');

  final String entity;
  final String id;
}
