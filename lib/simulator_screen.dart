import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'app_state.dart';

class SimulatorScreen extends StatefulWidget {
  final AppState state;
  const SimulatorScreen({super.key, required this.state});

  @override
  State<SimulatorScreen> createState() => _SimulatorScreenState();
}

class _SimulatorScreenState extends State<SimulatorScreen> {
  String _scenario = 'Кризис 2008 (Ипотечный обвал)';
  List<double> _prices = [100.0, 102.0, 101.5, 104.0, 103.0];
  double? _entryPrice;
  int _qty = 0;
  Timer? _timer;
  bool _isRunning = false;
  String _newsBanner = 'Рынок спокоен. Нажмите «Старт таймлапс» или «Шаг +1 день».';
  String _expectationVsReality = 'Ожидание: Рост прибыли +15% | Реальность: ждём отчёт';

  final Map<String, List<double>> _crisisPresets = {
    'Кризис 2008 (Ипотечный обвал)': [100, 105, 108, 98, 85, 72, 60, 65, 78, 92],
    'Пандемия 2020 (Локдаун и V-отскок)': [100, 103, 91, 75, 68, 82, 96, 112, 120, 128],
    'Ставка ЦБ 21% (Облигационный шторм)': [100, 96, 92, 88, 83, 81, 84, 87, 91, 95],
  };

  void _nextStep() {
    setState(() {
      final preset = _crisisPresets[_scenario]!;
      final idx = _prices.length % preset.length;
      final noise = (Random().nextDouble() - 0.48) * 3.0;
      final nextP = (preset[idx] + noise).clamp(20.0, 250.0);
      _prices.add(nextP);

      if (_prices.length % 4 == 0) {
        _pauseTimelapse();
        _newsBanner = '⚡ АВТО-ПАУЗА: Срочное заседание ЦБ / Отчёт компании!';
        _expectationVsReality = nextP < _prices[_prices.length - 2]
            ? 'Ожидание: Снижение ставки | Реальность: Ставку повысили! (Негатив)'
            : 'Ожидание: Падение выручки | Реальность: Рекордные дивиденды! (Позитив)';
      }
    });
  }

  void _toggleTimelapse() {
    if (_isRunning) {
      _pauseTimelapse();
    } else {
      setState(() => _isRunning = true);
      _timer = Timer.periodic(const Duration(milliseconds: 900), (_) => _nextStep());
    }
  }

  void _pauseTimelapse() {
    _timer?.cancel();
    setState(() => _isRunning = false);
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currPrice = _prices.last;
    final brokerFee = 0.003; // 0.3%
    final breakEven = _entryPrice == null ? null : _entryPrice! * (1 + brokerFee * 2 + 0.002);
    final rawPnl = _entryPrice == null ? 0.0 : (currPrice - _entryPrice!) * _qty;
    final tax = rawPnl > 0 ? rawPnl * 0.13 : 0.0;
    final netPnl = rawPnl - tax - ((_entryPrice ?? 0) * _qty * brokerFee);

    int redSignals = 0;
    if (currPrice < (_entryPrice ?? currPrice) * 0.92) redSignals++;
    if (_newsBanner.contains('Негатив') || _expectationVsReality.contains('Негатив')) redSignals++;
    if (currPrice > (_entryPrice ?? currPrice) * 1.20) redSignals++;

    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        DropdownButtonFormField<String>(
          value: _scenario,
          decoration: const InputDecoration(labelText: 'Сценарий / Исторический Босс', border: OutlineInputBorder()),
          items: _crisisPresets.keys.map((k) => DropdownMenuItem(value: k, child: Text(k))).toList(),
          onChanged: (v) {
            if (v != null) {
              _pauseTimelapse();
              setState(() {
                _scenario = v;
                _prices = [100.0, 101.0];
                _entryPrice = null;
                _qty = 0;
              });
            }
          },
        ),
        const SizedBox(height: 10),
        Card(
          color: Colors.amber.withValues(alpha: 0.15),
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_newsBanner, style: const TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text('🔍 Рентген: $_expectationVsReality', style: const TextStyle(fontSize: 13)),
              ],
            ),
          ),
        ),
        const SizedBox(height: 10),
        Container(
          height: 160,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade700), borderRadius: BorderRadius.circular(8)),
          child: CustomPaint(
            painter: _ChartPainter(_prices, _entryPrice, breakEven),
            size: Size.infinite,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Цена: ${currPrice.toStringAsFixed(2)} ₽', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            if (breakEven != null)
              Text('Безубыток (с ком. и НДФЛ): ${breakEven.toStringAsFixed(2)} ₽', style: const TextStyle(color: Colors.orangeAccent, fontWeight: FontWeight.bold)),
          ],
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: [
            ElevatedButton.icon(
              onPressed: _toggleTimelapse,
              icon: Icon(_isRunning ? Icons.pause : Icons.play_arrow),
              label: Text(_isRunning ? 'Пауза' : 'Таймлапс'),
            ),
            OutlinedButton(onPressed: _nextStep, child: const Text('Шаг +1 день')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green.shade700),
              onPressed: () => setState(() {
                _entryPrice = currPrice;
                _qty = 100;
              }),
              child: const Text('Купить 100 лотов'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red.shade700),
              onPressed: _qty == 0
                  ? null
                  : () {
                      if (netPnl < 0) {
                        widget.state.addMistake(_scenario, 'Продажа в минус без стоп-плана', netPnl);
                      }
                      setState(() {
                        widget.state.virtualBalance += netPnl;
                        _entryPrice = null;
                        _qty = 0;
                      });
                    },
              child: const Text('Закрыть сделку'),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('🧾 Прозрачный чек сделки и 🚦 Светофор выхода (5 сигналов)', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                Text('Грязная прибыль: ${rawPnl.toStringAsFixed(1)} ₽ | Налог 13%: -${tax.toStringAsFixed(1)} ₽ | Чистыми: ${netPnl.toStringAsFixed(1)} ₽'),
                const Divider(),
                Row(
                  children: [
                    Icon(Icons.circle, color: redSignals == 0 ? Colors.green : (redSignals == 1 ? Colors.amber : Colors.red)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        redSignals == 0
                            ? 'ЗЕЛЕНЫЙ: Держим позицию. 5 сигналов в норме.'
                            : (redSignals == 1 ? 'ЖЕЛТЫЙ: Внимание! Новостной фон или цена у границы.' : 'КРАСНЫЙ: Сработали сигналы выхода! Фиксируй позицию.'),
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _ChartPainter extends CustomPainter {
  final List<double> prices;
  final double? entry;
  final double? breakEven;
  _ChartPainter(this.prices, this.entry, this.breakEven);

  @override
  void paint(Canvas canvas, Size size) {
    if (prices.length < 2) return;
    final minP = prices.reduce(min) - 5;
    final maxP = prices.reduce(max) + 5;
    final paintLine = Paint()
      ..color = Colors.lightBlueAccent
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke;

    final path = Path();
    for (int i = 0; i < prices.length; i++) {
      final x = i * (size.width / (prices.length - 1));
      final y = size.height - ((prices[i] - minP) / (maxP - minP)) * size.height;
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    canvas.drawPath(path, paintLine);

    if (breakEven != null && breakEven! >= minP && breakEven! <= maxP) {
      final by = size.height - ((breakEven! - minP) / (maxP - minP)) * size.height;
      final bePaint = Paint()
        ..color = Colors.orangeAccent
        ..strokeWidth = 1.5;
      canvas.drawLine(Offset(0, by), Offset(size.width, by), bePaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
