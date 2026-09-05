import 'dart:convert';
import 'dart:io';

import 'package:booknote/services/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  late Directory tmp;
  late String audioPath;

  setUp(() async {
    tmp = await Directory.systemTemp.createTemp('booknote_whisper_');
    audioPath = '${tmp.path}/note.m4a';
    await File(audioPath).writeAsBytes(List.filled(64, 1));
  });

  tearDown(() => tmp.delete(recursive: true));

  WhisperService service({
    String? key = 'sk-test',
    required Future<http.Response> Function(http.Request) handler,
  }) => WhisperService(
    apiKeys: InMemoryApiKeyStore(openAiKey: key),
    client: MockClient(handler),
  );

  http.Response json(int status, Map<String, Object?> body) =>
      http.Response(jsonEncode(body), status);

  Future<TranscriptionErrorKind> kindOf(Future<String> f) async {
    try {
      await f;
      fail('erwartete TranscriptionException');
    } on TranscriptionException catch (e) {
      return e.kind;
    }
  }

  test('sendet Multipart mit Key, Modell, Sprache und liefert text', () async {
    late http.Request captured;
    final s = service(
      handler: (req) async {
        captured = req;
        return json(200, {'text': '  Seite 47 oben, Text  '});
      },
    );

    final text = await s.transcribe(audioPath);

    expect(text, 'Seite 47 oben, Text');
    expect(captured.method, 'POST');
    expect(captured.url, WhisperService.defaultEndpoint);
    expect(captured.headers['Authorization'], 'Bearer sk-test');
    expect(captured.headers['content-type'], startsWith('multipart/form-data'));
    final body = utf8.decode(captured.bodyBytes, allowMalformed: true);
    expect(body, contains('name="model"'));
    expect(body, contains('whisper-1'));
    expect(body, contains('name="language"'));
    expect(body, contains('\r\nde\r\n'));
    expect(body, contains('filename="note.m4a"'));
  });

  test('ohne Key → missingApiKey, kein Request', () async {
    var called = false;
    final s = service(
      key: null,
      handler: (_) async {
        called = true;
        return json(200, {'text': 'x'});
      },
    );
    expect(
      await kindOf(s.transcribe(audioPath)),
      TranscriptionErrorKind.missingApiKey,
    );
    expect(called, isFalse);
  });

  test('fehlende Datei → invalidAudio', () async {
    final s = service(handler: (_) async => json(200, {'text': 'x'}));
    expect(
      await kindOf(s.transcribe('${tmp.path}/nope.m4a')),
      TranscriptionErrorKind.invalidAudio,
    );
  });

  test('HTTP-Status → Fehlerart', () async {
    final expectations = {
      401: TranscriptionErrorKind.unauthorized,
      403: TranscriptionErrorKind.unauthorized,
      429: TranscriptionErrorKind.rateLimited,
      400: TranscriptionErrorKind.invalidAudio,
      413: TranscriptionErrorKind.invalidAudio,
      500: TranscriptionErrorKind.server,
      503: TranscriptionErrorKind.server,
    };
    for (final e in expectations.entries) {
      final s = service(
        handler: (_) async => json(e.key, {
          'error': {'message': 'boom'},
        }),
      );
      expect(
        await kindOf(s.transcribe(audioPath)),
        e.value,
        reason: 'Status ${e.key}',
      );
    }
  });

  test('Fehlermeldung der API landet in cause', () async {
    final s = service(
      handler: (_) async => json(401, {
        'error': {'message': 'Incorrect API key'},
      }),
    );
    try {
      await s.transcribe(audioPath);
      fail('erwartete Exception');
    } on TranscriptionException catch (e) {
      expect(e.cause, 'Incorrect API key');
    }
  });

  test('Netzwerkfehler → network', () async {
    final s = service(
      handler: (_) async => throw const SocketException('offline'),
    );
    expect(
      await kindOf(s.transcribe(audioPath)),
      TranscriptionErrorKind.network,
    );
  });

  test('kaputtes JSON bei 200 → server', () async {
    final s = service(handler: (_) async => http.Response('not json', 200));
    expect(
      await kindOf(s.transcribe(audioPath)),
      TranscriptionErrorKind.server,
    );
  });
}
