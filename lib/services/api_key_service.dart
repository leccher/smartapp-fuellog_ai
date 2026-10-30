import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ApiKeyService {
  static const _storage = FlutterSecureStorage();
  static const _storageKey = 'gemini_api_key';

  /// Recupera la chiave API (prima dal file .env, poi dallo storage sicuro)
  static Future<String?> getActiveApiKey() async {
    String? apiKey;
    // 1. Prova a leggerla dal file .env (protetto da try-catch se .env non è inizializzato)
    try {
      apiKey = dotenv.env['GEMINI_API_KEY'];
    } catch (_) {
      apiKey = null;
    }
    
    // 2. Se non è presente nel .env, la legge dallo storage sicuro (per gli utenti dello store)
    if (apiKey == null || apiKey.isEmpty) {
      apiKey = await _storage.read(key: _storageKey);
    }
    return apiKey;
  }


  /// Salva la chiave inserita dall'utente nello storage sicuro
  static Future<void> saveApiKey(String key) async {
    await _storage.write(key: _storageKey, value: key.trim());
  }

  /// Cancella la chiave salvata (utile per il reset o il logout)
  static Future<void> deleteApiKey() async {
    await _storage.delete(key: _storageKey);
  }
}