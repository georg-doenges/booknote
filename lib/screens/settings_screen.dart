import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show PlatformException;

import '../app_scope.dart';
import '../l10n/l10n.dart';
import '../models/models.dart';
import '../services/services.dart';
import '../theme.dart';
import '../widgets/theme_swatch.dart';
import 'theme_catalog_screen.dart';

/// Alle Einstellungen auf einer aufgeräumten Seite: Darstellung, Aufnahme,
/// API-Schlüssel, Geräte-Abgleich. Erreichbar über das Overflow-Menü der
/// Bibliothek.
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _openAi = TextEditingController();
  final _googleBooks = TextEditingController();
  bool _showOpenAi = false;
  bool _loaded = false;
  bool _savingKeys = false;

  static const _gcDayOptions = [30, 60, 90, 120, 180, 365];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    final keys = AppScope.of(context).apiKeys;
    _openAi.text = await keys.getOpenAiKey() ?? '';
    _googleBooks.text = await keys.getGoogleBooksKey() ?? '';
    if (mounted) setState(() => _loaded = true);
  }

  Future<void> _saveKeys() async {
    setState(() => _savingKeys = true);
    final keys = AppScope.of(context).apiKeys;
    final messenger = ScaffoldMessenger.of(context);
    final l = context.l10n;
    try {
      await keys.setOpenAiKey(_openAi.text);
      await keys.setGoogleBooksKey(_googleBooks.text);
      messenger.showSnackBar(SnackBar(content: Text(l.settingsKeysSaved)));
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(l.commonSaveFailed('$e'))));
    } finally {
      if (mounted) setState(() => _savingKeys = false);
    }
  }

  @override
  void dispose() {
    _openAi.dispose();
    _googleBooks.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final settings = AppScope.of(context).settings;
    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.commonSettings)),
      body: !_loaded
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
              top: false,
              child: ListenableBuilder(
                listenable: Listenable.merge([
                  settings,
                  AppScope.of(context).customThemes,
                ]),
                builder: (context, _) => ListView(
                  padding: const EdgeInsets.only(bottom: BooknoteTheme.gap24),
                  children: [
                    _languageSection(settings),
                    _displayModeSection(settings),
                    _customThemesSection(settings),
                    _recordingSection(settings),
                    _apiKeysSection(),
                    _syncSection(settings),
                  ],
                ),
              ),
            ),
    );
  }

  // ---- Darstellung ----

  Future<void> _importTheme() async {
    final messenger = ScaffoldMessenger.of(context);
    final store = AppScope.of(context).customThemes;
    final settings = AppScope.of(context).settings;
    final l = context.l10n;
    FilePickerResult? picked;
    try {
      picked = await FilePicker.platform.pickFiles(
        dialogTitle: l.dialogPickThemeFile,
        type: FileType.custom,
        allowedExtensions: ['json'],
        withData: true,
      );
    } on PlatformException {
      picked = await FilePicker.platform.pickFiles(
        dialogTitle: l.dialogPickThemeFile,
        withData: true,
      );
    }
    final bytes = picked?.files.firstOrNull?.bytes;
    if (bytes == null) return;
    try {
      final theme = await store.import(bytes);
      await settings.setActiveCustomTheme(theme.id);
      messenger.showSnackBar(
        SnackBar(content: Text(l.settingsThemeLoaded(theme.name))),
      );
    } on CustomThemeException catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text(customThemeErrorText(l, e))),
      );
    }
  }

  void _openCatalog() {
    final scope = AppScope.of(context);
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ThemeCatalogScreen(
          service: scope.themeCatalog,
          store: scope.customThemes,
          settings: scope.settings,
        ),
      ),
    );
  }

  Future<void> _deleteTheme(CustomTheme t) async {
    final store = AppScope.of(context).customThemes;
    final settings = AppScope.of(context).settings;
    if (settings.activeCustomThemeId == t.id) {
      await settings.setThemeMode(settings.themeMode);
    }
    await store.delete(t.id);
  }

  /// Sprache der App: Gerätesprache oder eine der drei Sprachen fest.
  Widget _languageSection(AppSettings settings) {
    final l = context.l10n;
    return _Section(
      title: l.settingsLanguageTitle,
      caption: context.explain(l.settingsLanguageCaption),
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            BooknoteTheme.gap16,
            BooknoteTheme.gap4,
            BooknoteTheme.gap16,
            0,
          ),
          child: DropdownButton<_UiLanguageChoice>(
            isExpanded: true,
            value: _UiLanguageChoice.of(settings.uiLanguage),
            items: [
              DropdownMenuItem(
                value: _UiLanguageChoice.device,
                child: Text(l.settingsLanguageDevice),
              ),
              for (final language in AppLanguage.values)
                DropdownMenuItem(
                  value: _UiLanguageChoice.of(language),
                  child: Text(language.label),
                ),
            ],
            onChanged: (choice) {
              if (choice != null) settings.setUiLanguage(choice.language);
            },
          ),
        ),
      ],
    );
  }

  Widget _displayModeSection(AppSettings settings) {
    final l = context.l10n;
    final customActive = settings.activeCustomThemeId != null;
    return _Section(
      title: l.settingsDisplay,
      caption: context.explain(
        customActive
            ? l.settingsDisplayCaptionCustom
            : l.settingsDisplayCaption,
      ),
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            BooknoteTheme.gap16,
            BooknoteTheme.gap4,
            BooknoteTheme.gap16,
            0,
          ),
          child: SegmentedButton<ThemeMode>(
            segments: [
              ButtonSegment(
                value: ThemeMode.system,
                label: Text(l.settingsThemeSystem),
              ),
              ButtonSegment(value: ThemeMode.light, label: Text(l.commonLight)),
              ButtonSegment(value: ThemeMode.dark, label: Text(l.commonDark)),
            ],
            selected: customActive ? const {} : {settings.themeMode},
            emptySelectionAllowed: true,
            showSelectedIcon: false,
            onSelectionChanged: (s) => settings.setThemeMode(s.first),
          ),
        ),
        // Der Schalter selbst behält seinen Satz: Er erklärt, wie man den
        // Clean Mode wieder ausschaltet.
        SwitchListTile(
          title: Text(l.settingsCleanMode),
          subtitle: Text(l.settingsCleanModeSub),
          value: settings.cleanMode,
          onChanged: settings.setCleanMode,
        ),
      ],
    );
  }

  Widget _customThemesSection(AppSettings settings) {
    final l = context.l10n;
    final store = AppScope.of(context).customThemes;
    final customActive = settings.activeCustomThemeId != null;
    final caption = Theme.of(context).textTheme.bodySmall
        ?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant);
    return _Section(
      title: l.settingsCustomThemes,
      caption: context.explain(l.settingsCustomThemesCaption),
      children: [
        RadioGroup<String>(
          groupValue: settings.activeCustomThemeId,
          onChanged: (id) => settings.setActiveCustomTheme(id),
          child: Column(
            children: [
              for (final t in store.themes)
                RadioListTile<String>(
                  value: t.id,
                  secondary: ThemeSwatch.fromTheme(t),
                  title: Text(t.name),
                  subtitle: Text(
                    t.brightness == Brightness.dark
                        ? l.commonDark
                        : l.commonLight,
                    style: caption,
                  ),
                ),
              if (store.themes.isEmpty && !context.cleanMode)
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: BooknoteTheme.gap16,
                  ),
                  child: Text(l.settingsNoThemes, style: caption),
                ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(
            BooknoteTheme.gap16,
            BooknoteTheme.gap8,
            BooknoteTheme.gap16,
            0,
          ),
          child: Wrap(
            spacing: BooknoteTheme.gap8,
            runSpacing: BooknoteTheme.gap8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              FilledButton.tonalIcon(
                onPressed: _openCatalog,
                icon: const Icon(Icons.cloud_download_outlined),
                label: Text(l.settingsLoadThemes),
              ),
              OutlinedButton.icon(
                onPressed: _importTheme,
                icon: const Icon(Icons.file_open_outlined),
                label: Text(l.settingsFromFile),
              ),
              if (customActive)
                Builder(
                  builder: (context) {
                    final active = store.byId(settings.activeCustomThemeId);
                    if (active == null) return const SizedBox.shrink();
                    return IconButton(
                      icon: const Icon(Icons.delete_outline),
                      tooltip: l.settingsDeleteActiveTheme,
                      onPressed: () => _deleteTheme(active),
                    );
                  },
                ),
            ],
          ),
        ),
      ],
    );
  }

  // ---- Aufnahme ----

  Widget _recordingSection(AppSettings settings) => _Section(
    title: context.l10n.settingsRecording,
    children: [
      SwitchListTile(
        title: Text(context.l10n.settingsVibration),
        subtitle: switch (context.explain(context.l10n.settingsVibrationSub)) {
          final text? => Text(text),
          null => null,
        },
        value: settings.hapticsEnabled,
        onChanged: settings.setHapticsEnabled,
      ),
    ],
  );

  // ---- API-Schlüssel ----

  Widget _apiKeysSection() {
    final l = context.l10n;
    final caption = Theme.of(context).textTheme.bodySmall
        ?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant);
    return _Section(
      title: l.settingsApiKeys,
      caption: context.explain(l.settingsApiKeysCaption),
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            BooknoteTheme.gap16,
            BooknoteTheme.gap8,
            BooknoteTheme.gap16,
            0,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(l.settingsOpenAiLabel, style: caption),
              const SizedBox(height: BooknoteTheme.gap4),
              TextField(
                controller: _openAi,
                obscureText: !_showOpenAi,
                autocorrect: false,
                enableSuggestions: false,
                decoration: InputDecoration(
                  hintText: 'sk-…',
                  helperText: context.explain(l.settingsOpenAiHelper),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _showOpenAi ? Icons.visibility_off : Icons.visibility,
                    ),
                    tooltip: _showOpenAi
                        ? l.settingsHideKey
                        : l.settingsShowKey,
                    onPressed: () => setState(() => _showOpenAi = !_showOpenAi),
                  ),
                ),
              ),
              const SizedBox(height: BooknoteTheme.gap16),
              Text(l.settingsGoogleLabel, style: caption),
              const SizedBox(height: BooknoteTheme.gap4),
              TextField(
                controller: _googleBooks,
                autocorrect: false,
                enableSuggestions: false,
                decoration: InputDecoration(
                  helperText: context.explain(l.settingsGoogleHelper),
                ),
              ),
              const SizedBox(height: BooknoteTheme.gap16),
              Align(
                alignment: Alignment.centerLeft,
                child: FilledButton.icon(
                  onPressed: _savingKeys ? null : _saveKeys,
                  icon: const Icon(Icons.save_outlined),
                  label: Text(l.settingsSaveKeys),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ---- Geräte-Abgleich ----

  Widget _syncSection(AppSettings settings) {
    final l = context.l10n;
    final gc = settings.sync;
    return _Section(
      title: l.settingsSync,
      caption: context.explain(l.settingsSyncCaption),
      children: [
        SwitchListTile(
          title: Text(l.settingsForget),
          subtitle: switch (context.explain(
            gc.tombstoneGcEnabled
                ? l.settingsForgetOn(gc.tombstoneGcDays)
                : l.settingsForgetOff,
          )) {
            final text? => Text(text),
            null => null,
          },
          value: gc.tombstoneGcEnabled,
          onChanged: (v) =>
              settings.updateSync(gc.copyWith(tombstoneGcEnabled: v)),
        ),
        if (gc.tombstoneGcEnabled)
          ListTile(
            title: Text(l.settingsPeriod),
            trailing: DropdownButton<int>(
              value: _gcDayOptions.contains(gc.tombstoneGcDays)
                  ? gc.tombstoneGcDays
                  : null,
              hint: Text(l.settingsDays(gc.tombstoneGcDays)),
              items: [
                for (final d in _gcDayOptions)
                  DropdownMenuItem(value: d, child: Text(l.settingsDays(d))),
              ],
              onChanged: (v) => v == null
                  ? null
                  : settings.updateSync(gc.copyWith(tombstoneGcDays: v)),
            ),
          ),
      ],
    );
  }
}

/// Abschnitt mit Titel, optionalem Erklärtext und Inhalt.
class _Section extends StatelessWidget {
  const _Section({required this.title, this.caption, required this.children});

  final String title;
  final String? caption;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            BooknoteTheme.gap16,
            BooknoteTheme.gap24,
            BooknoteTheme.gap16,
            BooknoteTheme.gap4,
          ),
          child: Text(
            title,
            style: theme.textTheme.titleSmall?.copyWith(
              color: theme.colorScheme.primary,
            ),
          ),
        ),
        if (caption != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(
              BooknoteTheme.gap16,
              0,
              BooknoteTheme.gap16,
              BooknoteTheme.gap4,
            ),
            child: Text(
              caption!,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ...children,
      ],
    );
  }
}

/// Auswahl im Sprach-Menü: Gerätesprache oder eine feste Sprache. (Ein
/// `DropdownButton` mit `null`-Wert zeigt statt des Eintrags den Hinweistext.)
enum _UiLanguageChoice {
  device(null),
  german(AppLanguage.german),
  english(AppLanguage.english),
  french(AppLanguage.french);

  const _UiLanguageChoice(this.language);

  /// `null` = wie das Gerät.
  final AppLanguage? language;

  static _UiLanguageChoice of(AppLanguage? language) =>
      values.firstWhere((c) => c.language == language, orElse: () => device);
}
