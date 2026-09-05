/// Art einer Notiz-Quelle.
///
/// Stufe 1 kennt nur [book]. Weitere Typen (z.B. `video`, `notebook`) werden
/// später ergänzt, ohne dass sich das Schema ändert: In der Datenbank wird
/// [dbValue] als `source_type`-Text gespeichert.
enum SourceType {
  book('book');

  const SourceType(this.dbValue);

  /// Wert, der in der Spalte `source_type` gespeichert wird.
  final String dbValue;

  static SourceType fromDbValue(String value) {
    return SourceType.values.firstWhere(
      (t) => t.dbValue == value,
      orElse: () =>
          throw ArgumentError.value(value, 'value', 'Unbekannter SourceType'),
    );
  }
}
