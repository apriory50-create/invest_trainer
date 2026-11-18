import 'package:flutter/material.dart';
import 'app_state.dart';
import 'services/bond_calculator.dart';

class PortfolioScreen extends StatefulWidget {
  final AppState state;
  const PortfolioScreen({super.key, required this.state});

  @override
  State<PortfolioScreen> createState() => _PortfolioScreenState();
}

class _PortfolioScreenState extends State<PortfolioScreen> {
  double _stressRateDelta = 0.0;
  double _stockRateSensitivity = 2.2; // Допущение: % изменения акций на 1 п.п. ставки
  double _cashTopUp = 30000.0;

  final _tickerCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();
  final _qtyCtrl = TextEditingController(text: '10');
  final _priceCtrl = TextEditingController(text: '250');
  final _durCtrl = TextEditingController(text: '0.0');
  String _selectedType = 'stock';
  String? _formError;

  @override
  void dispose() {
    _tickerCtrl.dispose();
    _nameCtrl.dispose();
    _qtyCtrl.dispose();
    _priceCtrl.dispose();
    _durCtrl.dispose();
    super.dispose();
  }

  void _openAddAssetDialog() {
    _formError = null;
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Добавить бумагу в портфель'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  value: _selectedType,
                  decoration: const InputDecoration(labelText: 'Класс актива'),
                  items: const [
                    DropdownMenuItem(value: 'stock', child: Text('Акция')),
                    DropdownMenuItem(value: 'bond', child: Text('Облигация')),
                    DropdownMenuItem(
                        value: 'etf', child: Text('Фонд БПИФ / Ликвидность')),
                  ],
                  onChanged: (v) {
                    if (v != null) setDialogState(() => _selectedType = v);
                  },
                ),
                TextField(
                  controller: _tickerCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Тикер (например: LKOH, SBER, SU26238)',
                  ),
                ),
                TextField(
                  controller: _nameCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Название (необязательно)',
                  ),
                ),
                TextField(
                  controller: _qtyCtrl,
                  decoration:
                      const InputDecoration(labelText: 'Количество (шт.)'),
                  keyboardType: TextInputType.number,
                ),
                TextField(
                  controller: _priceCtrl,
                  decoration:
                      const InputDecoration(labelText: 'Цена покупки (₽)'),
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                ),
                if (_selectedType != 'stock')
                  TextField(
                    controller: _durCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Дюрация (лет, для облигаций)',
                    ),
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                  ),
                if (_formError != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    _formError!,
                    style: const TextStyle(color: Colors.red, fontSize: 13),
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Отмена'),
            ),
            ElevatedButton(
              onPressed: () {
                final ticker = _tickerCtrl.text.trim().toUpperCase();
                final qty = int.tryParse(_qtyCtrl.text.trim());
                final price =
                    double.tryParse(_priceCtrl.text.trim().replaceAll(',', '.'));
                final dur =
                    double.tryParse(_durCtrl.text.trim().replaceAll(',', '.')) ??
                        0.0;

                if (ticker.isEmpty) {
                  setDialogState(() => _formError = 'Укажите тикер бумаги');
                  return;
                }
                if (qty == null || qty <= 0) {
                  setDialogState(
                      () => _formError = 'Количество должно быть больше 0');
                  return;
                }
                if (price == null || price <= 0) {
                  setDialogState(
                      () => _formError = 'Укажите корректную цену больше 0');
                  return;
                }

                final name = _nameCtrl.text.trim().isEmpty
                    ? 'Актив $ticker'
                    : _nameCtrl.text.trim();

                widget.state.addAsset(
                  ticker,
                  name,
                  _selectedType,
                  qty,
                  price,
                  _selectedType == 'stock' ? 0.0 : dur,
                );
                _tickerCtrl.clear();
                _nameCtrl.clear();
                Navigator.pop(ctx);
              },
              child: const Text('Добавить'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final items = widget.state.portfolio;
    double totalVal = 0;
    double stressedVal = 0;
    double stocksVal = 0;

    for (final a in items) {
      final val = a.qty * a.currPrice;
      totalVal += val;
      if (a.type == 'stock') stocksVal += val;

      final dropPct = a.type == 'stock'
          ? (-_stressRateDelta * _stockRateSensitivity)
          : (-a.duration * _stressRateDelta);
      stressedVal += val * (1 + dropPct / 100);
    }

    final stockShareBefore = totalVal == 0 ? 0.0 : (stocksVal / totalVal * 100);
    final newTotal = totalVal + _cashTopUp;
    final targetStocksVal = newTotal * 0.5; // Целевой баланс 50% / 50%
    final neededForStocks =
        (targetStocksVal - stocksVal).clamp(0.0, _cashTopUp);
    final neededForBonds = (_cashTopUp - neededForStocks).clamp(0.0, _cashTopUp);
    final newStocksVal = stocksVal + neededForStocks;
    final stockShareAfter =
        newTotal == 0 ? 0.0 : (newStocksVal / newTotal * 100);

    String rebalanceAdvice;
    if (neededForStocks > 0 && neededForBonds > 0) {
      rebalanceAdvice =
          'Направить ${neededForStocks.toStringAsFixed(0)} ₽ в акции и ${neededForBonds.toStringAsFixed(0)} ₽ в ОФЗ/фонды ликвидности.';
    } else if (neededForStocks > 0) {
      rebalanceAdvice =
          'Докупить акции на все ${neededForStocks.toStringAsFixed(0)} ₽ (сейчас перевес в защитных активах).';
    } else {
      rebalanceAdvice =
          'Докупить ОФЗ/фонды ликвидности на все ${neededForBonds.toStringAsFixed(0)} ₽ (сейчас перевес в акциях).';
    }

    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              '💼 Ваш портфель (MOEX)',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            ElevatedButton.icon(
              onPressed: _openAddAssetDialog,
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Добавить бумагу'),
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
                Text(
                  '🩺 Стресс-тест ключевой ставки ЦБ (Текущая: ${widget.state.cbRate.toStringAsFixed(1)}%)',
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 15),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Упрощённая учебная модель (не является инвестиционным прогнозом): облигации переоцениваются через дюрацию, акции — по выбранному коэффициенту чувствительности.',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
                const SizedBox(height: 6),
                Text(
                  'Изменение ставки ЦБ: ${_stressRateDelta.isNegative ? '' : '+'}${_stressRateDelta.toStringAsFixed(1)} п.п.',
                ),
                Slider(
                  value: _stressRateDelta,
                  min: -5.0,
                  max: 5.0,
                  divisions: 20,
                  onChanged: (v) => setState(() => _stressRateDelta = v),
                ),
                Text(
                  'Чувствительность акций на 1 п.п. ставки: -${_stockRateSensitivity.toStringAsFixed(1)}%',
                  style: const TextStyle(fontSize: 13),
                ),
                Slider(
                  value: _stockRateSensitivity,
                  min: 0.5,
                  max: 5.0,
                  divisions: 9,
                  onChanged: (v) => setState(() => _stockRateSensitivity = v),
                ),
                Text(
                  'Оценка сейчас: ${totalVal.toStringAsFixed(0)} ₽ ➔ После шока: ${stressedVal.toStringAsFixed(0)} ₽ (${(stressedVal - totalVal).isNegative ? '' : '+'}${(stressedVal - totalVal).toStringAsFixed(0)} ₽)',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: (stressedVal - totalVal).isNegative
                        ? Colors.redAccent
                        : Colors.green,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '⚖️ Ребалансировка к 50/50 без продаж и налогов',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                ),
                const SizedBox(height: 4),
                Text(
                    'Сумма свежего пополнения: ${_cashTopUp.toStringAsFixed(0)} ₽'),
                Slider(
                  value: _cashTopUp,
                  min: 5000,
                  max: 150000,
                  divisions: 29,
                  onChanged: (v) => setState(() => _cashTopUp = v),
                ),
                Text(
                  '• ДО: Акции ${stockShareBefore.toStringAsFixed(1)}% / Защитные ${(100 - stockShareBefore).toStringAsFixed(1)}%',
                ),
                Text('• РЕКОМЕНДАЦИЯ: $rebalanceAdvice'),
                Text(
                  '• ПОСЛЕ: Акции ${stockShareAfter.toStringAsFixed(1)}% / Защитные ${(100 - stockShareAfter).toStringAsFixed(1)}%',
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, color: Colors.green),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        ...items.map((a) {
          final pnl = (a.currPrice - a.buyPrice) * a.qty;
          String bondMetrics = '';
          if (a.type == 'bond') {
            final ytm = BondCalculator.calculateYTM(
              currentPrice: a.currPrice,
              nominal: 1000.0,
              couponRate: a.coupon,
              yearsToMaturity: a.duration > 0 ? a.duration : 5.0,
            );
            final macDur = BondCalculator.calculateDuration(
              currentPrice: a.currPrice,
              nominal: 1000.0,
              couponRate: a.coupon,
              yearsToMaturity: a.duration > 0 ? a.duration : 5.0,
            );
            bondMetrics = ' | YTM: ~$ytm% | Дюрация Маколея: $macDur г.';
          }

          return Card(
            child: ListTile(
              title: Text(
                '${a.name} (${a.ticker})',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Text(
                'Кол-во: ${a.qty} шт | Вход: ${a.buyPrice} ₽ | Тек: ${a.currPrice} ₽$bondMetrics',
              ),
              trailing: Text(
                '${pnl.isNegative ? '' : '+'}${pnl.toStringAsFixed(0)} ₽',
                style: TextStyle(
                  color: pnl.isNegative ? Colors.redAccent : Colors.green,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          );
        }),
      ],
    );
  }
}



