// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for German (`de`).
class AppLocalizationsDe extends AppLocalizations {
  AppLocalizationsDe([String locale = 'de']) : super(locale);

  @override
  String get commonCancel => 'Abbrechen';

  @override
  String get commonSave => 'Speichern';

  @override
  String get commonDelete => 'Löschen';

  @override
  String get commonDiscard => 'Verwerfen';

  @override
  String get commonRetry => 'Erneut versuchen';

  @override
  String get commonBack => 'Zurück';

  @override
  String get commonDone => 'Fertig';

  @override
  String get commonShare => 'Teilen';

  @override
  String get commonSettings => 'Einstellungen';

  @override
  String get commonAgain => 'Nochmal';

  @override
  String get commonDark => 'Dunkel';

  @override
  String get commonLight => 'Hell';

  @override
  String get commonSearch => 'Suchen';

  @override
  String commonError(String error) {
    return 'Fehler: $error';
  }

  @override
  String commonSaveFailed(String error) {
    return 'Speichern fehlgeschlagen: $error';
  }

  @override
  String get librarySearchHint => 'Titel oder Autor suchen';

  @override
  String get libraryClearTooltip => 'Leeren';

  @override
  String get libraryMenuExport => 'Exportieren …';

  @override
  String get libraryMenuSync => 'Bibliothek sichern / abgleichen …';

  @override
  String get libraryEmpty =>
      'Noch keine Bücher.\nLege mit „+“ dein erstes Buch an.';

  @override
  String get libraryEmptyShort => 'Noch keine Bücher.';

  @override
  String get libraryNothingFound => 'Nichts gefunden.';

  @override
  String get libraryResetFilter => 'Filter zurücksetzen';

  @override
  String get libraryFilterAll => 'Alle';

  @override
  String get libraryNewBook => 'Neues Buch';

  @override
  String get searchChangeCoverTitle => 'Cover suchen';

  @override
  String get searchFieldLabel => 'Titel (und ggf. Autor)';

  @override
  String get searchFieldHelper => 'z.B. „Zauberberg Mann“';

  @override
  String get searchVoiceTooltip => 'Titel einsprechen';

  @override
  String get bookLanguageLabel => 'Sprache dieses Buchs';

  @override
  String get bookLanguageHintNew =>
      'Für Aufnahmen und Cover-Suche. Lässt sich später ändern.';

  @override
  String get bookLanguageHintEdit =>
      'Gilt für neue Aufnahmen und die Cover-Suche.';

  @override
  String get searchWithoutCover => 'Ohne Cover anlegen';

  @override
  String get searchEnterTitle => 'Titel eingeben, um Cover zu suchen.';

  @override
  String get searchNothingFound =>
      'Nichts gefunden. Anderen Titel probieren\noder ohne Cover anlegen.';

  @override
  String searchFallbackWarning(String reason) {
    return '$reason Treffer stammen nur vom Fallback.';
  }

  @override
  String coverErrNoConnection(String provider) {
    return 'Keine Verbindung zu $provider.';
  }

  @override
  String coverErrUnreachable(String provider) {
    return '$provider nicht erreichbar.';
  }

  @override
  String coverErrQuotaNoKey(int status) {
    return 'Google Books: Kontingent ohne API-Key erschöpft (Status $status). Kostenlosen Key in den Einstellungen eintragen.';
  }

  @override
  String coverErrKeyRejected(int status) {
    return 'Google Books lehnt den API-Key ab oder das Kontingent ist erschöpft (Status $status).';
  }

  @override
  String coverErrStatus(String provider, int status) {
    return '$provider antwortete mit Status $status.';
  }

  @override
  String coverErrUnexpected(String provider) {
    return 'Unerwartete Antwort von $provider.';
  }

  @override
  String get recMicPermission =>
      'Mikrofon-Berechtigung fehlt. Bitte in den System-Einstellungen erlauben.';

  @override
  String recCouldNotStart(String error) {
    return 'Aufnahme konnte nicht starten: $error';
  }

  @override
  String get recVeryShortTitle => 'Sehr kurze Aufnahme';

  @override
  String get recVeryShortBody =>
      'Die Aufnahme war unter einer Sekunde. Trotzdem transkribieren?';

  @override
  String get recTranscribe => 'Transkribieren';

  @override
  String recLanguageChip(String language) {
    return 'Aufnahmesprache: $language';
  }

  @override
  String recLanguageMenuNote(String language) {
    return 'Nur für jetzt. Sprache des Buchs: $language';
  }

  @override
  String get recLongHint =>
      'Lange Aufnahme – Whisper transkribiert alles am Stück.';

  @override
  String recFirstHint(String example) {
    return 'Sprich z.B.: „$example“';
  }

  @override
  String get recStatusIdle => 'Tippen zum Aufnehmen';

