import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../app_scope.dart';
import '../l10n/l10n.dart';
import '../models/models.dart';
import '../services/services.dart';
import '../theme.dart';
import '../widgets/framed_cover.dart';
import '../widgets/language_choice.dart';
import '../widgets/voice_input_button.dart';
import 'settings_screen.dart';

/// Ergebnis der Buchsuche: entweder ein ausgewählter Treffer oder der vom
/// Nutzer eingetippte Titel ohne Cover. [language] ist nur bei einem neuen
/// Buch relevant (siehe [BookSearchScreen.newBook]).
class BookSearchResult {
  const BookSearchResult({
    required this.title,
    this.author,
    this.coverUrl,
    this.language = AppLanguage.german,
  });
  final String title;
  final String? author;
  final String? coverUrl;
  final AppLanguage language;
}

/// Titel eingeben → Google Books / Open Library abfragen → Treffer mit Cover
/// zur Auswahl. Wird zum Anlegen (Library) und zum Cover-Ändern (BookDetail)
/// benutzt; gibt ein [BookSearchResult] zurück oder `null` bei Abbruch.
class BookSearchScreen extends StatefulWidget {
  const BookSearchScreen({
    super.key,
    this.initialQuery = '',
    this.title,
    this.allowWithoutCover = true,
    this.newBook = true,
    this.bookLanguage,
  });

  final String initialQuery;

  /// `null` → „Neues Buch" in der Sprache der App.
  final String? title;

  /// Zeigt „Ohne Cover anlegen" mit dem eingetippten Titel.
  final bool allowWithoutCover;

  /// `true`: ein neues Buch entsteht hier → die Sprache des Buchs wird
  /// abgefragt (Start: Sprache der App). `false`: nur ein Cover für ein
  /// bestehendes Buch suchen (`BookDetailScreen._changeCover`) – dessen
  /// Sprache bleibt unangetastet und wird über [bookLanguage] mitgegeben.
  final bool newBook;

  /// Sprache des bestehenden Buchs bei `newBook: false`; sie steuert die
  /// Cover-Suche. Bei einem neuen Buch ohne Bedeutung (die Wahl liegt auf der
  /// Seite).
  final AppLanguage? bookLanguage;

  @override
  State<BookSearchScreen> createState() => _BookSearchScreenState();
}

class _BookSearchScreenState extends State<BookSearchScreen> {
  late final _query = TextEditingController(text: widget.initialQuery);
  Timer? _debounce;
  int _requestId = 0;

  List<CoverCandidate>? _results;
  CoverSearchException? _warning;
  bool _loading = false;
  CoverSearchException? _error;

  /// Wahl des Nutzers bei einem neuen Buch. `null` = noch nicht gewählt.
  AppLanguage? _language;

  /// Sprache dieses Buchs – steuert Aufnahmen und Cover-Suche gemeinsam, damit
  /// die Seite nur eine Sprachwahl hat. Ohne Wahl: die des bestehenden Buchs,
  /// sonst die Sprache der App.
  AppLanguage get _bookLanguage =>
      _language ?? widget.bookLanguage ?? uiLanguageOf(context);

  @override
  void initState() {
    super.initState();
    if (widget.initialQuery.trim().isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _search());
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _query.dispose();
    super.dispose();
  }

