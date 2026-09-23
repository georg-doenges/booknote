import 'dart:io';

import 'package:flutter/material.dart';

import '../models/models.dart';
import '../services/services.dart';
import '../theme.dart';
import '../widgets/theme_swatch.dart';

/// Katalog weiterer Farbschemata aus dem Booknote-Repo auf GitHub: Schema
/// antippen → wird geladen und gleich eingeschaltet (THEMES.md, „Theme-Katalog").
class ThemeCatalogScreen extends StatefulWidget {
  const ThemeCatalogScreen({
    super.key,
    required this.service,
    required this.store,
    required this.settings,
  });

  final ThemeCatalogService service;
  final CustomThemeStore store;
  final AppSettings settings;

  @override
  State<ThemeCatalogScreen> createState() => _ThemeCatalogScreenState();
}

enum _InstallState { notInstalled, updateAvailable, current }

class _ThemeCatalogScreenState extends State<ThemeCatalogScreen> {
  List<ThemeCatalogEntry>? _entries;
  String? _error;
  bool _loading = true;

  /// ID des Eintrags, der gerade geladen wird (nur einer zur Zeit).
  String? _busyId;

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  void _reload() {
    setState(() {
      _loading = true;
      _error = null;
    });
    _fetch();
  }

  Future<void> _fetch() async {
    try {
      final entries = await widget.service.fetchIndex();
      if (!mounted) return;
      setState(() {
        _entries = entries;
        _loading = false;
      });
    } on ThemeCatalogException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.message;
        _loading = false;
      });
    }
  }

  _InstallState _stateOf(ThemeCatalogEntry e) {
    final installed = widget.store.byId(e.id);
    if (installed == null) return _InstallState.notInstalled;
    return e.revision > installed.revision
        ? _InstallState.updateAvailable
        : _InstallState.current;
  }

  Future<void> _install(ThemeCatalogEntry e) async {
    final messenger = ScaffoldMessenger.of(context);
    final wasInstalled = widget.store.byId(e.id) != null;
    setState(() => _busyId = e.id);
    try {
      final bytes = await widget.service.fetchTheme(e);
      final theme = await widget.store.import(bytes);
      // Neu installierte Schemata gleich einschalten; ein Update ändert nichts
      // daran, welches Schema gerade aktiv ist.
      if (!wasInstalled) await widget.settings.setActiveCustomTheme(theme.id);
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            wasInstalled
                ? '„${theme.name}" aktualisiert.'
                : '„${theme.name}" installiert und eingeschaltet.',
          ),
        ),
      );
    } on ThemeCatalogException catch (ex) {
      messenger.showSnackBar(SnackBar(content: Text(ex.message)));
    } on CustomThemeException catch (ex) {
      messenger.showSnackBar(SnackBar(content: Text(ex.message)));
    } on FileSystemException {
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Speichern auf dem Gerät fehlgeschlagen.'),
        ),
      );
    } finally {
      if (mounted) setState(() => _busyId = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Farbschemata laden'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Katalog neu laden',
            onPressed: _loading ? null : _reload,
          ),
        ],
      ),
      body: _body(scheme),
    );
  }

  Widget _body(ColorScheme scheme) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    final error = _error;
    if (error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(BooknoteTheme.gap24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.cloud_off, color: scheme.error, size: 40),
              const SizedBox(height: BooknoteTheme.gap8),
              Text(error, textAlign: TextAlign.center),
              const SizedBox(height: BooknoteTheme.gap12),
              FilledButton.tonal(
                onPressed: _reload,
                child: const Text('Erneut versuchen'),
              ),
            ],
          ),
        ),
      );
    }
    final entries = _entries ?? const [];
    if (entries.isEmpty) {
      return Center(
        child: Text(
          'Der Katalog ist noch leer.',
          style: TextStyle(color: scheme.onSurfaceVariant),
        ),
      );
    }
    final caption = Theme.of(context).textTheme.bodySmall
        ?.copyWith(color: scheme.onSurfaceVariant);
    return ListenableBuilder(
      listenable: Listenable.merge([widget.store, widget.settings]),
      builder: (context, _) => ListView(
        padding: EdgeInsets.only(
          bottom: BooknoteTheme.gap16 + MediaQuery.paddingOf(context).bottom,
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(BooknoteTheme.gap16),
            child: Text(
              'Aus dem öffentlichen Booknote-Katalog auf GitHub. Ein Tipp auf '
              '„Installieren" lädt das Schema und schaltet es gleich ein.',
              style: caption,
            ),
          ),
          for (final e in entries) _tile(e, scheme, caption),
        ],
      ),
    );
  }

  Widget _tile(ThemeCatalogEntry e, ColorScheme scheme, TextStyle? caption) {
    final logo = e.logoFile;
    return ListTile(
      leading: ThemeSwatch(
        logoUrl: logo == null ? null : widget.service.urlFor(logo).toString(),
        surface: e.swatchSurface ?? ThemeSwatch.defaultSurface(e.brightness),
        primary: e.swatchPrimary ?? scheme.outline,
      ),
      title: Text(e.name),
      subtitle: Text(
        [
          e.brightness == Brightness.dark ? 'Dunkel' : 'Hell',
          ?e.description,
        ].join(' · '),
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: _trailing(e, scheme, caption),
    );
  }

  Widget _trailing(
    ThemeCatalogEntry e,
    ColorScheme scheme,
    TextStyle? caption,
  ) {
    if (_busyId == e.id) {
      return const SizedBox(
        width: 24,
        height: 24,
        child: CircularProgressIndicator(strokeWidth: 2),
      );
    }
    final idle = _busyId == null;
    return switch (_stateOf(e)) {
      _InstallState.notInstalled => FilledButton.tonal(
        onPressed: idle ? () => _install(e) : null,
        child: const Text('Installieren'),
      ),
      _InstallState.updateAvailable => OutlinedButton(
        onPressed: idle ? () => _install(e) : null,
        child: const Text('Aktualisieren'),
      ),
      _InstallState.current => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.check, size: 18, color: scheme.primary),
          const SizedBox(width: BooknoteTheme.gap4),
          Text('Installiert', style: caption),
        ],
      ),
    };
  }
}
