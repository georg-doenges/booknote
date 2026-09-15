import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../models/models.dart';

/// Hält die verfügbaren Custom-Themes. Alle liegen als JSON-Datei im
/// App-Dokumentenverzeichnis (`<docs>/themes/<id>.json`) und sind gleichwertig –
/// auch die mitgelieferten lassen sich löschen. Siehe THEMES.md.
///
/// Die mitgelieferten Schemata (`assets/themes/*.json`) werden beim Erststart
/// einmalig dorthin kopiert. Ein danach gelöschtes mitgeliefertes Schema kann
/// über [restore] zurückgeholt werden.
class CustomThemeStore extends ChangeNotifier {
  CustomThemeStore([this._bundled = _bundledAssets]);

  static const _bundledAssets = [
    'assets/themes/blue_gold.json',
    'assets/themes/old_library.json',
  ];
  static const _dirName = 'themes';
  static const _markerName = '.initialized';

  final List<String> _bundled;

  List<CustomTheme> _themes = const [];
  List<CustomTheme> get themes => _themes;

  /// Parsed aus den Assets – Grundlage für [restorable] und [restore].
  List<CustomTheme> _catalog = const [];

  /// Mitgelieferte Schemata, die aktuell nicht in der Liste stehen (vom Nutzer
  /// gelöscht). Für diese bietet die UI „wiederherstellen" an.
  List<CustomTheme> get restorable => _catalog
      .where((c) => _themes.every((t) => t.id != c.id))
      .toList(growable: false);

  CustomTheme? byId(String? id) {
    if (id == null) return null;
    for (final t in _themes) {
      if (t.id == id) return t;
    }
    return null;
  }

  Future<void> refresh() async {
    final dir = await _themesDir();
    await dir.create(recursive: true);

    // Assets parsen (Katalog) und beim Erststart einmalig ins Verzeichnis
    // kopieren.
    final marker = File(p.join(dir.path, _markerName));
    final firstRun = !marker.existsSync();
    final catalog = <CustomTheme>[];
    for (final asset in _bundled) {
      try {
        final text = await rootBundle.loadString(asset);
        final theme = CustomTheme.parse(text);
        catalog.add(theme);
        if (firstRun) {
          await File(p.join(dir.path, '${theme.id}.json')).writeAsString(text);
        }
      } catch (e) {
        debugPrint('Theme-Asset $asset kaputt: $e');
      }
    }
    if (firstRun) {
      await marker.writeAsString(DateTime.now().toUtc().toIso8601String());
    }
    _catalog = catalog;

    // Alle Themes aus dem Verzeichnis lesen, nach ID entdoppeln.
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

  /// Löscht ein Theme. Betrifft auch mitgelieferte – die lassen sich über
  /// [restore] zurückholen.
  Future<void> delete(String id) async {
    final file = File(p.join((await _themesDir()).path, '$id.json'));
    if (file.existsSync()) await file.delete();
    await refresh();
  }

  /// Holt ein gelöschtes mitgeliefertes Schema aus den Assets zurück.
  Future<void> restore(String id) async {
    final dir = await _themesDir();
    await dir.create(recursive: true);
    for (final asset in _bundled) {
      final text = await rootBundle.loadString(asset);
      if (CustomTheme.parse(text).id == id) {
        await File(p.join(dir.path, '$id.json')).writeAsString(text);
        break;
      }
    }
    await refresh();
  }

  Future<Directory> _themesDir() async => Directory(
    p.join((await getApplicationDocumentsDirectory()).path, _dirName),
  );
}
