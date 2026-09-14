import 'dart:async';

import 'package:uuid/uuid.dart';

import '../models/models.dart';
import 'book_repository.dart';
import 'note_repository.dart';
import 'repository_exceptions.dart';
import 'watch_stream.dart';

/// Gemeinsamer Zustand der In-Memory-Implementierung, damit
/// `BookRepository.delete` die Notizen mitlöschen kann.
///
/// Dient Tests und als Referenz dafür, wie das Interface gemeint ist.
/// Nicht für den produktiven Einsatz.
class InMemoryStore {
  InMemoryStore({Uuid? uuid, DateTime Function()? clock})
    : _uuid = uuid ?? const Uuid(),
      _clock = clock ?? DateTime.now;

  final Uuid _uuid;
  final DateTime Function() _clock;

  final Map<String, Book> books = {};
  final Map<String, Note> notes = {};

  /// Grabsteine gelöschter Einträge (für Parität mit SQLite, s. SYNC_DESIGN.md).
  final Map<String, Tombstone> tombstones = {};

  void addTombstone(String id, TombstoneEntityType type) =>
      tombstones[id] = Tombstone(entityId: id, type: type, deletedAt: now());

  final _booksChanged = StreamController<void>.broadcast();
  final _notesChanged = StreamController<void>.broadcast();

  String newId() => _uuid.v4();
  DateTime now() => _clock();

  void notifyBooks() => _booksChanged.add(null);
  void notifyNotes() => _notesChanged.add(null);

  Stream<void> get onBooksChanged => _booksChanged.stream;
  Stream<void> get onNotesChanged => _notesChanged.stream;

  Future<void> dispose() async {
    await _booksChanged.close();
    await _notesChanged.close();
  }
}

class InMemoryBookRepository implements BookRepository {
  InMemoryBookRepository(this._store);

  final InMemoryStore _store;

  List<Book> _sorted() {
    final list = _store.books.values.toList();
    list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return list;
  }

  @override
  Future<List<Book>> getAll() async => _sorted();

  @override
  Future<Book?> getById(String id) async => _store.books[id];

  @override
  Future<Book> create({
    required String title,
    String? author,
    String? coverUrl,
    AppLanguage language = AppLanguage.german,
  }) async {
    final now = _store.now();
    final book = Book(
      id: _store.newId(),
      title: title,
      author: author,
      coverUrl: coverUrl,
      language: language,
      createdAt: now,
      updatedAt: now,
    );
    _store.books[book.id] = book;
    _store.notifyBooks();
    return book;
  }

  @override
  Future<void> update(Book book) async {
    final existing = _store.books[book.id];
    if (existing == null) throw EntityNotFoundException('Book', book.id);
    _store.books[book.id] = existing.copyWith(
      title: book.title,
      author: book.author,
      clearAuthor: book.author == null,
      coverUrl: book.coverUrl,
      clearCoverUrl: book.coverUrl == null,
      updatedAt: _store.now(),
    );
    _store.notifyBooks();
  }

  @override
  Future<void> delete(String id) async {
    if (_store.books.remove(id) == null) {
      throw EntityNotFoundException('Book', id);
    }
    final noteIds = _store.notes.values
        .where((n) => n.sourceId == id)
        .map((n) => n.id)
        .toList();
    _store.notes.removeWhere((_, n) => n.sourceId == id);
    _store.addTombstone(id, TombstoneEntityType.source);
    for (final noteId in noteIds) {
      _store.addTombstone(noteId, TombstoneEntityType.note);
    }
    _store.notifyBooks();
    _store.notifyNotes();
  }

  @override
  Stream<List<Book>> watchAll() => watchStream(_store.onBooksChanged, _sorted);
}

class InMemoryNoteRepository implements NoteRepository {
  InMemoryNoteRepository(this._store);

  final InMemoryStore _store;

  List<Note> _forSource(String sourceId, NoteSort sort) => sortNotes(
    _store.notes.values.where((n) => n.sourceId == sourceId).toList(),
    sort,
  );

  @override
  Future<List<Note>> getBySource(
    String sourceId, {
    NoteSort sort = NoteSort.createdAt,
  }) async => _forSource(sourceId, sort);

  @override
  Future<Note?> getById(String id) async => _store.notes[id];

  @override
  Future<int> countBySource(String sourceId) async =>
      _store.notes.values.where((n) => n.sourceId == sourceId).length;

  Map<String, int> _counts() {
    final m = <String, int>{};
    for (final n in _store.notes.values) {
      m[n.sourceId] = (m[n.sourceId] ?? 0) + 1;
    }
    return m;
  }

  @override
  Stream<Map<String, int>> watchCounts() =>
      watchStream(_store.onNotesChanged, _counts);

  @override
  Future<Note> create({
    required String sourceId,
    String? page,
    String? position,
    required String text,
    required String rawTranscript,
    AppLanguage language = AppLanguage.german,
  }) async {
    if (!_store.books.containsKey(sourceId)) {
      throw EntityNotFoundException('Source', sourceId);
    }
    final now = _store.now();
    final note = Note(
      id: _store.newId(),
      sourceId: sourceId,
      page: page,
      position: position,
      text: text,
      rawTranscript: rawTranscript,
      language: language,
      createdAt: now,
      updatedAt: now,
    );
    _store.notes[note.id] = note;
    _store.notifyNotes();
    return note;
  }

  @override
  Future<void> update(Note note) async {
    final existing = _store.notes[note.id];
    if (existing == null) throw EntityNotFoundException('Note', note.id);
    _store.notes[note.id] = existing.copyWith(
      page: note.page,
      clearPage: note.page == null,
      position: note.position,
      clearPosition: note.position == null,
      text: note.text,
      updatedAt: _store.now(),
    );
    _store.notifyNotes();
  }

  @override
  Future<void> delete(String id) async {
    if (_store.notes.remove(id) == null) {
      throw EntityNotFoundException('Note', id);
    }
    _store.addTombstone(id, TombstoneEntityType.note);
    _store.notifyNotes();
  }

  @override
  Stream<List<Note>> watchBySource(
    String sourceId, {
    NoteSort sort = NoteSort.createdAt,
  }) => watchStream(_store.onNotesChanged, () => _forSource(sourceId, sort));
}
