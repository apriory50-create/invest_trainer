import 'package:flutter/material.dart';

void main() => runApp(const InvestTrainerApp());

class InvestTrainerApp extends StatelessWidget {
  const InvestTrainerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Invest Trainer',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const MainScreen(),
    );
  }
}

class AssetItem {
  final String ticker;
  final String name;
  final String type; // Акция, ОФЗ, Фонд
  double price;
  final double couponOrDiv; // % годовых
  final double nkd; // НКД для облигаций

  AssetItem({
    required this.ticker,
    required this.name,
    required this.type,
    required this.price,
    required this.couponOrDiv,
    this.nkd = 0.0,
  });
}

class LessonItem {
  final String title;
  final String subtitle;
  final String content;
  final String question;
  final List<String> options;
  final int correctIndex;
  bool completed;

  LessonItem({
    required this.title,
    required this.subtitle,
    required this.content,
    required this.question,
    required this.options,
    required this.correctIndex,
    this.completed = false,
  });
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _tab = 0;
  double _cash = 100000.0;
  double _imoex = 2745.50;
  double _imoexChange = 1.2;
  final Map<String, int> _portfolio = {'SU26238': 10, 'SBER': 20};

  // Стресс-тест параметры
  double _crashPercent = -20.0;
  bool _useBondShield = true;

  // Калькулятор ОФЗ параметры
  int _calcBondCount = 10;

  final List<AssetItem> _market = [
    AssetItem(ticker: 'SBER', name: 'Сбербанк', type: 'Акция', price: 280.0, couponOrDiv: 12.5),
    AssetItem(ticker: 'LKOH', name: 'Лукойл', type: 'Акция', price: 6900.0, couponOrDiv: 14.0),
    AssetItem(ticker: 'SU26238', name: 'ОФЗ 26238 (Длинная)', type: 'ОФЗ', price: 540.0, couponOrDiv: 13.1, nkd: 18.4),
    AssetItem(ticker: 'SU26244', name: 'ОФЗ 26244 (Средняя)', type: 'ОФЗ', price: 820.0, couponOrDiv: 15.2, nkd: 24.1),
    AssetItem(ticker: 'LQDT', name: 'Фонд Ликвидности', type: 'Фонд', price: 1.55, couponOrDiv: 19.5),
  ];

  final List<LessonItem> _lessons = [
    LessonItem(
      title: 'Урок 1: Что такое акции и облигации?',
      subtitle: 'Основы фондового рынка для новичков.',
      content: 'Акция — это доля в бизнесе. Покупая акцию Сбера или Лукойла, вы становитесь совладельцем компании и получаете часть прибыли (дивиденды), но берете на себя риск падения цены.\n\nОблигация (например, ОФЗ) — это долговая расписка. Вы даете в долг государству или компании под заранее известный процент (купон) и знаете точную дату возврата номинала (обычно 1000 ₽).',
      question: 'Что из этого является долговой распиской с известным купоном?',
      options: ['Акция', 'Облигация (ОФЗ)', 'Фьючерс'],
      correctIndex: 1,
    ),
    LessonItem(
      title: 'Урок 2: Купоны и НКД по ОФЗ',
      subtitle: 'Как работают государственные облигации.',
      content: 'По облигациям купон начисляется каждый день, хотя выплачивается обычно раз в полгода. Накопленный купонный доход (НКД) — это та часть купона, которая накопилась с момента последней выплаты.\n\nПри покупке облигации вы платите продавцу рыночную цену + НКД, но в день выплаты получаете весь купон целиком на свой счет. Поэтому вы не теряете проценты даже при продаже бумаги раньше срока.',
      question: 'Что происходит с НКД при продаже облигации до выплаты купона?',
      options: ['Он сгорает полностью', 'Покупатель возмещает вам накопленный НКД', 'Его забирает биржа'],
      correctIndex: 1,
    ),
    LessonItem(
      title: 'Урок 3: Диверсификация портфеля',
      subtitle: 'Почему нельзя хранить все яйца в одной корзине.',
      content: 'Если вложить все деньги в одну акцию, любая плохая новость по компании может обрушить ваш капитал на 40–50%. Диверсификация — это распределение денег между разными классами активов: акциями, короткими ОФЗ и фондами денежного рынка (БПИФ).\n\nВ кризис акции падают, но короткие ОФЗ и фонды ликвидности продолжают приносить купонный доход и дают кэш для докупки подешевевших акций.',
      question: 'Зачем в портфеле нужны короткие ОФЗ и фонды ликвидности?',
      options: ['Для снижения просадки и запаса кэша', 'Они растут на 200% в год', 'Чтобы платить больше комиссий'],
      correctIndex: 0,
    ),
    LessonItem(
      title: 'Урок 4: Дюрация и ключевая ставка ЦБ',
      subtitle: 'Почему длинные ОФЗ падают при росте ставки.',
      content: 'Когда ЦБ повышает ключевую ставку, старые облигации с маленьким купоном дешевеют, чтобы их доходность к погашению сравнялась с новыми условиями рынка.\n\nДюрация показывает чувствительность цены облигации к ставке ЦБ: если дюрация равна 5 годам, то при росте ставки на 1% цена бумаги упадет примерно на 5%. А когда ЦБ начинает снижать ставку — длинные ОФЗ дают мощный рост тела бумаги!',
      question: 'Как ведут себя длинные ОФЗ при переходе ЦБ к снижению ключевой ставки?',
      options: ['Их цена на бирже растет', 'Их отменяют', 'Купон становится отрицательным'],
      correctIndex: 0,
    ),
    LessonItem(
      title: 'Урок 5: Фьючерсы и Опционы — база',
      subtitle: 'Срочный рынок и защита портфеля (хеджирование).',
      content: 'Фьючерс — это контракт на покупку или продажу актива в будущем по фиксированной сегодня цене. В нем есть встроенное кредитное плечо (гарантийное обеспечение), поэтому без опыта на нем легко потерять депозит.\n\nОпцион дает ПРАВО (но не обязанность) купить или продать актив по заданной цене. Опытные инвесторы покупают Put-опционы как страховку (КАСКО) от обвала рынка.',
      question: 'Чем покупка опциона отличается от фьючерса?',
      options: ['Риск покупателя опциона ограничен ценой премии', 'Опцион не имеет срока действия', 'По опциону платят НКД'],
      correctIndex: 0,
    ),
  ];

