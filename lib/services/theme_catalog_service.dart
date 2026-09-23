import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui' show Brightness, Color;

import 'package:http/http.dart' as http;

import '../models/models.dart';

/// Ein Eintrag im Theme-Katalog (`themes/index.json` im GitHub-Repo, erzeugt
/// von `tool/build_theme_index.dart`; siehe THEMES.md).
class ThemeCatalogEntry {
  const ThemeCatalogEntry({
    required this.id,
    required this.name,
    required this.brightness,
    required this.file,
    this.revision = 1,
    this.description,
    this.swatchSurface,
    this.swatchPrimary,
    this.logoFile,
  });

  final String id;
  final String name;
  final Brightness brightness;

  /// Theme-Datei relativ zum Katalog-Ordner (z.B. `blue_gold.json`).
  final String file;

  /// Inhaltsstand; höher als der installierte → „Aktualisieren".
  final int revision;
  final String? description;

  /// Farben der Ersatz-Vorschau, falls es kein Logo gibt.
  final Color? swatchSurface;
  final Color? swatchPrimary;

  /// Vorschau-Logo relativ zum Katalog-Ordner (z.B. `previews/blue_gold.png`).
  final String? logoFile;

  static final _idPattern = RegExp(r'^[A-Za-z0-9_-]+$');

  /// Nur schlichte relative Pfade – nie ein Schema, Host oder `..`, damit ein
  /// Katalogeintrag die App nicht auf eine fremde Adresse lenken kann.
  static final _pathPattern = RegExp(
    r'^[A-Za-z0-9_-]+(/[A-Za-z0-9_-]+)*\.\w+$',
  );

  /// Wirft [FormatException] bei einem unbrauchbaren Eintrag.
  factory ThemeCatalogEntry.fromJson(Map<String, Object?> j) {
    final id = j['id'];
    final name = j['name'];
    final file = j['file'];
    if (id is! String || !_idPattern.hasMatch(id)) {
      throw const FormatException('id');
    }
    if (name is! String || name.trim().isEmpty) {
      throw const FormatException('name');
    }
    if (file is! String ||
        !file.endsWith('.json') ||
        !_pathPattern.hasMatch(file)) {
      throw const FormatException('file');
    }
    final logo = j['logo'];
    final swatch = j['swatch'];
    final description = (j['description'] as String?)?.trim();
    return ThemeCatalogEntry(
      id: id,
      name: name.trim(),
      brightness: j['brightness'] == 'light'
          ? Brightness.light
          : Brightness.dark,
      file: file,
      revision: switch (j['revision']) {
        final int r when r >= 1 => r,
        _ => 1,
      },
      description: description == null || description.isEmpty
          ? null
          : description,
      swatchSurface: swatch is Map ? _color(swatch['surface']) : null,
      swatchPrimary: swatch is Map ? _color(swatch['primary']) : null,
      logoFile: logo is String && _pathPattern.hasMatch(logo) ? logo : null,
    );
  }

  static Color? _color(Object? hex) {
    if (hex is! String) return null;
    var s = hex.trim().replaceFirst('#', '');
    if (s.length == 6) s = 'FF$s';
    final v = s.length == 8 ? int.tryParse(s, radix: 16) : null;
    return v == null ? null : Color(v);
  }
}

class ThemeCatalogException implements Exception {
  const ThemeCatalogException(this.message, [this.cause]);
  final String message;
  final Object? cause;

  @override
  String toString() => 'ThemeCatalogException: $message';
}

/// Holt den Theme-Katalog und einzelne Theme-Dateien aus dem Booknote-Repo auf
/// GitHub (`raw.githubusercontent.com`, nur lesend, kein Login). Themes sind
/// reine Daten (Farben, Bilder, ein Schriftname) – es wird nie Code geladen.
class ThemeCatalogService {
  ThemeCatalogService({
    http.Client? client,
    Uri? baseUrl,
    this.timeout = const Duration(seconds: 15),
  }) : _client = client ?? http.Client(),
       baseUrl = baseUrl ?? defaultBaseUrl;

