class AiRiskAnalysisResult {
  final String sentiment;
  final double riskScore;
  final String summary;

  AiRiskAnalysisResult({
    required this.sentiment,
    required this.riskScore,
    required this.summary,
  });
}

class AiRiskAnalyzer {
  static AiRiskAnalysisResult analyzeNews({
    required String newsTitle,
    required String ticker,
  }) {
    final lowerTitle = newsTitle.toLowerCase();
    final upperTicker = ticker.trim().toUpperCase();
    final isBond =
        upperTicker.startsWith('SU') || upperTicker.startsWith('OFZ');

    final hasMacroTrigger = lowerTitle.contains('ставк') ||
        lowerTitle.contains('инфляц') ||
        lowerTitle.contains('санкц') ||
        lowerTitle.contains('цб');

    if (hasMacroTrigger) {
      final isRateCut = lowerTitle.contains('сниз') ||
          lowerTitle.contains('смягч') ||
          lowerTitle.contains('замедл');
      if (isRateCut) {
        return AiRiskAnalysisResult(
          sentiment: 'Позитивно',
          riskScore: 20.0,
          summary: isBond
              ? 'Замедление инфляции и снижение ставки ЦБ ведут к росту рыночной цены тела длинных ОФЗ.'
              : 'Смягчение денежно-кредитной политики поддерживает оценку акций.',
        );
      }

      if (isBond) {
        return AiRiskAnalysisResult(
          sentiment: 'Негативно',
          riskScore: 65.0,
          summary:
              'Рост ключевой ставки или инфляции снижает рыночную стоимость облигаций с фиксированным купоном.',
        );
      } else {
        return AiRiskAnalysisResult(
          sentiment: 'Осторожно',
          riskScore: 48.0,
          summary:
              'Жесткая процентная политика повышает стоимость долга для компаний и усиливает конкуренцию со стороны депозитов.',
        );
      }
    } else if (lowerTitle.contains('дивиденд') ||
        lowerTitle.contains('прибыл') ||
        lowerTitle.contains('рост') ||
        lowerTitle.contains('байбэк')) {
      final isNegativeDiv = lowerTitle.contains('отказ') ||
          lowerTitle.contains('отмен') ||
          lowerTitle.contains('сниз') ||
          lowerTitle.contains('упал');
      if (isNegativeDiv) {
        return AiRiskAnalysisResult(
          sentiment: 'Негативно',
          riskScore: 70.0,
          summary:
              'Отказ от дивидендов или падение прибыли негативно отражается на котировках.',
        );
      }
      return AiRiskAnalysisResult(
        sentiment: 'Позитивно',
        riskScore: 18.0,
        summary:
            'Рост финансовых показателей или выплата дивидендов поддерживают интерес к бумаге.',
      );
    } else {
      return AiRiskAnalysisResult(
        sentiment: 'Нейтрально',
        riskScore: 30.0,
        summary:
            'Новость носит общий информационный характер, резкого изменения фундаментальной оценки не ожидается.',
      );
    }
  }
}

