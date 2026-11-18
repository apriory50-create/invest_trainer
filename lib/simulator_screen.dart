import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'app_state.dart';
import 'news_data.dart';
import 'news_part2.dart';

class SimulatorScreen extends StatefulWidget {
  final AppState state;
  const SimulatorScreen({super.key, required this.state});

  @override
  State<SimulatorScreen> createState() => _SimulatorScreenState();
}

class _SimulatorScreenState extends State<SimulatorScreen> {
  static const int _maxHistory = 60;
  static const double _brokerFeeRate = 0.0005; // 0.05% за сделку

  bool _showNewsTrainer = false;
  int _newsScenarioIndex = 0;
  int? _selectedNewsOption;

  String _scenario = 'Кризис 2008 (Ипотечный обвал)';
  late List<double> _prices;
  int _presetCursor = 0;
  double? _entryPrice;
  int _qty = 0;
  Timer? _timer;
  bool _isRunning = false;
  bool _lastEventNegative = false;
  String _newsBanner = 'Рынок спокоен. Нажмите «Таймлапс» или «Шаг +1 день».';
  String _expectationVsReality =
      'Ожидание: Рост прибыли +15% | Реальность: ждём отчёт';

  final Map<String, List<double>> _crisisPresets = {
    'Кризис 2008 (Ипотечный обвал)': [
      100.0,
      103.0,
      105.0,
      101.0,
      96.0,
      90.0,
      83.0,
      76.0,
      72.0,
      68.0,
      65.0,
      70.0,
      78.0,
      86.0,
      92.0,
    ],
    'Пандемия 2020 (Локдаун и V-отскок)': [
      100.0,
      102.0,
      97.0,
      90.0,
      82.0,
      75.0,
      70.0,
      76.0,
      85.0,
      96.0,
      106.0,
      114.0,
      120.0,
      125.0,
      128.0,
    ],
    'Ставка ЦБ 21% (Облигационный шторм)': [
      100.0,
      98.0,
      95.0,
      92.0,
      89.0,
      86.0,
      83.5,
      81.5,
      83.0,
      85.5,
      88.0,
      91.0,
      93.5,
      95.5,
      97.0,
    ],
  };

  @override
  void initState() {
    super.initState();
    _resetScenario(_scenario);
  }

  void _resetScenario(String name) {
    final preset = _crisisPresets[name]!;
    _scenario = name;
    _prices = [preset[0], preset[1], preset[2]];
    _presetCursor = 3;
    _entryPrice = null;
    _qty = 0;
    _lastEventNegative = false;
    _newsBanner = 'Рынок спокоен. Нажмите «Таймлапс» или «Шаг +1 день».';
    _expectationVsReality =
        'Ожидание: Рост прибыли +15% | Реальность: ждём отчёт';
  }

  void _nextStep() {
    final preset = _crisisPresets[_scenario]!;
    final targetVal = preset[_presetCursor % preset.length];
    _presetCursor++;

    final prevP = _prices.last;
    final stepTowardTarget = prevP + (targetVal - prevP) * 0.65;
    final noise = (Random().nextDouble() - 0.48) * 2.2;
    final nextP = (stepTowardTarget + noise).clamp(25.0, 250.0);

    bool pauseNow = false;
    if (_presetCursor % 4 == 0) {
      pauseNow = true;
    }

    if (pauseNow && _isRunning) {
      _timer?.cancel();
    }

    setState(() {
      if (pauseNow && _isRunning) {
        _isRunning = false;
      }
      _prices.add(nextP);
      if (_prices.length > _maxHistory) {
        _prices.removeAt(0);
      }

      if (pauseNow) {
        _lastEventNegative = nextP < prevP;
        _newsBanner = '⚡ АВТО-ПАУЗА: Заседание ЦБ / Выход отчёта!';
        _expectationVsReality = _lastEventNegative
            ? 'Ожидание: Смягчение ДКП | Реальность: Жёсткий сигнал ЦБ (Давление на цену)'
            : 'Ожидание: Снижение маржи | Реальность: Сильный отчёт и дивиденды (Позитив)';
      }
    });
  }

