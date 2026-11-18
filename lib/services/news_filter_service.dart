import '../models/news_item.dart';

class NewsFilterService {
  static bool _matchesPortfolio(
    List<String> newsTickers,
    List<String> portfolioTickers,
  ) {
    final normPortfolio =
        portfolioTickers.map((t) => t.trim().toUpperCase()).toSet();
    final hasOfzInPortfolio =
        normPortfolio.any((t) => t.startsWith('SU') || t.startsWith('OFZ'));

    for (final rawNewsTicker in newsTickers) {
      final nt = rawNewsTicker.trim().toUpperCase();
      if (normPortfolio.contains(nt)) return true;
      if ((nt == 'OFZ' || nt.startsWith('SU')) && hasOfzInPortfolio) {
        return true;
      }
    }
    return false;
  }

  static List<NewsItem> getNewsForPortfolio(
    List<NewsItem> allNews,
    List<String> portfolioTickers,
  ) {
    if (portfolioTickers.isEmpty) return [];
    return allNews
        .where((news) => _matchesPortfolio(news.affectedTickers, portfolioTickers))
        .toList();
  }

  static NewsItem generateRandomMarketNews() {
    final randomEvents = [
      NewsItem(
        id: 'rand_${DateTime.now().millisecondsSinceEpoch}_1',
        title: 'Ускорение недельной инфляции: рынок ждет жесткого сигнала ЦБ',
        summary: 'Инфляционные ожидания выросли по итогам месяца.',
        content:
            'Учебный сценарий: Аналитики допускают повышение ключевой ставки на ближайшем заседании, что создает давление на длинные ОФЗ с постоянным купоном.',
        date: DateTime.now(),
        affectedTickers: ['OFZ', 'SU26238', 'SBER', 'VTBR'],
        sentiment: 'negative',
        source: 'Демо-генератор событий',
      ),
      NewsItem(
        id: 'rand_${DateTime.now().millisecondsSinceEpoch}_2',
        title: 'Экспортеры рекомендовали крупные промежуточные дивиденды',
        summary: 'Советы директоров направили свободный денежный поток на выплаты.',
        content:
            'Учебный сценарий: Рекомендация щедрых дивидендов вызвала приток покупателей в бумаги нефтегазового сектора.',
        date: DateTime.now(),
        affectedTickers: ['GAZP', 'LKOH', 'ROSN'],
        sentiment: 'positive',
        source: 'Демо-генератор событий',
      ),
      NewsItem(
        id: 'rand_${DateTime.now().millisecondsSinceEpoch}_3',
        title: 'IT-сектор отчитался о двузначном росте выручки за квартал',
        summary: 'Спрос на облачные сервисы и кибербезопасность продолжает расти.',
        content:
            'Учебный сценарий: Российские технологические компании показывают высокие темпы роста выручки на фоне корпоративного импортозамещения.',
        date: DateTime.now(),
        affectedTickers: ['OZON', 'YDEX', 'POSI'],
        sentiment: 'positive',
        source: 'Демо-генератор событий',
      ),
    ];

    randomEvents.shuffle();
    return randomEvents.first;
  }
}