  @override
  String get recStatusRecording => 'Aufnahme läuft – tippen zum Beenden';

  @override
  String get recStatusTranscribing => 'Wird transkribiert …';

  @override
  String get recStatusError => 'Transkription fehlgeschlagen';

  @override
  String recSession(int count) {
    return 'Diese Sitzung ($count)';
  }

  @override
  String recAllNotes(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Notizen zu diesem Buch',
      one: '1 Notiz zu diesem Buch',
    );
    return '$_temp0';
  }

  @override
  String get recAllNotesLoading => 'Notizen zu diesem Buch';

  @override
  String get recKept => 'Die Aufnahme ist noch da.';

  @override
  String get recEnterKey => 'API-Key eingeben';

  @override
  String get trMissingKey => 'Kein OpenAI-API-Key hinterlegt.';

  @override
  String get trUnauthorized =>
      'API-Key wurde abgelehnt. Bitte in den Einstellungen prüfen.';

  @override
  String get trNetwork =>
      'Keine Verbindung zur OpenAI-API. Bitte Internetverbindung prüfen.';

  @override
  String get trRateLimited => 'Kontingent oder Rate-Limit erreicht.';

  @override
  String get trInvalidAudio =>
      'Die Audiodatei fehlt, ist leer oder wurde von der API abgelehnt.';

  @override
  String get trServer => 'Unerwartete Antwort der OpenAI-API.';

  @override
  String trServerStatus(int status) {
    return 'Die OpenAI-API antwortete mit Status $status.';
  }

  @override
  String get bdDeleteNoteTitle => 'Notiz löschen?';

  @override
  String get bdDeleteBookTitle => 'Buch löschen?';

  @override
  String bdDeleteBookBody(String title) {
    return '„$title“ und alle zugehörigen Notizen werden gelöscht.';
  }

  @override
  String get bdSortedByPage => 'Sortiert nach Seite (tippen: chronologisch)';

  @override
  String get bdSortedChrono => 'Sortiert chronologisch (tippen: nach Seite)';

  @override
  String get bdExportTooltip => 'Exportieren (Buch, Autor oder Bibliothek)';

  @override
  String get bdMenuEdit => 'Titel / Autor bearbeiten';

  @override
  String get bdMenuRemoveCover => 'Cover entfernen';

  @override
  String get bdMenuDelete => 'Buch löschen';

  @override
  String get bdNoNotes => 'Noch keine Notizen zu diesem Buch.';

  @override
  String get bdRecord => 'Aufnehmen';

  @override
  String get noteNoPage => 'Ohne Seitenangabe';

  @override
  String get noteNoText => '(kein Text erkannt)';

  @override
  String get noteEditTitle => 'Notiz bearbeiten';

  @override
  String get noteEditPage => 'Seite';

  @override
  String get noteEditPageHint => '47 oder 88f.';

  @override
  String get noteEditPosition => 'Position';

  @override
  String get noteEditPositionHint => 'oben / Zeile 10';

  @override
  String get noteEditText => 'Text';

  @override
  String get noteEditRaw => 'Original-Transkript';

  @override
  String get bookEditTitle => 'Buch bearbeiten';

  @override
  String get bookEditTitleField => 'Titel';

  @override
  String get bookEditAuthorField => 'Autor (optional)';

  @override
  String get voiceTooltip => 'Per Sprache eingeben';

  @override
  String get voiceStarting => 'Mikrofon startet …';

  @override
  String get voiceListening => 'Sprich den Titel …';

  @override
  String get voiceRecognizing => 'Wird erkannt …';

  @override
  String get voiceAutoStop =>
      'stoppt nach kurzer Stille von selbst – oder tippen';

  @override
  String get voiceNothing => 'Nichts verstanden. Nochmal versuchen.';

  @override
  String get syncTitle => 'Bibliothek abgleichen';

  @override
  String get syncIntro =>
      'Die Bibliotheksdatei enthält alle Bücher und Notizen. Lege sie z.B. in Google Drive ab und gleiche darüber zwischen deinen Geräten ab.';

  @override
  String get syncFileHint =>
      'Schreibt eine Datei mit dem aktuellen Stand – zum Teilen oder direkt in einen Ordner (z.B. Google Drive).';

  @override
  String get syncMerge => 'Abgleichen (zusammenführen)';

  @override
  String get syncMergeHint =>
      'Vereint Datei und App. Alles, was auf einer Seite noch da ist, bleibt – Löschungen werden hier nicht übertragen.';

  @override
  String get syncMaster => 'Als Vorlage (Master) setzen';

  @override
  String get syncMasterHint =>
      'Der einzige Weg, Löschungen zu übertragen. Beim Setzen wählst du weich (lokal Neues bleibt) oder hart (exakt überschreiben).';

  @override
  String get syncSaved => 'Bibliotheksdatei gesichert.';

  @override
  String syncSaveFailed(String error) {
    return 'Sichern fehlgeschlagen: $error';
  }

  @override
  String syncMergeFailed(String error) {
    return 'Abgleich fehlgeschlagen: $error';
  }

  @override
  String syncFailed(String error) {
    return 'Fehlgeschlagen: $error';
  }

  @override
  String get syncMergedTitle => 'Zusammengeführt';

  @override
  String get syncBooks => 'Bücher';

  @override
  String get syncNotes => 'Notizen';

  @override
  String syncCountLine(String label, int count) {
    return '$label: $count';
  }

  @override
  String syncCountLineAdded(String label, int count, int added) {
    return '$label: $count  (+$added)';
  }

  @override
  String get syncSaveUpdated => 'Aktualisierte Datei sichern';

  @override
  String get syncUpdatedSaved => 'Aktualisierte Bibliotheksdatei gesichert.';

  @override
  String get syncMasterBody =>
      'Der aktuelle Stand dieses Geräts wird zur Vorlage. Andere Geräte richten sich beim nächsten Abgleich danach – nur so werden Löschungen übertragen.';

  @override
  String get syncSoft => 'Weich';

  @override
  String get syncSoftBody =>
      'Andere Geräte übernehmen den Stand samt Löschungen, behalten aber Einträge, die dort ganz neu sind.';

  @override
  String get syncHard => 'Hart';

  @override
  String get syncHardBody =>
      'Andere Geräte werden exakt auf diesen Stand gesetzt – alles andere dort wird gelöscht.';

  @override
  String get syncSet => 'Setzen';

  @override
  String syncAdoptedHard(int books, int notes) {
    return 'Harte Vorlage übernommen: exakt $books Bücher, $notes Notizen.';
  }

  @override
  String syncAdoptedSoft(int books, int notes) {
    return 'Weiche Vorlage übernommen: $books Bücher, $notes Notizen.';
  }

  @override
  String get syncMasterSavedHard =>
      'Als harte Vorlage gesichert. Andere Geräte werden exakt darauf gesetzt.';

  @override
  String get syncMasterSavedSoft =>
      'Als weiche Vorlage gesichert. Andere Geräte gleichen sich an.';

  @override
  String get dialogSaveAs => 'Speichern unter';

  @override
  String get dialogPickLibraryFile => 'Bibliotheksdatei wählen';

  @override
  String get dialogPickThemeFile => 'Theme-Datei wählen';

  @override
  String get errFileNotJson => 'Die Datei ist kein gültiges JSON.';

  @override
  String get errFileUnexpected => 'Unerwarteter Dateiaufbau.';

  @override
  String get errFileNewer => 'Die Datei stammt aus einer neueren App-Version.';

  @override
  String get lfNotLibrary => 'Das ist keine Booknote-Bibliotheksdatei.';

  @override
  String lfCorrupted(String detail) {
    return 'Die Datei ist beschädigt: $detail';
  }

  @override
  String get cteNotATheme => 'Das ist keine Booknote-Theme-Datei.';

  @override
  String get cteMissingName => 'Dem Theme fehlt ein Name.';

  @override
  String cteInvalidColor(String hex) {
    return 'Ungültige Farbe „$hex“.';
  }

  @override
  String cteCorrupted(String detail) {
    return 'Die Theme-Datei ist beschädigt: $detail';
  }

  @override
  String get exportTitle => 'Exportieren';

  @override
  String get exportThisBook => 'Dieses Buch';

  @override
  String get exportAuthorBooks => 'Alle Bücher dieses Autors';

  @override
  String get exportWholeLibrary => 'Ganze Bibliothek';

  @override
  String get exportNothing => 'Nichts zu exportieren.';

  @override
  String exportDone(String format, String file) {
    return '$format exportiert: $file';
  }

  @override
  String exportSavedFile(String format, String file) {
    return '$format gespeichert: $file';
  }

  @override
  String exportFailed(String error) {
    return 'Export fehlgeschlagen: $error';
  }

  @override
  String get exportFormatText => 'Text';

  @override
  String get exportLabelNotes => 'Notizen';

  @override
  String get exportLabelWithoutPage => 'Ohne Seitenangabe';

  @override
  String get exportLabelNoNotes => 'Keine Notizen mit Seitenangabe';

  @override
  String get exportLabelNoText => 'kein Text';

  @override
  String get exportLabelLibrary => 'Bibliothek';

  @override
  String get settingsLanguageTitle => 'App-Sprache';

  @override
  String get settingsLanguageCaption =>
      'Menüs und Texte der App. Die Sprache für Aufnahmen legst du für jedes Buch einzeln fest.';

  @override
  String get settingsLanguageDevice => 'Wie das Gerät';

  @override
  String get settingsDisplay => 'Anzeige';

  @override
  String get settingsDisplayCaptionCustom =>
      'Aktuell überschrieben durch ein eigenes Farbschema (siehe unten).';

  @override
  String get settingsDisplayCaption =>
      'Hell/Dunkel automatisch nach System – oder fest gewählt.';

  @override
  String get settingsThemeSystem => 'System';

  @override
  String get settingsCleanMode => 'Clean Mode';

  @override
  String get settingsCleanModeSub =>
      'Blendet Erklärungen und Hinweise aus – für alle, die die App schon kennen.';

  @override
  String get settingsCustomThemes => 'Eigene Farbschemata';

  @override
  String get settingsCustomThemesCaption =>
      'Ein fester Look statt Hell/Dunkel oben – bis dort wieder System, Hell oder Dunkel gewählt wird.';

  @override
  String get settingsNoThemes =>
      'Noch keine Farbschemata geladen – über „Farbschemata laden“ gibt es welche.';

  @override
  String get settingsLoadThemes => 'Farbschemata laden';

  @override
  String get settingsFromFile => 'Aus Datei …';

  @override
  String get settingsDeleteActiveTheme => 'Aktives Schema löschen';

  @override
  String settingsThemeLoaded(String name) {
    return '„$name“ geladen und aktiviert.';
  }

  @override
  String get settingsRecording => 'Aufnahme';

  @override
  String get settingsVibration => 'Vibration';

  @override
  String get settingsVibrationSub =>
      'Kurzes haptisches Signal beim Start und Stopp.';

  @override
  String get settingsApiKeys => 'API-Schlüssel';

  @override
  String get settingsApiKeysCaption =>
      'Werden nur auf diesem Gerät gespeichert und beim Abgleich nicht geteilt.';

  @override
  String get settingsOpenAiLabel => 'OpenAI (Whisper)';

  @override
  String get settingsOpenAiHelper =>
      'Pflicht für die Spracherkennung. ~0,006 \$/Min.';

  @override
  String get settingsShowKey => 'Anzeigen';

  @override
  String get settingsHideKey => 'Verbergen';

  @override
  String get settingsGoogleLabel => 'Google Books (optional)';

  @override
  String get settingsGoogleHelper =>
      'Macht die Cover-Suche stabiler. Kostenlos.';

  @override
  String get settingsSaveKeys => 'Schlüssel speichern';

  @override
  String get settingsKeysSaved => 'API-Schlüssel gespeichert.';

  @override
  String get settingsSync => 'Geräte-Abgleich';

  @override
  String get settingsSyncCaption =>
      'Beim Abgleich merkt sich die App gelöschte Einträge, damit eine Löschung per „Vorlage (Master)“ auf alle Geräte wirkt.';

  @override
  String get settingsForget => 'Alte Löschungen vergessen';

  @override
  String settingsForgetOn(int days) {
    return 'Nach $days Tagen. Spart Platz; bei sehr seltenem Abgleich kann ein alt-gelöschter Eintrag dann wieder auftauchen.';
  }

  @override
  String get settingsForgetOff =>
      'Gelöschte Einträge werden dauerhaft gemerkt.';

  @override
  String get settingsPeriod => 'Zeitraum';

  @override
  String settingsDays(int days) {
    return '$days Tage';
  }

  @override
  String get catReload => 'Katalog neu laden';

  @override
  String get catEmpty => 'Der Katalog ist noch leer.';

  @override
  String get catIntro =>
      'Aus dem öffentlichen Booknote-Katalog auf GitHub. Ein Tipp auf „Installieren“ lädt das Schema und schaltet es gleich ein.';

  @override
  String get catInstall => 'Installieren';

  @override
  String get catUpdate => 'Aktualisieren';

  @override
  String get catInstalled => 'Installiert';

  @override
  String catInstalledActivated(String name) {
    return '„$name“ installiert und eingeschaltet.';
  }

  @override
  String catUpdated(String name) {
    return '„$name“ aktualisiert.';
  }

  @override
  String get catSaveFailed => 'Speichern auf dem Gerät fehlgeschlagen.';

  @override
  String get tcNoConnection =>
      'Keine Verbindung zum Katalog – bitte Internetverbindung prüfen.';

  @override
  String tcStatus(int status) {
    return 'Der Katalog antwortete mit Status $status.';
  }

  @override
  String get tcUnexpected => 'Unerwartete Antwort vom Katalog.';

  @override
  String get tcNeedsNewerApp =>
      'Der Katalog braucht eine neuere Booknote-Version – bitte die App aktualisieren.';

  @override
  String get tcTooLarge =>
      'Die Datei ist ungewöhnlich groß und wurde nicht geladen.';

  @override
  String tcMismatch(String name) {
    return 'Der Katalogeintrag „$name“ passt nicht zu seiner Datei.';
  }

  @override
  String get tcCorrupted => 'Die Theme-Datei ist beschädigt.';
}
