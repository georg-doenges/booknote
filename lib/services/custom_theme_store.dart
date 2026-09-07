import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../models/models.dart';

/// Hält die verfügbaren Custom-Themes: mitgelieferte (Assets, nicht löschbar)
/// plus vom Nutzer importierte (im App-Dokumentenverzeichnis). Siehe THEMES.md.
class CustomThemeStore extends ChangeNotifier {
  CustomThemeStore([this._bundled = _bundledAssets]);

  static const _bundledAssets = ['assets/themes/blue_gold.json'];
  static const _dirName = 'themes';

  final List<String> _bundled;

  List<CustomTheme> _themes = const [];
  List<CustomTheme> get themes => _themes;

  CustomTheme? byId(String? id) {
    if (id == null) return null;
    for (final t in _themes) {
      if (t.id == id) return t;
    }
    return null;
  }

  Future<void> refresh() async {
    // Nach ID entdoppeln: mitgelieferte sind kanonisch, ein importiertes File
    // mit derselben ID wird ignoriert (verhindert doppelte Listeneinträge).
    final byId = <String, CustomTheme>{};

    for (final asset in _bundled) {
      try {
        final t = CustomTheme.parse(
          await rootBundle.loadString(asset),
          builtIn: true,
        );
        byId[t.id] = t;
      } catch (e) {
        debugPrint('Theme-Asset $asset kaputt: $e');
      }
    }

    final dir = await _themesDir();
    if (dir.existsSync()) {
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
          byId.putIfAbsent(t.id, () => t);
        } catch (e) {
          debugPrint('Importiertes Theme ${f.path} kaputt: $e');
        }
      }
    }

    _themes = byId.values.toList();
    notifyListeners();
  }

  /// Importiert eine Theme-Datei. Wirft [CustomThemeException] bei kaputter
  /// Datei. Ein vorhandenes Theme mit gleicher ID wird überschrieben.
  Future<CustomTheme> import(Uint8List bytes) async {
    final theme = CustomTheme.parse(String.fromCharCodes(bytes));
    final dir = await _themesDir();
    await dir.create(recursive: true);
    await File(p.join(dir.path, '${theme.id}.json')).writeAsBytes(bytes);
    await refresh();
    return theme;
  }

  /// Löscht ein importiertes Theme (mitgelieferte lassen sich nicht löschen).
  Future<void> delete(String id) async {
    final file = File(p.join((await _themesDir()).path, '$id.json'));
    if (file.existsSync()) await file.delete();
    await refresh();
  }

  Future<Directory> _themesDir() async => Directory(
    p.join((await getApplicationDocumentsDirectory()).path, _dirName),
  );
}
