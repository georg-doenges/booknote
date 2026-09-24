// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get commonCancel => 'Cancel';

  @override
  String get commonSave => 'Save';

  @override
  String get commonDelete => 'Delete';

  @override
  String get commonDiscard => 'Discard';

  @override
  String get commonRetry => 'Try again';

  @override
  String get commonBack => 'Back';

  @override
  String get commonDone => 'Done';

  @override
  String get commonShare => 'Share';

  @override
  String get commonSettings => 'Settings';

  @override
  String get commonAgain => 'Again';

  @override
  String get commonDark => 'Dark';

  @override
  String get commonLight => 'Light';

  @override
  String get commonSearch => 'Search';

  @override
  String commonError(String error) {
    return 'Error: $error';
  }

  @override
  String commonSaveFailed(String error) {
    return 'Saving failed: $error';
  }

  @override
  String get librarySearchHint => 'Search title or author';

  @override
  String get libraryClearTooltip => 'Clear';

  @override
  String get libraryMenuExport => 'Export …';

  @override
  String get libraryMenuSync => 'Back up / sync library …';

  @override
  String get libraryEmpty => 'No books yet.\nTap “+” to add your first book.';

  @override
  String get libraryEmptyShort => 'No books yet.';

  @override
  String get libraryNothingFound => 'Nothing found.';

  @override
  String get libraryResetFilter => 'Reset filter';

  @override
  String get libraryFilterAll => 'All';

  @override
  String get libraryNewBook => 'New book';

  @override
  String get searchChangeCoverTitle => 'Find cover';

  @override
  String get searchFieldLabel => 'Title (and author, if you like)';

  @override
  String get searchFieldHelper => 'e.g. “Magic Mountain Mann”';

  @override
  String get searchVoiceTooltip => 'Speak the title';

  @override
  String get bookLanguageLabel => 'Language of this book';

  @override
  String get bookLanguageHintNew =>
      'Used for recordings and cover search. You can change it later.';

  @override
  String get bookLanguageHintEdit =>
      'Applies to new recordings and cover search.';

  @override
  String get searchWithoutCover => 'Add without cover';

  @override
  String get searchEnterTitle => 'Enter a title to search for covers.';

  @override
  String get searchNothingFound =>
      'Nothing found. Try another title\nor add without a cover.';

  @override
  String searchFallbackWarning(String reason) {
    return '$reason Results come from the fallback source only.';
  }

  @override
  String coverErrNoConnection(String provider) {
    return 'No connection to $provider.';
  }

  @override
  String coverErrUnreachable(String provider) {
    return '$provider is not reachable.';
  }

  @override
  String coverErrQuotaNoKey(int status) {
    return 'Google Books: quota without an API key used up (status $status). Enter a free key in the settings.';
  }

  @override
  String coverErrKeyRejected(int status) {
    return 'Google Books rejects the API key or the quota is used up (status $status).';
  }

  @override
  String coverErrStatus(String provider, int status) {
    return '$provider answered with status $status.';
  }

  @override
  String coverErrUnexpected(String provider) {
    return 'Unexpected response from $provider.';
  }

  @override
  String get recMicPermission =>
      'Microphone permission is missing. Please allow it in the system settings.';

  @override
  String recCouldNotStart(String error) {
    return 'Recording could not start: $error';
  }

  @override
  String get recVeryShortTitle => 'Very short recording';

  @override
  String get recVeryShortBody =>
      'The recording was under one second. Transcribe it anyway?';

  @override
  String get recTranscribe => 'Transcribe';

  @override
  String recLanguageChip(String language) {
    return 'Recording language: $language';
  }

  @override
  String recLanguageMenuNote(String language) {
    return 'Just for now. Book language: $language';
  }

  @override
  String get recLongHint =>
      'Long recording – Whisper transcribes everything in one go.';

  @override
  String recFirstHint(String example) {
    return 'Say e.g.: “$example”';
  }

  @override
  String get recStatusIdle => 'Tap to record';

  @override
  String get recStatusRecording => 'Recording – tap to stop';

  @override
  String get recStatusTranscribing => 'Transcribing …';

  @override
  String get recStatusError => 'Transcription failed';

  @override
  String recSession(int count) {
    return 'This session ($count)';
  }

  @override
  String recAllNotes(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count notes for this book',
      one: '1 note for this book',
    );
    return '$_temp0';
  }

  @override
  String get recAllNotesLoading => 'Notes for this book';

  @override
  String get recKept => 'The recording is still there.';

  @override
  String get recEnterKey => 'Enter API key';

  @override
  String get trMissingKey => 'No OpenAI API key stored.';

  @override
  String get trUnauthorized =>
      'The API key was rejected. Please check it in the settings.';

  @override
  String get trNetwork =>
      'No connection to the OpenAI API. Please check your internet connection.';

  @override
  String get trRateLimited => 'Quota or rate limit reached.';

  @override
  String get trInvalidAudio =>
      'The audio file is missing, empty or was rejected by the API.';

  @override
  String get trServer => 'Unexpected response from the OpenAI API.';

  @override
  String trServerStatus(int status) {
    return 'The OpenAI API answered with status $status.';
  }

  @override
  String get bdDeleteNoteTitle => 'Delete note?';

  @override
  String get bdDeleteBookTitle => 'Delete book?';

  @override
  String bdDeleteBookBody(String title) {
    return '“$title” and all its notes will be deleted.';
  }

  @override
  String get bdSortedByPage => 'Sorted by page (tap: chronological)';

  @override
  String get bdSortedChrono => 'Sorted chronologically (tap: by page)';

  @override
  String get bdExportTooltip => 'Export (book, author or library)';

  @override
  String get bdMenuEdit => 'Edit title / author';

  @override
  String get bdMenuRemoveCover => 'Remove cover';

  @override
  String get bdMenuDelete => 'Delete book';

  @override
  String get bdNoNotes => 'No notes for this book yet.';

  @override
  String get bdRecord => 'Record';

  @override
  String get noteNoPage => 'No page';

  @override
  String get noteNoText => '(no text recognised)';

  @override
  String get noteEditTitle => 'Edit note';

  @override
  String get noteEditPage => 'Page';

  @override
  String get noteEditPageHint => '47 or 88f.';

  @override
  String get noteEditPosition => 'Position';

  @override
  String get noteEditPositionHint => 'top / line 10';

  @override
  String get noteEditText => 'Text';

  @override
  String get noteEditRaw => 'Original transcript';

  @override
  String get bookEditTitle => 'Edit book';

  @override
  String get bookEditTitleField => 'Title';

  @override
  String get bookEditAuthorField => 'Author (optional)';

  @override
  String get voiceTooltip => 'Enter by voice';

  @override
  String get voiceStarting => 'Starting microphone …';

  @override
  String get voiceListening => 'Say the title …';

  @override
  String get voiceRecognizing => 'Recognising …';

  @override
  String get voiceAutoStop => 'stops by itself after a short silence – or tap';

  @override
  String get voiceNothing => 'Didn’t catch that. Try again.';

  @override
  String get syncTitle => 'Sync library';

  @override
  String get syncIntro =>
      'The library file contains all books and notes. Put it in Google Drive, for example, and sync your devices through it.';

  @override
  String get syncFileHint =>
      'Writes a file with the current state – to share or to save straight into a folder (e.g. Google Drive).';

  @override
  String get syncMerge => 'Sync (merge)';

  @override
  String get syncMergeHint =>
      'Combines file and app. Everything that still exists on one side is kept – deletions are not transferred here.';

  @override
  String get syncMaster => 'Set as template (master)';

  @override
  String get syncMasterHint =>
      'The only way to transfer deletions. When setting it you choose soft (local additions are kept) or hard (overwrite exactly).';

  @override
  String get syncSaved => 'Library file saved.';

  @override
  String syncSaveFailed(String error) {
    return 'Saving failed: $error';
  }

  @override
  String syncMergeFailed(String error) {
    return 'Sync failed: $error';
  }

  @override
  String syncFailed(String error) {
    return 'Failed: $error';
  }

  @override
  String get syncMergedTitle => 'Merged';

  @override
  String get syncBooks => 'Books';

  @override
  String get syncNotes => 'Notes';

  @override
  String syncCountLine(String label, int count) {
    return '$label: $count';
  }

  @override
  String syncCountLineAdded(String label, int count, int added) {
    return '$label: $count  (+$added)';
  }

  @override
  String get syncSaveUpdated => 'Save updated file';

  @override
  String get syncUpdatedSaved => 'Updated library file saved.';

  @override
  String get syncMasterBody =>
      'This device’s current state becomes the template. Other devices follow it at their next sync – this is the only way deletions are transferred.';

  @override
  String get syncSoft => 'Soft';

  @override
  String get syncSoftBody =>
      'Other devices adopt the state including deletions, but keep entries that are brand new there.';

  @override
  String get syncHard => 'Hard';

  @override
  String get syncHardBody =>
      'Other devices are set to exactly this state – everything else there is deleted.';

  @override
  String get syncSet => 'Set';

  @override
  String syncAdoptedHard(int books, int notes) {
    return 'Hard template adopted: exactly $books books, $notes notes.';
  }

  @override
  String syncAdoptedSoft(int books, int notes) {
    return 'Soft template adopted: $books books, $notes notes.';
  }

  @override
  String get syncMasterSavedHard =>
      'Saved as hard template. Other devices will be set to exactly this state.';

  @override
  String get syncMasterSavedSoft =>
      'Saved as soft template. Other devices will align with it.';

  @override
  String get dialogSaveAs => 'Save as';

  @override
  String get dialogPickLibraryFile => 'Choose library file';

  @override
  String get dialogPickThemeFile => 'Choose theme file';

  @override
  String get errFileNotJson => 'The file is not valid JSON.';

  @override
  String get errFileUnexpected => 'Unexpected file structure.';

  @override
  String get errFileNewer => 'The file comes from a newer app version.';

  @override
  String get lfNotLibrary => 'This is not a Booknote library file.';

  @override
  String lfCorrupted(String detail) {
    return 'The file is damaged: $detail';
  }

  @override
  String get cteNotATheme => 'This is not a Booknote theme file.';

  @override
  String get cteMissingName => 'The theme has no name.';

  @override
  String cteInvalidColor(String hex) {
    return 'Invalid colour “$hex”.';
  }

  @override
  String cteCorrupted(String detail) {
    return 'The theme file is damaged: $detail';
  }

  @override
  String get exportTitle => 'Export';

  @override
  String get exportThisBook => 'This book';

  @override
  String get exportAuthorBooks => 'All books by this author';

  @override
  String get exportWholeLibrary => 'Whole library';

  @override
  String get exportNothing => 'Nothing to export.';

  @override
  String exportDone(String format, String file) {
    return '$format exported: $file';
  }

  @override
  String exportSavedFile(String format, String file) {
    return '$format saved: $file';
  }

  @override
  String exportFailed(String error) {
    return 'Export failed: $error';
  }

  @override
  String get exportFormatText => 'Text';

  @override
  String get exportLabelNotes => 'Notes';

  @override
  String get exportLabelWithoutPage => 'Without page number';

  @override
  String get exportLabelNoNotes => 'No notes with a page number';

  @override
  String get exportLabelNoText => 'no text';

  @override
  String get exportLabelLibrary => 'Library';

  @override
  String get settingsLanguageTitle => 'App language';

  @override
  String get settingsLanguageCaption =>
      'Menus and texts of the app. You set the language for recordings separately for each book.';

  @override
  String get settingsLanguageDevice => 'Same as device';

  @override
  String get settingsDisplay => 'Display';

  @override
  String get settingsDisplayCaptionCustom =>
      'Currently overridden by a custom colour scheme (see below).';

  @override
  String get settingsDisplayCaption =>
      'Light/dark follows the system – or pick one.';

  @override
  String get settingsThemeSystem => 'System';

  @override
  String get settingsCleanMode => 'Clean mode';

  @override
  String get settingsCleanModeSub =>
      'Hides explanations and hints – for people who already know the app.';

  @override
  String get settingsCustomThemes => 'Colour schemes';

  @override
  String get settingsCustomThemesCaption =>
      'A fixed look instead of light/dark above – until System, Light or Dark is chosen there again.';

  @override
  String get settingsNoThemes =>
      'No colour schemes loaded yet – “Load colour schemes” has some.';

  @override
  String get settingsLoadThemes => 'Load colour schemes';

  @override
  String get settingsFromFile => 'From file …';

  @override
  String get settingsDeleteActiveTheme => 'Delete active scheme';

  @override
  String settingsThemeLoaded(String name) {
    return '“$name” loaded and activated.';
  }

  @override
  String get settingsRecording => 'Recording';

  @override
  String get settingsVibration => 'Vibration';

  @override
  String get settingsVibrationSub => 'Short haptic signal on start and stop.';

  @override
  String get settingsApiKeys => 'API keys';

  @override
  String get settingsApiKeysCaption =>
      'Stored only on this device and not shared when syncing.';

  @override
  String get settingsOpenAiLabel => 'OpenAI (Whisper)';

  @override
  String get settingsOpenAiHelper =>
      'Required for speech recognition. About \$0.006/min.';

  @override
  String get settingsShowKey => 'Show';

  @override
  String get settingsHideKey => 'Hide';

  @override
  String get settingsGoogleLabel => 'Google Books (optional)';

  @override
  String get settingsGoogleHelper => 'Makes cover search more reliable. Free.';

  @override
  String get settingsSaveKeys => 'Save keys';

  @override
  String get settingsKeysSaved => 'API keys saved.';

  @override
  String get settingsSync => 'Device sync';

  @override
  String get settingsSyncCaption =>
      'When syncing, the app remembers deleted entries so that a deletion made with “Template (master)” reaches all devices.';

  @override
  String get settingsForget => 'Forget old deletions';

  @override
  String settingsForgetOn(int days) {
    return 'After $days days. Saves space; with very infrequent syncing an entry deleted long ago may then reappear.';
  }

  @override
  String get settingsForgetOff => 'Deleted entries are remembered permanently.';

  @override
  String get settingsPeriod => 'Period';

  @override
  String settingsDays(int days) {
    return '$days days';
  }

  @override
  String get catReload => 'Reload catalogue';

  @override
  String get catEmpty => 'The catalogue is still empty.';

  @override
  String get catIntro =>
      'From the public Booknote catalogue on GitHub. Tapping “Install” downloads the scheme and switches it on right away.';

  @override
  String get catInstall => 'Install';

  @override
  String get catUpdate => 'Update';

  @override
  String get catInstalled => 'Installed';

  @override
  String catInstalledActivated(String name) {
    return '“$name” installed and switched on.';
  }

  @override
  String catUpdated(String name) {
    return '“$name” updated.';
  }

  @override
  String get catSaveFailed => 'Saving on the device failed.';

  @override
  String get tcNoConnection =>
      'No connection to the catalogue – please check your internet connection.';

  @override
  String tcStatus(int status) {
    return 'The catalogue answered with status $status.';
  }

  @override
  String get tcUnexpected => 'Unexpected response from the catalogue.';

  @override
  String get tcNeedsNewerApp =>
      'The catalogue needs a newer Booknote version – please update the app.';

  @override
  String get tcTooLarge => 'The file is unusually large and was not loaded.';

  @override
  String tcMismatch(String name) {
    return 'The catalogue entry “$name” does not match its file.';
  }

  @override
  String get tcCorrupted => 'The theme file is damaged.';
}
