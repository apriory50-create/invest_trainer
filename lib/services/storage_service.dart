import 'package:shared_preferences/shared_preferences.dart';

class StorageService {
  static const String _keyAppStateJson = 'invest_trainer_full_state_v2';

  static Future<void> saveFullStateJson(String jsonStr) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyAppStateJson, jsonStr);
  }

  static Future<String?> loadFullStateJson() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyAppStateJson);
  }
}

