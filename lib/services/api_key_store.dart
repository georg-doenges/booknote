import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Sichere Ablage der vom Nutzer hinterlegten API-Keys.
///
/// Interface, damit Tests und UI-Entwicklung ohne Secure Storage auskommen.
abstract class ApiKeyStore {
  Future<String?> getOpenAiKey();
  Future<void> setOpenAiKey(String? key);

  /// Optionaler Google-Books-Key (PROJECT.md 7a). `null` = ohne Key abfragen.
  Future<String?> getGoogleBooksKey();
  Future<void> setGoogleBooksKey(String? key);
}

/// Produktive Implementierung über `flutter_secure_storage`
/// (Android Keystore / iOS Keychain).
class SecureApiKeyStore implements ApiKeyStore {
  SecureApiKeyStore({FlutterSecureStorage? storage})
    : _storage =
          storage ??
          const FlutterSecureStorage(
            aOptions: AndroidOptions(encryptedSharedPreferences: true),
          );

  static const _openAiKey = 'openai_api_key';
  static const _googleBooksKey = 'google_books_api_key';

  final FlutterSecureStorage _storage;

  @override
  Future<String?> getOpenAiKey() => _read(_openAiKey);

  @override
  Future<void> setOpenAiKey(String? key) => _write(_openAiKey, key);

  @override
  Future<String?> getGoogleBooksKey() => _read(_googleBooksKey);

  @override
  Future<void> setGoogleBooksKey(String? key) => _write(_googleBooksKey, key);

  Future<String?> _read(String k) async {
    final v = await _storage.read(key: k);
    return (v == null || v.trim().isEmpty) ? null : v.trim();
  }

  Future<void> _write(String k, String? v) async {
    if (v == null || v.trim().isEmpty) {
      await _storage.delete(key: k);
    } else {
      await _storage.write(key: k, value: v.trim());
    }
  }
}

/// Für Tests und Entwicklung.
class InMemoryApiKeyStore implements ApiKeyStore {
  String? openAiKey;
  String? googleBooksKey;

  InMemoryApiKeyStore({this.openAiKey, this.googleBooksKey});

  @override
  Future<String?> getOpenAiKey() async => openAiKey;
  @override
  Future<void> setOpenAiKey(String? key) async => openAiKey = key;
  @override
  Future<String?> getGoogleBooksKey() async => googleBooksKey;
  @override
  Future<void> setGoogleBooksKey(String? key) async => googleBooksKey = key;
}
