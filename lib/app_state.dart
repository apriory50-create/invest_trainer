import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'services/storage_service.dart';

class MistakeItem {
  final String date;
  final String asset;
  final String error;
  final double loss;
  MistakeItem(this.date, this.asset, this.error, this.loss);

  Map<String, dynamic> toJson() => {
        'date': date,
        'asset': asset,
        'error': error,
        'loss': loss,
      };

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

  AssetItem(
    this.ticker,
    this.name,
    this.type,
    this.qty,
    this.buyPrice,
    this.currPrice,
    this.duration,
    this.coupon,
  );

  Map<String, dynamic> toJson() => {
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
  List<int> completedLessons = [];

  List<MistakeItem> mistakeDiary = [
    MistakeItem(
      '15.11.2026',
      'Газпром',
      'Покупка под дивиденды без учёта дивгэпа и налога НДФЛ',
      -4200.0,
    ),
  ];

  List<AssetItem> portfolio = [
    AssetItem('SU26238', 'ОФЗ 26238', 'bond', 50, 510.0, 502.0, 7.8, 7.1),
    AssetItem('SBER', 'Сбербанк', 'stock', 100, 240.0, 265.0, 0.0, 12.5),
    AssetItem('LQDT', 'Фонд Ликвидность', 'etf', 10000, 1.45, 1.58, 0.1, 20.5),
  ];

  AppState() {
    _initFromStorage();
  }

  List<String> get portfolioTickers =>
      portfolio.map((e) => e.ticker.toUpperCase()).toSet().toList();

  Future<void> _initFromStorage() async {
    final saved = await StorageService.loadFullStateJson();
    if (saved != null && saved.isNotEmpty) {
      importBackupJson(saved, saveAfter: false);
    }
  }

  void _persist() {
    StorageService.saveFullStateJson(exportBackupJson());
  }

  void toggleProMode() {
    isProMode = !isProMode;
    _persist();
    notifyListeners();
  }

  void cycleTheme() {
    themeIndex = (themeIndex + 1) % 3;
    _persist();
    notifyListeners();
  }

  void updateCbRate(double val) {
    cbRate = val;
    _persist();
    notifyListeners();
  }

  void updateBalance(double newBalance) {
    virtualBalance = newBalance;
    _persist();
    notifyListeners();
  }

  void addMistake(String asset, String error, double loss) {
    final now = DateTime.now();
    final dateStr =
        '${now.day.toString().padLeft(2, '0')}.${now.month.toString().padLeft(2, '0')}.${now.year}';
    mistakeDiary.insert(0, MistakeItem(dateStr, asset, error, loss));
    _persist();
    notifyListeners();
  }

  void addAsset(
    String ticker,
    String name,
    String type,
    int qty,
    double price,
    double dur,
  ) {
    portfolio.add(AssetItem(ticker, name, type, qty, price, price, dur, 15.0));
    _persist();
    notifyListeners();
  }

  void completeLesson(int id) {
    if (!completedLessons.contains(id)) {
      completedLessons.add(id);
      _persist();
      notifyListeners();
    }
  }

  String exportBackupJson() {
    return jsonEncode({
      'isProMode': isProMode,
      'virtualBalance': virtualBalance,
      'cbRate': cbRate,
      'completedLessons': completedLessons,
      'mistakeDiary': mistakeDiary.map((e) => e.toJson()).toList(),
      'portfolio': portfolio.map((e) => e.toJson()).toList(),
    });
  }

  bool importBackupJson(String jsonStr, {bool saveAfter = true}) {
    try {
      final data = jsonDecode(jsonStr);
      if (data is! Map) return false;

      final newPro = data['isProMode'] == true;
      final newBal = ((data['virtualBalance'] ?? 100000.0) as num).toDouble();
      final newCb = ((data['cbRate'] ?? 21.0) as num).toDouble();

      final rawLessons = data['completedLessons'] as List? ?? [];
      final newLessons = <int>[];
      for (var item in rawLessons) {
        final parsed = int.tryParse(item.toString());
        if (parsed != null && !newLessons.contains(parsed)) {
          newLessons.add(parsed);
        }
      }

      final newMistakes = (data['mistakeDiary'] as List? ?? [])
          .map((e) => MistakeItem.fromJson(e))
          .toList();
      final newPortfolio = (data['portfolio'] as List? ?? [])
          .map((e) => AssetItem.fromJson(e))
          .toList();

      isProMode = newPro;
      virtualBalance = newBal;
      cbRate = newCb;
      completedLessons = newLessons;
      mistakeDiary = newMistakes;
      portfolio = newPortfolio;

      if (saveAfter) _persist();
      notifyListeners();
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<String> sendTelegramBackup(String botToken, String chatId) async {
    if (botToken.isEmpty || chatId.isEmpty) {
      return 'Введите Bot Token и ваш Chat ID';
    }
    try {
      final uri =
          Uri.parse('https://api.telegram.org/bot$botToken/sendDocument');
      final request = http.MultipartRequest('POST', uri)
        ..fields['chat_id'] = chatId
        ..fields['caption'] =
            '📦 Резервная копия Invest Trainer (Баланс: ${virtualBalance.toStringAsFixed(0)} ₽, Уроков: ${completedLessons.length}/100)'
        ..files.add(
          http.MultipartFile.fromString(
            'document',
            exportBackupJson(),
            filename: 'invest_trainer_backup.json',
          ),
        );

      final streamedRes =
          await request.send().timeout(const Duration(seconds: 12));
      return streamedRes.statusCode == 200
          ? 'Файл бэкапа успешно отправлен в Telegram!'
          : 'Ошибка Telegram API: код ${streamedRes.statusCode}';
    } catch (e) {
      return 'Офлайн-режим: скопируйте JSON вручную';
    }
  }
}


