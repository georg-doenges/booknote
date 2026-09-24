import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/app_language.dart';

const Object _unset = Object();

/// Einstellungen rund um den Geräte-Abgleich (siehe `SYNC_DESIGN.md`).
class SyncSettings {
  const SyncSettings({
    this.lastConsumedMasterGeneration = 0,
    this.tombstoneGcEnabled = true,
    this.tombstoneGcDays = 120,
  });

  /// Höchste Master-Generation, die dieses Gerät schon übernommen hat.
  final int lastConsumedMasterGeneration;

  /// Alte Grabsteine beim Abgleich verwerfen?
  final bool tombstoneGcEnabled;

  /// Ab diesem Alter (Tage) gilt ein Grabstein als „alt".
  final int tombstoneGcDays;

  SyncSettings copyWith({
    int? lastConsumedMasterGeneration,
    bool? tombstoneGcEnabled,
    int? tombstoneGcDays,
  }) => SyncSettings(
    lastConsumedMasterGeneration:
        lastConsumedMasterGeneration ?? this.lastConsumedMasterGeneration,
    tombstoneGcEnabled: tombstoneGcEnabled ?? this.tombstoneGcEnabled,
    tombstoneGcDays: tombstoneGcDays ?? this.tombstoneGcDays,
  );

  @override
  bool operator ==(Object other) =>
      other is SyncSettings &&
      other.lastConsumedMasterGeneration == lastConsumedMasterGeneration &&
      other.tombstoneGcEnabled == tombstoneGcEnabled &&
      other.tombstoneGcDays == tombstoneGcDays;

  @override
  int get hashCode => Object.hash(
    lastConsumedMasterGeneration,
    tombstoneGcEnabled,
    tombstoneGcDays,
  );
}

/// Alle nicht-geheimen App-Einstellungen als ein Wertobjekt. (API-Keys liegen
/// im `ApiKeyStore`.)
class AppPrefs {
  const AppPrefs({
    this.themeMode = ThemeMode.system,
    this.activeCustomThemeId,
    this.hapticsEnabled = true,
    this.uiLanguage,
    this.cleanMode = false,
    this.sync = const SyncSettings(),
  });

  final ThemeMode themeMode;

  /// ID eines aktiven importierten Farbschemas. `null` = [themeMode] gilt.
  final String? activeCustomThemeId;

  /// Haptisches Feedback beim Aufnehmen.
  final bool hapticsEnabled;

  /// Sprache der Oberfläche – die einzige globale Sprach-Einstellung. `null` =
  /// wie das Gerät (Deutsch, English oder Français; andere Gerätesprachen →
  /// English). Aufnahme- und Cover-Suche-Sprache hängen am Buch
  /// (`Source.language`), siehe `RecordingScreen` und `BookSearchScreen`.
  final AppLanguage? uiLanguage;

  /// Clean Mode: blendet Erklärtexte und Hinweise aus (nur Beschriftungen,
  /// Überschriften und Bedienelemente bleiben). Standard aus – wer die App noch
  /// nicht kennt, soll die Erklärungen sehen.
  final bool cleanMode;

  final SyncSettings sync;

  AppPrefs copyWith({
    ThemeMode? themeMode,
    Object? activeCustomThemeId = _unset,
    bool? hapticsEnabled,
    Object? uiLanguage = _unset,
    bool? cleanMode,
    SyncSettings? sync,
  }) => AppPrefs(
    themeMode: themeMode ?? this.themeMode,
    activeCustomThemeId: activeCustomThemeId == _unset
        ? this.activeCustomThemeId
        : activeCustomThemeId as String?,
    hapticsEnabled: hapticsEnabled ?? this.hapticsEnabled,
    uiLanguage: uiLanguage == _unset
        ? this.uiLanguage
        : uiLanguage as AppLanguage?,
    cleanMode: cleanMode ?? this.cleanMode,
    sync: sync ?? this.sync,
  );

  @override
  bool operator ==(Object other) =>
      other is AppPrefs &&
      other.themeMode == themeMode &&
      other.activeCustomThemeId == activeCustomThemeId &&
      other.hapticsEnabled == hapticsEnabled &&
      other.uiLanguage == uiLanguage &&
      other.cleanMode == cleanMode &&
      other.sync == sync;

  @override
  int get hashCode => Object.hash(
    themeMode,
    activeCustomThemeId,
    hapticsEnabled,
    uiLanguage,
    cleanMode,
    sync,
  );
}

/// Lädt/speichert [AppPrefs]. Interface, damit Tests ohne echte Persistenz
/// auskommen.
abstract class AppSettingsStore {
  Future<AppPrefs> load();
  Future<void> save(AppPrefs prefs);
}

/// Produktive Implementierung über `shared_preferences` (plattformneutral).
class SharedPrefsAppSettingsStore implements AppSettingsStore {
  static const _themeMode = 'theme_mode';
  static const _customTheme = 'active_custom_theme';
  static const _haptics = 'haptics_enabled';
  static const _cleanMode = 'clean_mode';

