import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
}

/// Persistente App-Einstellungen jenseits der API-Keys (die im [ApiKeyStore]
/// liegen).
///
/// Bewusst als eigenes Interface: hier stehen keine Geheimnisse, dafür Dinge
/// wie der Theme-Modus und die Abgleich-Optionen – und später (BACKLOG.md) die
/// Auswahl bzw. der Import eigener Farbschemata.
abstract class AppSettingsStore {
  Future<ThemeMode> getThemeMode();
  Future<void> setThemeMode(ThemeMode mode);

  Future<SyncSettings> getSyncSettings();
  Future<void> setSyncSettings(SyncSettings settings);
}

/// Produktive Implementierung über `shared_preferences` (plattformneutral).
class SharedPrefsAppSettingsStore implements AppSettingsStore {
  static const _themeModeKey = 'theme_mode';
  static const _masterGenKey = 'sync_last_master_generation';
  static const _gcEnabledKey = 'sync_tombstone_gc_enabled';
  static const _gcDaysKey = 'sync_tombstone_gc_days';

  @override
  Future<ThemeMode> getThemeMode() async {
    final prefs = await SharedPreferences.getInstance();
    return switch (prefs.getString(_themeModeKey)) {
      'light' => ThemeMode.light,
      'dark' => ThemeMode.dark,
      _ => ThemeMode.system,
    };
  }

  @override
  Future<void> setThemeMode(ThemeMode mode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_themeModeKey, mode.name);
  }

  @override
  Future<SyncSettings> getSyncSettings() async {
    final prefs = await SharedPreferences.getInstance();
    const d = SyncSettings();
    return SyncSettings(
      lastConsumedMasterGeneration:
          prefs.getInt(_masterGenKey) ?? d.lastConsumedMasterGeneration,
      tombstoneGcEnabled: prefs.getBool(_gcEnabledKey) ?? d.tombstoneGcEnabled,
      tombstoneGcDays: prefs.getInt(_gcDaysKey) ?? d.tombstoneGcDays,
    );
  }

  @override
  Future<void> setSyncSettings(SyncSettings s) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_masterGenKey, s.lastConsumedMasterGeneration);
    await prefs.setBool(_gcEnabledKey, s.tombstoneGcEnabled);
    await prefs.setInt(_gcDaysKey, s.tombstoneGcDays);
  }
}

/// Für Tests und Entwicklung.
class InMemoryAppSettingsStore implements AppSettingsStore {
  InMemoryAppSettingsStore({
    this.themeMode = ThemeMode.system,
    this.syncSettings = const SyncSettings(),
  });

  ThemeMode themeMode;
  SyncSettings syncSettings;

  @override
  Future<ThemeMode> getThemeMode() async => themeMode;

  @override
  Future<void> setThemeMode(ThemeMode mode) async => themeMode = mode;

  @override
  Future<SyncSettings> getSyncSettings() async => syncSettings;

  @override
  Future<void> setSyncSettings(SyncSettings settings) async =>
      syncSettings = settings;
}

/// Hält die aktuellen Einstellungen im Speicher und schreibt jede Änderung
/// durch in den [AppSettingsStore]. `main.dart` erzeugt genau eine Instanz;
/// die UI liest daraus und ruft die Setter. Als [ChangeNotifier], damit
/// `MaterialApp` bei einem Theme-Wechsel sofort neu baut.
class AppSettings extends ChangeNotifier {
  AppSettings(this._store, this._themeMode, this._sync);

  /// Lädt den gespeicherten Stand und baut daraus die Instanz.
  static Future<AppSettings> load(AppSettingsStore store) async => AppSettings(
    store,
    await store.getThemeMode(),
    await store.getSyncSettings(),
  );

  final AppSettingsStore _store;

  ThemeMode _themeMode;
  ThemeMode get themeMode => _themeMode;

  SyncSettings _sync;
  SyncSettings get sync => _sync;

  Future<void> setThemeMode(ThemeMode mode) async {
    if (mode == _themeMode) return;
    _themeMode = mode;
    notifyListeners();
    await _store.setThemeMode(mode);
  }

  Future<void> updateSync(SyncSettings settings) async {
    _sync = settings;
    notifyListeners();
    await _store.setSyncSettings(settings);
  }
}
