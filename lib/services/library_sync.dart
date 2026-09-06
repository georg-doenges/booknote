import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../models/models.dart';
import '../repositories/repositories.dart';
import 'app_settings.dart';
import 'library_merge.dart';

/// Dateiname der Bibliotheksdatei (siehe `SYNC_DESIGN.md`).
const kLibraryFileName = 'booknote-library.json';

/// Ergebnis eines Abgleichs.
sealed class LibrarySyncResult {
  const LibrarySyncResult();
}

/// Nutzer hat die Dateiauswahl abgebrochen.
class LibrarySyncCancelled extends LibrarySyncResult {
  const LibrarySyncCancelled();
}

/// Datei und App wurden zusammengeführt (Standardfall).
class LibrarySyncMerged extends LibrarySyncResult {
  const LibrarySyncMerged({
    required this.booksBefore,
    required this.booksAfter,
    required this.notesBefore,
    required this.notesAfter,
    required this.merged,
  });

  final int booksBefore;
  final int booksAfter;
  final int notesBefore;
  final int notesAfter;

  /// Der zusammengeführte Stand – zum Zurückschreiben in die Datei.
  final LibrarySnapshot merged;

  int get booksAdded => booksAfter - booksBefore;
  int get notesAdded => notesAfter - notesBefore;
}

/// Die Datei war als **Master** markiert – der lokale Stand wurde komplett
/// daran angeglichen (kein Merge).
class LibrarySyncAdoptedMaster extends LibrarySyncResult {
  const LibrarySyncAdoptedMaster({
    required this.books,
    required this.notes,
    required this.masterGeneration,
  });

  final int books;
  final int notes;
  final int masterGeneration;
}

/// Kümmert sich um Sichern (Datei schreiben + teilen), Abgleichen (Datei
/// wählen, mergen bzw. Master übernehmen, DB ersetzen) und „Als Master
/// setzen". Ohne Google Drive – der Nutzer legt die Datei selbst ab bzw. wählt
/// sie aus.
class LibrarySync {
  LibrarySync(this._archive, this._settings, {DateTime Function()? clock})
    : _clock = clock ?? DateTime.now;

  final LibraryArchive _archive;
  final AppSettings _settings;
  final DateTime Function() _clock;

  /// Schreibt den aktuellen Stand als `booknote-library.json` und öffnet den
  /// Share-Sheet. `true`, wenn der Nutzer ein Ziel gewählt hat.
  Future<bool> save() async {
    final snapshot = await _archive.readSnapshot();
    return _shareSnapshot(snapshot);
  }

  /// Teilt einen bereits gemischten Stand erneut (Button „aktualisierte Datei
  /// sichern" nach einem Abgleich).
  Future<bool> shareSnapshot(LibrarySnapshot snapshot) =>
      _shareSnapshot(snapshot);

  /// Erklärt den lokalen Stand zur Vorlage: `masterGeneration` hochzählen, den
  /// **unveränderten** lokalen Stand als Datei schreiben und teilen. Andere
  /// Geräte übernehmen ihn beim nächsten Abgleich komplett.
  Future<bool> setAsMaster() async {
    final local = await _archive.readSnapshot();
    final nextGen = local.masterGeneration + 1;
    final master = LibrarySnapshot(
      sources: local.sources,
      notes: local.notes,
      tombstones: local.tombstones,
      masterGeneration: nextGen,
    );
    await _archive.replaceWith(master); // hält die neue Generation lokal fest
    await _settings.updateSync(
      _settings.sync.copyWith(lastConsumedMasterGeneration: nextGen),
    );
    return _shareSnapshot(master);
  }

  /// Lässt den Nutzer eine Bibliotheksdatei wählen und gleicht ab: normaler
  /// Merge, oder – wenn die Datei eine neuere Master-Generation trägt –
  /// vollständige Übernahme. Wirft [LibraryFileException] bei kaputter Datei.
  Future<LibrarySyncResult> pickAndMerge() async {
    final picked = await FilePicker.platform.pickFiles(
      dialogTitle: 'Bibliotheksdatei wählen',
      type: FileType.custom,
      allowedExtensions: ['json'],
      withData: true,
    );
    if (picked == null || picked.files.isEmpty) {
      return const LibrarySyncCancelled();
    }
    final file = picked.files.first;
    final text = file.bytes != null
        ? utf8.decode(file.bytes!)
        : await File(file.path!).readAsString();

    final incoming = LibrarySnapshot.parse(text);
    final local = await _archive.readSnapshot();

    // Master-Kurzschluss (SYNC_DESIGN.md §4.1).
    if (incoming.masterGeneration >
        _settings.sync.lastConsumedMasterGeneration) {
      await _archive.replaceWith(incoming);
      await _settings.updateSync(
        _settings.sync.copyWith(
          lastConsumedMasterGeneration: incoming.masterGeneration,
        ),
      );
      return LibrarySyncAdoptedMaster(
        books: incoming.sourceCount,
        notes: incoming.noteCount,
        masterGeneration: incoming.masterGeneration,
      );
    }

    final merged = mergeLibrary(
      local,
      incoming,
      now: _clock(),
      gcEnabled: _settings.sync.tombstoneGcEnabled,
      gcDays: _settings.sync.tombstoneGcDays,
    );
    await _archive.replaceWith(merged);

    return LibrarySyncMerged(
      booksBefore: local.sourceCount,
      booksAfter: merged.sourceCount,
      notesBefore: local.noteCount,
      notesAfter: merged.noteCount,
      merged: merged,
    );
  }

  Future<bool> _shareSnapshot(LibrarySnapshot snapshot) async {
    final dir = await getTemporaryDirectory();
    final exportDir = Directory(p.join(dir.path, 'exports'));
    await exportDir.create(recursive: true);
    final file = File(p.join(exportDir.path, kLibraryFileName));
    await file.writeAsString(snapshot.toJsonString(), flush: true);

    final result = await SharePlus.instance.share(
      ShareParams(
        files: [XFile(file.path, mimeType: 'application/json')],
        fileNameOverrides: [kLibraryFileName],
        subject: kLibraryFileName,
      ),
    );
    return result.status == ShareResultStatus.success;
  }
}
