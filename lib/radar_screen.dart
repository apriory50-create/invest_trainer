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
    text: 'ЦБ повысил ключевую ставку, а совет директоров Сбербанка рекомендовал рекордные дивиденды',
  );
  final _tgTokenCtrl = TextEditingController();
  final _tgChatCtrl = TextEditingController();
  final _jsonBackupCtrl = TextEditingController();
  String _analysisResult = 'Нажмите «Просветить новость рентгеном», чтобы увидеть влияние на ваш портфель.';
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
    final List<String> findings = [];
    final portfolio = widget.state.portfolio;

    final bonds = portfolio.where((a) => a.type == 'bond').toList();
    final etfs = portfolio.where((a) => a.type == 'etf').toList();

    if (text.contains('ставк') || text.contains('цб') || text.contains('инфляц')) {
      final bondHint = bonds.isNotEmpty
          ? 'В вашем портфеле есть ${bonds.map((b) => b.ticker).join(', ')} — риск просадки тела при росте ставки.'
          : 'Длинные ОФЗ сейчас под давлением.';
      final etfHint = etfs.isNotEmpty
          ? 'Фонды (${etfs.map((e) => e.ticker).join(', ')}) в плюсе от высокой ставки.'
          : '';
      findings.add('🔴 Триггер ДКП (Ставка ЦБ): $bondHint $etfHint'.trim());
    }

    if (text.contains('дивиденд') || text.contains('сбер') || text.contains('лукойл')) {
      final hasSber = portfolio.any((a) => a.ticker == 'SBER');
      findings.add(
        hasSber
            ? '🟢 Триггер Дивидендов: Позитив для SBER в вашем портфеле. Учтите налог 13% и дивгэп в дату отсечки.'
            : '🟢 Триггер Дивидендов: Позитив для дивидендных фишек, но учтите налог 13% и утренний дивгэп.',
      );
    }

    if (text.contains('оферт') || text.contains('дефолт') || text.contains('допэмисс')) {
      findings.add('⚠️ Критический риск: Проверьте дату пут-оферты, ковенанты и риск размытия доли!');
    }

    if (findings.isEmpty) {
      findings.add('🟡 Нейтральный шум: Прямых фундаментальных триггеров для бумаг вашего портфеля не обнаружено.');
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
                  '📡 Двухуровневый Инфо-Радар (Офлайн-словарь + ИИ-фильтр)',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _newsCtrl,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Вставьте текст новости из Telegram / СМИ',
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
                  '☁️ Бэкап базы данных (JSON-файл и Telegram Bot API)',
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
                          setState(() => _backupStatus = 'JSON скопирован в буфер обмена!');
                        },
                        child: const Text('Экспорт JSON'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          final ok = widget.state.importBackupJson(_jsonBackupCtrl.text);
                          setState(() => _backupStatus = ok ? 'Данные успешно восстановлены!' : 'Ошибка формата JSON');
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
                  decoration: const InputDecoration(labelText: 'Telegram Bot Token (необязательно)'),
                ),
                TextField(
                  controller: _tgChatCtrl,
                  decoration: const InputDecoration(labelText: 'Ваш Telegram Chat ID'),
                ),
                const SizedBox(height: 8),
                ElevatedButton.icon(
                  onPressed: () async {
                    final msg = await widget.state.sendTelegramBackup(
                      _tgTokenCtrl.text.trim(),
                      _tgChatCtrl.text.trim(),
                    );
                    if (!mounted) return;
                    setState(() => _backupStatus = msg);
                  },
                  icon: const Icon(Icons.send),
                  label: const Text('Отправить бэкап в Telegram'),
                ),
                if (_backupStatus.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      _backupStatus,
                      style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
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