  final List> _newsList = [
    {
      'title': 'ЦБ РФ сохранил ключевую ставку на текущем уровне',
      'impact': 'Нейтрально-позитивно',
      'advice': 'Ставка стабильна. Удерживайте до 40% в коротких ОФЗ и фондах ликвидности, а купоны реинвестируйте в подешевевшие дивидендные акции.',
      'marketShift': '1.5',
    },
    {
      'title': 'Нефтяные компании объявили рекордные промежуточные дивиденды',
      'impact': 'Позитив для акций (+3.5%)',
      'advice': 'Экспортеры (Лукойл и др.) поддержат индекс Мосбиржи. Хороший момент для удержания акций в портфеле.',
      'marketShift': '3.5',
    },
    {
      'title': 'Ужесточение налоговой нагрузки и геополитический шум',
      'impact': 'Высокий риск просадки (-4.0%)',
      'advice': 'Рынок акций может временно просесть. Не покупайте на эмоциях, используйте защитную часть портфеля (ОФЗ/LQDT) для плавной докупки на просадке.',
      'marketShift': '-4.0',
    },
  ];
  int _selectedNewsIndex = 0;

  double get _portfolioAssetsValue {
    double total = 0;
    _portfolio.forEach((ticker, qty) {
      final asset = _market.firstWhere((a) => a.ticker == ticker);
      total += (asset.price + asset.nkd) * qty;
    });
    return total;
  }

  double get _totalCapital => _cash + _portfolioAssetsValue;

