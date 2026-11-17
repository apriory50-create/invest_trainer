import 'package:flutter/material.dart';

class PortfolioStressTestScreen extends StatefulWidget {
  final double portfolioValue;
  const PortfolioStressTestScreen({super.key, this.portfolioValue = 150000.0});

  @override
  State<PortfolioStressTestScreen> createState() => _PortfolioStressTestScreenState();
}

class _PortfolioStressTestScreenState extends State<PortfolioStressTestScreen> {
  double _marketDropPercent = 20.0; // Сценарий падения рынка в %
  bool _includeBondsHedge = true;

  @override
  Widget build(BuildContext context) {
    // Расчет стресс-теста
    double dropFactor = _marketDropPercent / 100.0;
    // Облигации и фонды денежного рынка падают меньше при падении акций
    double adjustedDrop = _includeBondsHedge ? dropFactor * 0.7 : dropFactor;
    double simulatedLoss = widget.portfolioValue * adjustedDrop;
    double finalPortfolioValue = widget.portfolioValue - simulatedLoss;

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: ListView(
        children: [
          const Text(
            'Стресс-тест портфеля (Кризис-менеджер)',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.blueAccent),
          ),
          const SizedBox(height: 8),
          const Text(
            'Оцените, как ваш портфель перенесет резкое падение фондового рынка или геополитический шок.',
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 20),
          Card(
            elevation: 4,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Текущая стоимость портфеля:', style: TextStyle(color: Colors.grey)),
                  Text(
                    '${widget.portfolioValue.toStringAsFixed(0)} ₽',
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const Divider(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Сценарий падения индекса:'),
                      Text('-${_marketDropPercent.toStringAsFixed(0)}%', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.red)),
                    ],
                  ),
                  Slider(
                    value: _marketDropPercent,
                    min: 5.0,
                    max: 50.0,
                    divisions: 9,
                    label: '-${_marketDropPercent.toStringAsFixed(0)}%',
                    onChanged: (value) => setState(() => _marketDropPercent = value),
                  ),
                  SwitchListTile(
                    title: const Text('Защита облигациями / ОФЗ'),
                    subtitle: const Text('Снижает общую просадку портфеля на 30%'),
                    value: _includeBondsHedge,
                    onChanged: (val) => setState(() => _includeBondsHedge = val),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            color: Colors.red.shade50,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Результат стресс-теста:',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.red),
                  ),
                  const SizedBox(height: 8),
                  Text('Прогнозируемый убыток: -${simulatedLoss.toStringAsFixed(0)} ₽'),
                  const SizedBox(height: 4),
                  Text(
                    'Стоимость портфеля в кризис: ${finalPortfolioValue.toStringAsFixed(0)} ₽',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
