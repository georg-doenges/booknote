/// Merkzettel „dieser Eintrag wurde gelöscht" – nötig, damit eine Löschung
/// beim Geräte-Abgleich nicht wieder auferstehen kann (siehe `SYNC_DESIGN.md`).
///
/// Eine Löschung ist damit auch nur ein Fakt mit Zeitstempel: Beim Merge
/// gewinnt pro Eintrags-ID der neueste Fakt (lebende Version per `updatedAt`
/// oder Grabstein per [deletedAt]).
class Tombstone {
  const Tombstone({
    required this.entityId,
    required this.type,
    required this.deletedAt,
  });

  /// UUID des gelöschten Eintrags (geräteübergreifend eindeutig).
  final String entityId;

  final TombstoneEntityType type;

  final DateTime deletedAt;

  Tombstone copyWith({DateTime? deletedAt}) => Tombstone(
    entityId: entityId,
    type: type,
    deletedAt: deletedAt ?? this.deletedAt,
  );

  @override
  bool operator ==(Object other) =>
      other is Tombstone &&
      other.entityId == entityId &&
      other.type == type &&
      other.deletedAt == deletedAt;

  @override
  int get hashCode => Object.hash(entityId, type, deletedAt);

  @override
  String toString() => 'Tombstone(${type.dbValue} $entityId @ $deletedAt)';
}

/// Auf welche Tabelle sich ein [Tombstone] bezieht.
enum TombstoneEntityType {
  source('source'),
  note('note');

  const TombstoneEntityType(this.dbValue);

  final String dbValue;

  static TombstoneEntityType fromDbValue(String value) =>
      TombstoneEntityType.values.firstWhere(
        (t) => t.dbValue == value,
        orElse: () => throw ArgumentError.value(
          value,
          'value',
          'Unbekannter TombstoneEntityType',
        ),
      );
}
