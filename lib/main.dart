import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'lessons_data.dart';

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
  int selectedStage = 1; // 1..5 (по 20 уроков)
  String searchQuery = '';
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
            title: Text('Академия: ${doneLessons.length}/100'),
            actions: [
              TextButton(
                onPressed: () => setState(() => isPro = !isPro),
                child: Text(isPro ? '⚡ ПРОФИ' : '🌱 НА ПАЛЬЦАХ'),
              ),
              IconButton(
                icon: const Icon(Icons.help_outline),
                onPressed: () => showModalBottomSheet(
                  context: ctx,
                  builder: (_) => ListView(
                    padding: const EdgeInsets.all(16),
                    children: const [
                      Text('📖 Быстрый словарь на пальцах', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      ListTile(title: Text('НКД'), subtitle: Text('Копейки купона за каждый день, которые покупатель возвращает продавцу.')),
                      ListTile(title: Text('Дюрация'), subtitle: Text('На сколько % упадёт облигация, если ЦБ поднимет ставку на 1%.')),
                      ListTile(title: Text('Оферта'), subtitle: Text('Опасная дата, когда купон облигации могут сбросить до 0.01%!')),
                      ListTile(title: Text('Дивгэп'), subtitle: Text('Утреннее падение акции ровно на сумму выплаченного дивиденда.')),
                      ListTile(title: Text('ГО'), subtitle: Text('Залог (10–20%) при покупке фьючерса. Опасно брать на весь счёт!')),
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
              NavigationDestination(icon: Icon(Icons.school_outlined), label: '100 Уроков'),
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
    final stageNames = [
      '1. Азы и ОФЗ (1-20)',
      '2. Ставка и Оферта (21-40)',
      '3. Акции и БПИФ (41-60)',
      '4. Фьючерсы и ГО (61-80)',
      '5. Опционы и Профи (81-100)',
    ];

    final filtered = all100Lessons.where((raw) {
      final item = raw as List;
      if (searchQuery.isNotEmpty) {
        final q = searchQuery.toLowerCase();
        return item[2].toString().toLowerCase().contains(q) || item[3].toString().toLowerCase().contains(q);
      }
      return item[1] == selectedStage;
    }).toList();

    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('📊 Прогресс обучения: пройдено ${doneLessons.length} из 100 уроков', style: const TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                LinearProgressIndicator(value: doneLessons.length / 100.0, minHeight: 8),
                const SizedBox(height: 10),
                Text('🎛 Тренажер НКД и Дюрации: Дней ${daysSlider.toInt()} -> НКД: ${nkd.toStringAsFixed(1)} ₽ | Дюрация ${durSlider.toStringAsFixed(1)} -> Цена при росте ставки +2%: ${drop.toStringAsFixed(1)}%'),
                Slider(value: daysSlider, min: 0, max: 182, onChanged: (v) => setState(() => daysSlider = v)),
                Slider(value: durSlider, min: 1, max: 10, onChanged: (v) => setState(() => durSlider = v)),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          decoration: const InputDecoration(
            prefixIcon: Icon(Icons.search),
            labelText: 'Поиск по всем 100 урокам (например: оферта, дивгэп, шорт)',
            border: OutlineInputBorder(),
          ),
          onChanged: (v) => setState(() => searchQuery = v.trim()),
        ),
        const SizedBox(height: 8),
        if (searchQuery.isEmpty)
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: List.generate(5, (idx) {
              final stNum = idx + 1;
              final active = selectedStage == stNum;
              return ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: active ? Colors.amber.shade800 : null,
                  foregroundColor: active ? Colors.white : null,
                ),
                onPressed: () => setState(() => selectedStage = stNum),
                child: Text(stageNames[idx]),
              );
            }),
          ),
        const SizedBox(height: 8),
        ...filtered.map((raw) {
          final l = raw as List;
          final numId = l[0];
          final title = l[2].toString();
          final simpleText = l[3].toString();
          final proText = l[4].toString();
          final isDone = doneLessons.contains(numId);

          return Card(
            margin: const EdgeInsets.only(bottom: 10),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 16,
                        backgroundColor: isDone ? Colors.green : Colors.blueGrey,
                        child: Text('$numId', style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                      ),
                      const SizedBox(width: 10),
                      Expanded(child: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16))),
                      ElevatedButton(
                        onPressed: () => setState(() {
                          if (isDone) {
                            doneLessons.remove(numId);
                          } else {
                            doneLessons.add(numId);
                          }
                        }),
                        child: Text(isDone ? '✅ Сдано' : 'Понял!'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text('🌱 На пальцах: $simpleText', style: const TextStyle(fontSize: 14.5)),
                  if (isPro) ...[
                    const Divider(height: 14),
                    Text('⚡ На языке профи: $proText', style: const TextStyle(fontSize: 13, color: Colors.amberAccent)),
                  ],
                ],
              ),
            ),
          );
        }),
        Card(
          child: Column(
            children: [
              const Padding(padding: EdgeInsets.all(8), child: Text('🛡 4 Фильтра Профи и 📓 Дневник граблей', style: TextStyle(fontWeight: FontWeight.bold))),
              CheckboxListTile(value: filters[0] as bool, onChanged: (v) => setState(() => filters[0] = v ?? false), title: const Text('1. Понятен источник дохода и проверена дата оферты')),
              CheckboxListTile(value: filters[1] as bool, onChanged: (v) => setState(() => filters[1] = v ?? false), title: const Text('2. Учтена комиссия, налог 13% и известна точка выхода')),
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
                        final j = jsonEncode({'bal': virtualBal, 'port': portfolio, 'mistakes': mistakes, 'done': doneLessons});
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
                          setState(() {
                            virtualBal = ((d['bal'] ?? 100000) as num).toDouble();
                            doneLessons = (d['done'] as List? ?? []);
                          });
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



