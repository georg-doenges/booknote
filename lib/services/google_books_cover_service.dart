import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import 'api_key_store.dart';
import 'cover_service.dart';

/// Google Books Volumes API. Funktioniert ohne Key; mit Key (aus
/// [ApiKeyStore]) stabiler gegen Rate-Limits.
class GoogleBooksCoverService implements CoverService {
  GoogleBooksCoverService({
    required ApiKeyStore apiKeys,
    http.Client? client,
    this.maxResults = 10,
    this.timeout = const Duration(seconds: 15),
  }) : _keys = apiKeys,
       _client = client ?? http.Client();

  static const providerName = 'Google Books';
  static final _base = Uri.parse('https://www.googleapis.com/books/v1/volumes');

  final ApiKeyStore _keys;
  final http.Client _client;
  final int maxResults;
  final Duration timeout;

  @override
  Future<List<CoverCandidate>> search(String query) async {
    final q = query.trim();
    if (q.isEmpty) return const [];

    final key = await _keys.getGoogleBooksKey();
    final uri = _base.replace(
      queryParameters: {
        'q': q,
        'maxResults': '$maxResults',
        'printType': 'books',
        'fields': 'items(volumeInfo(title,subtitle,authors,imageLinks(thumbnail,smallThumbnail)))',
        'key': ?key,
      },
    );

    http.Response res;
    try {
      res = await _client.get(uri).timeout(timeout);
    } on SocketException catch (e) {
      throw CoverSearchException('Keine Verbindung zu Google Books.', e);
    } on Exception catch (e) {
      throw CoverSearchException('Google Books nicht erreichbar.', e);
    }
    if (res.statusCode != 200) {
      throw CoverSearchException(
        'Google Books antwortete mit Status ${res.statusCode}.',
        res.body,
      );
    }

    try {
      final json = jsonDecode(res.body) as Map<String, dynamic>;
      final items = (json['items'] as List?) ?? const [];
      return items
          .map((it) => _toCandidate(it as Map<String, dynamic>))
          .whereType<CoverCandidate>()
          .toList();
    } catch (e) {
      throw CoverSearchException('Unerwartete Antwort von Google Books.', e);
    }
  }

  static CoverCandidate? _toCandidate(Map<String, dynamic> item) {
    final info = item['volumeInfo'] as Map<String, dynamic>?;
    final title = info?['title'] as String?;
    if (info == null || title == null || title.isEmpty) return null;

    final subtitle = info['subtitle'] as String?;
    final authors = (info['authors'] as List?)?.cast<String>();
    final links = info['imageLinks'] as Map<String, dynamic>?;
    final thumb = (links?['thumbnail'] ?? links?['smallThumbnail']) as String?;

    return CoverCandidate(
      title: subtitle == null || subtitle.isEmpty ? title : '$title: $subtitle',
      author: authors == null || authors.isEmpty ? null : authors.join(', '),
      coverUrl: thumb == null ? null : _httpsAndLarger(thumb),
      provider: providerName,
    );
  }

  /// Google liefert http-URLs und kleine Thumbnails; https erzwingen und
  /// `zoom=1` (statt 5) für etwas größere Bilder.
  static String _httpsAndLarger(String url) {
    var u = url.replaceFirst(RegExp(r'^http://'), 'https://');
    u = u.replaceAll('&edge=curl', '');
    return u.replaceFirst(RegExp(r'zoom=\d'), 'zoom=1');
  }
}
