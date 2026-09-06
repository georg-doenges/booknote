import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../models/models.dart';
import '../repositories/repositories.dart';
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

/// Abgleich durchgeführt. Zahlen für die Rückmeldung an den Nutzer.
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

/// Kümmert sich um Sichern (Datei schreiben + teilen) und Abgleichen (Datei
/// wählen, mergen, DB ersetzen). Ohne Google Drive – der Nutzer legt die Datei
/// selbst in Drive/Files ab bzw. wählt sie dort aus.
class LibrarySync {
  LibrarySync(this._archive, {DateTime Function()? clock})
    : _clock = clock ?? DateTime.now;

  final LibraryArchive _archive;
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

  /// Lässt den Nutzer eine Bibliotheksdatei wählen, führt den Merge aus und
  /// ersetzt den lokalen Stand. Wirft [LibraryFileException] bei kaputter Datei.
  Future<LibrarySyncResult> pickAndMerge() async {
    final picked = await FilePicker.platform.pickFiles(
      dialogTitle: 'Bibliotheksdatei wählen',
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
    final merged = mergeLibrary(local, incoming, now: _clock());
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
