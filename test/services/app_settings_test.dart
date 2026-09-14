import 'package:booknote/models/models.dart';
import 'package:booknote/services/services.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('AppPrefs', () {
    test('Defaults', () {
      const p = AppPrefs();
      expect(p.themeMode, ThemeMode.system);
      expect(p.hapticsEnabled, isTrue);
      expect(p.coverSearchLanguage, AppLanguage.german);
      expect(p.sync.tombstoneGcDays, 120);
    });

    test('== / copyWith', () {
      const a = AppPrefs();
      expect(a, a.copyWith());
      expect(a == a.copyWith(hapticsEnabled: false), isFalse);
      expect(
        a
            .copyWith(coverSearchLanguage: AppLanguage.english)
            .coverSearchLanguage,
        AppLanguage.english,
      );
    });
  });

  group('AppSettings', () {
    test('load() übernimmt den gespeicherten Stand', () async {
      final store = InMemoryAppSettingsStore(
        prefs: const AppPrefs(
          themeMode: ThemeMode.light,
          coverSearchLanguage: AppLanguage.english,
        ),
      );
      final settings = await AppSettings.load(store);
      expect(settings.themeMode, ThemeMode.light);
      expect(settings.coverSearchLanguage, AppLanguage.english);
    });

    test('setThemeMode benachrichtigt und schreibt durch', () async {
      final store = InMemoryAppSettingsStore();
      final settings = await AppSettings.load(store);
      var notified = 0;
      settings.addListener(() => notified++);

      await settings.setThemeMode(ThemeMode.dark);

      expect(settings.themeMode, ThemeMode.dark);
      expect(notified, 1);
      expect(store.prefs.themeMode, ThemeMode.dark);
    });

    test('unveränderter Wert löst keine Benachrichtigung aus', () async {
      final settings = await AppSettings.load(InMemoryAppSettingsStore());
      var notified = 0;
      settings.addListener(() => notified++);

      await settings.setThemeMode(ThemeMode.system);
      await settings.setHapticsEnabled(true);

      expect(notified, 0);
    });

    test('Cover-Sprache und GC-Tage lassen sich setzen', () async {
      final store = InMemoryAppSettingsStore();
      final settings = await AppSettings.load(store);

      await settings.setCoverSearchLanguage(AppLanguage.english);
      await settings.updateSync(settings.sync.copyWith(tombstoneGcDays: 30));

      expect(store.prefs.coverSearchLanguage, AppLanguage.english);
      expect(store.prefs.sync.tombstoneGcDays, 30);
    });
  });

  group('SharedPrefsAppSettingsStore', () {
    setUp(() => SharedPreferences.setMockInitialValues({}));

    test('leerer Speicher → Defaults', () async {
      final p = await SharedPrefsAppSettingsStore().load();
      expect(p.themeMode, ThemeMode.system);
      expect(p.coverSearchLanguage, AppLanguage.german);
    });

    test('Roundtrip', () async {
      final store = SharedPrefsAppSettingsStore();
      await store.save(
        const AppPrefs(
          themeMode: ThemeMode.dark,
          hapticsEnabled: false,
          coverSearchLanguage: AppLanguage.english,
          sync: SyncSettings(tombstoneGcEnabled: false, tombstoneGcDays: 60),
        ),
      );
      final p = await store.load();
      expect(p.themeMode, ThemeMode.dark);
      expect(p.hapticsEnabled, isFalse);
      expect(p.coverSearchLanguage, AppLanguage.english);
      expect(p.sync.tombstoneGcEnabled, isFalse);
      expect(p.sync.tombstoneGcDays, 60);
    });
  });
}
