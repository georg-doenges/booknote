import 'package:booknote/l10n/l10n.dart';
import 'package:booknote/models/models.dart';
import 'package:booknote/services/services.dart';
import 'package:booknote/widgets/format.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

void main() {
  setUpAll(() async {
    for (final l in AppLanguage.values) {
      await initializeDateFormatting(l.code);
    }
  });

  AppLocalizations lookup(AppLanguage l) => lookupAppLocalizations(l.locale);

  group('Sprachauflösung', () {
    const supported = AppLocalizations.supportedLocales;

    test('erste unterstützte Gerätesprache gewinnt', () {
      expect(
        resolveAppLocale([
          const Locale('nl'),
          const Locale('fr', 'BE'),
        ], supported),
        const Locale('fr'),
      );
      expect(
        resolveAppLocale([const Locale('de', 'AT')], supported),
        const Locale('de'),
      );
      expect(
        resolveAppLocale([const Locale('en', 'GB')], supported),
        const Locale('en'),
      );
    });

    test(
      'nicht unterstützt (Niederländisch, Spanisch …) → English, nicht Deutsch',
      () {
        expect(
          resolveAppLocale([const Locale('nl', 'BE')], supported),
          const Locale('en'),
        );
        expect(
          resolveAppLocale([const Locale('es')], supported),
          const Locale('en'),
        );
        expect(resolveAppLocale(const [], supported), const Locale('en'));
        expect(resolveAppLocale(null, supported), const Locale('en'));
      },
    );

    test('die drei Sprachen sind genau die des AppLanguage-Enums', () {
      expect(
        supported.map((l) => l.languageCode).toSet(),
        AppLanguage.values.map((l) => l.code).toSet(),
      );
    });
  });

  group('Fehlertexte', () {
    for (final language in AppLanguage.values) {
      final l = lookup(language);

      test('Transkription (${language.code}): jede Art hat einen Text', () {
        for (final kind in TranscriptionErrorKind.values) {
          final text = transcriptionErrorText(
            l,
            TranscriptionException(kind, 'x', status: 502),
          );
          expect(text, isNotEmpty, reason: kind.name);
        }
        expect(
          transcriptionErrorText(
            l,
            const TranscriptionException(
              TranscriptionErrorKind.server,
              'x',
              status: 502,
            ),
          ),
          contains('502'),
        );
        expect(
          transcriptionErrorText(
            l,
            const TranscriptionException(TranscriptionErrorKind.server, 'x'),
          ),
          isNot(contains('null')),
        );
      });

      test(
        'Cover-Suche (${language.code}): Quelle und Status stehen im Text',
        () {
          for (final kind in CoverSearchErrorKind.values) {
            final text = coverSearchErrorText(
              l,
              CoverSearchException(kind, provider: 'Open Library', status: 429),
            );
            expect(text, isNotEmpty, reason: kind.name);
            expect(text, isNot(contains('null')), reason: kind.name);
          }
          expect(
            coverSearchErrorText(
              l,
              const CoverSearchException(
                CoverSearchErrorKind.badStatus,
                provider: 'Open Library',
                status: 503,
              ),
            ),
            allOf(contains('Open Library'), contains('503')),
          );
          expect(
            coverSearchWarningText(
              l,
              const CoverSearchException(
                CoverSearchErrorKind.unreachable,
                provider: 'Google Books',
              ),
            ),
            contains('Google Books'),
          );
        },
      );

      test(
        'Dateien (${language.code}): Theme-, Bibliotheks- und Katalog-Fehler',
        () {
          for (final kind in CustomThemeErrorKind.values) {
            expect(
              customThemeErrorText(l, CustomThemeException(kind, '#GGG')),
              isNotEmpty,
              reason: kind.name,
            );
          }
          expect(
            customThemeErrorText(
              l,
              const CustomThemeException(
                CustomThemeErrorKind.invalidColor,
                '#GGG',
              ),
            ),
            contains('#GGG'),
          );
          for (final kind in LibraryFileErrorKind.values) {
            expect(
              libraryFileErrorText(l, LibraryFileException(kind, 'boom')),
              isNotEmpty,
              reason: kind.name,
            );
          }
          for (final kind in ThemeCatalogErrorKind.values) {
            expect(
              themeCatalogErrorText(
                l,
                ThemeCatalogException(kind, status: 404, name: 'Aurora'),
              ),
              isNotEmpty,
              reason: kind.name,
            );
          }
          expect(
            themeCatalogErrorText(
              l,
              const ThemeCatalogException(
                ThemeCatalogErrorKind.badStatus,
                status: 404,
              ),
            ),
            contains('404'),
          );
          expect(
            themeCatalogErrorText(
              l,
              const ThemeCatalogException(
                ThemeCatalogErrorKind.idMismatch,
                name: 'Aurora',
              ),
            ),
            contains('Aurora'),
          );
          // Ungültiges Theme: die Ursache aus dem Theme-Format wird übernommen.
          expect(
            themeCatalogErrorText(
              l,
              const ThemeCatalogException(
                ThemeCatalogErrorKind.invalidTheme,
                cause: CustomThemeException(CustomThemeErrorKind.notATheme),
              ),
            ),
            customThemeErrorText(
              l,
              const CustomThemeException(CustomThemeErrorKind.notATheme),
            ),
          );
        },
      );
    }
  });

  group('Beispielsatz und Export-Beschriftungen', () {
    test('der gesprochene Beispielsatz folgt der Aufnahmesprache und wird vom Parser verstanden', () {
      const parser = NoteParser();
      for (final language in AppLanguage.values) {
        final parsed = parser.parse(
          recordingExample(language),
          language: language,
        );
        expect(parsed.page, '47', reason: language.code);
        expect(parsed.position, isNotNull, reason: language.code);
        expect(parsed.text, isNotEmpty, reason: language.code);
      }
    });

    test('Export-Beschriftungen in der Sprache der App', () {
      final en = exportLabelsFor(lookup(AppLanguage.english), 'en');
      expect(en.notes, 'Notes');
      expect(en.withoutPage, 'Without page number');
      final fr = exportLabelsFor(lookup(AppLanguage.french), 'fr');
      expect(fr.notes, 'Notes');
      expect(fr.library, 'Bibliothèque');
      final de = exportLabelsFor(lookup(AppLanguage.german), 'de');
      expect(de.library, 'Bibliothek');
      expect(
        de.formatDateTime(DateTime(2026, 9, 5, 19, 26)),
        '05.09.2026, 19:26',
      );
    });
  });

  group('Datum und Seitenpräfix', () {
    // Lokale Zeit, damit die Ausgabe nicht von der Zeitzone des Rechners abhängt.
    final t = DateTime(2026, 9, 5, 19, 26);

    test('Deutsch numerisch, Englisch/Französisch mit Monatsname', () {
      expect(formatDateTime(t, 'de'), '05.09.2026, 19:26');
      expect(
        formatDateTime(t, 'en'),
        allOf(contains('Sep'), contains('2026'), contains('7:26')),
      );
      expect(
        formatDateTime(t, 'fr'),
        allOf(contains('sept'), contains('2026'), contains('19:26')),
      );
    });
  });
}
