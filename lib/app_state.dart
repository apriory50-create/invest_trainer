import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';

class MistakeItem {
  final String date;
  final String asset;
  final String error;
  final double loss;
  MistakeItem(this.date, this.asset, this.error, this.loss);

  Map toJson() => {'date': date, 'asset': asset, 'error': error, 'loss': loss};
  static MistakeItem fromJson(dynamic m) => MistakeItem(
        (m['date'] ?? 'Сегодня').toString(),
        (m['asset'] ?? '').toString(),
        (m['error'] ?? '').toString(),
        ((m['loss'] ?? 0) as num).toDouble(),
      );
}

class AssetItem {
  final String ticker;
  final String name;
  final String type;
  final int qty;
  final double buyPrice;
  final double currPrice;
  final double duration;
  final double coupon;

  AssetItem(this.ticker, this.name, this.type, this.qty, this.buyPrice, this.currPrice, this.duration, this.coupon);

  Map toJson() => {
        'ticker': ticker,
        'name': name,
        'type': type,
        'qty': qty,
        'buyPrice': buyPrice,
        'currPrice': currPrice,
        'duration': duration,
        'coupon': coupon,
      };

  static AssetItem fromJson(dynamic m) => AssetItem(
        (m['ticker'] ?? '').toString(),
        (m['name'] ?? '').toString(),
        (m['type'] ?? 'stock').toString(),
        ((m['qty'] ?? 1) as num).toInt(),
        ((m['buyPrice'] ?? 100) as num).toDouble(),
        ((m['currPrice'] ?? 100) as num).toDouble(),
        ((m['duration'] ?? 0) as num).toDouble(),
        ((m['coupon'] ?? 0) as num).toDouble(),
      );
}

class AppState extends ChangeNotifier {
  bool isProMode = false;
  int themeIndex = 0;
  double cbRate = 21.0;
  double virtualBalance = 100000.0;
  List completedLessons = [];

  List mistakeDiary = [
    MistakeItem('15.11.2026', 'Газпром', 'Покупка под дивиденды без учёта дивгэпа и налога 13%', -4200.0),
  ];

  List portfolio = [
    AssetItem('SU26238', 'ОФЗ 26238', 'bond', 50, 510.0, 502.0, 7.8, 7.1),
    AssetItem('SBER', 'Сбербанк', 'stock', 100, 240.0, 265.0, 0.0, 12.5),
    AssetItem('LQDT', 'Фонд Ликвидность', 'etf', 10000, 1.45, 1.58, 0.1, 20.5),
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
    mistakeDiary.insert(0, MistakeItem('Сегодня', asset, error, loss));
    notifyListeners();
  }

  void addAsset(String ticker, String name, String type, int qty, double price, double dur) {
    portfolio.add(AssetItem(ticker, name, type, qty, price, price, dur, 15.0));
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
      'mistakeDiary': mistakeDiary.map((e) => (e as MistakeItem).toJson()).toList(),
      'portfolio': portfolio.map((e) => (e as AssetItem).toJson()).toList(),
    });
  }

  bool importBackupJson(String jsonStr) {
    try {
      final data = jsonDecode(jsonStr);
      isProMode = data['isProMode'] ?? false;
      virtualBalance = ((data['virtualBalance'] ?? 100000.0) as num).toDouble();
      cbRate = ((data['cbRate'] ?? 21.0) as num).toDouble();
      completedLessons = (data['completedLessons'] as List? ?? []).map((e) => e.toString()).toList();
      mistakeDiary = (data['mistakeDiary'] as List? ?? []).map((e) => MistakeItem.fromJson(e)).toList();
      portfolio = (data['portfolio'] as List? ?? []).map((e) => AssetItem.fromJson(e)).toList();
      notifyListeners();
      return true;
    } catch (_) {
      return false;
    }
  }

  Future sendTelegramBackup(String botToken, String chatId) async {
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

