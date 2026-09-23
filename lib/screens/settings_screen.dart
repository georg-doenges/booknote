import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show PlatformException;

import '../app_scope.dart';
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
    try {
      await keys.setOpenAiKey(_openAi.text);
      await keys.setGoogleBooksKey(_googleBooks.text);
      messenger.showSnackBar(
        const SnackBar(content: Text('API-Schlüssel gespeichert.')),
      );
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text('Speichern fehlgeschlagen: $e')),
      );
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
      appBar: AppBar(title: const Text('Einstellungen')),
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
    FilePickerResult? picked;
    try {
      picked = await FilePicker.platform.pickFiles(
        dialogTitle: 'Theme-Datei wählen',
        type: FileType.custom,
        allowedExtensions: ['json'],
        withData: true,
      );
    } on PlatformException {
      picked = await FilePicker.platform.pickFiles(
        dialogTitle: 'Theme-Datei wählen',
        withData: true,
      );
    }
    final bytes = picked?.files.firstOrNull?.bytes;
    if (bytes == null) return;
    try {
      final theme = await store.import(bytes);
      await settings.setActiveCustomTheme(theme.id);
      messenger.showSnackBar(
        SnackBar(content: Text('„${theme.name}" geladen und aktiviert.')),
      );
    } on CustomThemeException catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(e.message)));
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

  Widget _displayModeSection(AppSettings settings) {
    final customActive = settings.activeCustomThemeId != null;
    return _Section(
      title: 'Anzeige',
      caption: customActive
          ? 'Aktuell überschrieben durch ein eigenes Farbschema (siehe unten).'
          : 'Hell/Dunkel automatisch nach System – oder fest gewählt.',
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            BooknoteTheme.gap16,
            BooknoteTheme.gap4,
            BooknoteTheme.gap16,
            0,
          ),
          child: SegmentedButton<ThemeMode>(
            segments: const [
              ButtonSegment(value: ThemeMode.system, label: Text('System')),
              ButtonSegment(value: ThemeMode.light, label: Text('Hell')),
              ButtonSegment(value: ThemeMode.dark, label: Text('Dunkel')),
            ],
            selected: customActive ? const {} : {settings.themeMode},
            emptySelectionAllowed: true,
            showSelectedIcon: false,
            onSelectionChanged: (s) => settings.setThemeMode(s.first),
          ),
        ),
      ],
    );
  }

  Widget _customThemesSection(AppSettings settings) {
    final store = AppScope.of(context).customThemes;
    final customActive = settings.activeCustomThemeId != null;
    final caption = Theme.of(context).textTheme.bodySmall
        ?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant);
    return _Section(
      title: 'Eigene Farbschemata',
      caption:
          'Ein fester Look statt Hell/Dunkel oben – bis dort wieder System, '
          'Hell oder Dunkel gewählt wird.',
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
                    t.brightness == Brightness.dark ? 'Dunkel' : 'Hell',
                    style: caption,
                  ),
                ),
              if (store.themes.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: BooknoteTheme.gap16,
                  ),
                  child: Text(
                    'Noch keine Farbschemata geladen – über „Farbschemata '
                    'laden" gibt es welche.',
                    style: caption,
                  ),
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
                label: const Text('Farbschemata laden'),
              ),
              OutlinedButton.icon(
                onPressed: _importTheme,
                icon: const Icon(Icons.file_open_outlined),
                label: const Text('Aus Datei …'),
              ),
              if (customActive)
                Builder(
                  builder: (context) {
                    final active = store.byId(settings.activeCustomThemeId);
                    if (active == null) return const SizedBox.shrink();
                    return IconButton(
                      icon: const Icon(Icons.delete_outline),
                      tooltip: 'Aktives Schema löschen',
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
    title: 'Aufnahme',
    children: [
      SwitchListTile(
        title: const Text('Vibration'),
        subtitle: const Text('Kurzes haptisches Signal beim Start und Stopp.'),
        value: settings.hapticsEnabled,
        onChanged: settings.setHapticsEnabled,
      ),
    ],
  );

  // ---- API-Schlüssel ----

  Widget _apiKeysSection() {
    final caption = Theme.of(context).textTheme.bodySmall
        ?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant);
    return _Section(
      title: 'API-Schlüssel',
      caption:
          'Werden nur auf diesem Gerät gespeichert und beim Abgleich nicht '
          'geteilt.',
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
              Text('OpenAI (Whisper)', style: caption),
              const SizedBox(height: BooknoteTheme.gap4),
              TextField(
                controller: _openAi,
                obscureText: !_showOpenAi,
                autocorrect: false,
                enableSuggestions: false,
                decoration: InputDecoration(
                  hintText: 'sk-…',
                  helperText: 'Pflicht für die Spracherkennung. ~0,006 \$/Min.',
                  suffixIcon: IconButton(
                    icon: Icon(
                      _showOpenAi ? Icons.visibility_off : Icons.visibility,
                    ),
                    tooltip: _showOpenAi ? 'Verbergen' : 'Anzeigen',
                    onPressed: () => setState(() => _showOpenAi = !_showOpenAi),
                  ),
                ),
              ),
              const SizedBox(height: BooknoteTheme.gap16),
              Text('Google Books (optional)', style: caption),
              const SizedBox(height: BooknoteTheme.gap4),
              TextField(
                controller: _googleBooks,
                autocorrect: false,
                enableSuggestions: false,
                decoration: const InputDecoration(
                  helperText: 'Macht die Cover-Suche stabiler. Kostenlos.',
                ),
              ),
              const SizedBox(height: BooknoteTheme.gap16),
              Align(
                alignment: Alignment.centerLeft,
                child: FilledButton.icon(
                  onPressed: _savingKeys ? null : _saveKeys,
                  icon: const Icon(Icons.save_outlined),
                  label: const Text('Schlüssel speichern'),
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
    final gc = settings.sync;
    return _Section(
      title: 'Geräte-Abgleich',
      caption:
          'Beim Abgleich merkt sich die App gelöschte Einträge, damit eine '
          'Löschung per „Vorlage (Master)" auf alle Geräte wirkt.',
      children: [
        SwitchListTile(
          title: const Text('Alte Löschungen vergessen'),
          subtitle: Text(
            gc.tombstoneGcEnabled
                ? 'Nach ${gc.tombstoneGcDays} Tagen. Spart Platz; bei sehr '
                      'seltenem Abgleich kann ein alt-gelöschter Eintrag dann '
                      'wieder auftauchen.'
                : 'Gelöschte Einträge werden dauerhaft gemerkt.',
          ),
          value: gc.tombstoneGcEnabled,
          onChanged: (v) =>
              settings.updateSync(gc.copyWith(tombstoneGcEnabled: v)),
        ),
        if (gc.tombstoneGcEnabled)
          ListTile(
            title: const Text('Zeitraum'),
            trailing: DropdownButton<int>(
              value: _gcDayOptions.contains(gc.tombstoneGcDays)
                  ? gc.tombstoneGcDays
                  : null,
              hint: Text('${gc.tombstoneGcDays} Tage'),
              items: [
                for (final d in _gcDayOptions)
                  DropdownMenuItem(value: d, child: Text('$d Tage')),
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
