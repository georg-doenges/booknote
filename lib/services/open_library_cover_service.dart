import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import 'cover_service.dart';

/// Open Library Search + Covers API. Kein Key nötig, komplett kostenlos.
/// Fallback für Google Books.
class OpenLibraryCoverService implements CoverService {
  OpenLibraryCoverService({
    http.Client? client,
    this.maxResults = 10,
    this.timeout = const Duration(seconds: 15),
  }) : _client = client ?? http.Client();

  static const providerName = 'Open Library';
  static final _search = Uri.parse('https://openlibrary.org/search.json');

  final http.Client _client;
  final int maxResults;
  final Duration timeout;

  @override
  Future<List<CoverCandidate>> search(String query) async {
    final q = query.trim();
    if (q.isEmpty) return const [];

    final uri = _search.replace(
      queryParameters: {
        'q': q,
        'limit': '$maxResults',
        'fields': 'title,author_name,cover_i',
      },
    );

    http.Response res;
    try {
      res = await _client
          .get(uri, headers: {'User-Agent': 'Booknote/0.1 (Flutter app)'})
          .timeout(timeout);
    } on SocketException catch (e) {
      throw CoverSearchException('Keine Verbindung zu Open Library.', e);
    } on Exception catch (e) {
      throw CoverSearchException('Open Library nicht erreichbar.', e);
    }
    if (res.statusCode != 200) {
      throw CoverSearchException(
        'Open Library antwortete mit Status ${res.statusCode}.',
        res.body,
      );
    }

    try {
      final json = jsonDecode(res.body) as Map<String, dynamic>;
      final docs = (json['docs'] as List?) ?? const [];
      return docs
          .map((d) => _toCandidate(d as Map<String, dynamic>))
          .whereType<CoverCandidate>()
          .toList();
    } catch (e) {
      throw CoverSearchException('Unerwartete Antwort von Open Library.', e);
    }
  }

  static CoverCandidate? _toCandidate(Map<String, dynamic> doc) {
    final title = doc['title'] as String?;
    if (title == null || title.isEmpty) return null;
    final authors = (doc['author_name'] as List?)?.cast<String>();
    final coverId = doc['cover_i'];
    return CoverCandidate(
      title: title,
      author: authors == null || authors.isEmpty ? null : authors.join(', '),
      coverUrl: coverId == null ? null : coverUrlForId(coverId as int),
      provider: providerName,
    );
  }

  /// Größe M (~180 px breit) reicht fürs Grid; L wäre ~500 px.
  static String coverUrlForId(int id, {String size = 'M'}) =>
      'https://covers.openlibrary.org/b/id/$id-$size.jpg';
}
