// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class AppLocalizationsFr extends AppLocalizations {
  AppLocalizationsFr([String locale = 'fr']) : super(locale);

  @override
  String get commonCancel => 'Annuler';

  @override
  String get commonSave => 'Enregistrer';

  @override
  String get commonDelete => 'Supprimer';

  @override
  String get commonDiscard => 'Abandonner';

  @override
  String get commonRetry => 'Réessayer';

  @override
  String get commonBack => 'Retour';

  @override
  String get commonDone => 'Terminé';

  @override
  String get commonShare => 'Partager';

  @override
  String get commonSettings => 'Paramètres';

  @override
  String get commonAgain => 'Encore';

  @override
  String get commonDark => 'Sombre';

  @override
  String get commonLight => 'Clair';

  @override
  String get commonSearch => 'Rechercher';

  @override
  String commonError(String error) {
    return 'Erreur : $error';
  }

  @override
  String commonSaveFailed(String error) {
    return 'Échec de l’enregistrement : $error';
  }

  @override
  String get librarySearchHint => 'Rechercher un titre ou un auteur';

  @override
  String get libraryClearTooltip => 'Effacer';

  @override
  String get libraryMenuExport => 'Exporter …';

  @override
  String get libraryMenuSync => 'Sauvegarder / synchroniser la bibliothèque …';

  @override
  String get libraryEmpty =>
      'Aucun livre pour l’instant.\nAppuie sur « + » pour ajouter ton premier livre.';

  @override
  String get libraryEmptyShort => 'Aucun livre pour l’instant.';

  @override
  String get libraryNothingFound => 'Aucun résultat.';

  @override
  String get libraryResetFilter => 'Réinitialiser le filtre';

  @override
  String get libraryFilterAll => 'Tous';

  @override
  String get libraryNewBook => 'Nouveau livre';

  @override
  String get searchChangeCoverTitle => 'Chercher une couverture';

  @override
  String get searchFieldLabel => 'Titre (et éventuellement auteur)';

  @override
  String get searchFieldHelper => 'p. ex. « La Montagne magique Mann »';

  @override
  String get searchVoiceTooltip => 'Dicter le titre';

  @override
  String get bookLanguageLabel => 'Langue de ce livre';

  @override
  String get bookLanguageHintNew =>
      'Pour les enregistrements et la recherche de couvertures. Modifiable plus tard.';

  @override
  String get bookLanguageHintEdit =>
      'Valable pour les nouveaux enregistrements et la recherche de couvertures.';

  @override
  String get searchWithoutCover => 'Ajouter sans couverture';

  @override
  String get searchEnterTitle =>
      'Saisis un titre pour chercher des couvertures.';

  @override
  String get searchNothingFound =>
      'Aucun résultat. Essaie un autre titre\nou ajoute sans couverture.';

  @override
  String searchFallbackWarning(String reason) {
    return '$reason Les résultats viennent uniquement de la source de secours.';
  }

  @override
  String coverErrNoConnection(String provider) {
    return 'Pas de connexion à $provider.';
  }

  @override
  String coverErrUnreachable(String provider) {
    return '$provider est injoignable.';
  }

  @override
  String coverErrQuotaNoKey(int status) {
    return 'Google Books : quota sans clé API épuisé (statut $status). Saisis une clé gratuite dans les paramètres.';
  }

  @override
  String coverErrKeyRejected(int status) {
    return 'Google Books refuse la clé API ou le quota est épuisé (statut $status).';
  }

  @override
  String coverErrStatus(String provider, int status) {
    return '$provider a répondu avec le statut $status.';
  }

  @override
  String coverErrUnexpected(String provider) {
    return 'Réponse inattendue de $provider.';
  }

  @override
  String get recMicPermission =>
      'L’autorisation du microphone manque. Autorise-la dans les paramètres du système.';

  @override
  String recCouldNotStart(String error) {
    return 'L’enregistrement n’a pas pu démarrer : $error';
  }

  @override
  String get recVeryShortTitle => 'Enregistrement très court';

  @override
  String get recVeryShortBody =>
      'L’enregistrement dure moins d’une seconde. Le transcrire quand même ?';

  @override
  String get recTranscribe => 'Transcrire';

  @override
  String recLanguageChip(String language) {
    return 'Langue d’enregistrement : $language';
  }

  @override
  String recLanguageMenuNote(String language) {
    return 'Seulement pour l’instant. Langue du livre : $language';
  }

  @override
  String get recLongHint => 'Longue prise – Whisper transcrit tout d’un bloc.';

  @override
  String recFirstHint(String example) {
    return 'Dis par ex. : « $example »';
  }

  @override
  String get recStatusIdle => 'Appuie pour enregistrer';

  @override
  String get recStatusRecording =>
      'Enregistrement en cours – appuie pour arrêter';

  @override
  String get recStatusTranscribing => 'Transcription en cours …';

  @override
  String get recStatusError => 'Échec de la transcription';

  @override
  String recSession(int count) {
    return 'Cette session ($count)';
  }

  @override
  String recAllNotes(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count notes pour ce livre',
      one: '1 note pour ce livre',
      zero: 'Aucune note pour ce livre',
    );
    return '$_temp0';
  }

  @override
  String get recAllNotesLoading => 'Notes pour ce livre';

  @override
  String get recKept => 'L’enregistrement est toujours là.';

  @override
  String get recEnterKey => 'Saisir la clé API';

  @override
  String get trMissingKey => 'Aucune clé API OpenAI enregistrée.';

  @override
  String get trUnauthorized =>
      'La clé API a été refusée. Vérifie-la dans les paramètres.';

  @override
  String get trNetwork =>
      'Pas de connexion à l’API OpenAI. Vérifie ta connexion internet.';

  @override
  String get trRateLimited => 'Quota ou limite de requêtes atteint.';

  @override
  String get trInvalidAudio =>
      'Le fichier audio est absent, vide ou a été refusé par l’API.';

  @override
  String get trServer => 'Réponse inattendue de l’API OpenAI.';

  @override
  String trServerStatus(int status) {
    return 'L’API OpenAI a répondu avec le statut $status.';
  }

  @override
  String get bdDeleteNoteTitle => 'Supprimer la note ?';

  @override
  String get bdDeleteBookTitle => 'Supprimer le livre ?';

  @override
  String bdDeleteBookBody(String title) {
    return '« $title » et toutes ses notes seront supprimés.';
  }

  @override
  String get bdSortedByPage => 'Trié par page (appuyer : chronologique)';

  @override
  String get bdSortedChrono => 'Trié chronologiquement (appuyer : par page)';

  @override
  String get bdExportTooltip => 'Exporter (livre, auteur ou bibliothèque)';

  @override
  String get bdEditBook => 'Modifier titre, auteur, langue';

  @override
  String get bdMenuRemoveCover => 'Retirer la couverture';

  @override
  String get bdMenuDelete => 'Supprimer le livre';

  @override
  String get bdNoNotes => 'Pas encore de notes pour ce livre.';

  @override
  String get bdRecord => 'Enregistrer';

  @override
  String get noteNoPage => 'Sans numéro de page';

  @override
  String get noteNoText => '(aucun texte reconnu)';

  @override
  String get noteEditTitle => 'Modifier la note';

  @override
  String get noteEditPage => 'Page';

  @override
  String get noteEditPageHint => '47 ou 88 sq.';

  @override
  String get noteEditPosition => 'Position';

  @override
  String get noteEditPositionHint => 'haut / ligne 10';

  @override
  String get noteEditText => 'Texte';

  @override
  String get noteEditRaw => 'Transcription originale';

  @override
  String get bookEditTitle => 'Modifier le livre';

  @override
  String get bookEditTitleField => 'Titre';

  @override
  String get bookEditAuthorField => 'Auteur (facultatif)';

  @override
  String get voiceTooltip => 'Saisir à la voix';

  @override
  String get voiceStarting => 'Démarrage du microphone …';

  @override
  String get voiceListening => 'Dis le titre …';

  @override
  String get voiceRecognizing => 'Reconnaissance en cours …';

  @override
  String get voiceAutoStop =>
      's’arrête tout seul après un court silence – ou appuie';

  @override
  String get voiceNothing => 'Rien compris. Réessaie.';

  @override
  String get syncTitle => 'Synchroniser la bibliothèque';

  @override
  String get syncIntro =>
      'Le fichier de bibliothèque contient tous les livres et notes. Dépose-le p. ex. dans Google Drive et synchronise ainsi tes appareils.';

  @override
  String get syncFileHint =>
      'Écrit un fichier avec l’état actuel – à partager ou à enregistrer directement dans un dossier (p. ex. Google Drive).';

  @override
  String get syncMerge => 'Synchroniser (fusionner)';

  @override
  String get syncMergeHint =>
      'Réunit le fichier et l’appli. Tout ce qui existe encore d’un côté est conservé – les suppressions ne sont pas transmises ici.';

  @override
  String get syncMaster => 'Définir comme modèle (master)';

  @override
  String get syncMasterHint =>
      'Le seul moyen de transmettre les suppressions. Tu choisis alors doux (les ajouts locaux restent) ou strict (écrasement exact).';

  @override
  String get syncSaved => 'Fichier de bibliothèque enregistré.';

  @override
  String syncSaveFailed(String error) {
    return 'Échec de l’enregistrement : $error';
  }

  @override
  String syncMergeFailed(String error) {
    return 'Échec de la synchronisation : $error';
  }

  @override
  String syncFailed(String error) {
    return 'Échec : $error';
  }

  @override
  String get syncMergedTitle => 'Fusionné';

  @override
  String get syncBooks => 'Livres';

  @override
  String get syncNotes => 'Notes';

  @override
  String syncCountLine(String label, int count) {
    return '$label : $count';
  }

  @override
  String syncCountLineAdded(String label, int count, int added) {
    return '$label : $count  (+$added)';
  }

  @override
  String get syncSaveUpdated => 'Enregistrer le fichier mis à jour';

  @override
  String get syncUpdatedSaved =>
      'Fichier de bibliothèque mis à jour enregistré.';

  @override
  String get syncMasterBody =>
      'L’état actuel de cet appareil devient le modèle. Les autres appareils s’y alignent à la prochaine synchronisation – c’est le seul moyen de transmettre les suppressions.';

  @override
  String get syncSoft => 'Doux';

  @override
  String get syncSoftBody =>
      'Les autres appareils reprennent l’état, suppressions comprises, mais gardent les entrées toutes nouvelles chez eux.';

  @override
  String get syncHard => 'Strict';

  @override
  String get syncHardBody =>
      'Les autres appareils sont réglés exactement sur cet état – tout le reste y est supprimé.';

  @override
  String get syncSet => 'Définir';

  @override
  String syncAdoptedHard(int books, int notes) {
    return 'Modèle strict repris : exactement $books livres, $notes notes.';
  }

  @override
  String syncAdoptedSoft(int books, int notes) {
    return 'Modèle doux repris : $books livres, $notes notes.';
  }

  @override
  String get syncMasterSavedHard =>
      'Enregistré comme modèle strict. Les autres appareils seront réglés exactement dessus.';

  @override
  String get syncMasterSavedSoft =>
      'Enregistré comme modèle doux. Les autres appareils s’alignent dessus.';

  @override
  String get dialogSaveAs => 'Enregistrer sous';

  @override
  String get dialogPickLibraryFile => 'Choisir le fichier de bibliothèque';

  @override
  String get dialogPickThemeFile => 'Choisir le fichier de thème';

  @override
  String get errFileNotJson => 'Le fichier n’est pas du JSON valide.';

  @override
  String get errFileUnexpected => 'Structure de fichier inattendue.';

  @override
  String get errFileNewer =>
      'Le fichier provient d’une version plus récente de l’appli.';

  @override
  String get lfNotLibrary =>
      'Ce n’est pas un fichier de bibliothèque Booknote.';

  @override
  String lfCorrupted(String detail) {
    return 'Le fichier est endommagé : $detail';
  }

  @override
  String get cteNotATheme => 'Ce n’est pas un fichier de thème Booknote.';

  @override
  String get cteMissingName => 'Le thème n’a pas de nom.';

  @override
  String cteInvalidColor(String hex) {
    return 'Couleur « $hex » invalide.';
  }

  @override
  String cteCorrupted(String detail) {
    return 'Le fichier de thème est endommagé : $detail';
  }

  @override
  String get exportTitle => 'Exporter';

  @override
  String get exportThisBook => 'Ce livre';

  @override
  String get exportAuthorBooks => 'Tous les livres de cet auteur';

  @override
  String get exportWholeLibrary => 'Toute la bibliothèque';

  @override
  String get exportNothing => 'Rien à exporter.';

  @override
  String exportDone(String format, String file) {
    return '$format exporté : $file';
  }

  @override
  String exportSavedFile(String format, String file) {
    return '$format enregistré : $file';
  }

  @override
  String exportFailed(String error) {
    return 'Échec de l’export : $error';
  }

  @override
  String get exportFormatText => 'Texte';

  @override
  String get exportLabelNotes => 'Notes';

  @override
  String get exportLabelWithoutPage => 'Sans numéro de page';

  @override
  String get exportLabelNoNotes => 'Aucune note avec numéro de page';

  @override
  String get exportLabelNoText => 'pas de texte';

  @override
  String get exportLabelLibrary => 'Bibliothèque';

  @override
  String get settingsLanguageTitle => 'Langue de l’appli';

  @override
  String get settingsLanguageCaption =>
      'Menus et textes de l’appli. La langue des enregistrements se règle séparément pour chaque livre.';

  @override
  String get settingsLanguageDevice => 'Comme l’appareil';

  @override
  String get settingsDisplay => 'Affichage';

  @override
  String get settingsDisplayCaptionCustom =>
      'Actuellement remplacé par un thème de couleurs personnalisé (voir ci-dessous).';

  @override
  String get settingsDisplayCaption =>
      'Clair/sombre selon le système – ou à choisir.';

  @override
  String get settingsThemeSystem => 'Système';

  @override
  String get settingsCleanMode => 'Mode épuré';

  @override
  String get settingsCleanModeSub =>
      'Masque les explications et les conseils – pour ceux qui connaissent déjà l’appli.';

  @override
  String get settingsCustomThemes => 'Thèmes de couleurs';

  @override
  String get settingsCustomThemesCaption =>
      'Un look fixe à la place de clair/sombre ci-dessus – jusqu’à ce que Système, Clair ou Sombre y soit de nouveau choisi.';

  @override
  String get settingsNoThemes =>
      'Aucun thème chargé pour l’instant – « Charger des thèmes » en propose.';

  @override
  String get settingsLoadThemes => 'Charger des thèmes';

  @override
  String get settingsFromFile => 'Depuis un fichier …';

  @override
  String get settingsDeleteActiveTheme => 'Supprimer le thème actif';

  @override
  String settingsThemeLoaded(String name) {
    return '« $name » chargé et activé.';
  }

  @override
  String get settingsRecording => 'Enregistrement';

  @override
  String get settingsVibration => 'Vibration';

  @override
  String get settingsVibrationSub =>
      'Bref signal haptique au démarrage et à l’arrêt.';

  @override
  String get settingsApiKeys => 'Clés API';

  @override
  String get settingsApiKeysCaption =>
      'Enregistrées uniquement sur cet appareil et non partagées lors de la synchronisation.';

  @override
  String get settingsOpenAiLabel => 'OpenAI (Whisper)';

  @override
  String get settingsOpenAiHelper =>
      'Obligatoire pour la reconnaissance vocale. Env. 0,006 \$/min.';

  @override
  String get settingsShowKey => 'Afficher';

  @override
  String get settingsHideKey => 'Masquer';

  @override
  String get settingsGoogleLabel => 'Google Books (facultatif)';

  @override
  String get settingsGoogleHelper =>
      'Rend la recherche de couvertures plus fiable. Gratuit.';

  @override
  String get settingsSaveKeys => 'Enregistrer les clés';

  @override
  String get settingsKeysSaved => 'Clés API enregistrées.';

  @override
  String get settingsSync => 'Synchronisation des appareils';

  @override
  String get settingsSyncCaption =>
      'Lors de la synchronisation, l’appli mémorise les entrées supprimées afin qu’une suppression via « Modèle (master) » atteigne tous les appareils.';

  @override
  String get settingsForget => 'Oublier les anciennes suppressions';

  @override
  String settingsForgetOn(int days) {
    return 'Après $days jours. Économise de la place ; en cas de synchronisation très rare, une entrée supprimée depuis longtemps peut réapparaître.';
  }

  @override
  String get settingsForgetOff =>
      'Les entrées supprimées sont mémorisées définitivement.';

  @override
  String get settingsPeriod => 'Période';

  @override
  String settingsDays(int days) {
    return '$days jours';
  }

  @override
  String get catReload => 'Recharger le catalogue';

  @override
  String get catEmpty => 'Le catalogue est encore vide.';

  @override
  String get catIntro =>
      'Issu du catalogue public de Booknote sur GitHub. Appuyer sur « Installer » télécharge le thème et l’active aussitôt.';

  @override
  String get catInstall => 'Installer';

  @override
  String get catUpdate => 'Mettre à jour';

  @override
  String get catInstalled => 'Installé';

  @override
  String catInstalledActivated(String name) {
    return '« $name » installé et activé.';
  }

  @override
  String catUpdated(String name) {
    return '« $name » mis à jour.';
  }

  @override
  String get catSaveFailed => 'Échec de l’enregistrement sur l’appareil.';

  @override
  String get tcNoConnection =>
      'Pas de connexion au catalogue – vérifie ta connexion internet.';

  @override
  String tcStatus(int status) {
    return 'Le catalogue a répondu avec le statut $status.';
  }

  @override
  String get tcUnexpected => 'Réponse inattendue du catalogue.';

  @override
  String get tcNeedsNewerApp =>
      'Le catalogue nécessite une version plus récente de Booknote – mets l’appli à jour.';

  @override
  String get tcTooLarge =>
      'Le fichier est anormalement volumineux et n’a pas été chargé.';

  @override
  String tcMismatch(String name) {
    return 'L’entrée « $name » ne correspond pas à son fichier.';
  }

  @override
  String get tcCorrupted => 'Le fichier de thème est endommagé.';
}
