import 'package:flutter/material.dart';

import '../app_scope.dart';

/// Einstellungen: OpenAI-API-Key (Pflicht für Whisper) und optionaler
/// Google-Books-Key (Cover-Suche, Schritt 6).
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
  bool _saving = false;

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

  Future<void> _save() async {
    setState(() => _saving = true);
    final keys = AppScope.of(context).apiKeys;
    final messenger = ScaffoldMessenger.of(context);
    try {
      await keys.setOpenAiKey(_openAi.text);
      await keys.setGoogleBooksKey(_googleBooks.text);
      messenger.showSnackBar(const SnackBar(content: Text('Gespeichert.')));
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text('Speichern fehlgeschlagen: $e')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
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
    final text = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Einstellungen')),
      body: !_loaded
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Text('OpenAI-API-Key', style: text.titleMedium),
                const SizedBox(height: 4),
                Text(
                  'Für die Spracherkennung (Whisper). Wird nur auf diesem Gerät '
                  'gespeichert. Kosten: ca. 0,006 US-Dollar pro Minute Aufnahme, '
                  'kein Abo.',
                  style: text.bodySmall,
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _openAi,
                  obscureText: !_showOpenAi,
                  autocorrect: false,
                  enableSuggestions: false,
                  decoration: InputDecoration(
                    hintText: 'sk-…',
                    border: const OutlineInputBorder(),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _showOpenAi ? Icons.visibility_off : Icons.visibility,
                      ),
                      onPressed: () =>
                          setState(() => _showOpenAi = !_showOpenAi),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'Google-Books-API-Key (optional)',
                  style: text.titleMedium,
                ),
                const SizedBox(height: 4),
                Text(
                  'Für die Cover-Suche. Ohne Key funktioniert die Suche meist '
                  'auch, mit Key stabiler. Kostenlos.',
                  style: text.bodySmall,
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _googleBooks,
                  autocorrect: false,
                  enableSuggestions: false,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 24),
                FilledButton.icon(
                  onPressed: _saving ? null : _save,
                  icon: const Icon(Icons.save_outlined),
                  label: const Text('Speichern'),
                ),
              ],
            ),
    );
  }
}
