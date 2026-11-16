import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';

class AppState extends ChangeNotifier {
  bool isProMode = false;
  int themeIndex = 0; // 0: Dark, 1: Light, 2: OLED
  double cbRate = 21.0;
  double virtualBalance = 100000.0;
  List<String>completedLessons = [];
  List> mistakeDiary = [
    {'date': '15.11.2026', 'asset': 'Газпром', 'error': 'Покупка под дивиденды без учёта дивгэпа и налога 13%', 'loss': -4200}
  ];

  List> portfolio = [
    {'ticker': 'SU26238', 'name': 'ОФЗ 26238', 'type': 'bond', 'qty': 50, 'buyPrice': 510.0, 'currPrice': 502.0, 'duration': 7.8, 'coupon': 7.1},
    {'ticker': 'SBER', 'name': 'Сбербанк', 'type': 'stock', 'qty': 100, 'buyPrice': 240.0, 'currPrice': 265.0, 'duration': 0.0, 'coupon': 12.5},
    {'ticker': 'LQDT', 'name': 'Фонд Ликвидность', 'type': 'etf', 'qty': 10000, 'buyPrice': 1.45, 'currPrice': 1.58, 'duration': 0.1, 'coupon': 20.5},
  ];

  void toggleProMode() {
    isProMode = !isProMode;
    notifyListeners();
  }

  void cycleTheme() {
    themeIndex = (themeIndex + 1) % 3;
    notifyListeners();
  }

  void updateCbRate(double val) {
    cbRate = val;
    notifyListeners();
  }

  void addMistake(String asset, String error, double loss) {
    mistakeDiary.insert(0, {'date': 'Сегодня', 'asset': asset, 'error': error, 'loss': loss});
    notifyListeners();
  }

  void addAsset(String ticker, String name, String type, int qty, double price, double dur) {
    portfolio.add({'ticker': ticker, 'name': name, 'type': type, 'qty': qty, 'buyPrice': price, 'currPrice': price, 'duration': dur, 'coupon': 15.0});
    notifyListeners();
  }

  void completeLesson(String id) {
    if (!completedLessons.contains(id)) {
      completedLessons.add(id);
      notifyListeners();
    }
  }

  String exportBackupJson() {
    return jsonEncode({
      'isProMode': isProMode,
      'virtualBalance': virtualBalance,
      'cbRate': cbRate,
      'completedLessons': completedLessons,
      'mistakeDiary': mistakeDiary,
      'portfolio': portfolio,
    });
  }

  bool importBackupJson(String jsonStr) {
    try {
      final data = jsonDecode(jsonStr);
      isProMode = data['isProMode'] ?? false;
      virtualBalance = (data['virtualBalance'] ?? 100000.0).toDouble();
      cbRate = (data['cbRate'] ?? 21.0).toDouble();
      completedLessons = List<String>.from(data['completedLessons'] ?? []);
      mistakeDiary = List>.from(data['mistakeDiary'] ?? []);
      portfolio = List>.from(data['portfolio'] ?? []);
      notifyListeners();
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<String> sendTelegramBackup(String botToken, String chatId) async {
    if (botToken.isEmpty || chatId.isEmpty) return 'Введите токен и Chat ID';
    try {
      final client = HttpClient();
      final uri = Uri.parse('https://api.telegram.org/bot$botToken/sendMessage');
      final req = await client.postUrl(uri);
      req.headers.set('content-type', 'application/json');
      req.write(jsonEncode({'chat_id': chatId, 'text': '📦 БЭКАП ИНВЕСТ-ТРЕНАЖЕРА:\n${exportBackupJson()}'}));
      final res = await req.close();
      return res.statusCode == 200 ? 'Успешно отправлено в Telegram!' : 'Ошибка API: код ${res.statusCode}';
    } catch (e) {
      return 'Офлайн-режим: скопируйте JSON вручную';
    }
  }
}