  /// Ordner `themes/` im Repo; endet auf `/`, damit relative Pfade darunter
  /// aufgelöst werden.
  static final defaultBaseUrl = Uri.parse(
    'https://raw.githubusercontent.com/georg-doenges/booknote/main/themes/',
  );

  static const indexFormat = 'booknote-theme-index';
  static const supportedFormatVersion = 1;
  static const maxIndexBytes = 512 * 1024;
  static const maxThemeBytes = 8 * 1024 * 1024;

  final http.Client _client;
  final Uri baseUrl;
  final Duration timeout;

  /// Adresse einer Datei im Katalog-Ordner (z.B. für Vorschau-Logos).
  Uri urlFor(String relativePath) => baseUrl.resolve(relativePath);

  Future<List<ThemeCatalogEntry>> fetchIndex() async {
    final res = await _get(urlFor('index.json'), maxBytes: maxIndexBytes);
    final Object? decoded;
    try {
      decoded = jsonDecode(utf8.decode(res.bodyBytes));
    } on FormatException catch (e) {
      throw ThemeCatalogException('Unerwartete Antwort vom Katalog.', e);
    }
    if (decoded is! Map<String, Object?> || decoded['format'] != indexFormat) {
      throw const ThemeCatalogException('Unerwartete Antwort vom Katalog.');
    }
    final version = decoded['formatVersion'];
    if (version is! int || version > supportedFormatVersion) {
      throw const ThemeCatalogException(
        'Der Katalog braucht eine neuere Booknote-Version – bitte die App '
        'aktualisieren.',
      );
    }
    final raw = decoded['themes'];
    if (raw is! List) {
      throw const ThemeCatalogException('Unerwartete Antwort vom Katalog.');
    }
    final entries = <ThemeCatalogEntry>[];
    for (final item in raw) {
      if (item is! Map<String, Object?>) continue;
      try {
        entries.add(ThemeCatalogEntry.fromJson(item));
      } on FormatException {
        continue; // ein kaputter Eintrag soll nicht den ganzen Katalog kippen
      }
    }
    return entries;
  }

  /// Lädt die Theme-Datei und prüft sie (gültiges Theme, passende ID). Gibt die
  /// Roh-Bytes zurück, die `CustomThemeStore.import` speichert.
  Future<Uint8List> fetchTheme(ThemeCatalogEntry entry) async {
    final res = await _get(urlFor(entry.file), maxBytes: maxThemeBytes);
    try {
      final theme = CustomTheme.parse(utf8.decode(res.bodyBytes));
      if (theme.id != entry.id) {
        throw ThemeCatalogException(
          'Der Katalogeintrag „${entry.name}" passt nicht zu seiner Datei.',
        );
      }
    } on CustomThemeException catch (e) {
      throw ThemeCatalogException(e.message, e);
    } on FormatException catch (e) {
      throw ThemeCatalogException('Die Theme-Datei ist beschädigt.', e);
    }
    return res.bodyBytes;
  }

  Future<http.Response> _get(Uri uri, {required int maxBytes}) async {
    final http.Response res;
    try {
      res = await _client
          .get(uri, headers: const {'User-Agent': 'Booknote/0.1 (Flutter app)'})
          .timeout(timeout);
    } on Exception catch (e) {
      throw ThemeCatalogException(
        'Keine Verbindung zum Katalog – bitte Internetverbindung prüfen.',
        e,
      );
    }
    if (res.statusCode != 200) {
      throw ThemeCatalogException(
        'Der Katalog antwortete mit Status ${res.statusCode}.',
        res.statusCode,
      );
    }
    if (res.bodyBytes.length > maxBytes) {
      throw const ThemeCatalogException(
        'Die Datei ist ungewöhnlich groß und wurde nicht geladen.',
      );
    }
    return res;
  }
}
