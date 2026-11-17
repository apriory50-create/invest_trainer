import 'package:shared_preferences/shared_preferences.dart';

class StorageService {
  static const String _keyCompletedLessons = 'completed_lessons';
  static const String _keyPortfolioBalance = 'portfolio_balance';
  static const String _keyUserXp = 'user_xp';

  // Сохранение пройденных уроков
  static Future<void> saveCompletedLessons(List<int> lessonIds) async {
    final prefs = await SharedPreferences.getInstance();
    final listStr = lessonIds.map((id) => id.toString()).toList();
    await prefs.setStringList(_keyCompletedLessons, listStr);
  }

  // Загрузка пройденных уроков
  static Future<List<int>> loadCompletedLessons() async {
    final prefs = await SharedPreferences.getInstance();
    final listStr = prefs.getStringList(_keyCompletedLessons) ?? [];
    return listStr.map((id) => int.parse(id)).toList();
  }

  // Сохранение баланса
  static Future<void> saveBalance(double balance) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_keyPortfolioBalance, balance);
  }

  // Загрузка баланса (по умолчанию 100,000 руб)
  static Future<double> loadBalance() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getDouble(_keyPortfolioBalance) ?? 100000.0;
  }
}
