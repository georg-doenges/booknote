import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

/// Dünne Hülle um das `record`-Package: verwaltet Aufnahmedateien im
/// temporären App-Verzeichnis (plattformneutral über `path_provider`).
///
/// Aufnahmen werden als AAC/m4a gespeichert – klein und von Whisper akzeptiert.
class NoteRecorder {
  NoteRecorder({AudioRecorder? recorder})
    : _recorder = recorder ?? AudioRecorder();

  final AudioRecorder _recorder;

  Future<bool> hasPermission() => _recorder.hasPermission();

  Future<bool> get isRecording => _recorder.isRecording();

  /// Startet eine Aufnahme und gibt den Zieldateipfad zurück.
  Future<String> start() async {
    final dir = await getTemporaryDirectory();
    final recDir = Directory(p.join(dir.path, 'recordings'));
    await recDir.create(recursive: true);
    final path = p.join(
      recDir.path,
      'note_${DateTime.now().millisecondsSinceEpoch}.m4a',
    );
    await _recorder.start(
      const RecordConfig(
        encoder: AudioEncoder.aacLc,
        bitRate: 96000,
        sampleRate: 44100,
        numChannels: 1,
      ),
      path: path,
    );
    return path;
  }

  /// Stoppt die Aufnahme, liefert den Dateipfad (oder `null`, wenn keine lief).
  Future<String?> stop() => _recorder.stop();

  Future<void> cancel() => _recorder.cancel();

  /// Löscht eine Aufnahmedatei, wenn sie nicht mehr gebraucht wird.
  static Future<void> discard(String? path) async {
    if (path == null) return;
    final f = File(path);
    if (await f.exists()) await f.delete();
  }

  Future<void> dispose() => _recorder.dispose();
}
