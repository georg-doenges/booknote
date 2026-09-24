/// Sammelstelle für alles Sprachabhängige der Oberfläche: der Zugriff
/// `context.l10n`, die Umwandlung der Fehlertypen der Services in Meldungen
/// und die Beschriftungen der Exportdateien.
///
/// Die Texte selbst stehen in `lib/l10n/app_{de,en,fr}.arb` (siehe l10n.yaml).
library;

import 'package:flutter/widgets.dart';

import '../export/export_labels.dart';
import '../models/models.dart';
import '../services/services.dart';
import '../widgets/format.dart';
import 'app_localizations.dart';

export 'app_localizations.dart';

extension L10nContext on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this);
}

extension AppLanguageLocale on AppLanguage {
  Locale get locale => Locale(code);
}

/// Wählt die Sprache der Oberfläche aus den bevorzugten Sprachen des Geräts (bzw.
/// der ausdrücklichen Wahl in den Einstellungen): die erste unterstützte, sonst
/// English – eine niederländische oder spanische Gerätesprache landet also bei
/// Englisch statt bei der Sprache des Entwicklers.
Locale resolveAppLocale(List<Locale>? preferred, Iterable<Locale> supported) {
  for (final locale in preferred ?? const <Locale>[]) {
    for (final candidate in supported) {
      if (candidate.languageCode == locale.languageCode) return candidate;
    }
  }
  return const Locale('en');
}

/// Sprache der Oberfläche, wie sie gerade gilt (Wahl in den Einstellungen oder
/// Gerätesprache) – immer eine der unterstützten.
AppLanguage uiLanguageOf(BuildContext context) =>
    AppLanguage.fromCode(Localizations.localeOf(context).languageCode);

/// Beispielsatz für den Erst-Hinweis im Aufnahme-Screen. Bewusst nicht in den
/// ARB-Dateien: Es ist der **gesprochene** Satz, er richtet sich nach der
/// Aufnahmesprache, nicht nach der Sprache der Oberfläche.
String recordingExample(AppLanguage language) => switch (language) {
  AppLanguage.german => 'Seite 47 oben, hier argumentiert der Autor, dass …',
  AppLanguage.english => 'Page 47 top, here the author argues that …',
  AppLanguage.french => 'Page 47 en haut, ici l’auteur soutient que …',
};

/// Beschriftungen für Exportdateien in der Sprache der Oberfläche.
ExportLabels exportLabelsFor(AppLocalizations l, String languageCode) =>
    ExportLabels(
      notes: l.exportLabelNotes,
      withoutPage: l.exportLabelWithoutPage,
      noNotesWithPage: l.exportLabelNoNotes,
      noText: l.exportLabelNoText,
      library: l.exportLabelLibrary,
      formatDateTime: (t) => formatDateTime(t, languageCode),
    );

// ---- Fehlertypen der Services → Meldungen ----

String transcriptionErrorText(AppLocalizations l, TranscriptionException e) =>
    switch (e.kind) {
      TranscriptionErrorKind.missingApiKey => l.trMissingKey,
      TranscriptionErrorKind.unauthorized => l.trUnauthorized,
      TranscriptionErrorKind.network => l.trNetwork,
      TranscriptionErrorKind.rateLimited => l.trRateLimited,
      TranscriptionErrorKind.invalidAudio => l.trInvalidAudio,
      TranscriptionErrorKind.server =>
        e.status == null ? l.trServer : l.trServerStatus(e.status!),
    };

String coverSearchErrorText(
  AppLocalizations l,
  CoverSearchException e,
) => switch (e.kind) {
  CoverSearchErrorKind.noConnection => l.coverErrNoConnection(e.provider),
  CoverSearchErrorKind.unreachable => l.coverErrUnreachable(e.provider),
  CoverSearchErrorKind.quotaWithoutKey => l.coverErrQuotaNoKey(e.status ?? 0),
  CoverSearchErrorKind.keyRejected => l.coverErrKeyRejected(e.status ?? 0),
  CoverSearchErrorKind.badStatus => l.coverErrStatus(e.provider, e.status ?? 0),
  CoverSearchErrorKind.unexpectedResponse => l.coverErrUnexpected(e.provider),
};

/// Hinweis über den Treffern, wenn die Primärquelle ausgefallen ist.
String coverSearchWarningText(AppLocalizations l, CoverSearchException e) =>
    l.searchFallbackWarning(coverSearchErrorText(l, e));

String customThemeErrorText(AppLocalizations l, CustomThemeException e) =>
    switch (e.kind) {
      CustomThemeErrorKind.notJson => l.errFileNotJson,
      CustomThemeErrorKind.unexpectedStructure => l.errFileUnexpected,
      CustomThemeErrorKind.notATheme => l.cteNotATheme,
      CustomThemeErrorKind.newerVersion => l.errFileNewer,
      CustomThemeErrorKind.missingName => l.cteMissingName,
      CustomThemeErrorKind.invalidColor => l.cteInvalidColor(e.detail ?? ''),
      CustomThemeErrorKind.corrupted => l.cteCorrupted(e.detail ?? ''),
    };

String libraryFileErrorText(AppLocalizations l, LibraryFileException e) =>
    switch (e.kind) {
      LibraryFileErrorKind.notJson => l.errFileNotJson,
      LibraryFileErrorKind.unexpectedStructure => l.errFileUnexpected,
      LibraryFileErrorKind.notALibrary => l.lfNotLibrary,
      LibraryFileErrorKind.newerVersion => l.errFileNewer,
      LibraryFileErrorKind.corrupted => l.lfCorrupted(e.detail ?? ''),
    };

String themeCatalogErrorText(AppLocalizations l, ThemeCatalogException e) =>
    switch (e.kind) {
      ThemeCatalogErrorKind.noConnection => l.tcNoConnection,
      ThemeCatalogErrorKind.badStatus => l.tcStatus(e.status ?? 0),
      ThemeCatalogErrorKind.unexpectedResponse => l.tcUnexpected,
      ThemeCatalogErrorKind.needsNewerApp => l.tcNeedsNewerApp,
      ThemeCatalogErrorKind.tooLarge => l.tcTooLarge,
      ThemeCatalogErrorKind.idMismatch => l.tcMismatch(e.name ?? ''),
      ThemeCatalogErrorKind.invalidTheme =>
        e.cause is CustomThemeException
            ? customThemeErrorText(l, e.cause! as CustomThemeException)
            : l.tcCorrupted,
      ThemeCatalogErrorKind.corrupted => l.tcCorrupted,
    };
