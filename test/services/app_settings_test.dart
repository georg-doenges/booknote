import 'package:booknote/services/services.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('InMemoryAppSettingsStore', () {
    test('Standard ist ThemeMode.system', () async {
      expect(await InMemoryAppSettingsStore().getThemeMode(), ThemeMode.system);
    });

    test('speichert und liest den Modus zurück', () async {
      final store = InMemoryAppSettingsStore();
      await store.setThemeMode(ThemeMode.dark);
      expect(await store.getThemeMode(), ThemeMode.dark);
    });
  });

  group('AppSettings', () {
    test('load() übernimmt den gespeicherten Modus', () async {
      final store = InMemoryAppSettingsStore(themeMode: ThemeMode.light);
      final settings = await AppSettings.load(store);
      expect(settings.themeMode, ThemeMode.light);
    });

    test('setThemeMode benachrichtigt Listener und schreibt durch', () async {
      final store = InMemoryAppSettingsStore();
      final settings = await AppSettings.load(store);
      var notified = 0;
      settings.addListener(() => notified++);

      await settings.setThemeMode(ThemeMode.dark);

      expect(settings.themeMode, ThemeMode.dark);
      expect(notified, 1);
      expect(store.themeMode, ThemeMode.dark);
    });

    test('gleicher Modus löst keine Benachrichtigung aus', () async {
      final settings = await AppSettings.load(InMemoryAppSettingsStore());
      var notified = 0;
      settings.addListener(() => notified++);

      await settings.setThemeMode(ThemeMode.system);

      expect(notified, 0);
    });
  });

  group('SharedPrefsAppSettingsStore', () {
    setUp(() => SharedPreferences.setMockInitialValues({}));

    test('ohne gespeicherten Wert → system', () async {
      expect(
        await SharedPrefsAppSettingsStore().getThemeMode(),
        ThemeMode.system,
      );
    });

    test('Runde: dark schreiben, dark lesen', () async {
      final store = SharedPrefsAppSettingsStore();
      await store.setThemeMode(ThemeMode.dark);
      expect(await store.getThemeMode(), ThemeMode.dark);
    });
  });
}
