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
      expect(p.uiLanguage, isNull, reason: 'null = Gerätesprache');
      expect(
        p.cleanMode,
        isFalse,
        reason: 'wer die App nicht kennt, soll die Erklärungen sehen',
      );
      expect(p.sync.tombstoneGcDays, 120);
    });

    test('== / copyWith', () {
      const a = AppPrefs();
      expect(a, a.copyWith());
      expect(a == a.copyWith(hapticsEnabled: false), isFalse);
      expect(a == a.copyWith(cleanMode: true), isFalse);
      expect(a.copyWith(cleanMode: true).cleanMode, isTrue);
      expect(
        a.copyWith(uiLanguage: AppLanguage.english).uiLanguage,
        AppLanguage.english,
      );
    });

    test('copyWith kann die App-Sprache wieder auf null (= Gerät) setzen', () {
      const a = AppPrefs(uiLanguage: AppLanguage.french);
      expect(a.copyWith(uiLanguage: null).uiLanguage, isNull);
      // ohne Angabe bleibt der Wert
      expect(a.copyWith(hapticsEnabled: false).uiLanguage, AppLanguage.french);
    });
  });

  group('AppSettings', () {
    test('load() übernimmt den gespeicherten Stand', () async {
      final store = InMemoryAppSettingsStore(
        prefs: const AppPrefs(
          themeMode: ThemeMode.light,
          uiLanguage: AppLanguage.english,
        ),
      );
      final settings = await AppSettings.load(store);
      expect(settings.themeMode, ThemeMode.light);
      expect(settings.uiLanguage, AppLanguage.english);
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

    test('GC-Tage lassen sich setzen', () async {
      final store = InMemoryAppSettingsStore();
      final settings = await AppSettings.load(store);

      await settings.updateSync(settings.sync.copyWith(tombstoneGcDays: 30));

      expect(store.prefs.sync.tombstoneGcDays, 30);
    });

    test('Clean Mode: Standard aus, umschaltbar, benachrichtigt', () async {
      final store = InMemoryAppSettingsStore();
      final settings = await AppSettings.load(store);
      expect(settings.cleanMode, isFalse);
      var notified = 0;
      settings.addListener(() => notified++);

      await settings.setCleanMode(true);
      expect(settings.cleanMode, isTrue);
      expect(store.prefs.cleanMode, isTrue);
      expect(notified, 1);

      await settings.setCleanMode(true); // unverändert
      expect(notified, 1);
      await settings.setCleanMode(false);
      expect(settings.cleanMode, isFalse);
      expect(notified, 2);
    });

    test('App-Sprache setzen und mit null auf Gerätesprache zurück', () async {
      final store = InMemoryAppSettingsStore();
      final settings = await AppSettings.load(store);
      var notified = 0;
      settings.addListener(() => notified++);

      await settings.setUiLanguage(AppLanguage.french);
      expect(settings.uiLanguage, AppLanguage.french);
      expect(store.prefs.uiLanguage, AppLanguage.french);

      await settings.setUiLanguage(null);
      expect(settings.uiLanguage, isNull);
      expect(store.prefs.uiLanguage, isNull);
      expect(notified, 2);

      // gleicher Wert → keine Benachrichtigung
      await settings.setUiLanguage(null);
      expect(notified, 2);
    });
  });

  group('SharedPrefsAppSettingsStore', () {
    setUp(() => SharedPreferences.setMockInitialValues({}));

    test('leerer Speicher → Defaults', () async {
      final p = await SharedPrefsAppSettingsStore().load();
      expect(p.themeMode, ThemeMode.system);
      expect(p.uiLanguage, isNull);
    });

    test('Clean Mode überlebt Speichern und Laden', () async {
      final store = SharedPrefsAppSettingsStore();
      expect((await store.load()).cleanMode, isFalse);
      await store.save(const AppPrefs(cleanMode: true));
      expect((await store.load()).cleanMode, isTrue);
    });

    test('Roundtrip', () async {
      final store = SharedPrefsAppSettingsStore();
      await store.save(
        const AppPrefs(
          themeMode: ThemeMode.dark,
          hapticsEnabled: false,
          uiLanguage: AppLanguage.french,
          sync: SyncSettings(tombstoneGcEnabled: false, tombstoneGcDays: 60),
        ),
      );
      final p = await store.load();
      expect(p.themeMode, ThemeMode.dark);
      expect(p.hapticsEnabled, isFalse);
      expect(p.uiLanguage, AppLanguage.french);
      expect(p.sync.tombstoneGcEnabled, isFalse);
      expect(p.sync.tombstoneGcDays, 60);
    });

    test(
      'App-Sprache wieder auf „wie das Gerät" → Wert wird entfernt',
      () async {
        final store = SharedPrefsAppSettingsStore();
        await store.save(const AppPrefs(uiLanguage: AppLanguage.french));
        await store.save(const AppPrefs());
        expect((await store.load()).uiLanguage, isNull);
      },
    );

    test('alte Cover-Sprache aus früheren Versionen wird beim Speichern '
        'aufgeräumt', () async {
      SharedPreferences.setMockInitialValues({'lang_cover': 'de'});
      await SharedPrefsAppSettingsStore().save(const AppPrefs());
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.containsKey('lang_cover'), isFalse);
    });
  });
}
