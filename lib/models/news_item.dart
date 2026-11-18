class NewsItem {
  final String id;
  final String title;
  final String summary;
  final String content;
  final DateTime date;
  final List<String> affectedTickers;
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

  static List<NewsItem> getInitialNews() {
    return [
      NewsItem(
        id: '1',
        title: 'ЦБ РФ сохранил ключевую ставку на прежнем уровне',
        summary: 'Регулятор взял паузу в цикле ужесточения денежно-кредитной политики.',
        content:
            'Учебный сценарий: Банк России принял решение сохранить ключевую ставку. Замедление инфляционных рисков поддерживает рынок облигаций с фиксированным купоном (ОФЗ) и банковский сектор.',
        date: DateTime.now().subtract(const Duration(hours: 2)),
        affectedTickers: ['OFZ', 'SU26238', 'SBER', 'VTBR'],
        sentiment: 'positive',
        source: 'Демо (Учебный пример)',
      ),
      NewsItem(
        id: '2',
        title: 'Крупнейший банк опубликовал сильные финансовые результаты',
        summary: 'Чистая прибыль банка выросла на 15% год к году при высокой рентабельности капитала.',
        content:
            'Учебный сценарий: Сбер демонстрирует устойчивую рентабельность капитала (ROE свыше 22%) и рост чистого комиссионного дохода, формируя базу под годовые дивиденды.',
        date: DateTime.now().subtract(const Duration(hours: 5)),
        affectedTickers: ['SBER'],
        sentiment: 'positive',
        source: 'Демо (Учебный пример)',
      ),
      NewsItem(
        id: '3',
        title: 'Цены на нефть Brent корректируются на фоне роста запасов сырья',
        summary: 'Увеличение коммерческих запасов нефти оказывает давление на котировки экспортеров.',
        content:
            'Учебный сценарий: Снижение мировых цен на нефть может временно сократить валютную выручку и свободный денежный поток (FCF) компаний нефтегазового сектора.',
        date: DateTime.now().subtract(const Duration(hours: 9)),
        affectedTickers: ['GAZP', 'LKOH', 'ROSN'],
        sentiment: 'negative',
        source: 'Демо (Учебный пример)',
      ),
    ];
  }
}

