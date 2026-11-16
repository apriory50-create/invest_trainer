import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'app_state.dart';

class RadarScreen extends StatefulWidget {
  final AppState state;
  const RadarScreen({super.key, required this.state});

  @override
  State createState() => _RadarScreenState();
}

class _RadarScreenState extends State {
  final _newsCtrl = TextEditingController(text: 'ЦБ повысил ключевую ставку, а совет директоров Сбербанка рекомендовал рекордные дивиденды');
  final _tgTokenCtrl = TextEditingController();
  final _tgChatCtrl = TextEditingController();
  final _jsonBackupCtrl = TextEditingController();
  String _analysisResult = 'Нажмите «Просветить новость рентгеном», чтобы увидеть влияние на ваш портфель.';
  String _backupStatus = '';

  AppState get _appState => (widget as RadarScreen).state;

  void _analyzeNews() {
    final text = _newsCtrl.text.toLowerCase();
    final List findings = [];

    if (text.contains('ставк') || text.contains('цб') || text.contains('инфляц')) {
      findings.add('🔴 Триггер ДКП (Ставка ЦБ): Давление на длинные облигации (ОФЗ 26238 в вашем портфеле имеет дюрацию 7.8 — риск просадки тела). Фонд LQDT выигрывает.');
    }
    if (text.contains('дивиденд') || text.contains('сбер')) {
      findings.add('🟢 Триггер Дивидендов: Позитив для акции SBER в вашем портфеле. Внимание: учтите налог 13% и будущий дивгэп утром в дату отсечки.');
    }
    if (text.contains('оферт') || text.contains('дефолт') || text.contains('допэмисс')) {
      findings.add('⚠️ Критический риск: Проверьте дату пут-оферты и размытие доли акционеров!');
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
                const Text('📡 Двухуровневый Инфо-Радар (Офлайн-словарь + ИИ-фильтр)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 8),
                TextField(
                  controller: _newsCtrl,
                  maxLines: 3,
                  decoration: const InputDecoration(labelText: 'Вставьте текст новости из Telegram / СМИ', border: OutlineInputBorder()),
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
                const Text('☁️ Бэкап базы данных (JSON-файл и Telegram Bot API)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          final jsonStr = _appState.exportBackupJson();
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
                          final ok = _appState.importBackupJson(_jsonBackupCtrl.text);
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
                  decoration: const InputDecoration(labelText: 'Строка резервной копии (JSON)', border: OutlineInputBorder()),
                ),
                const Divider(height: 20),
                TextField(controller: _tgTokenCtrl, decoration: const InputDecoration(labelText: 'Telegram Bot Token (необязательно)')),
                TextField(controller: _tgChatCtrl, decoration: const InputDecoration(labelText: 'Ваш Telegram Chat ID')),
                const SizedBox(height: 8),
                ElevatedButton.icon(
                  onPressed: () async {
                    final msg = await _appState.sendTelegramBackup(_tgTokenCtrl.text.trim(), _tgChatCtrl.text.trim());
                    setState(() => _backupStatus = msg.toString());
                  },
                  icon: const Icon(Icons.send),
                  label: const Text('Отправить бэкап в Telegram'),
                ),
                if (_backupStatus.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(_backupStatus, style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

