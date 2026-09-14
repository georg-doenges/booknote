import '../models/app_language.dart';
import '../models/book.dart';

/// Datenzugriff für Bücher.
///
/// Reines CRUD-Interface ohne Storage-Details. Stufe 1 wird durch eine
/// SQLite-Implementierung erfüllt; eine spätere `SupabaseBookRepository`
/// tritt daneben, ohne dass UI oder Services angepasst werden müssen.
///
/// Konventionen:
/// - IDs und Zeitstempel vergibt das Repository (in [create]), nicht der Aufrufer.
/// - [update] und [delete] werfen `EntityNotFoundException`, wenn die ID fehlt.
/// - Alle Listen sind nach `createdAt` absteigend sortiert (neueste zuerst).
abstract class BookRepository {
  /// Alle Bücher, neueste zuerst.
  Future<List<Book>> getAll();

  /// Ein Buch nach ID, `null` wenn nicht vorhanden.
  Future<Book?> getById(String id);

  /// Legt ein neues Buch an und gibt es mit vergebener ID zurück.
  /// [language] ist die Default-Sprache für Aufnahmen zu diesem Buch
  /// (Deutsch, wenn nicht angegeben).
  Future<Book> create({
    required String title,
    String? author,
    String? coverUrl,
    AppLanguage language = AppLanguage.german,
  });

  /// Speichert Titel/Autor/Cover eines bestehenden Buchs. `updatedAt` setzt das
  /// Repository selbst.
  Future<void> update(Book book);

  /// Löscht ein Buch **und alle zugehörigen Notizen**.
  Future<void> delete(String id);

  /// Reaktive Sicht auf [getAll]: liefert sofort den aktuellen Stand und
  /// danach bei jeder Änderung eine neue Liste. Für die Bibliotheks-UI.
  Stream<List<Book>> watchAll();
}