  void _toggleTimelapse() {
    if (_isRunning) {
      _pauseTimelapse();
    } else {
      setState(() => _isRunning = true);
      _timer = Timer.periodic(
        const Duration(milliseconds: 900),
        (_) => _nextStep(),
      );
    }
  }

  void _pauseTimelapse() {
    _timer?.cancel();
    if (_isRunning) {
      setState(() => _isRunning = false);
    }
  }

  void _buyLots(double currPrice) {
    const int buyQty = 100;
    final tradeValue = currPrice * buyQty;
    final entryFee = tradeValue * _brokerFeeRate;
    final totalCost = tradeValue + entryFee;

    if (widget.state.virtualBalance < totalCost) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Недостаточно средств! Нужно ${totalCost.toStringAsFixed(0)} ₽, на счёте ${widget.state.virtualBalance.toStringAsFixed(0)} ₽',
          ),
        ),
      );
      return;
    }

    setState(() {
      if (_qty == 0 || _entryPrice == null) {
        _entryPrice = currPrice;
        _qty = buyQty;
      } else {
        final totalOld = _entryPrice! * _qty;
        final newTotalQty = _qty + buyQty;
        _entryPrice = (totalOld + tradeValue) / newTotalQty;
        _qty = newTotalQty;
      }
    });

    widget.state.updateBalance(widget.state.virtualBalance - totalCost);
  }

  void _closePosition(double currPrice, double netPnl) {
    if (_qty == 0 || _entryPrice == null) return;
    final saleProceeds = currPrice * _qty;
    final exitFee = saleProceeds * _brokerFeeRate;
    final grossProfit = (currPrice - _entryPrice!) * _qty;
    final entryFee = (_entryPrice! * _qty) * _brokerFeeRate;
    final taxableProfit = grossProfit - entryFee - exitFee;
    final tax = taxableProfit > 0 ? taxableProfit * 0.13 : 0.0;
    final cashReturned = saleProceeds - exitFee - tax;

    if (netPnl < 0) {
      widget.state.addMistake(
        _scenario,
        'Закрытие позиции в убыток (${netPnl.toStringAsFixed(0)} ₽)',
        netPnl,
      );
    }

    setState(() {
      _entryPrice = null;
      _qty = 0;
    });

    widget.state.updateBalance(widget.state.virtualBalance + cashReturned);
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        SegmentedButton<bool>(
          segments: const [
            ButtonSegment(
              value: false,
              icon: Icon(Icons.show_chart),
              label: Text('Биржевой график'),
            ),
            ButtonSegment(
              value: true,
              icon: Icon(Icons.newspaper),
              label: Text('35 Новостей-задач'),
            ),
          ],
          selected: {_showNewsTrainer},
          onSelectionChanged: (s) {
            _pauseTimelapse();
            setState(() => _showNewsTrainer = s.first);
          },
        ),
        const SizedBox(height: 10),
        if (_showNewsTrainer)
          _buildNewsScenarioTrainer()
        else
          _buildChartSimulator(),
      ],
    );
  }

  Widget _buildNewsScenarioTrainer() {
    final allScenarios = <NewsScenario>[...marketNewsList, ...marketNewsPart2];
    final item = allScenarios[_newsScenarioIndex % allScenarios.length];
    final isPro = widget.state.isProMode;

    // Перемешиваем варианты ответов с детерминированным seed по id сценария
    final indices = List<int>.generate(item.options.length, (i) => i)
      ..shuffle(Random(item.id * 37));

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Chip(
                  label: Text('${item.category} • ${item.tag}'),
                  visualDensity: VisualDensity.compact,
                ),
                Text(
                  'Задача ${_newsScenarioIndex + 1} из ${allScenarios.length}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              item.headline,
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            Text(item.contextText),
            const Divider(height: 20),
            Text(
              item.question,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            ...List.generate(indices.length, (shufIdx) {
              final origIdx = indices[shufIdx];
              final isCorrect = origIdx == item.correctIndex;
              final isSelected = _selectedNewsOption == shufIdx;

              Color? bg;
              if (_selectedNewsOption != null) {
                if (isCorrect) {
                  bg = Colors.green.withValues(alpha: 0.18);
                } else if (isSelected) {
                  bg = Colors.red.withValues(alpha: 0.18);
                }
              }

              return Card(
                color: bg,
                margin: const EdgeInsets.only(bottom: 6),
                child: ListTile(
                  title: Text(item.options[origIdx]),
                  onTap: () => setState(() => _selectedNewsOption = shufIdx),
                ),
              );
            }),
            if (_selectedNewsOption != null) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.blue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  isPro ? item.proExplain : item.simpleExplain,
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
              ),
            ],
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                OutlinedButton(
                  onPressed: _newsScenarioIndex > 0
                      ? () => setState(() {
                            _newsScenarioIndex--;
                            _selectedNewsOption = null;
                          })
                      : null,
                  child: const Text('Назад'),
                ),
                ElevatedButton(
                  onPressed: () => setState(() {
                    _newsScenarioIndex =
                        (_newsScenarioIndex + 1) % allScenarios.length;
                    _selectedNewsOption = null;
                  }),
                  child: const Text('Следующая ситуация ➔'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChartSimulator() {
    final currPrice = _prices.last;
    final breakEven =
        _entryPrice == null ? null : _entryPrice! * (1 + _brokerFeeRate * 2);

    final rawPnl =
        _entryPrice == null ? 0.0 : (currPrice - _entryPrice!) * _qty;
    final entryFee =
        _entryPrice == null ? 0.0 : (_entryPrice! * _qty * _brokerFeeRate);
    final exitFee = _qty == 0 ? 0.0 : (currPrice * _qty * _brokerFeeRate);
    final totalFees = entryFee + exitFee;
    final pnlAfterFees = rawPnl - totalFees;
    final tax = pnlAfterFees > 0 ? pnlAfterFees * 0.13 : 0.0;
    final netPnl = pnlAfterFees - tax;

    // Честная проверка 5 сигналов светофора выхода
    final baseEntry = _entryPrice ?? currPrice;
    final sig1TakeProfit =
        _qty > 0 && currPrice >= baseEntry * 1.15; // Цель +15% достигнута
    final sig2StopLoss =
        _qty > 0 && currPrice <= baseEntry * 0.92; // Стоп-убыток -8%
    final sig3FundamentalNegative = _lastEventNegative; // Негативный отчет/ДКП
    final sig4HighDrawdownFromPeak =
        currPrice <= _prices.reduce(max) * 0.88; // Просадка от пика >12%
    final sig5HighRatePressure =
        widget.state.cbRate >= 20.0 && _scenario.contains('21%');

    final activeSignals = [
      if (sig1TakeProfit) '1) Достигнута цель прибыли (+15%)',
      if (sig2StopLoss) '2) Сработал порог стоп-риска (-8%)',
      if (sig3FundamentalNegative) '3) Негативный фундаментальный триггер',
      if (sig4HighDrawdownFromPeak) '4) Просадка от локального максимума >12%',
      if (sig5HighRatePressure) '5) Жёсткое давление ставки ЦБ на выпуск',
    ];
    final redSignals = activeSignals.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DropdownButtonFormField<String>(
          value: _scenario,
          decoration: const InputDecoration(
            labelText: 'Сценарий / Исторический кризис',
            border: OutlineInputBorder(),
          ),
          items: _crisisPresets.keys
              .map((k) => DropdownMenuItem(value: k, child: Text(k)))
              .toList(),
          onChanged: (v) {
            if (v != null) {
              _pauseTimelapse();
              setState(() => _resetScenario(v));
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
                Text(_newsBanner,
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text('🔍 Рентген: $_expectationVsReality',
                    style: const TextStyle(fontSize: 13)),
              ],
            ),
          ),
        ),
        const SizedBox(height: 10),
        Container(
          height: 160,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade700),
            borderRadius: BorderRadius.circular(8),
          ),
          child: CustomPaint(
            painter: _ChartPainter(_prices, breakEven),
            size: Size.infinite,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Цена: ${currPrice.toStringAsFixed(2)} ₽ (Лотов: $_qty)',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            if (breakEven != null)
              Text(
                'Безубыток: ${breakEven.toStringAsFixed(2)} ₽',
                style: const TextStyle(
                    color: Colors.orangeAccent, fontWeight: FontWeight.bold),
              ),
          ],
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            ElevatedButton.icon(
              onPressed: _toggleTimelapse,
              icon: Icon(_isRunning ? Icons.pause : Icons.play_arrow),
              label: Text(_isRunning ? 'Пауза' : 'Таймлапс'),
            ),
            OutlinedButton(
              onPressed: _nextStep,
              child: const Text('Шаг +1 день'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green.shade700,
                foregroundColor: Colors.white,
              ),
              onPressed: () => _buyLots(currPrice),
              child: const Text('Купить 100 шт.'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.shade700,
                foregroundColor: Colors.white,
              ),
              onPressed:
                  _qty == 0 ? null : () => _closePosition(currPrice, netPnl),
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
                const Text(
                  '🧾 Прозрачный чек сделки и 🚦 Светофор (5 сигналов)',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 6),
                Text(
                  'Грязная: ${rawPnl.toStringAsFixed(1)} ₽ | Комиссии (вход+выход): -${totalFees.toStringAsFixed(1)} ₽ | НДФЛ: -${tax.toStringAsFixed(1)} ₽ | Чистыми: ${netPnl.toStringAsFixed(1)} ₽',
                ),
                const Divider(),
                Row(
                  children: [
                    Icon(
                      Icons.circle,
                      color: redSignals == 0
                          ? Colors.green
                          : (redSignals == 1 ? Colors.amber : Colors.red),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        redSignals == 0
                            ? 'ЗЕЛЕНЫЙ: Все 5 индикаторов спокойны.'
                            : 'АКТИВНЫЕ СИГНАЛЫ ($redSignals из 5): ${activeSignals.join("; ")}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
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
                Text(
                  '📓 Дневник граблей (записей: ${widget.state.mistakeDiary.length})',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 6),
                ...widget.state.mistakeDiary.take(5).map(
                      (m) => Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Text(
                          '• [${m.date}] ${m.asset}: ${m.error} (${m.loss.toStringAsFixed(0)} ₽)',
                          style: const TextStyle(fontSize: 13),
                        ),
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

class _ChartPainter extends CustomPainter {
  final List<double> prices;
  final double? breakEven;
  _ChartPainter(this.prices, this.breakEven);

  @override
  void paint(Canvas canvas, Size size) {
    if (prices.length < 2) return;
    final minP = prices.reduce(min) - 5.0;
    final maxP = prices.reduce(max) + 5.0;
    final paintLine = Paint()
      ..color = Colors.blueAccent
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke;

    final path = Path();
    for (int i = 0; i < prices.length; i++) {
      final x = i * (size.width / (prices.length - 1));
      final y =
          size.height - ((prices[i] - minP) / (maxP - minP)) * size.height;
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    canvas.drawPath(path, paintLine);

    if (breakEven != null) {
      final by =
          size.height - ((breakEven! - minP) / (maxP - minP)) * size.height;
      final bePaint = Paint()
        ..color = Colors.orangeAccent
        ..strokeWidth = 1.5;
      canvas.drawLine(
        Offset(0, by.clamp(0.0, size.height)),
        Offset(size.width, by.clamp(0.0, size.height)),
        bePaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}



