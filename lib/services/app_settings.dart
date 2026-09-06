import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Persistente App-Einstellungen jenseits der API-Keys (die im [ApiKeyStore]
/// liegen).
///
/// Bewusst als eigenes Interface: hier stehen keine Geheimnisse, dafür Dinge
/// wie der Theme-Modus – und später (siehe BACKLOG.md) die Auswahl bzw. der
/// Import eigener Farbschemata. Deshalb spricht das Interface schon jetzt in
/// `themeMode` statt in einem einzelnen Bool und lässt sich um weitere Getter
/// erweitern, ohne die UI umzubauen.
abstract class AppSettingsStore {
  Future<ThemeMode> getThemeMode();
  Future<void> setThemeMode(ThemeMode mode);
}

/// Produktive Implementierung über `shared_preferences` (plattformneutral).
class SharedPrefsAppSettingsStore implements AppSettingsStore {
  static const _themeModeKey = 'theme_mode';

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
}

/// Für Tests und Entwicklung.
class InMemoryAppSettingsStore implements AppSettingsStore {
  InMemoryAppSettingsStore({this.themeMode = ThemeMode.system});

  ThemeMode themeMode;

  @override
  Future<ThemeMode> getThemeMode() async => themeMode;

  @override
  Future<void> setThemeMode(ThemeMode mode) async => themeMode = mode;
}

/// Hält die aktuellen Einstellungen im Speicher und schreibt jede Änderung
/// durch in den [AppSettingsStore]. `main.dart` erzeugt genau eine Instanz;
/// die UI liest daraus (`themeMode`) und ruft die Setter. Als [ChangeNotifier],
/// damit `MaterialApp` bei einem Wechsel sofort neu baut.
class AppSettings extends ChangeNotifier {
  AppSettings(this._store, this._themeMode);

  /// Lädt den gespeicherten Stand und baut daraus die Instanz.
  static Future<AppSettings> load(AppSettingsStore store) async =>
      AppSettings(store, await store.getThemeMode());

  final AppSettingsStore _store;

  ThemeMode _themeMode;
  ThemeMode get themeMode => _themeMode;

  Future<void> setThemeMode(ThemeMode mode) async {
    if (mode == _themeMode) return;
    _themeMode = mode;
    notifyListeners();
    await _store.setThemeMode(mode);
  }
}
