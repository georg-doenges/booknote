import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import 'exporter.dart';

/// Schreibt ein [ExportResult] ins Temp-Verzeichnis und öffnet den
/// System-Share-Sheet (Android + iOS via `share_plus`).
///
/// Gibt `true` zurück, wenn der Nutzer ein Ziel gewählt hat.
Future<bool> shareExport(ExportResult result) async {
  final dir = await getTemporaryDirectory();
  final exportDir = Directory(p.join(dir.path, 'exports'));
  await exportDir.create(recursive: true);
  final file = File(p.join(exportDir.path, result.fileName));
  await file.writeAsString(result.content, flush: true);

  final share = await SharePlus.instance.share(
    ShareParams(
      files: [XFile(file.path, mimeType: result.mimeType)],
      fileNameOverrides: [result.fileName],
      subject: result.fileName,
    ),
  );
  return share.status == ShareResultStatus.success;
}

/// Öffnet den „Speichern unter"-Dialog des Systems und legt die Datei dort ab
/// (auch Google Drive, Dateien-App usw.). `true`, wenn gespeichert wurde.
Future<bool> saveExportToFile(ExportResult result) async {
  final path = await FilePicker.platform.saveFile(
    dialogTitle: 'Speichern unter',
    fileName: result.fileName,
    type: FileType.custom,
    allowedExtensions: [result.fileName.split('.').last],
    bytes: utf8.encode(result.content),
  );
  return path != null;
}
