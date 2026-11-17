// lib/services/ai_api_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class AiApiService {
  static const String _keyApiKey = 'user_custom_api_key';
  static const String _keyApiUrl = 'user_custom_api_url';

  // Сохранение настроек API
  static Future<void> saveSettings(String apiKey, String apiUrl) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyApiKey, apiKey);
    await prefs.setString(_keyApiUrl, apiUrl.isEmpty ? 'https://api.openai.com/v1/chat/completions' : apiUrl);
  }

  // Получение сохраненного ключа
  static Future<String> getApiKey() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyApiKey) ?? '';
  }

  // Получение сохраненного URL
  static Future<String> getApiUrl() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyApiUrl) ?? 'https://api.openai.com/v1/chat/completions';
  }

  // Запрос к произвольному API для анализа новости или портфеля
  static Future<String> analyzeText(String promptText) async {
    final apiKey = await getApiKey();
    final apiUrl = await getApiUrl();

    if (apiKey.isEmpty) {
      return 'Ошибка: API-ключ не задан. Укажите ключ в настройках приложения.';
    }

    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $apiKey',
        },
        body: jsonEncode({
          'model': 'gpt-4o-mini', // Или универсальный формат для совместимых API
          'messages': [
            {'role': 'system', 'content': 'Ты финансовый ИИ-ассистент в приложении invest_trainer.'},
            {'role': 'user', 'content': promptText}
          ],
          'temperature': 0.7,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        return data['choices'][0]['message']['content'] ?? 'Пустой ответ от модели.';
      } else {
        return 'Ошибка API: Статус ${response.statusCode}\n${response.body}';
      }
    } catch (e) {
      return 'Ошибка соединения с API: $e';
    }
  }
}
