import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'app_state.dart';

class RadarScreen extends StatefulWidget {
  final AppState state;
  const RadarScreen({super.key, required this.state});

  @override
  State<RadarScreen> createState() => _RadarScreenState();
}

class _RadarScreenState extends State<RadarScreen> {
  final _newsCtrl = TextEditingController(
    text:
        'ЦБ повысил ключевую ставку, а совет директоров Сбербанка рекомендовал рекордные дивиденды',
  );
  final _tgTokenCtrl = TextEditingController();
  final _tgChatCtrl = TextEditingController();
  final _jsonBackupCtrl = TextEditingController();
  String _analysisResult =
      'Нажмите «Просветить новость рентгеном», чтобы увидеть влияние на ваш реальный портфель.';
  String _backupStatus = '';

  @override
  void dispose() {
    _newsCtrl.dispose();
    _tgTokenCtrl.dispose();
    _tgChatCtrl.dispose();
    _jsonBackupCtrl.dispose();
    super.dispose();
  }

  void _analyzeNews() {
    final text = _newsCtrl.text.toLowerCase();
    final findings = <String>[];
    final portfolio = widget.state.portfolio;

    final bonds = portfolio.where((a) => a.type == 'bond').toList();
    final etfs = portfolio.where((a) => a.type == 'etf').toList();
    final stocks = portfolio.where((a) => a.type == 'stock').toList();

    final hasRateWord = text.contains('ставк') ||
        text.contains('цб') ||
        text.contains('инфляц') ||
        text.contains('ключев');

    if (hasRateWord) {
      final isCut = text.contains('сниз') ||
          text.contains('смягч') ||
          text.contains('пониз') ||
          text.contains('замедл');
      final bondNames = bonds.isEmpty
          ? 'облигаций в портфеле нет'
          : bonds
              .map((b) => '${b.ticker} (дюрация ${b.duration})')
              .join(', ');
      final etfNames =
          etfs.isEmpty ? '' : ' Фонды в портфеле: ${etfs.map((e) => e.ticker).join(', ')}.';

      if (isCut) {
        findings.add(
          '🟢 Смягчение ДКП / Снижение ставки ЦБ: Позитив для тела облигаций с фиксированным купоном ($bondNames) и рынка акций.',
        );
      } else {
        findings.add(
          '🔴 Ужесточение ДКП / Рост ставки ЦБ: Давление на цену длинных облигаций с постоянным купоном ($bondNames). Защиту дают флоатеры и фонды ликвидности.$etfNames',
        );
      }
    }

    if (text.contains('дивиденд')) {
      final isCanceled = text.contains('отказ') ||
          text.contains('не выплат') ||
          text.contains('отмен') ||
          text.contains('пропуск');

      final matchedStocks = stocks.where((s) {
        final t = s.ticker.toLowerCase();
        final n = s.name.toLowerCase();
        return text.contains(t) ||
            text.contains(n) ||
            (s.ticker == 'SBER' && text.contains('сбер')) ||
            (s.ticker == 'LKOH' && text.contains('лукойл')) ||
            (s.ticker == 'GAZP' && text.contains('газпром'));
      }).toList();

      final targetLabel = matchedStocks.isNotEmpty
          ? matchedStocks.map((s) => s.ticker).join(', ')
          : (stocks.isNotEmpty
              ? stocks.map((s) => s.ticker).join(', ')
              : 'акций в портфеле');

      if (isCanceled) {
        findings.add(
          '🔴 Негатив по дивидендам ($targetLabel): Отказ или отмена выплат обычно вызывает коррекцию котировок.',
        );
      } else {
        findings.add(
          '🟢 Дивидендный позитив ($targetLabel): Поддержка котировок, но учитывайте удержание НДФЛ и будущий дивидендный гэп утром в дату отсечки.',
        );
      }
    }

    if (text.contains('оферт') ||
        text.contains('дефолт') ||
        text.contains('допэмисс')) {
      findings.add(
        '⚠️ Корпоративный риск: Проверьте условия пут-оферты по облигациям и риск размытия доли (FPO) по акциям!',
      );
    }

    if (findings.isEmpty) {
      findings.add(
        '🟡 Нейтральный фон: Прямых триггеров для текущих бумаг вашего портфеля (${widget.state.portfolioTickers.join(", ")}) не обнаружено.',
      );
    }

    setState(() {
      _analysisResult = findings.join('\n\n');
    });
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '📡 Инфо-Радар портфеля',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _newsCtrl,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Вставьте текст новости из СМИ / Telegram',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 8),
                ElevatedButton.icon(
                  onPressed: _analyzeNews,
                  icon: const Icon(Icons.radar),
                  label: const Text('Просветить новость рентгеном'),
                ),
                const SizedBox(height: 10),
                Text(_analysisResult),
              ],
            ),
          ),
        ),
        const SizedBox(height: 10),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '☁️ Бэкап базы данных (JSON и отправка файлом в Telegram)',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          final jsonStr = widget.state.exportBackupJson();
                          _jsonBackupCtrl.text = jsonStr;
                          Clipboard.setData(ClipboardData(text: jsonStr));
                          setState(() => _backupStatus =
                              'JSON скопирован в буфер обмена!');
                        },
                        child: const Text('Экспорт JSON'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          final ok = widget.state
                              .importBackupJson(_jsonBackupCtrl.text);
                          setState(() => _backupStatus = ok
                              ? 'Данные успешно восстановлены!'
                              : 'Ошибка формата JSON (старые данные сохранены)');
                        },
                        child: const Text('Импорт JSON'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _jsonBackupCtrl,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'Строка резервной копии (JSON)',
                    border: OutlineInputBorder(),
                  ),
                ),
                const Divider(height: 20),
                TextField(
                  controller: _tgTokenCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Telegram Bot Token',
                  ),
                ),
                TextField(
                  controller: _tgChatCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Ваш Telegram Chat ID',
                  ),
                ),
                const SizedBox(height: 8),
                ElevatedButton.icon(
                  onPressed: () async {
                    final msg = await widget.state.sendTelegramBackup(
                      _tgTokenCtrl.text.trim(),
                      _tgChatCtrl.text.trim(),
                    );
                    setState(() => _backupStatus = msg);
                  },
                  icon: const Icon(Icons.send),
                  label: const Text('Отправить файл бэкапа в Telegram'),
                ),
                if (_backupStatus.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      _backupStatus,
                      style: const TextStyle(
                          color: Colors.green, fontWeight: FontWeight.bold),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
