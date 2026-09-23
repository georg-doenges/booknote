// Erzeugt den Katalog für die App aus den Theme-Dateien in `themes/`:
// `themes/index.json` plus je Theme mit Logo eine Vorschau `themes/previews/<id>.png`.
//
// Aufruf im Projektordner (nach jedem neuen/geänderten Theme):
//   dart run tool/build_theme_index.dart
// Danach committen + pushen – die App liest den Katalog direkt aus dem Repo
// (siehe THEMES.md, „Theme-Katalog").
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:path/path.dart' as p;

const indexFormat = 'booknote-theme-index';
const indexFormatVersion = 1;

class ThemeIndexBuild {
  ThemeIndexBuild(this.index, this.previews);

  final Map<String, Object?> index;

  /// Relativer Pfad im Theme-Ordner (`previews/<id>.png`) → PNG-Bytes.
  final Map<String, Uint8List> previews;
}

ThemeIndexBuild buildThemeIndex(Directory themesDir) {
  final files = themesDir.listSync().whereType<File>().where((f) {
    final name = p.basename(f.path);
    return name.endsWith('.json') && name != 'index.json';
  }).toList()..sort((a, b) => a.path.compareTo(b.path));

  final entries = <Map<String, Object?>>[];
  final previews = <String, Uint8List>{};
  for (final f in files) {
    final fileName = p.basename(f.path);
    final Object? decoded = jsonDecode(f.readAsStringSync());
    if (decoded is! Map<String, Object?> ||
        decoded['format'] != 'booknote-theme') {
      throw FormatException('$fileName: keine Booknote-Theme-Datei.');
    }
    final id = decoded['id'];
    if (id is! String || !RegExp(r'^[a-z0-9_]+$').hasMatch(id)) {
      throw FormatException(
        '$fileName: "id" fehlt oder ist ungültig (erlaubt: a-z, 0-9, _).',
      );
    }
    if (p.basenameWithoutExtension(fileName) != id) {
      throw FormatException('$fileName: Dateiname muss "$id.json" lauten.');
    }
    final name = (decoded['name'] as String?)?.trim() ?? '';
    if (name.isEmpty) throw FormatException('$fileName: "name" fehlt.');

    final revision = decoded['revision'];
    final description = (decoded['description'] as String?)?.trim() ?? '';
    final colors =
        (decoded['colors'] as Map?)?.cast<String, Object?>() ?? const {};
    final surface = colors['surface'];
    final primary = colors['primary'] ?? decoded['seed'];

    final logo = _decodeDataUri(decoded['logo']);
    if (logo != null) previews['previews/$id.png'] = logo;

    entries.add({
      'id': id,
      'name': name,
      'brightness': decoded['brightness'] == 'light' ? 'light' : 'dark',
      'revision': revision is int && revision >= 1 ? revision : 1,
      'file': fileName,
      'description': ?(description.isEmpty ? null : description),
      'swatch': {'surface': ?surface, 'primary': ?primary},
      'logo': ?(logo == null ? null : 'previews/$id.png'),
    });
  }
  entries.sort(
    (a, b) => (a['name'] as String).toLowerCase().compareTo(
      (b['name'] as String).toLowerCase(),
    ),
  );

  return ThemeIndexBuild({
    'format': indexFormat,
    'formatVersion': indexFormatVersion,
    'themes': entries,
  }, previews);
}

Uint8List? _decodeDataUri(Object? value) {
  if (value is! String || value.isEmpty) return null;
  final comma = value.indexOf(',');
  return base64Decode((comma >= 0 ? value.substring(comma + 1) : value).trim());
}

void main(List<String> args) {
  final dir = Directory(args.isNotEmpty ? args.first : 'themes');
  if (!dir.existsSync()) {
    stderr.writeln(
      'Ordner "${dir.path}" nicht gefunden – im Projektordner starten.',
    );
    exit(1);
  }
  final build = buildThemeIndex(dir);

  final previewsDir = Directory(p.join(dir.path, 'previews'));
  if (previewsDir.existsSync()) previewsDir.deleteSync(recursive: true);
  if (build.previews.isNotEmpty) previewsDir.createSync(recursive: true);
  for (final e in build.previews.entries) {
    File(p.join(dir.path, e.key)).writeAsBytesSync(e.value);
  }

  final json = const JsonEncoder.withIndent('  ').convert(build.index);
  File(p.join(dir.path, 'index.json')).writeAsStringSync('$json\n');
  stdout.writeln(
    '${dir.path}/index.json: ${(build.index['themes'] as List).length} Themes, '
    '${build.previews.length} Vorschauen.',
  );
}
