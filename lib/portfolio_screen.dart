import 'package:flutter/material.dart';
import 'app_state.dart';

class PortfolioScreen extends StatefulWidget {
  final AppState state;
  const PortfolioScreen({super.key, required this.state});

  @override
  State createState() => _PortfolioScreenState();
}

class _PortfolioScreenState extends State<PortfolioScreen> {
  double _stressRateDelta = 0.0;
  double _cashTopUp = 30000.0;
  final _tickerCtrl = TextEditingController();
  final _qtyCtrl = TextEditingController(text: '10');
  final _priceCtrl = TextEditingController(text: '250');

  void _showImportDialog(String method) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Импорт: $method'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Распознавание ($method) готово. Проверьте или добавьте бумагу MOEX/World:'),
            TextField(controller: _tickerCtrl, decoration: const InputDecoration(labelText: 'Тикер (напр. LKOH, SBER, SU26238)')),
            TextField(controller: _qtyCtrl, decoration: const InputDecoration(labelText: 'Количество шт.'), keyboardType: TextInputType.number),
            TextField(controller: _priceCtrl, decoration: const InputDecoration(labelText: 'Цена покупки ₽'), keyboardType: TextInputType.number),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Отмена')),
          ElevatedButton(
            onPressed: () {
              final t = _tickerCtrl.text.trim().isEmpty ? 'LKOH' : _tickerCtrl.text.trim().toUpperCase();
              final q = int.tryParse(_qtyCtrl.text) ?? 10;
              final p = double.tryParse(_priceCtrl.text) ?? 250.0;
              widget.state.addAsset(t, 'Актив $t', 'stock', q, p, 0.0);
              Navigator.pop(context);
            },
            child: const Text('Импортировать'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final items = widget.state.portfolio;
    double totalVal = 0;
    double stressedVal = 0;
    double stocksVal = 0;

    for (var raw in items) {
      final a = raw as AssetItem;
      final val = a.qty * a.currPrice;
      totalVal += val;
      if (a.type == 'stock') stocksVal += val;

      final dropPct = a.type == 'stock' ? (-_stressRateDelta * 2.2) : (-a.duration * _stressRateDelta);
      stressedVal += val * (1 + dropPct / 100);
    }

    final stockShareBefore = totalVal == 0 ? 0.0 : (stocksVal / totalVal * 100);
    final newTotal = totalVal + _cashTopUp;
    final buyBondsAmount = _cashTopUp;
    final stockShareAfter = newTotal == 0 ? 0.0 : (stocksVal / newTotal * 100);

    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        const Text('📥 4 способа импорта портфеля (MOEX + Мир):', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 6),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            ElevatedButton.icon(onPressed: () => _showImportDialog('Скриншот OCR'), icon: const Icon(Icons.image, size: 18), label: const Text('По скриншоту')),
            ElevatedButton.icon(onPressed: () => _showImportDialog('Отчёт брокера XML/CSV'), icon: const Icon(Icons.upload_file, size: 18), label: const Text('По файлу')),
            ElevatedButton.icon(onPressed: () => _showImportDialog('Read-Only API токен'), icon: const Icon(Icons.vpn_key, size: 18), label: const Text('По API')),
            ElevatedButton.icon(onPressed: () => _showImportDialog('Вручную MOEX'), icon: const Icon(Icons.edit, size: 18), label: const Text('Вручную')),
          ],
        ),
        const SizedBox(height: 10),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('🩺 Медосмотр и Стресс-тест ставки ЦБ (Текущая: ${widget.state.cbRate.toStringAsFixed(1)}%)', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                const SizedBox(height: 6),
                Text('Если ЦБ изменит ставку на: ${_stressRateDelta.isNegative ? '' : '+'}${_stressRateDelta.toStringAsFixed(1)}%'),
                Slider(
                  value: _stressRateDelta,
                  min: -5.0,
                  max: 5.0,
                  divisions: 20,
                  onChanged: (v) => setState(() => _stressRateDelta = v),
                ),
                Text('Оценка сейчас: ${totalVal.toStringAsFixed(0)} ₽ ➔ После шока: ${stressedVal.toStringAsFixed(0)} ₽ (${(stressedVal - totalVal).toStringAsFixed(0)} ₽)',
                    style: TextStyle(fontWeight: FontWeight.bold, color: (stressedVal - totalVal).isNegative ? Colors.redAccent : Colors.green)),
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
                const Text('⚖️ Ребалансировка без налогов и продаж (До / После)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                const SizedBox(height: 4),
                Text('Сумма свежего пополнения: ${_cashTopUp.toStringAsFixed(0)} ₽'),
                Slider(value: _cashTopUp, min: 5000, max: 150000, divisions: 29, onChanged: (v) => setState(() => _cashTopUp = v)),
                Text('• ДО: Акции ${stockShareBefore.toStringAsFixed(1)}% / Защитные ${(100 - stockShareBefore).toStringAsFixed(1)}% (Налог к уплате: 0 ₽)'),
                Text('• РЕКОМЕНДАЦИЯ: Докупить ОФЗ/Фонды ликвидности на ${buyBondsAmount.toStringAsFixed(0)} ₽ без продажи акций.'),
                Text('• ПОСЛЕ: Акции ${stockShareAfter.toStringAsFixed(1)}% / Защитные ${(100 - stockShareAfter).toStringAsFixed(1)}%', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        ...items.map((raw) {
          final a = raw as AssetItem;
          final pnl = (a.currPrice - a.buyPrice) * a.qty;
          return Card(
            child: ListTile(
              title: Text('${a.name} (${a.ticker})', style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text('Кол-во: ${a.qty} шт | Ср. цена: ${a.buyPrice} ₽ | Дюрация: ${a.duration}'),
              trailing: Text('${pnl.isNegative ? '' : '+'}${pnl.toStringAsFixed(0)} ₽', style: TextStyle(color: pnl.isNegative ? Colors.redAccent : Colors.green, fontWeight: FontWeight.bold)),
            ),
          );
        }),
      ],
    );
  }
}

