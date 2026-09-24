import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_de.dart';
import 'app_localizations_en.dart';
import 'app_localizations_fr.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('de'),
    Locale('en'),
    Locale('fr'),
  ];

  /// No description provided for @commonCancel.
  ///
  /// In de, this message translates to:
  /// **'Abbrechen'**
  String get commonCancel;

  /// No description provided for @commonSave.
  ///
  /// In de, this message translates to:
  /// **'Speichern'**
  String get commonSave;

  /// No description provided for @commonDelete.
  ///
  /// In de, this message translates to:
  /// **'Löschen'**
  String get commonDelete;

  /// No description provided for @commonDiscard.
  ///
  /// In de, this message translates to:
  /// **'Verwerfen'**
  String get commonDiscard;

  /// No description provided for @commonRetry.
  ///
  /// In de, this message translates to:
  /// **'Erneut versuchen'**
  String get commonRetry;

  /// No description provided for @commonBack.
  ///
  /// In de, this message translates to:
  /// **'Zurück'**
  String get commonBack;

  /// No description provided for @commonDone.
  ///
  /// In de, this message translates to:
  /// **'Fertig'**
  String get commonDone;

  /// No description provided for @commonShare.
  ///
  /// In de, this message translates to:
  /// **'Teilen'**
  String get commonShare;

  /// No description provided for @commonSettings.
  ///
  /// In de, this message translates to:
  /// **'Einstellungen'**
  String get commonSettings;

  /// No description provided for @commonAgain.
  ///
  /// In de, this message translates to:
  /// **'Nochmal'**
  String get commonAgain;

  /// No description provided for @commonDark.
  ///
  /// In de, this message translates to:
  /// **'Dunkel'**
  String get commonDark;

  /// No description provided for @commonLight.
  ///
  /// In de, this message translates to:
  /// **'Hell'**
  String get commonLight;

  /// No description provided for @commonSearch.
  ///
  /// In de, this message translates to:
  /// **'Suchen'**
  String get commonSearch;

  /// No description provided for @commonError.
  ///
  /// In de, this message translates to:
  /// **'Fehler: {error}'**
  String commonError(String error);

  /// No description provided for @commonSaveFailed.
  ///
  /// In de, this message translates to:
  /// **'Speichern fehlgeschlagen: {error}'**
  String commonSaveFailed(String error);

  /// No description provided for @librarySearchHint.
  ///
  /// In de, this message translates to:
  /// **'Titel oder Autor suchen'**
  String get librarySearchHint;

  /// No description provided for @libraryClearTooltip.
  ///
  /// In de, this message translates to:
  /// **'Leeren'**
  String get libraryClearTooltip;

  /// No description provided for @libraryMenuExport.
  ///
  /// In de, this message translates to:
  /// **'Exportieren …'**
  String get libraryMenuExport;

  /// No description provided for @libraryMenuSync.
  ///
  /// In de, this message translates to:
  /// **'Bibliothek sichern / abgleichen …'**
  String get libraryMenuSync;

  /// No description provided for @libraryEmpty.
  ///
  /// In de, this message translates to:
  /// **'Noch keine Bücher.\nLege mit „+“ dein erstes Buch an.'**
  String get libraryEmpty;

  /// No description provided for @libraryEmptyShort.
  ///
  /// In de, this message translates to:
  /// **'Noch keine Bücher.'**
  String get libraryEmptyShort;

  /// No description provided for @libraryNothingFound.
  ///
  /// In de, this message translates to:
  /// **'Nichts gefunden.'**
  String get libraryNothingFound;

  /// No description provided for @libraryResetFilter.
  ///
  /// In de, this message translates to:
  /// **'Filter zurücksetzen'**
  String get libraryResetFilter;

  /// No description provided for @libraryFilterAll.
  ///
  /// In de, this message translates to:
  /// **'Alle'**
  String get libraryFilterAll;

  /// No description provided for @libraryNewBook.
  ///
  /// In de, this message translates to:
  /// **'Neues Buch'**
  String get libraryNewBook;

  /// No description provided for @searchChangeCoverTitle.
  ///
  /// In de, this message translates to:
  /// **'Cover suchen'**
  String get searchChangeCoverTitle;

  /// No description provided for @searchFieldLabel.
  ///
  /// In de, this message translates to:
  /// **'Titel (und ggf. Autor)'**
  String get searchFieldLabel;

  /// No description provided for @searchFieldHelper.
  ///
  /// In de, this message translates to:
  /// **'z.B. „Zauberberg Mann“'**
  String get searchFieldHelper;

  /// No description provided for @searchVoiceTooltip.
  ///
  /// In de, this message translates to:
  /// **'Titel einsprechen'**
  String get searchVoiceTooltip;

  /// No description provided for @bookLanguageLabel.
  ///
  /// In de, this message translates to:
  /// **'Sprache dieses Buchs'**
  String get bookLanguageLabel;

  /// No description provided for @bookLanguageHintNew.
  ///
  /// In de, this message translates to:
  /// **'Für Aufnahmen und Cover-Suche. Lässt sich später ändern.'**
  String get bookLanguageHintNew;

  /// No description provided for @bookLanguageHintEdit.
  ///
  /// In de, this message translates to:
  /// **'Gilt für neue Aufnahmen und die Cover-Suche.'**
  String get bookLanguageHintEdit;

  /// No description provided for @searchWithoutCover.
  ///
  /// In de, this message translates to:
  /// **'Ohne Cover anlegen'**
  String get searchWithoutCover;

  /// No description provided for @searchEnterTitle.
  ///
  /// In de, this message translates to:
  /// **'Titel eingeben, um Cover zu suchen.'**
  String get searchEnterTitle;

  /// No description provided for @searchNothingFound.
  ///
  /// In de, this message translates to:
  /// **'Nichts gefunden. Anderen Titel probieren\noder ohne Cover anlegen.'**
  String get searchNothingFound;

  /// No description provided for @searchFallbackWarning.
  ///
  /// In de, this message translates to:
  /// **'{reason} Treffer stammen nur vom Fallback.'**
  String searchFallbackWarning(String reason);

  /// No description provided for @coverErrNoConnection.
  ///
  /// In de, this message translates to:
  /// **'Keine Verbindung zu {provider}.'**
  String coverErrNoConnection(String provider);

  /// No description provided for @coverErrUnreachable.
  ///
  /// In de, this message translates to:
  /// **'{provider} nicht erreichbar.'**
  String coverErrUnreachable(String provider);

  /// No description provided for @coverErrQuotaNoKey.
  ///
  /// In de, this message translates to:
  /// **'Google Books: Kontingent ohne API-Key erschöpft (Status {status}). Kostenlosen Key in den Einstellungen eintragen.'**
  String coverErrQuotaNoKey(int status);

  /// No description provided for @coverErrKeyRejected.
  ///
  /// In de, this message translates to:
  /// **'Google Books lehnt den API-Key ab oder das Kontingent ist erschöpft (Status {status}).'**
  String coverErrKeyRejected(int status);

  /// No description provided for @coverErrStatus.
  ///
  /// In de, this message translates to:
  /// **'{provider} antwortete mit Status {status}.'**
  String coverErrStatus(String provider, int status);

  /// No description provided for @coverErrUnexpected.
  ///
  /// In de, this message translates to:
  /// **'Unerwartete Antwort von {provider}.'**
  String coverErrUnexpected(String provider);

  /// No description provided for @recMicPermission.
  ///
  /// In de, this message translates to:
  /// **'Mikrofon-Berechtigung fehlt. Bitte in den System-Einstellungen erlauben.'**
  String get recMicPermission;

  /// No description provided for @recCouldNotStart.
  ///
  /// In de, this message translates to:
  /// **'Aufnahme konnte nicht starten: {error}'**
  String recCouldNotStart(String error);

  /// No description provided for @recVeryShortTitle.
  ///
  /// In de, this message translates to:
  /// **'Sehr kurze Aufnahme'**
  String get recVeryShortTitle;

  /// No description provided for @recVeryShortBody.
  ///
  /// In de, this message translates to:
  /// **'Die Aufnahme war unter einer Sekunde. Trotzdem transkribieren?'**
  String get recVeryShortBody;

  /// No description provided for @recTranscribe.
  ///
  /// In de, this message translates to:
  /// **'Transkribieren'**
  String get recTranscribe;

  /// No description provided for @recLanguageChip.
  ///
  /// In de, this message translates to:
  /// **'Aufnahmesprache: {language}'**
  String recLanguageChip(String language);

  /// No description provided for @recLanguageMenuNote.
  ///
  /// In de, this message translates to:
  /// **'Nur für jetzt. Sprache des Buchs: {language}'**
  String recLanguageMenuNote(String language);

  /// No description provided for @recLongHint.
  ///
  /// In de, this message translates to:
  /// **'Lange Aufnahme – Whisper transkribiert alles am Stück.'**
  String get recLongHint;

  /// No description provided for @recFirstHint.
  ///
  /// In de, this message translates to:
  /// **'Sprich z.B.: „{example}“'**
  String recFirstHint(String example);

  /// No description provided for @recStatusIdle.
  ///
  /// In de, this message translates to:
  /// **'Tippen zum Aufnehmen'**
  String get recStatusIdle;

  /// No description provided for @recStatusRecording.
  ///
  /// In de, this message translates to:
  /// **'Aufnahme läuft – tippen zum Beenden'**
  String get recStatusRecording;

  /// No description provided for @recStatusTranscribing.
  ///
  /// In de, this message translates to:
  /// **'Wird transkribiert …'**
  String get recStatusTranscribing;

  /// No description provided for @recStatusError.
  ///
  /// In de, this message translates to:
  /// **'Transkription fehlgeschlagen'**
  String get recStatusError;

  /// No description provided for @recSession.
  ///
  /// In de, this message translates to:
  /// **'Diese Sitzung ({count})'**
  String recSession(int count);

  /// No description provided for @recAllNotes.
  ///
  /// In de, this message translates to:
  /// **'{count, plural, =1{1 Notiz zu diesem Buch} other{{count} Notizen zu diesem Buch}}'**
  String recAllNotes(int count);

  /// No description provided for @recAllNotesLoading.
  ///
  /// In de, this message translates to:
  /// **'Notizen zu diesem Buch'**
  String get recAllNotesLoading;

  /// No description provided for @recKept.
  ///
  /// In de, this message translates to:
  /// **'Die Aufnahme ist noch da.'**
  String get recKept;

  /// No description provided for @recEnterKey.
  ///
  /// In de, this message translates to:
  /// **'API-Key eingeben'**
  String get recEnterKey;

  /// No description provided for @trMissingKey.
  ///
  /// In de, this message translates to:
  /// **'Kein OpenAI-API-Key hinterlegt.'**
  String get trMissingKey;

  /// No description provided for @trUnauthorized.
  ///
  /// In de, this message translates to:
  /// **'API-Key wurde abgelehnt. Bitte in den Einstellungen prüfen.'**
  String get trUnauthorized;

  /// No description provided for @trNetwork.
  ///
  /// In de, this message translates to:
  /// **'Keine Verbindung zur OpenAI-API. Bitte Internetverbindung prüfen.'**
  String get trNetwork;

  /// No description provided for @trRateLimited.
  ///
  /// In de, this message translates to:
  /// **'Kontingent oder Rate-Limit erreicht.'**
  String get trRateLimited;

  /// No description provided for @trInvalidAudio.
  ///
  /// In de, this message translates to:
  /// **'Die Audiodatei fehlt, ist leer oder wurde von der API abgelehnt.'**
  String get trInvalidAudio;

  /// No description provided for @trServer.
  ///
  /// In de, this message translates to:
  /// **'Unerwartete Antwort der OpenAI-API.'**
  String get trServer;

  /// No description provided for @trServerStatus.
  ///
  /// In de, this message translates to:
  /// **'Die OpenAI-API antwortete mit Status {status}.'**
  String trServerStatus(int status);

  /// No description provided for @bdDeleteNoteTitle.
  ///
  /// In de, this message translates to:
  /// **'Notiz löschen?'**
  String get bdDeleteNoteTitle;

  /// No description provided for @bdDeleteBookTitle.
  ///
  /// In de, this message translates to:
  /// **'Buch löschen?'**
  String get bdDeleteBookTitle;

  /// No description provided for @bdDeleteBookBody.
  ///
  /// In de, this message translates to:
  /// **'„{title}“ und alle zugehörigen Notizen werden gelöscht.'**
  String bdDeleteBookBody(String title);

  /// No description provided for @bdSortedByPage.
  ///
  /// In de, this message translates to:
  /// **'Sortiert nach Seite (tippen: chronologisch)'**
  String get bdSortedByPage;

  /// No description provided for @bdSortedChrono.
  ///
  /// In de, this message translates to:
  /// **'Sortiert chronologisch (tippen: nach Seite)'**
  String get bdSortedChrono;

  /// No description provided for @bdExportTooltip.
  ///
  /// In de, this message translates to:
  /// **'Exportieren (Buch, Autor oder Bibliothek)'**
  String get bdExportTooltip;

  /// No description provided for @bdEditBook.
  ///
  /// In de, this message translates to:
  /// **'Titel, Autor, Sprache bearbeiten'**
  String get bdEditBook;

  /// No description provided for @bdMenuRemoveCover.
  ///
  /// In de, this message translates to:
  /// **'Cover entfernen'**
  String get bdMenuRemoveCover;

  /// No description provided for @bdMenuDelete.
  ///
  /// In de, this message translates to:
  /// **'Buch löschen'**
  String get bdMenuDelete;

  /// No description provided for @bdNoNotes.
  ///
  /// In de, this message translates to:
  /// **'Noch keine Notizen zu diesem Buch.'**
  String get bdNoNotes;

  /// No description provided for @bdRecord.
  ///
  /// In de, this message translates to:
  /// **'Aufnehmen'**
  String get bdRecord;

  /// No description provided for @noteNoPage.
  ///
  /// In de, this message translates to:
  /// **'Ohne Seitenangabe'**
  String get noteNoPage;

  /// No description provided for @noteNoText.
  ///
  /// In de, this message translates to:
  /// **'(kein Text erkannt)'**
  String get noteNoText;

  /// No description provided for @noteEditTitle.
  ///
  /// In de, this message translates to:
  /// **'Notiz bearbeiten'**
  String get noteEditTitle;

  /// No description provided for @noteEditPage.
  ///
  /// In de, this message translates to:
  /// **'Seite'**
  String get noteEditPage;

  /// No description provided for @noteEditPageHint.
  ///
  /// In de, this message translates to:
  /// **'47 oder 88f.'**
  String get noteEditPageHint;

  /// No description provided for @noteEditPosition.
  ///
  /// In de, this message translates to:
  /// **'Position'**
  String get noteEditPosition;

  /// No description provided for @noteEditPositionHint.
  ///
  /// In de, this message translates to:
  /// **'oben / Zeile 10'**
  String get noteEditPositionHint;

  /// No description provided for @noteEditText.
  ///
  /// In de, this message translates to:
  /// **'Text'**
  String get noteEditText;

  /// No description provided for @noteEditRaw.
  ///
  /// In de, this message translates to:
  /// **'Original-Transkript'**
  String get noteEditRaw;

  /// No description provided for @bookEditTitle.
  ///
  /// In de, this message translates to:
  /// **'Buch bearbeiten'**
  String get bookEditTitle;

  /// No description provided for @bookEditTitleField.
  ///
  /// In de, this message translates to:
  /// **'Titel'**
  String get bookEditTitleField;

  /// No description provided for @bookEditAuthorField.
  ///
  /// In de, this message translates to:
  /// **'Autor (optional)'**
  String get bookEditAuthorField;

  /// No description provided for @voiceTooltip.
  ///
  /// In de, this message translates to:
  /// **'Per Sprache eingeben'**
  String get voiceTooltip;

  /// No description provided for @voiceStarting.
  ///
  /// In de, this message translates to:
  /// **'Mikrofon startet …'**
  String get voiceStarting;

  /// No description provided for @voiceListening.
  ///
  /// In de, this message translates to:
  /// **'Sprich den Titel …'**
  String get voiceListening;

  /// No description provided for @voiceRecognizing.
  ///
  /// In de, this message translates to:
  /// **'Wird erkannt …'**
  String get voiceRecognizing;

  /// No description provided for @voiceAutoStop.
  ///
  /// In de, this message translates to:
  /// **'stoppt nach kurzer Stille von selbst – oder tippen'**
  String get voiceAutoStop;

  /// No description provided for @voiceNothing.
  ///
  /// In de, this message translates to:
  /// **'Nichts verstanden. Nochmal versuchen.'**
  String get voiceNothing;

  /// No description provided for @syncTitle.
  ///
  /// In de, this message translates to:
  /// **'Bibliothek abgleichen'**
  String get syncTitle;

  /// No description provided for @syncIntro.
  ///
  /// In de, this message translates to:
  /// **'Die Bibliotheksdatei enthält alle Bücher und Notizen. Lege sie z.B. in Google Drive ab und gleiche darüber zwischen deinen Geräten ab.'**
  String get syncIntro;

  /// No description provided for @syncFileHint.
  ///
  /// In de, this message translates to:
  /// **'Schreibt eine Datei mit dem aktuellen Stand – zum Teilen oder direkt in einen Ordner (z.B. Google Drive).'**
  String get syncFileHint;

  /// No description provided for @syncMerge.
  ///
  /// In de, this message translates to:
  /// **'Abgleichen (zusammenführen)'**
  String get syncMerge;

  /// No description provided for @syncMergeHint.
  ///
  /// In de, this message translates to:
  /// **'Vereint Datei und App. Alles, was auf einer Seite noch da ist, bleibt – Löschungen werden hier nicht übertragen.'**
  String get syncMergeHint;

  /// No description provided for @syncMaster.
  ///
  /// In de, this message translates to:
  /// **'Als Vorlage (Master) setzen'**
  String get syncMaster;

  /// No description provided for @syncMasterHint.
  ///
  /// In de, this message translates to:
  /// **'Der einzige Weg, Löschungen zu übertragen. Beim Setzen wählst du weich (lokal Neues bleibt) oder hart (exakt überschreiben).'**
  String get syncMasterHint;

  /// No description provided for @syncSaved.
  ///
  /// In de, this message translates to:
  /// **'Bibliotheksdatei gesichert.'**
  String get syncSaved;

  /// No description provided for @syncSaveFailed.
  ///
  /// In de, this message translates to:
  /// **'Sichern fehlgeschlagen: {error}'**
  String syncSaveFailed(String error);

  /// No description provided for @syncMergeFailed.
  ///
  /// In de, this message translates to:
  /// **'Abgleich fehlgeschlagen: {error}'**
  String syncMergeFailed(String error);

  /// No description provided for @syncFailed.
  ///
  /// In de, this message translates to:
  /// **'Fehlgeschlagen: {error}'**
  String syncFailed(String error);

  /// No description provided for @syncMergedTitle.
  ///
  /// In de, this message translates to:
  /// **'Zusammengeführt'**
  String get syncMergedTitle;

  /// No description provided for @syncBooks.
  ///
  /// In de, this message translates to:
  /// **'Bücher'**
  String get syncBooks;

  /// No description provided for @syncNotes.
  ///
  /// In de, this message translates to:
  /// **'Notizen'**
  String get syncNotes;

  /// No description provided for @syncCountLine.
  ///
  /// In de, this message translates to:
  /// **'{label}: {count}'**
  String syncCountLine(String label, int count);

  /// No description provided for @syncCountLineAdded.
  ///
  /// In de, this message translates to:
  /// **'{label}: {count}  (+{added})'**
  String syncCountLineAdded(String label, int count, int added);

  /// No description provided for @syncSaveUpdated.
  ///
  /// In de, this message translates to:
  /// **'Aktualisierte Datei sichern'**
  String get syncSaveUpdated;

  /// No description provided for @syncUpdatedSaved.
  ///
  /// In de, this message translates to:
  /// **'Aktualisierte Bibliotheksdatei gesichert.'**
  String get syncUpdatedSaved;

  /// No description provided for @syncMasterBody.
  ///
  /// In de, this message translates to:
  /// **'Der aktuelle Stand dieses Geräts wird zur Vorlage. Andere Geräte richten sich beim nächsten Abgleich danach – nur so werden Löschungen übertragen.'**
  String get syncMasterBody;

  /// No description provided for @syncSoft.
  ///
  /// In de, this message translates to:
  /// **'Weich'**
  String get syncSoft;

  /// No description provided for @syncSoftBody.
  ///
  /// In de, this message translates to:
  /// **'Andere Geräte übernehmen den Stand samt Löschungen, behalten aber Einträge, die dort ganz neu sind.'**
  String get syncSoftBody;

  /// No description provided for @syncHard.
  ///
  /// In de, this message translates to:
  /// **'Hart'**
  String get syncHard;

  /// No description provided for @syncHardBody.
  ///
  /// In de, this message translates to:
  /// **'Andere Geräte werden exakt auf diesen Stand gesetzt – alles andere dort wird gelöscht.'**
  String get syncHardBody;

  /// No description provided for @syncSet.
  ///
  /// In de, this message translates to:
  /// **'Setzen'**
  String get syncSet;

  /// No description provided for @syncAdoptedHard.
  ///
  /// In de, this message translates to:
  /// **'Harte Vorlage übernommen: exakt {books} Bücher, {notes} Notizen.'**
  String syncAdoptedHard(int books, int notes);

  /// No description provided for @syncAdoptedSoft.
  ///
  /// In de, this message translates to:
  /// **'Weiche Vorlage übernommen: {books} Bücher, {notes} Notizen.'**
  String syncAdoptedSoft(int books, int notes);

  /// No description provided for @syncMasterSavedHard.
  ///
  /// In de, this message translates to:
  /// **'Als harte Vorlage gesichert. Andere Geräte werden exakt darauf gesetzt.'**
  String get syncMasterSavedHard;

  /// No description provided for @syncMasterSavedSoft.
  ///
  /// In de, this message translates to:
  /// **'Als weiche Vorlage gesichert. Andere Geräte gleichen sich an.'**
  String get syncMasterSavedSoft;

  /// No description provided for @dialogSaveAs.
  ///
  /// In de, this message translates to:
  /// **'Speichern unter'**
  String get dialogSaveAs;

  /// No description provided for @dialogPickLibraryFile.
  ///
  /// In de, this message translates to:
  /// **'Bibliotheksdatei wählen'**
  String get dialogPickLibraryFile;

  /// No description provided for @dialogPickThemeFile.
  ///
  /// In de, this message translates to:
  /// **'Theme-Datei wählen'**
  String get dialogPickThemeFile;

  /// No description provided for @errFileNotJson.
  ///
  /// In de, this message translates to:
  /// **'Die Datei ist kein gültiges JSON.'**
  String get errFileNotJson;

  /// No description provided for @errFileUnexpected.
  ///
  /// In de, this message translates to:
  /// **'Unerwarteter Dateiaufbau.'**
  String get errFileUnexpected;

  /// No description provided for @errFileNewer.
  ///
  /// In de, this message translates to:
  /// **'Die Datei stammt aus einer neueren App-Version.'**
  String get errFileNewer;

  /// No description provided for @lfNotLibrary.
  ///
  /// In de, this message translates to:
  /// **'Das ist keine Booknote-Bibliotheksdatei.'**
  String get lfNotLibrary;

  /// No description provided for @lfCorrupted.
  ///
  /// In de, this message translates to:
  /// **'Die Datei ist beschädigt: {detail}'**
  String lfCorrupted(String detail);

  /// No description provided for @cteNotATheme.
  ///
  /// In de, this message translates to:
  /// **'Das ist keine Booknote-Theme-Datei.'**
  String get cteNotATheme;

  /// No description provided for @cteMissingName.
  ///
  /// In de, this message translates to:
  /// **'Dem Theme fehlt ein Name.'**
  String get cteMissingName;

  /// No description provided for @cteInvalidColor.
  ///
  /// In de, this message translates to:
  /// **'Ungültige Farbe „{hex}“.'**
  String cteInvalidColor(String hex);

  /// No description provided for @cteCorrupted.
  ///
  /// In de, this message translates to:
  /// **'Die Theme-Datei ist beschädigt: {detail}'**
  String cteCorrupted(String detail);

  /// No description provided for @exportTitle.
  ///
  /// In de, this message translates to:
  /// **'Exportieren'**
  String get exportTitle;

  /// No description provided for @exportThisBook.
  ///
  /// In de, this message translates to:
  /// **'Dieses Buch'**
  String get exportThisBook;

  /// No description provided for @exportAuthorBooks.
  ///
  /// In de, this message translates to:
  /// **'Alle Bücher dieses Autors'**
  String get exportAuthorBooks;

  /// No description provided for @exportWholeLibrary.
  ///
  /// In de, this message translates to:
  /// **'Ganze Bibliothek'**
  String get exportWholeLibrary;

  /// No description provided for @exportNothing.
  ///
  /// In de, this message translates to:
  /// **'Nichts zu exportieren.'**
  String get exportNothing;

  /// No description provided for @exportDone.
  ///
  /// In de, this message translates to:
  /// **'{format} exportiert: {file}'**
  String exportDone(String format, String file);

  /// No description provided for @exportSavedFile.
  ///
  /// In de, this message translates to:
  /// **'{format} gespeichert: {file}'**
  String exportSavedFile(String format, String file);

  /// No description provided for @exportFailed.
  ///
  /// In de, this message translates to:
  /// **'Export fehlgeschlagen: {error}'**
  String exportFailed(String error);

  /// No description provided for @exportFormatText.
  ///
  /// In de, this message translates to:
  /// **'Text'**
  String get exportFormatText;

  /// No description provided for @exportLabelNotes.
  ///
  /// In de, this message translates to:
  /// **'Notizen'**
  String get exportLabelNotes;

  /// No description provided for @exportLabelWithoutPage.
  ///
  /// In de, this message translates to:
  /// **'Ohne Seitenangabe'**
  String get exportLabelWithoutPage;

  /// No description provided for @exportLabelNoNotes.
  ///
  /// In de, this message translates to:
  /// **'Keine Notizen mit Seitenangabe'**
  String get exportLabelNoNotes;

  /// No description provided for @exportLabelNoText.
  ///
  /// In de, this message translates to:
  /// **'kein Text'**
  String get exportLabelNoText;

  /// No description provided for @exportLabelLibrary.
  ///
  /// In de, this message translates to:
  /// **'Bibliothek'**
  String get exportLabelLibrary;

  /// No description provided for @settingsLanguageTitle.
  ///
  /// In de, this message translates to:
  /// **'App-Sprache'**
  String get settingsLanguageTitle;

  /// No description provided for @settingsLanguageCaption.
  ///
  /// In de, this message translates to:
  /// **'Menüs und Texte der App. Die Sprache für Aufnahmen legst du für jedes Buch einzeln fest.'**
  String get settingsLanguageCaption;

  /// No description provided for @settingsLanguageDevice.
  ///
  /// In de, this message translates to:
  /// **'Wie das Gerät'**
  String get settingsLanguageDevice;

  /// No description provided for @settingsDisplay.
  ///
  /// In de, this message translates to:
  /// **'Anzeige'**
  String get settingsDisplay;

  /// No description provided for @settingsDisplayCaptionCustom.
  ///
  /// In de, this message translates to:
  /// **'Aktuell überschrieben durch ein eigenes Farbschema (siehe unten).'**
  String get settingsDisplayCaptionCustom;

  /// No description provided for @settingsDisplayCaption.
  ///
  /// In de, this message translates to:
  /// **'Hell/Dunkel automatisch nach System – oder fest gewählt.'**
  String get settingsDisplayCaption;

  /// No description provided for @settingsThemeSystem.
  ///
  /// In de, this message translates to:
  /// **'System'**
  String get settingsThemeSystem;

  /// No description provided for @settingsCleanMode.
  ///
  /// In de, this message translates to:
  /// **'Clean Mode'**
  String get settingsCleanMode;

  /// No description provided for @settingsCleanModeSub.
  ///
  /// In de, this message translates to:
  /// **'Blendet Erklärungen und Hinweise aus – für alle, die die App schon kennen.'**
  String get settingsCleanModeSub;

  /// No description provided for @settingsCustomThemes.
  ///
  /// In de, this message translates to:
  /// **'Eigene Farbschemata'**
  String get settingsCustomThemes;

  /// No description provided for @settingsCustomThemesCaption.
  ///
  /// In de, this message translates to:
  /// **'Ein fester Look statt Hell/Dunkel oben – bis dort wieder System, Hell oder Dunkel gewählt wird.'**
  String get settingsCustomThemesCaption;

  /// No description provided for @settingsNoThemes.
  ///
  /// In de, this message translates to:
  /// **'Noch keine Farbschemata geladen – über „Farbschemata laden“ gibt es welche.'**
  String get settingsNoThemes;

  /// No description provided for @settingsLoadThemes.
  ///
  /// In de, this message translates to:
  /// **'Farbschemata laden'**
  String get settingsLoadThemes;

  /// No description provided for @settingsFromFile.
  ///
  /// In de, this message translates to:
  /// **'Aus Datei …'**
  String get settingsFromFile;

  /// No description provided for @settingsDeleteActiveTheme.
  ///
  /// In de, this message translates to:
  /// **'Aktives Schema löschen'**
  String get settingsDeleteActiveTheme;

  /// No description provided for @settingsThemeLoaded.
  ///
  /// In de, this message translates to:
  /// **'„{name}“ geladen und aktiviert.'**
  String settingsThemeLoaded(String name);

  /// No description provided for @settingsRecording.
  ///
  /// In de, this message translates to:
  /// **'Aufnahme'**
  String get settingsRecording;

  /// No description provided for @settingsVibration.
  ///
  /// In de, this message translates to:
  /// **'Vibration'**
  String get settingsVibration;

  /// No description provided for @settingsVibrationSub.
  ///
  /// In de, this message translates to:
  /// **'Kurzes haptisches Signal beim Start und Stopp.'**
  String get settingsVibrationSub;

  /// No description provided for @settingsApiKeys.
  ///
  /// In de, this message translates to:
  /// **'API-Schlüssel'**
  String get settingsApiKeys;

  /// No description provided for @settingsApiKeysCaption.
  ///
  /// In de, this message translates to:
  /// **'Werden nur auf diesem Gerät gespeichert und beim Abgleich nicht geteilt.'**
  String get settingsApiKeysCaption;

  /// No description provided for @settingsOpenAiLabel.
  ///
  /// In de, this message translates to:
  /// **'OpenAI (Whisper)'**
  String get settingsOpenAiLabel;

  /// No description provided for @settingsOpenAiHelper.
  ///
  /// In de, this message translates to:
  /// **'Pflicht für die Spracherkennung. ~0,006 \$/Min.'**
  String get settingsOpenAiHelper;

  /// No description provided for @settingsShowKey.
  ///
  /// In de, this message translates to:
  /// **'Anzeigen'**
  String get settingsShowKey;

  /// No description provided for @settingsHideKey.
  ///
  /// In de, this message translates to:
  /// **'Verbergen'**
  String get settingsHideKey;

  /// No description provided for @settingsGoogleLabel.
  ///
  /// In de, this message translates to:
  /// **'Google Books (optional)'**
  String get settingsGoogleLabel;

  /// No description provided for @settingsGoogleHelper.
  ///
  /// In de, this message translates to:
  /// **'Macht die Cover-Suche stabiler. Kostenlos.'**
  String get settingsGoogleHelper;

  /// No description provided for @settingsSaveKeys.
  ///
  /// In de, this message translates to:
  /// **'Schlüssel speichern'**
  String get settingsSaveKeys;

  /// No description provided for @settingsKeysSaved.
  ///
  /// In de, this message translates to:
  /// **'API-Schlüssel gespeichert.'**
  String get settingsKeysSaved;

  /// No description provided for @settingsSync.
  ///
  /// In de, this message translates to:
  /// **'Geräte-Abgleich'**
  String get settingsSync;

  /// No description provided for @settingsSyncCaption.
  ///
  /// In de, this message translates to:
  /// **'Beim Abgleich merkt sich die App gelöschte Einträge, damit eine Löschung per „Vorlage (Master)“ auf alle Geräte wirkt.'**
  String get settingsSyncCaption;

  /// No description provided for @settingsForget.
  ///
  /// In de, this message translates to:
  /// **'Alte Löschungen vergessen'**
  String get settingsForget;

  /// No description provided for @settingsForgetOn.
  ///
  /// In de, this message translates to:
  /// **'Nach {days} Tagen. Spart Platz; bei sehr seltenem Abgleich kann ein alt-gelöschter Eintrag dann wieder auftauchen.'**
  String settingsForgetOn(int days);

  /// No description provided for @settingsForgetOff.
  ///
  /// In de, this message translates to:
  /// **'Gelöschte Einträge werden dauerhaft gemerkt.'**
  String get settingsForgetOff;

  /// No description provided for @settingsPeriod.
  ///
  /// In de, this message translates to:
  /// **'Zeitraum'**
  String get settingsPeriod;

  /// No description provided for @settingsDays.
  ///
  /// In de, this message translates to:
  /// **'{days} Tage'**
  String settingsDays(int days);

  /// No description provided for @catReload.
  ///
  /// In de, this message translates to:
  /// **'Katalog neu laden'**
  String get catReload;

  /// No description provided for @catEmpty.
  ///
  /// In de, this message translates to:
  /// **'Der Katalog ist noch leer.'**
  String get catEmpty;

  /// No description provided for @catIntro.
  ///
  /// In de, this message translates to:
  /// **'Aus dem öffentlichen Booknote-Katalog auf GitHub. Ein Tipp auf „Installieren“ lädt das Schema und schaltet es gleich ein.'**
  String get catIntro;

  /// No description provided for @catInstall.
  ///
  /// In de, this message translates to:
  /// **'Installieren'**
  String get catInstall;

  /// No description provided for @catUpdate.
  ///
  /// In de, this message translates to:
  /// **'Aktualisieren'**
  String get catUpdate;

  /// No description provided for @catInstalled.
  ///
  /// In de, this message translates to:
  /// **'Installiert'**
  String get catInstalled;

  /// No description provided for @catInstalledActivated.
  ///
  /// In de, this message translates to:
  /// **'„{name}“ installiert und eingeschaltet.'**
  String catInstalledActivated(String name);

  /// No description provided for @catUpdated.
  ///
  /// In de, this message translates to:
  /// **'„{name}“ aktualisiert.'**
  String catUpdated(String name);

  /// No description provided for @catSaveFailed.
  ///
  /// In de, this message translates to:
  /// **'Speichern auf dem Gerät fehlgeschlagen.'**
  String get catSaveFailed;

  /// No description provided for @tcNoConnection.
  ///
  /// In de, this message translates to:
  /// **'Keine Verbindung zum Katalog – bitte Internetverbindung prüfen.'**
  String get tcNoConnection;

  /// No description provided for @tcStatus.
  ///
  /// In de, this message translates to:
  /// **'Der Katalog antwortete mit Status {status}.'**
  String tcStatus(int status);

  /// No description provided for @tcUnexpected.
  ///
  /// In de, this message translates to:
  /// **'Unerwartete Antwort vom Katalog.'**
  String get tcUnexpected;

  /// No description provided for @tcNeedsNewerApp.
  ///
  /// In de, this message translates to:
  /// **'Der Katalog braucht eine neuere Booknote-Version – bitte die App aktualisieren.'**
  String get tcNeedsNewerApp;

  /// No description provided for @tcTooLarge.
  ///
  /// In de, this message translates to:
  /// **'Die Datei ist ungewöhnlich groß und wurde nicht geladen.'**
  String get tcTooLarge;

  /// No description provided for @tcMismatch.
  ///
  /// In de, this message translates to:
  /// **'Der Katalogeintrag „{name}“ passt nicht zu seiner Datei.'**
  String tcMismatch(String name);

  /// No description provided for @tcCorrupted.
  ///
  /// In de, this message translates to:
  /// **'Die Theme-Datei ist beschädigt.'**
  String get tcCorrupted;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['de', 'en', 'fr'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'de':
      return AppLocalizationsDe();
    case 'en':
      return AppLocalizationsEn();
    case 'fr':
      return AppLocalizationsFr();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