  /// Früher eigene Cover-Sprache; seit sie dem Buch folgt, ohne Wirkung.
  static const _legacyLangCover = 'lang_cover';
  static const _langUi = 'lang_ui';
  static const _masterGen = 'sync_last_master_generation';
  static const _gcEnabled = 'sync_tombstone_gc_enabled';
  static const _gcDays = 'sync_tombstone_gc_days';

  @override
  Future<AppPrefs> load() async {
    final p = await SharedPreferences.getInstance();
    const d = AppPrefs();
    return AppPrefs(
      themeMode: switch (p.getString(_themeMode)) {
        'light' => ThemeMode.light,
        'dark' => ThemeMode.dark,
        _ => ThemeMode.system,
      },
      activeCustomThemeId: p.getString(_customTheme),
      hapticsEnabled: p.getBool(_haptics) ?? d.hapticsEnabled,
      uiLanguage: AppLanguage.tryFromCode(p.getString(_langUi)),
      cleanMode: p.getBool(_cleanMode) ?? d.cleanMode,
      sync: SyncSettings(
        lastConsumedMasterGeneration:
            p.getInt(_masterGen) ?? d.sync.lastConsumedMasterGeneration,
        tombstoneGcEnabled: p.getBool(_gcEnabled) ?? d.sync.tombstoneGcEnabled,
        tombstoneGcDays: p.getInt(_gcDays) ?? d.sync.tombstoneGcDays,
      ),
    );
  }

  @override
  Future<void> save(AppPrefs a) async {
    final p = await SharedPreferences.getInstance();
    await p.setString(_themeMode, a.themeMode.name);
    if (a.activeCustomThemeId == null) {
      await p.remove(_customTheme);
    } else {
      await p.setString(_customTheme, a.activeCustomThemeId!);
    }
    await p.setBool(_haptics, a.hapticsEnabled);
    await _setOrRemove(p, _langUi, a.uiLanguage?.code);
    await p.setBool(_cleanMode, a.cleanMode);
    await p.remove(_legacyLangCover);
    await p.setInt(_masterGen, a.sync.lastConsumedMasterGeneration);
    await p.setBool(_gcEnabled, a.sync.tombstoneGcEnabled);
    await p.setInt(_gcDays, a.sync.tombstoneGcDays);
  }
}

Future<void> _setOrRemove(SharedPreferences p, String key, String? value) =>
    value == null ? p.remove(key) : p.setString(key, value);

/// Für Tests und Entwicklung.
class InMemoryAppSettingsStore implements AppSettingsStore {
  InMemoryAppSettingsStore({this.prefs = const AppPrefs()});

  AppPrefs prefs;

  @override
  Future<AppPrefs> load() async => prefs;

  @override
  Future<void> save(AppPrefs p) async => prefs = p;
}

/// Hält die aktuellen Einstellungen im Speicher und schreibt jede Änderung
/// durch. `main.dart` erzeugt genau eine Instanz; die UI liest daraus und ruft
/// die Setter. [ChangeNotifier], damit `MaterialApp` bei einem Theme-Wechsel
/// sofort neu baut.
class AppSettings extends ChangeNotifier {
  AppSettings(this._store, this._prefs);

  /// Lädt den gespeicherten Stand.
  static Future<AppSettings> load(AppSettingsStore store) async =>
      AppSettings(store, await store.load());

  final AppSettingsStore _store;
  AppPrefs _prefs;

  AppPrefs get prefs => _prefs;
  ThemeMode get themeMode => _prefs.themeMode;
  String? get activeCustomThemeId => _prefs.activeCustomThemeId;
  bool get hapticsEnabled => _prefs.hapticsEnabled;
  AppLanguage? get uiLanguage => _prefs.uiLanguage;
  bool get cleanMode => _prefs.cleanMode;
  SyncSettings get sync => _prefs.sync;

  Future<void> _update(AppPrefs next) async {
    if (next == _prefs) return;
    _prefs = next;
    notifyListeners();
    await _store.save(next);
  }

  /// Wählt einen eingebauten Modus – deaktiviert dabei ein aktives Custom-Theme.
  Future<void> setThemeMode(ThemeMode mode) =>
      _update(_prefs.copyWith(themeMode: mode, activeCustomThemeId: null));

  /// Aktiviert ein importiertes Farbschema (`null` → zurück zu [themeMode]).
  Future<void> setActiveCustomTheme(String? id) =>
      _update(_prefs.copyWith(activeCustomThemeId: id));

  Future<void> setHapticsEnabled(bool enabled) =>
      _update(_prefs.copyWith(hapticsEnabled: enabled));

  /// `null` = Sprache des Geräts.
  Future<void> setUiLanguage(AppLanguage? language) =>
      _update(_prefs.copyWith(uiLanguage: language));

  /// Clean Mode an/aus: Erklärtexte und Hinweise ein- bzw. ausblenden.
  Future<void> setCleanMode(bool enabled) =>
      _update(_prefs.copyWith(cleanMode: enabled));

  Future<void> updateSync(SyncSettings settings) =>
      _update(_prefs.copyWith(sync: settings));
}