  void _onChanged(String _) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 600), _search);
  }

  Future<void> _search() async {
    _debounce?.cancel();
    final q = _query.text.trim();
    final id = ++_requestId;
    if (q.isEmpty) {
      setState(() {
        _results = null;
        _warning = null;
        _error = null;
        _loading = false;
      });
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    final scope = AppScope.of(context);
    try {
      final r = await scope.covers.search(q, language: _bookLanguage.code);
      if (!mounted || id != _requestId) return;
      setState(() {
        _results = r.candidates;
        _warning = r.warning;
        _loading = false;
      });
    } on CoverSearchException catch (e) {
      if (!mounted || id != _requestId) return;
      setState(() {
        _error = e;
        _loading = false;
      });
    }
  }

  void _pick(CoverCandidate c) => Navigator.of(context).pop(
    BookSearchResult(
      title: c.title,
      author: c.author,
      coverUrl: c.coverUrl,
      language: _bookLanguage,
    ),
  );

  void _onVoice(String text) {
    _query.text = text;
    _query.selection = TextSelection.collapsed(offset: text.length);
    _search();
  }

  void _openSettings() =>
      Navigator.of(context)
          .push(MaterialPageRoute(builder: (_) => const SettingsScreen()));

  void _withoutCover() {
    final t = _query.text.trim();
    if (t.isEmpty) return;
    Navigator.of(context)
        .pop(BookSearchResult(title: t, language: _bookLanguage));
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final l = context.l10n;
    return Scaffold(
      appBar: AppBar(title: Text(widget.title ?? l.libraryNewBook)),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              BooknoteTheme.gap16,
              BooknoteTheme.gap12,
              BooknoteTheme.gap16,
              BooknoteTheme.gap4,
            ),
            child: TextField(
              controller: _query,
              autofocus: widget.initialQuery.isEmpty,
              textCapitalization: TextCapitalization.sentences,
              textInputAction: TextInputAction.search,
              onChanged: _onChanged,
              onSubmitted: (_) => _search(),
              decoration: InputDecoration(
                labelText: l.searchFieldLabel,
                helperText: context.explain(l.searchFieldHelper),
                suffixIcon: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    VoiceInputButton(
                      onResult: _onVoice,
                      onOpenSettings: _openSettings,
                      tooltip: l.searchVoiceTooltip,
                      language: _bookLanguage.code,
                    ),
                    IconButton(
                      icon: const Icon(Icons.search),
                      tooltip: l.commonSearch,
                      onPressed: _search,
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (widget.newBook)
            Padding(
              padding: const EdgeInsets.fromLTRB(
                BooknoteTheme.gap16,
                0,
                BooknoteTheme.gap16,
                BooknoteTheme.gap8,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l.bookLanguageLabel,
                    style: Theme.of(context).textTheme.labelLarge,
                  ),
                  const SizedBox(height: BooknoteTheme.gap4),
                  LanguageChoice(
                    value: _bookLanguage,
                    // Die Cover-Suche folgt der Sprache – neu suchen.
                    onChanged: (language) {
                      setState(() => _language = language);
                      _search();
                    },
                  ),
                  Explanation(
                    child: Text(
                      l.bookLanguageHintNew,
                      style: Theme.of(context).textTheme.bodySmall
                          ?.copyWith(color: scheme.onSurfaceVariant),
                    ),
                  ),
                ],
              ),
            ),
          if (widget.allowWithoutCover)
            Align(
              alignment: Alignment.centerRight,
              child: Padding(
                padding: const EdgeInsets.only(right: 12),
                child: TextButton.icon(
                  onPressed: _withoutCover,
                  icon: const Icon(Icons.block),
                  label: Text(l.searchWithoutCover),
                ),
              ),
            ),
          if (_loading) const LinearProgressIndicator(),
          if (_warning != null)
            MaterialBanner(
              backgroundColor: scheme.tertiaryContainer,
              leading: Icon(
                Icons.info_outline,
                color: scheme.onTertiaryContainer,
              ),
              content: Text(
                coverSearchWarningText(l, _warning!),
                style: TextStyle(color: scheme.onTertiaryContainer),
              ),
              actions: [
                TextButton(
                  onPressed: _openSettings,
                  child: Text(l.commonSettings),
                ),
              ],
            ),
          Expanded(child: _body(scheme)),
        ],
      ),
    );
  }

  Widget _body(ColorScheme scheme) {
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.cloud_off, color: scheme.error, size: 40),
              const SizedBox(height: 8),
              Text(
                coverSearchErrorText(context.l10n, _error!),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              FilledButton.tonal(
                onPressed: _search,
                child: Text(context.l10n.commonRetry),
              ),
            ],
          ),
        ),
      );
    }
    final results = _results;
    if (results == null) {
      if (context.cleanMode) return const SizedBox.shrink();
      return Center(
        child: Text(
          context.l10n.searchEnterTitle,
          style: TextStyle(color: scheme.onSurfaceVariant),
        ),
      );
    }
    if (results.isEmpty && !_loading) {
      return Center(
        child: Text(
          context.l10n.searchNothingFound,
          textAlign: TextAlign.center,
          style: TextStyle(color: scheme.onSurfaceVariant),
        ),
      );
    }
    return ListView.separated(
      padding: EdgeInsets.only(
        bottom: BooknoteTheme.gap16 + MediaQuery.paddingOf(context).bottom,
      ),
      itemCount: results.length,
      separatorBuilder: (_, _) => const Divider(height: 1),
      itemBuilder: (context, i) {
        final c = results[i];
        return ListTile(
          onTap: () => _pick(c),
          leading: SizedBox(
            width: 48,
            height: 72,
            child: FramedCover(
              image: c.coverUrl == null
                  ? null
                  : CachedNetworkImageProvider(c.coverUrl!),
              fallback: ColoredBox(
                color: scheme.surfaceContainerHighest,
                child: const Icon(Icons.menu_book),
              ),
              radius: 6,
              padding: 2,
            ),
          ),
          title: Text(c.title, maxLines: 2, overflow: TextOverflow.ellipsis),
          subtitle: Text(
            [if (c.author != null) c.author!, c.provider].join(' · '),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        );
      },
    );
  }
}
