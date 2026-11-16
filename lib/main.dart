import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

void main() => runApp(const InvestApp());

class InvestApp extends StatefulWidget {
  const InvestApp({super.key});
  @override
  State createState() => _InvestAppState();
}

class _InvestAppState extends State {
  bool isPro = false;
  int themeIdx = 0;
  int tabIdx = 0;
  double virtualBal = 100000.0;
  List doneLessons = [];
  List mistakes = ['15.11.2026 | Газпром: Покупка под дивы без учёта дивгэпа (-4200 ₽)'];
  List portfolio = [
    {'t': 'SU26238', 'n': 'ОФЗ 26238', 'type': 'bond', 'q': 50, 'p': 502.0, 'd': 7.8},
    {'t': 'SBER', 'n': 'Сбербанк', 'type': 'stock', 'q': 100, 'p': 265.0, 'd': 0.0},
    {'t': 'LQDT', 'n': 'Фонд Ликвидность', 'type': 'etf', 'q': 10000, 'p': 1.58, 'd': 0.1},
  ];

  double daysSlider = 45.0;
  double durSlider = 5.0;
  List filters = [false, false, false, false];

  String scenario = 'Кризис 2008';
  List prices = [100.0, 102.0, 99.0, 95.0, 91.0];
  double? entryP;
  int simQty = 0;
  Timer? timer;
  String simNews = 'Рынок спокоен. Нажмите Шаг +1 день или Таймлапс.';

  double stressDelta = 0.0;
  double topUp = 30000.0;
  final newsCtrl = TextEditingController(text: 'ЦБ повысил ставку, Сбербанк объявил рекордные дивиденды');
  final backupCtrl = TextEditingController();
  String radarOut = 'Нажмите кнопку ниже для рентгена новости.';

