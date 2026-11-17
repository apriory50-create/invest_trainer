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
    String lowerTitle = newsTitle.toLowerCase();
    
    if (lowerTitle.contains('ставка') || lowerTitle.contains('инфляция') || lowerTitle.contains('санкции')) {
      if (ticker.startsWith('OFZ')) {
        return AiRiskAnalysisResult(
          sentiment: 'Негативно',
          riskScore: 65.0,
          summary: 'Рост ключевой ставки снижает рыночную стоимость текущих облигаций с фиксированным купоном.',
        );
      } else {
        return AiRiskAnalysisResult(
          sentiment: 'Нейтрально',
          riskScore: 45.0,
          summary: 'Макроэкономическое давление умеренно влияет на акции широкого рынка.',
        );
      }
    } else if (lowerTitle.contains('дивиденд') || lowerTitle.contains('прибыль') || lowerTitle.contains('рост')) {
      return AiRiskAnalysisResult(
        sentiment: 'Позитивно',
        riskScore: 15.0,
        summary: 'Отличные новости для держателей актива. Ожидается приток капитала.',
      );
    } else {
      return AiRiskAnalysisResult(
        sentiment: 'Нейтрально',
        riskScore: 30.0,
        summary: 'Новость носит информационный характер, существенного изменения котировок не ожидается.',
      );
    }
  }
}
