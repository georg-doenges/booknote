import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;

import 'api_key_store.dart';
import 'transcription_service.dart';

/// Transkription über die OpenAI-Audio-API (PROJECT.md, Abschnitt 7).
///
/// POST multipart an `/v1/audio/transcriptions` mit `model=whisper-1`,
/// `language=de`, `response_format=json`. Kosten ~$0.006/Minute, kein Abo.
class WhisperService implements TranscriptionService {
  WhisperService({
    required ApiKeyStore apiKeys,
    http.Client? client,
    Uri? endpoint,
    this.model = 'whisper-1',
    this.timeout = const Duration(seconds: 60),
  }) : _keys = apiKeys,
       _client = client ?? http.Client(),
       _endpoint = endpoint ?? defaultEndpoint;

  static final defaultEndpoint = Uri.parse(
    'https://api.openai.com/v1/audio/transcriptions',
  );

  final ApiKeyStore _keys;
  final http.Client _client;
  final Uri _endpoint;
  final String model;
  final Duration timeout;

  @override
  Future<String> transcribe(String audioPath, {String language = 'de'}) async {
    final apiKey = await _keys.getOpenAiKey();
    if (apiKey == null) {
      throw const TranscriptionException(
        TranscriptionErrorKind.missingApiKey,
        'Kein OpenAI-API-Key hinterlegt.',
      );
    }

    final file = File(audioPath);
    if (!await file.exists() || await file.length() == 0) {
      throw TranscriptionException(
        TranscriptionErrorKind.invalidAudio,
        'Audiodatei fehlt oder ist leer: $audioPath',
      );
    }

    final request = http.MultipartRequest('POST', _endpoint)
      ..headers['Authorization'] = 'Bearer $apiKey'
      ..fields['model'] = model
      ..fields['language'] = language
      ..fields['response_format'] = 'json'
      ..files.add(
        await http.MultipartFile.fromPath(
          'file',
          audioPath,
          filename: p.basename(audioPath),
        ),
      );

    http.StreamedResponse streamed;
    try {
      streamed = await _client.send(request).timeout(timeout);
    } on SocketException catch (e) {
      throw TranscriptionException(
        TranscriptionErrorKind.network,
        'Keine Verbindung zur OpenAI-API.',
        e,
      );
    } on HttpException catch (e) {
      throw TranscriptionException(
        TranscriptionErrorKind.network,
        'Netzwerkfehler.',
        e,
      );
    } on Exception catch (e) {
      // TimeoutException, HandshakeException, ClientException …
      throw TranscriptionException(
        TranscriptionErrorKind.network,
        'Netzwerkfehler oder Zeitüberschreitung.',
        e,
      );
    }

    final body = await streamed.stream.bytesToString();
    final status = streamed.statusCode;

    if (status == 200) {
      try {
        final json = jsonDecode(body) as Map<String, dynamic>;
        return (json['text'] as String? ?? '').trim();
      } catch (e) {
        throw TranscriptionException(
          TranscriptionErrorKind.server,
          'Unerwartete Antwort der API.',
          e,
        );
      }
    }

    final apiMessage = _extractErrorMessage(body);
    switch (status) {
      case 401:
      case 403:
        throw TranscriptionException(
          TranscriptionErrorKind.unauthorized,
          'API-Key wurde abgelehnt. Bitte in den Einstellungen prüfen.',
          apiMessage,
        );
      case 429:
        throw TranscriptionException(
          TranscriptionErrorKind.rateLimited,
          'Kontingent oder Rate-Limit erreicht.',
          apiMessage,
        );
      case 400:
      case 413:
      case 415:
        throw TranscriptionException(
          TranscriptionErrorKind.invalidAudio,
          'Die Audiodatei wurde von der API abgelehnt.',
          apiMessage,
        );
      default:
        throw TranscriptionException(
          TranscriptionErrorKind.server,
          'OpenAI-API antwortete mit Status $status.',
          apiMessage,
        );
    }
  }

  static String? _extractErrorMessage(String body) {
    try {
      final json = jsonDecode(body);
      return (json as Map<String, dynamic>)['error']?['message'] as String?;
    } catch (_) {
      return body.isEmpty ? null : body;
    }
  }
}