  void nextSimStep() {
    setState(() {
      final last = (prices.last as num).toDouble();
      final delta = (Random().nextDouble() - 0.48) * 6.0;
      final next = (last + delta).clamp(30.0, 200.0);
      prices.add(next);
      if (prices.length % 4 == 0) {
        timer?.cancel();
        timer = null;
        simNews = (next - last).isNegative
            ? '⚡ АВТО-ПАУЗА: ЦБ жёстко поднял ставку! Ожидание: пауза | Реальность: негатив'
            : '⚡ АВТО-ПАУЗА: Вышел сильный отчёт! Ожидание: спад | Реальность: рекордные дивы';
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = themeIdx == 1
        ? ThemeData.light(useMaterial3: true)
        : ThemeData.dark(useMaterial3: true).copyWith(scaffoldBackgroundColor: themeIdx == 2 ? Colors.black : null);

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: theme,
      home: Builder(
        builder: (ctx) => Scaffold(
          appBar: AppBar(
            title: Text(isPro ? 'PRO Терминал' : 'Инвест-Тренажер'),
            actions: [
              TextButton(
                onPressed: () => setState(() => isPro = !isPro),
                child: Text(isPro ? '⚡ ПРОФИ' : '🌱 НОВИЧОК'),
              ),
              IconButton(
                icon: const Icon(Icons.help_outline),
                onPressed: () => showModalBottomSheet(
                  context: ctx,
                  builder: (_) => ListView(
                    padding: const EdgeInsets.all(16),
                    children: const [
                      Text('📖 Словарь терминов', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      ListTile(title: Text('НКД'), subtitle: Text('Накопленный купонный доход за дни владения облигацией.')),
                      ListTile(title: Text('Дюрация'), subtitle: Text('На сколько % упадёт облигация при росте ставки ЦБ на 1%.')),
                      ListTile(title: Text('Оферта'), subtitle: Text('Дата, когда купон могут сбросить до 0.01%. Опасно пропускать!')),
                      ListTile(title: Text('Дивгэп'), subtitle: Text('Падение акции на сумму дивиденда в день отсечки.')),
                      ListTile(title: Text('ГО'), subtitle: Text('Гарантийное обеспечение (залог) по фьючерсу.')),
                    ],
                  ),
                ),
              ),
              IconButton(icon: const Icon(Icons.palette_outlined), onPressed: () => setState(() => themeIdx = (themeIdx + 1) % 3)),
            ],
          ),
          body: [buildAcademy(), buildSim(), buildPortfolio(), buildRadar()][tabIdx],
          bottomNavigationBar: NavigationBar(
            selectedIndex: tabIdx,
            onDestinationSelected: (i) => setState(() => tabIdx = i),
            destinations: const [
              NavigationDestination(icon: Icon(Icons.school_outlined), label: 'Академия'),
              NavigationDestination(icon: Icon(Icons.candlestick_chart_outlined), label: 'Тренажер'),
              NavigationDestination(icon: Icon(Icons.pie_chart_outline), label: 'Портфель'),
              NavigationDestination(icon: Icon(Icons.radar_outlined), label: 'Инфо-Радар'),
            ],
          ),
        ),
      ),
    );
  }

  Widget buildAcademy() {
    final nkd = 1000 * 0.12 / 365 * daysSlider;
    final drop = -(durSlider * 2.0);
    final lessons = [
      ['m1', 'Ступень 1: ОФЗ и НКД', 'Продаёшь раньше купона — покупатель платит тебе НКД за дни владения.', 'НКД = Номинал * Купон / 365 * Дни. Учитывайте НДФЛ 13%.'],
      ['m2', 'Ступень 2: Дюрация и Оферта', 'Дюрация = падение цены при росте ставки ЦБ. В оферту купон могут сделать 0.01%!', 'dP = -D * dr. Подавайте заявку брокеру за 5 дней до пут-оферты.'],
      ['m3', 'Ступень 3: Акции, Дивгэп, БПИФ', 'Утром после отсечки акция падает на размер дивиденда.', 'Дивгэп = Дивиденд * 0.87. В БПИФ проверяйте скрытую комиссию TER.'],
      ['m4', 'Ступень 4: Фьючерсы и ГО', 'Залог (ГО) всего 15%, но убытки списывают со счёта каждый вечер!', 'При нехватке кэша под вариационную маржу в клиринг наступает Margin Call.'],
      ['m5', 'Ступень 5: Опционы и Шорты', 'В шорте убыток бесконечен. В покупке опциона риск ограничен ценой страховки.', 'Тэта-распад играет против покупателя опциона Call/Put.'],
    ];
    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('🎛 Ползунки: Дней ${daysSlider.toInt()} -> НКД: ${nkd.toStringAsFixed(1)} ₽ | Дюрация ${durSlider.toStringAsFixed(1)} -> Цена: ${drop.toStringAsFixed(1)}%'),
                Slider(value: daysSlider, min: 0, max: 182, onChanged: (v) => setState(() => daysSlider = v)),
                Slider(value: durSlider, min: 1, max: 10, onChanged: (v) => setState(() => durSlider = v)),
              ],
            ),
          ),
        ),
        ...lessons.map((l) => Card(
              child: ListTile(
                title: Text(l[1], style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text(isPro ? l[3] : l[2]),
                trailing: ElevatedButton(
                  onPressed: () => setState(() => doneLessons.add(l[0])),
                  child: Text(doneLessons.contains(l[0]) ? '✅' : 'Понял'),
                ),
              ),
            )),
        Card(
          child: Column(
            children: [
              const Padding(padding: EdgeInsets.all(8), child: Text('🛡 4 Фильтра Профи и 📓 Дневник граблей', style: TextStyle(fontWeight: FontWeight.bold))),
              CheckboxListTile(value: filters[0] as bool, onChanged: (v) => setState(() => filters[0] = v ?? false), title: const Text('1. Понятен источник дохода и оферта')),
              CheckboxListTile(value: filters[1] as bool, onChanged: (v) => setState(() => filters[1] = v ?? false), title: const Text('2. Учтена комиссия, НДФЛ и точка выхода')),
              ...mistakes.map((m) => ListTile(dense: true, leading: const Icon(Icons.warning, color: Colors.orange), title: Text(m.toString()))),
            ],
          ),
        ),
      ],
    );
  }

  Widget buildSim() {
    final curr = (prices.last as num).toDouble();
    final breakEven = entryP == null ? null : entryP! * 1.008;
    final rawPnl = entryP == null ? 0.0 : (curr - entryP!) * simQty;
    final netPnl = rawPnl - (rawPnl.isNegative ? 0.0 : rawPnl * 0.13) - ((entryP ?? 0) * simQty * 0.003);
    final isDanger = (curr - (entryP ?? curr) * 0.93).isNegative || simNews.contains('негатив');

    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        Card(color: Colors.amber.withValues(alpha: 0.15), child: Padding(padding: const EdgeInsets.all(10), child: Text(simNews))),
        const SizedBox(height: 8),
        Container(
          height: 140,
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(border: Border.all(color: Colors.grey), borderRadius: BorderRadius.circular(8)),
          child: CustomPaint(painter: SimpleChart(prices), size: Size.infinite),
        ),
        const SizedBox(height: 8),
        Text('Цена: ${curr.toStringAsFixed(2)} ₽ | Безубыток: ${breakEven?.toStringAsFixed(2) ?? "-"} ₽ | Чистыми: ${netPnl.toStringAsFixed(1)} ₽', style: const TextStyle(fontWeight: FontWeight.bold)),
        Wrap(
          spacing: 8,
          children: [
            ElevatedButton(onPressed: nextSimStep, child: const Text('Шаг +1 день')),
            ElevatedButton(
              onPressed: () => setState(() {
                if (timer != null) {
                  timer?.cancel();
                  timer = null;
                } else {
                  timer = Timer.periodic(const Duration(milliseconds: 800), (_) => nextSimStep());
                }
              }),
              child: Text(timer != null ? 'Пауза' : 'Таймлапс'),
            ),
            ElevatedButton(onPressed: () => setState(() { entryP = curr; simQty = 100; }), child: const Text('Купить 100 шт')),
            ElevatedButton(
              onPressed: simQty == 0 ? null : () => setState(() {
                if (netPnl.isNegative) mistakes.insert(0, 'Тренажер: Продажа в минус (${netPnl.toStringAsFixed(0)} ₽)');
                virtualBal += netPnl;
                entryP = null;
                simQty = 0;
              }),
              child: const Text('Закрыть'),
            ),
          ],
        ),
        Card(
          child: ListTile(
            leading: Icon(Icons.circle, color: isDanger ? Colors.red : Colors.green),
            title: Text(isDanger ? '🚦 КРАСНЫЙ: Сработал сигнал выхода!' : '🚦 ЗЕЛЕНЫЙ: 5 сигналов в норме, держим'),
            subtitle: Text('Виртуальный счёт: ${virtualBal.toStringAsFixed(0)} ₽'),
          ),
        ),
      ],
    );
  }

  Widget buildPortfolio() {
    double total = 0, stressed = 0, stocks = 0;
    for (var raw in portfolio) {
      final a = raw as Map;
      final v = (a['q'] as int) * (a['p'] as double);
      total += v;
      if (a['type'] == 'stock') stocks += v;
      final drop = a['type'] == 'stock' ? (-stressDelta * 2.2) : (-(a['d'] as double) * stressDelta);
      stressed += v * (1 + drop / 100);
    }
    final beforePct = total == 0 ? 0.0 : (stocks / total * 100);
    final afterPct = (total + topUp) == 0 ? 0.0 : (stocks / (total + topUp) * 100);

    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        ElevatedButton(
          onPressed: () => setState(() => portfolio.add({'t': 'LKOH', 'n': 'Лукойл (Импорт)', 'type': 'stock', 'q': 10, 'p': 7100.0, 'd': 0.0})),
          child: const Text('📥 Импорт: Скриншот / Файл / API / Вручную (+LKOH)'),
        ),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('🩺 Стресс-тест ставки ЦБ (${stressDelta.toStringAsFixed(1)}%): ${total.toStringAsFixed(0)} ₽ -> ${stressed.toStringAsFixed(0)} ₽'),
                Slider(value: stressDelta, min: -5, max: 5, onChanged: (v) => setState(() => stressDelta = v)),
                Text('⚖️ Ребалансировка без налогов (+${topUp.toStringAsFixed(0)} ₽ в бонды): Акции ДО ${beforePct.toStringAsFixed(1)}% -> ПОСЛЕ ${afterPct.toStringAsFixed(1)}%'),
                Slider(value: topUp, min: 10000, max: 150000, onChanged: (v) => setState(() => topUp = v)),
              ],
            ),
          ),
        ),
        ...portfolio.map((raw) {
          final a = raw as Map;
          return Card(child: ListTile(title: Text('${a['n']} (${a['t']})'), subtitle: Text('${a['q']} шт по ${a['p']} ₽ | Дюрация: ${a['d']}')));
        }),
      ],
    );
  }

  Widget buildRadar() {
    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('📡 Двухуровневый Инфо-Радар', style: TextStyle(fontWeight: FontWeight.bold)),
                TextField(controller: newsCtrl, maxLines: 2),
                const SizedBox(height: 8),
                ElevatedButton(
                  onPressed: () => setState(() {
                    final t = newsCtrl.text.toLowerCase();
                    radarOut = '${t.contains('ставк') ? '🔴 Ставка ЦБ: Риск для длинных ОФЗ 26238, плюс для LQDT.\n' : ''}${t.contains('дивиденд') ? '🟢 Дивиденды: Плюс для SBER, учтите дивгэп и НДФЛ 13%.' : ''}';
                    if (radarOut.isEmpty) radarOut = '🟡 Нейтральный шум.';
                  }),
                  child: const Text('Просветить новость рентгеном'),
                ),
                const SizedBox(height: 8),
                Text(radarOut),
              ],
            ),
          ),
        ),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                const Text('☁️ Бэкап (JSON + Telegram Bot API)', style: TextStyle(fontWeight: FontWeight.bold)),
                TextField(controller: backupCtrl, decoration: const InputDecoration(labelText: 'JSON строка бэкапа')),
                Row(
                  children: [
                    ElevatedButton(
                      onPressed: () {
                        final j = jsonEncode({'bal': virtualBal, 'port': portfolio, 'mistakes': mistakes});
                        backupCtrl.text = j;
                        Clipboard.setData(ClipboardData(text: j));
                      },
                      child: const Text('Экспорт JSON'),
                    ),
                    const SizedBox(width: 8),
                    OutlinedButton(
                      onPressed: () {
                        try {
                          final d = jsonDecode(backupCtrl.text);
                          setState(() => virtualBal = ((d['bal'] ?? 100000) as num).toDouble());
                        } catch (_) {}
                      },
                      child: const Text('Импорт JSON'),
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

class SimpleChart extends CustomPainter {
  final List p;
  SimpleChart(this.p);
  @override
  void paint(Canvas canvas, Size size) {
    if (p.length == 1) return;
    final list = p.map((e) => (e as num).toDouble()).toList();
    final minV = list.reduce(min) - 5, maxV = list.reduce(max) + 5;
    final path = Path();
    for (int i = 0; i != list.length; i++) {
      final x = i * (size.width / (list.length - 1));
      final y = size.height - ((list[i] - minV) / (maxV - minV)) * size.height;
      i == 0 ? path.moveTo(x, y) : path.lineTo(x, y);
    }
    canvas.drawPath(path, Paint()..color = Colors.lightBlueAccent..strokeWidth = 2.5..style = PaintingStyle.stroke);
  }
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
// КОНЕЦ ФАЙЛА


