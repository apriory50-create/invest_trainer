// lib/models/news_item.dart
class NewsItem {
  final String id;
  final String title;
  final String summary;
  final String content;
  final DateTime date;
  final List<String> affectedTickers; // Например: ['SBER', 'GAZP', 'OFZ']
  final String sentiment; // 'positive', 'negative', 'neutral'
  final String source;

  NewsItem({
    required this.id,
    required this.title,
    required this.summary,
    required this.content,
    required this.date,
    required this.affectedTickers,
    required this.sentiment,
    required this.source,
  });

  // Моковые/стартовые новости для демонстрации
  static List<NewsItem> getInitialNews() {
    return [
      NewsItem(
        id: '1',
        title: 'ЦБ РФ неожиданно сохранил ключевую ставку на прежнем уровне',
        summary: 'Регулятор взял паузу в цикле ужесточения денежно-кредитной политики.',
        content: 'Банк России на сегодняшнем заседании принял решение сохранить ключевую ставку. Аналитики отмечают замедление инфляционных рисков, что позитивно для рынка облигаций (ОФЗ) и акций банковского сектора.',
        date: DateTime.now().subtract(const Duration(hours: 2)),
        affectedTickers: ['OFZ', 'SBER', 'VTBR'],
        sentiment: 'positive',
        source: 'РБК / ЦБ РФ',
      ),
      NewsItem(
        id: '2',
        title: 'Сбербанк опубликовал сильные финансовые результаты по РСБУ',
        summary: 'Чистая прибыль банка за прошлый месяц выросла на 15% г/г.',
        content: 'Сбер продолжает демонстрировать устойчивую рентабельность капитала. Рост кредитования физических лиц остается на высоком уровне несмотря на макропруденциальные лимиты.',
        date: DateTime.now().subtract(const Duration(hours: 5)),
        affectedTickers: ['SBER'],
        sentiment: 'positive',
        source: 'Интерфакс',
      ),
      NewsItem(
        id: '3',
        title: 'Цены на нефть марки Brent снижаются на фоне данных из США',
        summary: 'Увеличение коммерческих запасов нефти давит на котировки сырьевых компаний.',
        content: 'Экспортеры сырья могут столкнуться с временным сокращением валютной выручки, что отразится на дивидендной базе нефтяного сектора.',
        date: DateTime.now().subtract(const Duration(hours: 9)),
        affectedTickers: ['GAZP', 'LKOH', 'ROSN'],
        sentiment: 'negative',
        source: 'Bloomberg',
      ),
    ];
  }
}
