import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/news_item.dart';

class NewsSourceConfig {
  final String id;
  final String name;
  final String url;
  final String type; // 'rss', 'http'

  NewsSourceConfig({
    required this.id,
    required this.name,
    required this.url,
    required this.type,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'url': url,
        'type': type,
      };

  factory NewsSourceConfig.fromJson(Map<String, dynamic> json) =>
      NewsSourceConfig(
        id: (json['id'] ?? '').toString(),
        name: (json['name'] ?? 'Источник').toString(),
        url: (json['url'] ?? '').toString(),
        type: (json['type'] ?? 'rss').toString(),
      );
}

class NewsSourceService {
  static const String _storageKey = 'custom_news_sources_list';

  static List<NewsSourceConfig> getDefaultSources() {
    return [
      NewsSourceConfig(
        id: '1',
        name: 'РБК (RSS-лента)',
        url: 'https://rssexport.rbc.ru/rbcnews/news/30/full.rss',
        type: 'rss',
      ),
      NewsSourceConfig(
        id: '2',
        name: 'Интерфакс (RSS)',
        url: 'https://www.interfax.ru/rss.asp',
        type: 'rss',
      ),
    ];
  }

  static Future<List<NewsSourceConfig>> getSources() async {
    final prefs = await SharedPreferences.getInstance();
    final String? data = prefs.getString(_storageKey);
    if (data == null) {
      return getDefaultSources();
    }
    try {
      final List decoded = jsonDecode(data);
      return decoded.map((e) => NewsSourceConfig.fromJson(e)).toList();
    } catch (_) {
      return getDefaultSources();
    }
  }

  static Future<void> addSource(String name, String url, String type) async {
    final sources = await getSources();
    sources.add(
      NewsSourceConfig(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: name,
        url: url,
        type: type,
      ),
    );
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _storageKey,
      jsonEncode(sources.map((e) => e.toJson()).toList()),
    );
  }

