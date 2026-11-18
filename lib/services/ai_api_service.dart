import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class AiApiService {
  static const String _legacyKeyApiKey = 'user_custom_api_key';
  static const String _keyObfuscatedApiKey = 'user_obf_api_key_v2';
  static const String _keyRememberOnDisk = 'user_remember_api_key';
  static const String _keyApiUrl = 'user_custom_api_url';
  static const String _defaultUrl =
      'https://api.openai.com/v1/chat/completions';

  // Безопасное хранение ключа только в оперативной памяти на время сессии
  static String _sessionApiKey = '';

  static String _xorObfuscate(String input) {
    final bytes = utf8.encode(input);
    final mask = [0x5A, 0x3C, 0x7E, 0x19, 0xA5];
    final out = List<int>.generate(
      bytes.length,
      (i) => bytes[i] ^ mask[i % mask.length],
    );
    return base64Encode(out);
  }

  static String _xorDeobfuscate(String encoded) {
    try {
      final bytes = base64Decode(encoded);
      final mask = [0x5A, 0x3C, 0x7E, 0x19, 0xA5];
      final out = List<int>.generate(
        bytes.length,
        (i) => bytes[i] ^ mask[i % mask.length],
      );
      return utf8.decode(out);
    } catch (_) {
      return '';
    }
  }

  static Future<void> saveSettings(
    String apiKey,
    String apiUrl, {
    bool rememberOnDevice = false,
  }) async {
    _sessionApiKey = apiKey.trim();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_legacyKeyApiKey); // Удаляем старый открытый ключ
    await prefs.setBool(_keyRememberOnDisk, rememberOnDevice);

    if (rememberOnDevice && _sessionApiKey.isNotEmpty) {
      await prefs.setString(
        _keyObfuscatedApiKey,
        _xorObfuscate(_sessionApiKey),
      );
    } else {
      await prefs.remove(_keyObfuscatedApiKey);
    }

    await prefs.setString(
      _keyApiUrl,
      apiUrl.trim().isEmpty ? _defaultUrl : apiUrl.trim(),
    );
  }

  static Future<bool> getRememberKeyPreference() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyRememberOnDisk) ?? false;
  }

  static Future<String> getApiKey() async {
    if (_sessionApiKey.isNotEmpty) return _sessionApiKey;
    final prefs = await SharedPreferences.getInstance();

    // Миграция и удаление старого открытого ключа при первом чтении
    final legacyPlain = prefs.getString(_legacyKeyApiKey);
    if (legacyPlain != null && legacyPlain.isNotEmpty) {
      _sessionApiKey = legacyPlain;
      await prefs.remove(_legacyKeyApiKey);
      return _sessionApiKey;
    }

    final encoded = prefs.getString(_keyObfuscatedApiKey);
    if (encoded != null && encoded.isNotEmpty) {
      _sessionApiKey = _xorDeobfuscate(encoded);
      return _sessionApiKey;
    }
    return '';
  }

  static Future<String> getApiUrl() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyApiUrl) ?? _defaultUrl;
  }

  static bool isSecureEndpoint(String urlStr) {
    final uri = Uri.tryParse(urlStr.trim());
    if (uri == null) return false;
    if (uri.scheme == 'https') return true;
    if (uri.scheme == 'http' &&
        (uri.host == 'localhost' || uri.host == '127.0.0.1')) {
      return true;
    }
    return false;
  }

  static Future<String> analyzeText(String promptText) async {
    final apiKey = await getApiKey();
    final apiUrl = await getApiUrl();

    if (apiKey.isEmpty) {
      return 'API-ключ не задан. Откройте настройки (шестерёнка справа вверху на этой вкладке) и укажите ключ.';
    }

    if (!isSecureEndpoint(apiUrl)) {
      return 'Заблокировано в целях безопасности: передача API-ключа разрешена только по защищенному протоколу HTTPS (или на localhost).';
    }

    try {
      final response = await http
          .post(
            Uri.parse(apiUrl),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $apiKey',
            },
            body: jsonEncode({
              'model': 'gpt-4o-mini',
              'messages': [
                {
                  'role': 'system',
                  'content':
                      'Ты финансовый ИИ-ассистент в приложении invest_trainer. Отвечай кратко, структурно и понятным языком.',
                },
                {'role': 'user', 'content': promptText},
              ],
              'temperature': 0.5,
            }),
          )
          .timeout(const Duration(seconds: 20));

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        return data['choices']?[0]?['message']?['content']?.toString() ??
            'Пустой ответ от ИИ-модели.';
      } else {
        return 'Ошибка API (Статус ${response.statusCode}):\n${response.body}';
      }
    } catch (e) {
      return 'Ошибка соединения с API: $e';
    }
  }
}

