// lib/services/news_filter_service.dart
import '../models/news_item.dart';

class NewsFilterService {
  // Фильтрация новостей по тикерам, присутствующим в портфеле пользователя
  static List<NewsItem> getNewsForPortfolio(List<NewsItem> allNews, List<String> portfolioTickers) {
    if (portfolioTickers.isEmpty) return [];
    
    return allNews.where((news) {
      // Проверяем, есть ли пересечение между затронутыми в новости тикерами и портфелем
      return news.affectedTickers.any((ticker) => portfolioTickers.contains(ticker));
    }).toList();
  }

  // Генератор случайной рыночной новости дня для симулятора
  static NewsItem generateRandomMarketNews() {
    final randomEvents = [
      NewsItem(
        id: 'rand_1',
        title: 'Неожиданный рост инфляции: ЦБ рассматривает жесткое решение',
        summary: 'Инфляционные ожидания населения и бизнеса выросли по итогам месяца.',
        content: 'Аналитики прогнозируют возможное повышение ключевой ставки на ближайшем заседании, что создает давление на рынок облигаций и акции роста.',
        date: DateTime.now(),
        affectedTickers: ['OFZ', 'SBER', 'VTBR'],
        sentiment: 'negative',
        source: 'Рыночный радар / Инсайдер',
      ),
      NewsItem(
        id: 'rand_2',
        title: 'Крупнейшие экспортеры объявили рекордные дивидендные выплаты',
        summary: 'Советы директоров рекомендовали выплатить акционерам до 75% от чистой прибыли.',
        content: 'Позитивные новости вызвали ралли в сырьевом секторе. Инвесторы массово перекладывают средства в дивидендные бумаги.',
        date: DateTime.now(),
        affectedTickers: ['GAZP', 'LKOH', 'ROSN'],
        sentiment: 'positive',
        source: 'MOEX Info',
      ),
      NewsItem(
        id: 'rand_3',
        title: 'Технологический сектор показывает опережающие темпы роста выручки',
        summary: 'Импортозамещение ПО и облачных сервисов приносит свои плоды.',
        content: 'ИТ-компании отчитываются о двузначном росте финансовых показателей, привлекая внимание частных инвесторов.',
        date: DateTime.now(),
        affectedTickers: ['OZON', 'YNDX', 'POSITI'],
        sentiment: 'positive',
        source: 'ТехноРынок',
      ),
    ];

    randomEvents.shuffle();
    return randomEvents.first;
  }
}