  static Future<void> removeSource(String id) async {
    final sources = await getSources();
    sources.removeWhere((element) => element.id == id);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _storageKey,
      jsonEncode(sources.map((e) => e.toJson()).toList()),
    );
  }

  // Декодирование ответа с поддержкой UTF-8 и Windows-1251 (CP1251)
  static String decodeResponseBytes(
    Uint8List bytes, {
    String? contentTypeHeader,
  }) {
    final headerLower = (contentTypeHeader ?? '').toLowerCase();
    final asciiHead = String.fromCharCodes(
      bytes.take(250),
    ).toLowerCase();

    final isWin1251 = headerLower.contains('1251') ||
        asciiHead.contains('windows-1251') ||
        asciiHead.contains('cp1251');

    if (isWin1251) {
      return _decodeWindows1251(bytes);
    }

    try {
      return utf8.decode(bytes);
    } catch (_) {
      return _decodeWindows1251(bytes);
    }
  }

  static String _decodeWindows1251(Uint8List bytes) {
    final buffer = StringBuffer();
    for (final b in bytes) {
      if (b < 0x80) {
        buffer.writeCharCode(b);
      } else if (b >= 0xC0 && b <= 0xFF) {
        buffer.writeCharCode(0x0410 + (b - 0xC0));
      } else if (b == 0xA8) {
        buffer.writeCharCode(0x0401); // Ё
      } else if (b == 0xB8) {
        buffer.writeCharCode(0x0451); // ё
      } else if (b == 0xB9) {
        buffer.writeCharCode(0x2116); // №
      } else if (b == 0x96 || b == 0x97) {
        buffer.write('—');
      } else if (b == 0xAB) {
        buffer.write('«');
      } else if (b == 0xBB) {
        buffer.write('»');
      } else {
        buffer.write(' ');
      }
    }
    return buffer.toString();
  }

  static String _cleanXmlText(String raw) {
    return raw
        .replaceAll(RegExp(r'<!\[CDATA\[([\s\S]*?)\]\]>'), r'$1')
        .replaceAll(RegExp(r'<[^>]*>'), ' ')
        .replaceAll('&quot;', '"')
        .replaceAll('&amp;', '&')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&nbsp;', ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  static List<String> _detectTickers(String text) {
    final lower = text.toLowerCase();
    final found = <String>{};
    if (lower.contains('сбер') || lower.contains('sber')) found.add('SBER');
    if (lower.contains('лукойл') || lower.contains('lkoh')) found.add('LKOH');
    if (lower.contains('газпром') || lower.contains('gazp')) found.add('GAZP');
    if (lower.contains('роснефт') || lower.contains('rosn')) found.add('ROSN');
    if (lower.contains('втб') || lower.contains('vtbr')) found.add('VTBR');
    if (lower.contains('яндекс') || lower.contains('ydex')) found.add('YDEX');
    if (lower.contains('позитив') || lower.contains('posi')) found.add('POSI');
    if (lower.contains('озон') || lower.contains('ozon')) found.add('OZON');
    if (lower.contains('офз') ||
        lower.contains('цб') ||
        lower.contains('ставк') ||
        lower.contains('инфляц') ||
        lower.contains('минфин')) {
      found.add('OFZ');
    }
    if (found.isEmpty) found.add('MOEX');
    return found.toList();
  }

  static String _detectSentiment(String text) {
    final lower = text.toLowerCase();
    if (lower.contains('рост') ||
        lower.contains('вырос') ||
        lower.contains('рекорд') ||
        lower.contains('дивиденд') ||
        lower.contains('прибыл')) {
      return 'positive';
    }
    if (lower.contains('упал') ||
        lower.contains('сниз') ||
        lower.contains('санкц') ||
        lower.contains('убыт') ||
        lower.contains('дефолт')) {
      return 'negative';
    }
    return 'neutral';
  }

  static List<NewsItem> parseRssXml(String xml, String sourceName) {
    final items = <NewsItem>[];
    final itemMatches =
        RegExp(r'<item[\s>]([\s\S]*?)<\/item>', caseSensitive: false)
            .allMatches(xml);

    int counter = 0;
    for (final match in itemMatches) {
      if (counter >= 5) break;
      final block = match.group(1) ?? '';
      final titleMatch =
          RegExp(r'<title[^>]*>([\s\S]*?)<\/title>', caseSensitive: false)
              .firstMatch(block);
      final descMatch = RegExp(
        r'<description[^>]*>([\s\S]*?)<\/description>',
        caseSensitive: false,
      ).firstMatch(block);

      final title = _cleanXmlText(titleMatch?.group(1) ?? '');
      final desc = _cleanXmlText(descMatch?.group(1) ?? '');
      if (title.isEmpty) continue;

      final combined = '$title $desc';
      items.add(
        NewsItem(
          id: 'rss_${sourceName.hashCode}_$counter',
          title: title,
          summary: desc.isEmpty ? 'Новость из RSS-ленты $sourceName' : desc,
          content: desc.isEmpty ? title : desc,
          date: DateTime.now(),
          affectedTickers: _detectTickers(combined),
          sentiment: _detectSentiment(combined),
          source: sourceName,
        ),
      );
      counter++;
    }
    return items;
  }

  static Future<List<NewsItem>> fetchNewsFromSource(
    NewsSourceConfig source,
  ) async {
    try {
      final uri = Uri.parse(source.url);
      final response =
          await http.get(uri).timeout(const Duration(seconds: 8));
      if (response.statusCode == 200) {
        final xmlText = decodeResponseBytes(
          response.bodyBytes,
          contentTypeHeader: response.headers['content-type'],
        );
        final parsed = parseRssXml(xmlText, source.name);
        if (parsed.isNotEmpty) {
          return parsed;
        }
      }
      return [
        NewsItem(
          id: 'err_${source.id}',
          title: 'Лента «${source.name}» не содержит RSS-записей (код ${response.statusCode})',
          summary:
              'Проверьте адрес RSS-канала. Прямые ссылки на Telegram-каналы без RSS-моста не поддерживаются.',
          content: 'Источник ${source.url} вернул пустой список новостей.',
          date: DateTime.now(),
          affectedTickers: ['MOEX'],
          sentiment: 'neutral',
          source: '${source.name} (Статус)',
        ),
      ];
    } catch (_) {
      return [
        NewsItem(
          id: 'offline_${source.id}',
          title: 'Офлайн-режим: источник «${source.name}» сейчас недоступен',
          summary:
              'Не удалось загрузить RSS-ленту (${source.url}). Работают встроенные учебные сценарии.',
          content:
              'Проверьте подключение к интернету или корректность ссылки на RSS-поток.',
          date: DateTime.now(),
          affectedTickers: ['MOEX'],
          sentiment: 'neutral',
          source: '${source.name} (Офлайн)',
        ),
      ];
    }
  }
}

