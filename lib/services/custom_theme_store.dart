import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../models/models.dart';

/// Hält die installierten Custom-Themes. Alle liegen als JSON-Datei im
/// App-Dokumentenverzeichnis (`<docs>/themes/<id>.json`), sind gleichwertig und
/// löschbar. Sie kommen aus dem Theme-Katalog (`ThemeCatalogService`) oder per
/// Datei-Import; die App bringt selbst keine mit. Siehe THEMES.md.
class CustomThemeStore extends ChangeNotifier {
  CustomThemeStore({Future<Directory> Function()? directory})
    : _directory = directory ?? _documentsThemesDir;

  static const _dirName = 'themes';

  final Future<Directory> Function() _directory;

  List<CustomTheme> _themes = const [];
  List<CustomTheme> get themes => _themes;

  CustomTheme? byId(String? id) {
    if (id == null) return null;
    for (final t in _themes) {
      if (t.id == id) return t;
    }
    return null;
  }

  /// Liest alle Theme-Dateien neu ein (kaputte werden übersprungen).
  Future<void> refresh() async {
    final dir = await _directory();
    await dir.create(recursive: true);

    final byId = <String, CustomTheme>{};
    final files =
        dir
            .listSync()
            .whereType<File>()
            .where((f) => f.path.toLowerCase().endsWith('.json'))
            .toList()
          ..sort((a, b) => a.path.compareTo(b.path));
    for (final f in files) {
      try {
        final t = CustomTheme.parse(await f.readAsString());
        byId[t.id] = t;
      } catch (e) {
        debugPrint('Theme ${f.path} kaputt: $e');
      }
    }

    _themes = byId.values.toList();
    notifyListeners();
  }

  /// Installiert eine Theme-Datei. Wirft [CustomThemeException] bei kaputter
  /// Datei. Ein vorhandenes Theme mit gleicher ID wird überschrieben.
  Future<CustomTheme> import(Uint8List bytes) async {
    final String text;
    try {
      text = utf8.decode(bytes);
    } on FormatException {
      throw const CustomThemeException('Die Datei ist kein gültiges JSON.');
    }
    final theme = CustomTheme.parse(text);
    final dir = await _directory();
    await dir.create(recursive: true);
    await File(p.join(dir.path, '${theme.id}.json')).writeAsBytes(bytes);
    await refresh();
    return theme;
  }

  Future<void> delete(String id) async {
    final file = File(p.join((await _directory()).path, '$id.json'));
    if (file.existsSync()) await file.delete();
    await refresh();
  }

  static Future<Directory> _documentsThemesDir() async => Directory(
    p.join((await getApplicationDocumentsDirectory()).path, _dirName),
  );
}
