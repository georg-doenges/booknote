import 'dart:async';

import 'package:flutter/material.dart';

import '../app_scope.dart';
import '../services/services.dart';

/// Ergebnis der Buchsuche: entweder ein ausgewählter Treffer oder der vom
/// Nutzer eingetippte Titel ohne Cover.
class BookSearchResult {
  const BookSearchResult({required this.title, this.author, this.coverUrl});
  final String title;
  final String? author;
  final String? coverUrl;
}

/// Titel eingeben → Google Books / Open Library abfragen → Treffer mit Cover
/// zur Auswahl. Wird zum Anlegen (Library) und zum Cover-Ändern (BookDetail)
/// benutzt; gibt ein [BookSearchResult] zurück oder `null` bei Abbruch.
class BookSearchScreen extends StatefulWidget {
  const BookSearchScreen({
    super.key,
    this.initialQuery = '',
    this.title = 'Neues Buch',
    this.allowWithoutCover = true,
  });

  final String initialQuery;
  final String title;

  /// Zeigt „Ohne Cover anlegen" mit dem eingetippten Titel.
  final bool allowWithoutCover;

  @override
  State<BookSearchScreen> createState() => _BookSearchScreenState();
}

class _BookSearchScreenState extends State<BookSearchScreen> {
  late final _query = TextEditingController(text: widget.initialQuery);
  Timer? _debounce;
  int _requestId = 0;

  List<CoverCandidate>? _results;
  bool _loading = false;
  String? _error;

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
        _error = null;
        _loading = false;
      });
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final r = await AppScope.of(context).covers.search(q);
      if (!mounted || id != _requestId) return;
      setState(() {
        _results = r;
        _loading = false;
      });
    } on CoverSearchException catch (e) {
      if (!mounted || id != _requestId) return;
      setState(() {
        _error = e.message;
        _loading = false;
      });
    }
  }

  void _pick(CoverCandidate c) => Navigator.of(context).pop(
    BookSearchResult(title: c.title, author: c.author, coverUrl: c.coverUrl),
  );

  void _withoutCover() {
    final t = _query.text.trim();
    if (t.isEmpty) return;
    Navigator.of(context).pop(BookSearchResult(title: t));
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: TextField(
              controller: _query,
              autofocus: widget.initialQuery.isEmpty,
              textCapitalization: TextCapitalization.sentences,
              textInputAction: TextInputAction.search,
              onChanged: _onChanged,
              onSubmitted: (_) => _search(),
              decoration: InputDecoration(
                labelText: 'Titel (und ggf. Autor)',
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.search),
                  onPressed: _search,
                ),
              ),
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
                  label: const Text('Ohne Cover anlegen'),
                ),
              ),
            ),
          if (_loading) const LinearProgressIndicator(),
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
              Text(_error!, textAlign: TextAlign.center),
              const SizedBox(height: 12),
              FilledButton.tonal(
                onPressed: _search,
                child: const Text('Erneut suchen'),
              ),
            ],
          ),
        ),
      );
    }
    final results = _results;
    if (results == null) {
      return Center(
        child: Text(
          'Titel eingeben, um Cover zu suchen.',
          style: TextStyle(color: scheme.outline),
        ),
      );
    }
    if (results.isEmpty && !_loading) {
      return Center(
        child: Text(
          'Nichts gefunden. Anderen Titel probieren\noder ohne Cover anlegen.',
          textAlign: TextAlign.center,
          style: TextStyle(color: scheme.outline),
        ),
      );
    }
    return ListView.separated(
      itemCount: results.length,
      separatorBuilder: (_, _) => const Divider(height: 1),
      itemBuilder: (context, i) {
        final c = results[i];
        return ListTile(
          onTap: () => _pick(c),
          leading: SizedBox(
            width: 48,
            height: 72,
            child: c.coverUrl == null
                ? Container(
                    color: scheme.surfaceContainerHighest,
                    child: const Icon(Icons.menu_book),
                  )
                : Image.network(
                    c.coverUrl!,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => Container(
                      color: scheme.surfaceContainerHighest,
                      child: const Icon(Icons.broken_image_outlined),
                    ),
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
