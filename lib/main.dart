import 'package:flutter/material.dart';
import 'academy_data.dart';

void main() => runApp(const InvestTrainerApp());

class InvestTrainerApp extends StatefulWidget {
  const InvestTrainerApp({super.key});
  @override
  State<InvestTrainerApp> createState() => _InvestTrainerAppState();
}

class _InvestTrainerAppState extends State<InvestTrainerApp> {
  bool _isPro = false;
  int _tab = 0;
  String _selectedCategory = 'Все';
  String _searchQuery = '';
  final Set<int> _completedLessons = {};

  double _balance = 100000;
  final Map<String, int> _simHoldings = {'SBER': 0, 'LKOH': 0, 'OFZ26238': 0, 'LQDT': 0};
  final Map<String, double> _simPrices = {'SBER': 280, 'LKOH': 7100, 'OFZ26238': 520, 'LQDT': 1.45};
  int _simDay = 1;
  String _simEvent = 'Рынок спокоен. Выберите активы и нажмите «Следующий шаг».';

  @override
  Widget build(BuildContext context) {
    final categories = ['Все', ...{for (final l in academyLessons) l.category}];
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Инвест-Тренажёр',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: _isPro ? Colors.indigo : Colors.teal,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      home: Scaffold(
        appBar: AppBar(
          title: Text(_isPro ? 'PRO Терминал' : 'Инвест-Школа (Новичок)'),
          actions: [
            Row(
              children: [
                const Text('PRO', style: TextStyle(fontWeight: FontWeight.bold)),
                Switch(
                  value: _isPro,
                  onChanged: (v) => setState(() => _isPro = v),
                ),
              ],
            ),
          ],
        ),
        body:IndexedStack(
          index: _tab,
          children: [
            _buildAcademy(categories),
            _buildRadar(),
            _buildSimulator(),
            _buildPortfolioAndNews(),
          ],
        ),
        bottomNavigationBar: NavigationBar(
          selectedIndex: _tab,
          onDestinationSelected: (i) => setState(() => _tab = i),
          destinations: const [
            NavigationDestination(icon: Icon(Icons.school), label: 'Академия'),
            NavigationDestination(icon: Icon(Icons.radar), label: 'Радар'),
            NavigationDestination(icon: Icon(Icons.candlestick_chart), label: 'Симулятор'),
            NavigationDestination(icon: Icon(Icons.pie_chart), label: 'Портфель'),
          ],
        ),
      ),
    );
  }

  Widget _buildAcademy(List<String> categories) {
    final filtered = academyLessons.where((l) {
      final matchCat = _selectedCategory == 'Все' || l.category == _selectedCategory;
      final matchSearch = l.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          l.rule.toLowerCase().contains(_searchQuery.toLowerCase());
      return matchCat && matchSearch;
    }).toList();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
          child: TextField(
            decoration: InputDecoration(
              hintText: 'Поиск по 100 урокам (например: ОФЗ, НКД, P/E)...',
              prefixIcon: const Icon(Icons.search),
              isDense: true,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onChanged: (v) => setState(() => _searchQuery = v),
          ),
        ),
        SizedBox(
          height: 44,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            itemCount: categories.length,
            itemBuilder: (ctx, i) {
              final cat = categories[i];
              final sel = cat == _selectedCategory;
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: ChoiceChip(
                  label: Text(cat),
                  selected: sel,
                  onSelected: (_) => setState(() => _selectedCategory = cat),
                ),
              );
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Найдено уроков: ${filtered.length}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
              Text('Изучено: ${_completedLessons.length} / ${academyLessons.length}',
                  style: const TextStyle(fontSize: 12, color: Colors.tealAccent)),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: filtered.length,
            itemBuilder: (ctx, i) {
              final lesson = filtered[i];
              final done = _completedLessons.contains(lesson.id);
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                child: ExpansionTile(
                  leading: CircleAvatar(
                    backgroundColor: done ? Colors.green : Colors.white12,
                    child: Icon(done ? Icons.check : Icons.menu_book, size: 18),
                  ),
                  title: Text(lesson.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  subtitle: Text('Раздел: ${lesson.category}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _isPro ? 'Фундаментальное правило:' : 'Простыми словами:',
                            style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.tealAccent),
                          ),
                          const SizedBox(height: 4),
                          Text(lesson.rule, style: const TextStyle(fontSize: 15, height: 1.4)),
                          const SizedBox(height: 10),
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.white10,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text('Пример из жизни: ${lesson.example}',
                                style: const TextStyle(fontSize: 13, fontStyle: FontStyle.italic)),
                          ),
                          const SizedBox(height: 12),
                          Align(
                            alignment: Alignment.centerRight,
                            child: FilledButton.icon(
                              onPressed: () {
                                setState(() {
                                  if (done) {
                                    _completedLessons.remove(lesson.id);
                                  } else {
                                    _completedLessons.add(lesson.id);
                                  }
                                });
                              },
                              icon: Icon(done ? Icons.replay : Icons.done_all),
                              label: Text(done ? 'Пройдено (сбросить)' : 'Отметить изученным'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildRadar() {
    final stocks = [
      {'ticker': 'SBER', 'name': 'Сбербанк', 'pe': 4.2, 'debt': 0.0, 'roe': 24.5, 'fcf': 'Плюс', 'verdict': 'Лидер (4 из 4)'},
      {'ticker': 'LKOH', 'name': 'Лукойл', 'pe': 4.5, 'debt': -0.8, 'roe': 21.0, 'fcf': 'Плюс', 'verdict': 'Кубышка (4 из 4)'},
      {'ticker': 'YDEX', 'name': 'Яндекс', 'pe': 14.5, 'debt': 0.5, 'roe': 19.0, 'fcf': 'Плюс', 'verdict': 'Акция роста (3 из 4)'},
      {'ticker': 'MTSS', 'name': 'МТС', 'pe': 6.8, 'debt': 2.6, 'roe': 30.0, 'fcf': 'Слабый', 'verdict': 'Высокий долг (2 из 4)'},
      {'ticker': 'SGZH', 'name': 'Сегежа', 'pe': -5.0, 'debt': 4.8, 'roe': -15.0, 'fcf': 'Минус', 'verdict': 'Опасно! Долги (0 из 4)'},
    ];
    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        const Card(
          color: Colors.indigo,
          child: Padding(
            padding: EdgeInsets.all(12),
            child: Text(
              'Радар 4 Фильтров Профи: зелёным выделены компании с низкой окупаемостью (P/E < 7), низким долгом (Debt/EBITDA < 1.5), высокой рентабельностью (ROE > 20%) и положительным денежным потоком (FCF).',
              style: TextStyle(fontSize: 13),
            ),
          ),
        ),
        const SizedBox(height: 8),
        ...stocks.map((s) {
          final isGood = (s['verdict'] as String).contains('4 из 4');
          final isBad = (s['verdict'] as String).contains('0 из 4');
          return Card(
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: isGood ? Colors.green : (isBad ? Colors.red : Colors.orange),
                child: Text((s['ticker'] as String).substring(0, 2), style: const TextStyle(fontSize: 12)),
              ),
              title: Text('${s['name']} (${s['ticker']})', style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text('P/E: ${s['pe']} | Долг: ${s['debt']}x | ROE: ${s['roe']}% | FCF: ${s['fcf']}'),
              trailing: Text(s['verdict'] as String,
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                      color: isGood ? Colors.greenAccent : (isBad ? Colors.redAccent : Colors.amber))),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildSimulator() {
    double totalAssets = 0;
    _simHoldings.forEach((k, v) => totalAssets += v * (_simPrices[k] ?? 0));
    final totalCapital = _balance + totalAssets;

    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Шаг симуляции #$_simDay', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 6),
                Text('Общий капитал: ${totalCapital.toStringAsFixed(0)} ₽ (Свободный кэш: ${_balance.toStringAsFixed(0)} ₽)',
                    style: const TextStyle(fontSize: 15, color: Colors.tealAccent)),
                const Divider(),
                Text(_simEvent, style: const TextStyle(fontSize: 13)),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: _nextSimStep,
                    icon: const Icon(Icons.fast_forward),
                    label: const Text('Следующий рыночный шаг (Событие)'),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        ..._simPrices.keys.map((ticker) {
          final price = _simPrices[ticker]!;
          final qty = _simHoldings[ticker]!;
          return Card(
            child: ListTile(
              title: Text('$ticker — ${price.toStringAsFixed(2)} ₽'),
              subtitle: Text('В портфеле: $qty шт. на ${(qty * price).toStringAsFixed(0)} ₽'),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.remove_circle_outline, color: Colors.redAccent),
                    onPressed: qty > 0
                        ? () => setState(() {
                              _simHoldings[ticker] = qty - 1;
                              _balance += price;
                            })
                        : null,
                  ),
                  IconButton(
                    icon: const Icon(Icons.add_circle_outline, color: Colors.greenAccent),
                    onPressed: _balance >= price
                        ? () => setState(() {
                              _simHoldings[ticker] = qty + 1;
                              _balance -= price;
                            })
                        : null,
                  ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }

  void _nextSimStep() {
    setState(() {
      _simDay++;
      final step = _simDay % 4;
      if (step == 0) {
        _simEvent = 'ЦБ повысил ставку! Акции и длинные ОФЗ просели, фонд ликвидности LQDT вырос.';
        _simPrices['SBER'] = _simPrices['SBER']! * 0.95;
        _simPrices['OFZ26238'] = _simPrices['OFZ26238']! * 0.94;
        _simPrices['LQDT'] = _simPrices['LQDT']! * 1.02;
      } else if (step == 1) {
        _simEvent = 'Нефть подорожала и пришли дивиденды! Лукойл и Сбер уверенно растут.';
        _simPrices['LKOH'] = _simPrices['LKOH']! * 1.07;
        _simPrices['SBER'] = _simPrices['SBER']! * 1.05;
        _simPrices['LQDT'] = _simPrices['LQDT']! * 1.01;
      } else if (step == 2) {
        _simEvent = 'Инфляция замедлилась! Рынок ждёт снижения ставки: ОФЗ-ПД и акции взлетели.';
        _simPrices['OFZ26238'] = _simPrices['OFZ26238']! * 1.08;
        _simPrices['SBER'] = _simPrices['SBER']! * 1.04;
        _simPrices['LQDT'] = _simPrices['LQDT']! * 1.01;
      } else {
        _simEvent = 'Временная геополитическая коррекция (Шум 1-го уровня). Спокойный шанс докупить активы.';
        _simPrices['SBER'] = _simPrices['SBER']! * 0.97;
        _simPrices['LKOH'] = _simPrices['LKOH']! * 0.96;
        _simPrices['LQDT'] = _simPrices['LQDT']! * 1.01;
      }
    });
  }

  Widget _buildPortfolioAndNews() {
    return ListView(
      padding: const EdgeInsets.all(12),
      children: const [
        Card(
          child: ListTile(
            leading: Icon(Icons.balance, color: Colors.tealAccent),
            title: Text('Безналоговая ребалансировка'),
            subtitle: Text(
              'Целевая структура: 40% Акции РФ, 40% Облигации (ОФЗ + флоатеры), 10% Фонд ликвидности (LQDT), 10% Золото (GLDRUB_TOM). Выравнивай доли свежими пополнениями без продажи бумаг!',
            ),
          ),
        ),
        Card(
          child: ListTile(
            leading: Icon(Icons.newspaper, color: Colors.amber),
            title: Text('Фильтр новостей (Уровень 1 vs Уровень 2)'),
            subtitle: Text(
              'Игнорируй шум и прогнозы блогеров (Уровень 1). Реагируй только на ставку ЦБ, отчёты МСФО, допэмиссии и смену дивидендной политики (Уровень 2).',
            ),
          ),
        ),
        Card(
          child: ListTile(
            leading: Icon(Icons.shield, color: Colors.greenAccent),
            title: Text('Стресс-тест портфеля'),
            subtitle: Text(
              'Если ЦБ поднимет ставку на +2%: флоатеры и LQDT увеличат купон. Если рубль упадёт на 15%: экспортёры (Лукойл) и золото компенсируют просадку.',
            ),
          ),
        ),
      ],
    );
  }
}