  void _buyAsset(AssetItem asset) {
    final cost = asset.price + asset.nkd;
    if (_cash >= cost) {
      setState(() {
        _cash -= cost;
        _portfolio[asset.ticker] = (_portfolio[asset.ticker] ?? 0) + 1;
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Недостаточно свободных средств (кэша)!')),
      );
    }
  }

  void _sellAsset(AssetItem asset) {
    final currentQty = _portfolio[asset.ticker] ?? 0;
    if (currentQty > 0) {
      setState(() {
        _cash += (asset.price + asset.nkd);
        if (currentQty == 1) {
          _portfolio.remove(asset.ticker);
        } else {
          _portfolio[asset.ticker] = currentQty - 1;
        }
      });
    }
  }

  void _simulateMarketStep(double shiftPercent) {
    setState(() {
      _imoexChange = shiftPercent;
      _imoex = _imoex * (1 + shiftPercent / 100);
      for (var a in _market) {
        if (a.type == 'Акция') {
          a.price = double.parse((a.price * (1 + shiftPercent / 100)).toStringAsFixed(1));
        } else if (a.type == 'ОФЗ') {
          a.price = double.parse((a.price * (1 + (shiftPercent * 0.25) / 100)).toStringAsFixed(1));
        }
      }
    });
  }

  void _openLesson(LessonItem lesson) {
    int? selectedOption;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: const EdgeInsets.all(20),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(lesson.title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    Text(lesson.content, style: const TextStyle(fontSize: 16, height: 1.4)),
                    const Divider(height: 32),
                    const Text('Проверка знаний:', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Text(lesson.question, style: const TextStyle(fontSize: 15)),
                    const SizedBox(height: 10),
                    ...List.generate(lesson.options.length, (idx) {
                      return RadioListTile<int>(
                        title: Text(lesson.options[idx]),
                        value: idx,
                        groupValue: selectedOption,
                        onChanged: (val) => setModalState(() => selectedOption = val),
                      );
                    }),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: selectedOption == null
                            ? null
                            : () {
                                if (selectedOption == lesson.correctIndex) {
                                  setState(() {
                                    lesson.completed = true;
                                    _cash += 1000; // Бонус на счет за урок
                                  });
                                  Navigator.pop(context);
                                  ScaffoldMessenger.of(this.context).showSnackBar(
                                    const SnackBar(content: Text('Верно! Урок пройден (+1000 ₽ на учебный счет)')),
                                  );
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Не совсем так, попробуй другой вариант!')),
                                  );
                                }
                              },
                        child: const Text('Проверить ответ'),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildAcademyTab() {
    final doneCount = _lessons.where((l) => l.completed).length;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text('Академия инвестиций', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
        const SizedBox(height: 6),
        Text('Пройдено уроков: $doneCount из ${_lessons.length} (За каждый урок +1 000 ₽ в портфель)',
            style: const TextStyle(color: Colors.grey)),
        const SizedBox(height: 12),
        LinearProgressIndicator(value: doneCount / _lessons.length),
        const SizedBox(height: 16),
        ..._lessons.map((lesson) => Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: ListTile(
                leading: Icon(
                  lesson.completed ? Icons.check_circle : Icons.menu_book,
                  color: lesson.completed ? Colors.green : Colors.blue,
                  size: 30,
                ),
                title: Text(lesson.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text(lesson.subtitle),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _openLesson(lesson),
              ),
            )),
      ],
    );
  }

  Widget _buildSimulatorTab() {
    final ofz26238 = _market.firstWhere((a) => a.ticker == 'SU26238');
    final totalBondCost = (ofz26238.price + ofz26238.nkd) * _calcBondCount;
    final annualCoupon = _calcBondCount * 71.0; // ~71 руб купон в год на бумагу

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text('Симулятор торгов и MOEX', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        Card(
          color: Colors.blue.shade50,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Индекс Мосбиржи (IMOEX)', style: TextStyle(color: Colors.black54)),
                        Text(
                          '${_imoex.toStringAsFixed(2)} ₽ (${_imoexChange >= 0 ? '+' : ''}${_imoexChange.toStringAsFixed(1)}%)',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: _imoexChange >= 0 ? Colors.green.shade700 : Colors.red.shade700,
                          ),
                        ),
                      ],
                    ),
                    ElevatedButton.icon(
                      onPressed: () => _simulateMarketStep(1.8),
                      icon: const Icon(Icons.bolt, size: 18),
                      label: const Text('Новый день'),
                    ),
                  ],
                ),
                const Divider(height: 24),
                Text('Общий капитал: ${_totalCapital.toStringAsFixed(0)} ₽',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                Text('Свободный кэш: ${_cash.toStringAsFixed(0)} ₽  |  В активах: ${_portfolioAssetsValue.toStringAsFixed(0)} ₽'),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        const Text('Биржевой стакан (Покупка и Продажа):', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        ..._market.map((asset) {
          final qty = _portfolio[asset.ticker] ?? 0;
          return Card(
            margin: const EdgeInsets.only(bottom: 10),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('${asset.name} (${asset.ticker})', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        Text('Тип: ${asset.type} • Доходность: ~${asset.couponOrDiv}%'),
                        Text(
                          asset.nkd > 0
                              ? 'Цена: ${asset.price} ₽ + НКД ${asset.nkd} ₽ | В портфеле: $qty шт.'
                              : 'Цена: ${asset.price} ₽ | В портфеле: $qty шт.',
                          style: const TextStyle(color: Colors.blueGrey, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                  IconButton.filledTonal(
                    onPressed: qty > 0 ? () => _sellAsset(asset) : null,
                    icon: const Icon(Icons.remove),
                  ),
                  const SizedBox(width: 6),
                  IconButton.filled(
                    onPressed: () => _buyAsset(asset),
                    icon: const Icon(Icons.add),
                  ),
                ],
              ),
            ),
          );
        }),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Калькулятор ОФЗ 26238 и НКД', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text('Количество облигаций: $_calcBondCount шт.'),
                Slider(
                  value: _calcBondCount.toDouble(),
                  min: 1,
                  max: 100,
                  divisions: 99,
                  onChanged: (v) => setState(() => _calcBondCount = v.toInt()),
                ),
                Text('Сумма покупки (с учетом НКД): ${totalBondCost.toStringAsFixed(0)} ₽'),
                Text('Купонный доход за год: +${annualCoupon.toStringAsFixed(0)} ₽',
                    style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStressTestTab() {
    final factor = _useBondShield ? 0.7 : 1.0;
    final loss = _totalCapital * (_crashPercent.abs() / 100) * factor;
    final afterCrash = _totalCapital - loss;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text('Стресс-тест портфеля (Кризис-менеджер)', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        const Text('Расчет привязан к вашему реальному портфелю из вкладки «Симулятор».', style: TextStyle(color: Colors.grey)),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Текущая стоимость вашего портфеля:', style: TextStyle(color: Colors.grey)),
                Text('${_totalCapital.toStringAsFixed(0)} ₽', style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
                const Divider(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Сценарий падения индекса:'),
                    Text('${_crashPercent.toInt()}%', style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                  ],
                ),
                Slider(
                  value: _crashPercent,
                  min: -50,
                  max: -5,
                  divisions: 9,
                  onChanged: (v) => setState(() => _crashPercent = v),
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Защита облигациями / ОФЗ'),
                  subtitle: const Text('Снижает общую просадку портфеля на 30%'),
                  value: _useBondShield,
                  onChanged: (v) => setState(() => _useBondShield = v),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Card(
          color: Colors.red.shade50,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Результат стресс-теста:', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 8),
                Text('Прогнозируемый убыток: -${loss.toStringAsFixed(0)} ₽'),
                const SizedBox(height: 6),
                Text('Стоимость портфеля в кризис: ${afterCrash.toStringAsFixed(0)} ₽',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAiNewsTab() {
    final currentNews = _newsList[_selectedNewsIndex];
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text('ИИ Анализ новостей и рисков', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        const Text('Выберите новость ниже, чтобы увидеть оценку влияния на ваш портфель:', style: TextStyle(color: Colors.grey)),
        const SizedBox(height: 12),
        ...List.generate(_newsList.length, (i) {
          final item = _newsList[i];
          final isSelected = i == _selectedNewsIndex;
          return Card(
            color: isSelected ? Colors.blue.shade50 : null,
            margin: const EdgeInsets.only(bottom: 10),
            child: ListTile(
              leading: Icon(Icons.newspaper, color: isSelected ? Colors.blue : Colors.grey),
              title: Text(item['title']!, style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text('Оценка: ${item['impact']}'),
              trailing: ElevatedButton(
                onPressed: () {
                  setState(() => _selectedNewsIndex = i);
                  _simulateMarketStep(double.parse(item['marketShift']!));
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Новость отыграна в котировках Симулятора (${item['marketShift']}%)')),
                  );
                },
                child: const Text('Применить'),
              ),
              onTap: () => setState(() => _selectedNewsIndex = i),
            ),
          );
        }),
        const SizedBox(height: 12),
        Card(
          color: Colors.lightBlue.shade50,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('🤖 Рекомендация ИИ-наставника:',
                    style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 8),
                Text(currentNews['advice']!, style: const TextStyle(fontSize: 15, height: 1.4)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      _buildAcademyTab(),
      _buildSimulatorTab(),
      _buildStressTestTab(),
      _buildAiNewsTab(),
    ];

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blue.shade100,
        title: const Text('Invest Trainer 🚀'),
      ),
      body: pages[_tab],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tab,
        onDestinationSelected: (i) => setState(() => _tab = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.school), label: 'Академия'),
          NavigationDestination(icon: Icon(Icons.show_chart), label: 'Симулятор'),
          NavigationDestination(icon: Icon(Icons.shield), label: 'Стресс-тест'),
          NavigationDestination(icon: Icon(Icons.psychology), label: 'ИИ Анализ'),
        ],
      ),
    );
  }
}












