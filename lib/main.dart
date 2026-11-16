import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

void main() {
  runApp(const InvestTrainerApp());
}

class MistakeItem {
  final String date;
  final String asset;
  final String error;
  final double loss;
  MistakeItem(this.date, this.asset, this.error, this.loss);
  Map toJson() => {'date': date, 'asset': asset, 'error': error, 'loss': loss};
  static MistakeItem fromJson(dynamic m) => MistakeItem(
        (m['date'] ?? 'Сегодня').toString(),
        (m['asset'] ?? '').toString(),
        (m['error'] ?? '').toString(),
        ((m['loss'] ?? 0) as num).toDouble(),
      );
}

class AssetItem {
  final String ticker;
  final String name;
  final String type;
  final int qty;
  final double buyPrice;
  final double currPrice;
  final double duration;
  AssetItem(this.ticker, this.name, this.type, this.qty, this.buyPrice, this.currPrice, this.duration);
  Map toJson() => {'ticker': ticker, 'name': name, 'type': type, 'qty': qty, 'buyPrice': buyPrice, 'currPrice': currPrice, 'duration': duration};
  static AssetItem fromJson(dynamic m) => AssetItem(
        (m['ticker'] ?? '').toString(),
        (m['name'] ?? '').toString(),
        (m['type'] ?? 'stock').toString(),
        ((m['qty'] ?? 1) as num).toInt(),
        ((m['buyPrice'] ?? 100) as num).toDouble(),
        ((m['currPrice'] ?? 100) as num).toDouble(),
        ((m['duration'] ?? 0) as num).toDouble(),
      );
}

class LessonItem {
  final String id;
  final String lvl;
  final String title;
  final String simple;
  final String pro;
  LessonItem(this.id, this.lvl, this.title, this.simple, this.pro);
}

class AppState extends ChangeNotifier {
  bool isProMode = false;
  int themeIndex = 0;
  double cbRate = 21.0;
  double virtualBalance = 100000.0;
  List completedLessons = [];
  List mistakeDiary = [
    MistakeItem('15.11.2026', 'Газпром', 'Покупка под дивиденды без учёта дивгэпа и налога 13%', -4200.0),
  ];
  List portfolio = [
    AssetItem('SU26238', 'ОФЗ 26238', 'bond', 50, 510.0, 502.0, 7.8),
    AssetItem('SBER', 'Сбербанк', 'stock', 100, 240.0, 265.0, 0.0),
    AssetItem('LQDT', 'Фонд Ликвидность', 'etf', 10000, 1.45, 1.58, 0.1),
  ];

  void toggleProMode() {
    isProMode = !isProMode;
    notifyListeners();
  }

  void cycleTheme() {
    themeIndex = (themeIndex + 1) % 3;
    notifyListeners();
  }

  void addMistake(String asset, String error, double loss) {
    mistakeDiary.insert(0, MistakeItem('Сегодня', asset, error, loss));
    notifyListeners();
  }

  void addAsset(String ticker, String name, String type, int qty, double price, double dur) {
    portfolio.add(AssetItem(ticker, name, type, qty, price, price, dur));
    notifyListeners();
  }

  void completeLesson(String id) {
    if (!completedLessons.contains(id)) {
      completedLessons.add(id);
      notifyListeners();
    }
  }

  String exportBackupJson() => jsonEncode({
        'isProMode': isProMode,
        'virtualBalance': virtualBalance,
        'cbRate': cbRate,
        'completedLessons': completedLessons,
        'mistakeDiary': mistakeDiary.map((e) => (e as MistakeItem).toJson()).toList(),
        'portfolio': portfolio.map((e) => (e as AssetItem).toJson()).toList(),
      });

  bool importBackupJson(String jsonStr) {
    try {
      final data = jsonDecode(jsonStr);
      isProMode = data['isProMode'] ?? false;
      virtualBalance = ((data['virtualBalance'] ?? 100000.0) as num).toDouble();
      cbRate = ((data['cbRate'] ?? 21.0) as num).toDouble();
      completedLessons = (data['completedLessons'] as List? ?? []).map((e) => e.toString()).toList();
      mistakeDiary = (data['mistakeDiary'] as List? ?? []).map((e) => MistakeItem.fromJson(e)).toList();
      portfolio = (data['portfolio'] as List? ?? []).map((e) => AssetItem.fromJson(e)).toList();
      notifyListeners();
      return true;
    } catch (_) {
      return false;
    }
  }

  Future sendTelegramBackup(String botToken, String chatId) async {
    if (botToken.isEmpty || chatId.isEmpty) return 'Введите токен и Chat ID';
    try {
      final client = HttpClient();
      final uri = Uri.parse('https://api.telegram.org/bot$botToken/sendMessage');
      final req = await client.postUrl(uri);
      req.headers.set('content-type', 'application/json');
      req.write(jsonEncode({'chat_id': chatId, 'text': 'БЭКАП:\n${exportBackupJson()}'}));
      final res = await req.close();
      return res.statusCode == 200 ? 'Отправлено в Telegram!' : 'Ошибка API: ${res.statusCode}';
    } catch (_) {
      return 'Офлайн: скопируйте JSON вручную';
    }
  }
}

class InvestTrainerApp extends StatefulWidget {
  const InvestTrainerApp({super.key});
  @override
  State createState() => _InvestTrainerAppState();
}

class _InvestTrainerAppState extends State {
  final AppState _appState = AppState();
  int _tabIndex = 0;

  @override
  void initState() {
    super.initState();
    _appState.addListener(() => setState(() {}));
  }

  ThemeData _buildTheme() {
    if (_appState.themeIndex == 1) return ThemeData.light(useMaterial3: true);
    if (_appState.themeIndex == 2) return ThemeData.dark(useMaterial3: true).copyWith(scaffoldBackgroundColor: Colors.black);
    return ThemeData.dark(useMaterial3: true);
  }

  void _showGlossary(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (_) => ListView(
        padding: const EdgeInsets.all(16),
        children: const [
          Text('📖 Словарь терминов', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          Divider(),
          ListTile(title: Text('НКД'), subtitle: Text('Накопленный купонный доход за дни владения облигацией.')),
          ListTile(title: Text('Дюрация'), subtitle: Text('Чувствительность цены облигации к изменению ставки ЦБ.')),
          ListTile(title: Text('Оферта'), subtitle: Text('Дата, когда эмитент может сбросить купон до 0.01%.')),
          ListTile(title: Text('Дивгэп'), subtitle: Text('Падение акции утром после отсечки на размер дивиденда.')),
          ListTile(title: Text('ГО'), subtitle: Text('Гарантийное обеспечение (залог) по фьючерсу.')),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screens = [
      AcademyScreen(state: _appState),
      SimulatorScreen(state: _appState),
      PortfolioScreen(state: _appState),
      RadarScreen(state: _appState),
    ];
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Инвест-Тренажер',
      theme: _buildTheme(),
      home: Builder(
        builder: (ctx) => Scaffold(
          appBar: AppBar(
            title: Text(_appState.isProMode ? 'PRO Терминал' : 'Инвест-Тренажер'),
            actions: [
              TextButton.icon(
                onPressed: _appState.toggleProMode,
                icon: Icon(_appState.isProMode ? Icons.bolt : Icons.school, color: Colors.amber),
                label: Text(_appState.isProMode ? 'ПРОФИ' : 'НОВИЧОК'),
              ),
              IconButton(onPressed: () => _showGlossary(ctx), icon: const Icon(Icons.help_outline)),
              IconButton(onPressed: _appState.cycleTheme, icon: const Icon(Icons.palette_outlined)),
            ],
          ),
          body: screens[_tabIndex],
          bottomNavigationBar: NavigationBar(
            selectedIndex: _tabIndex,
            onDestinationSelected: (i) => setState(() => _tabIndex = i),
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
}

class AcademyScreen extends StatefulWidget {
  final AppState state;
  const AcademyScreen({super.key, required this.state});
  @override
  State createState() => _AcademyScreenState();
}

class _AcademyScreenState extends State {
  double _sliderDays = 45;
  double _sliderDuration = 5.0;
  final List _proFilters = [false, false, false, false];
  AppState get _st => (widget as AcademyScreen).state;

  final List _modules = [
    LessonItem('m1', 'Ступень 1', 'ОФЗ, купоны и ловушка НКД', 'Если продать облигацию раньше купона, покупатель вернёт накопленные копейки (НКД).', 'НКД = (Номинал * Купон / 365) * Дни. Учитывайте НДФЛ 13%.'),
    LessonItem('m2', 'Ступень 2', 'Дюрация и Оферта', 'Дюрация показывает, на сколько % упадёт бумага при росте ставки ЦБ на 1%.', 'Модифицированная дюрация: dP = -D * dr. Не пропускайте пут-оферту!'),
    LessonItem('m3', 'Ступень 3', 'Акции, Дивгэпы и БПИФ', 'Утром после отсечки акция падает на размер дивиденда.', 'Дивгэп равен Дивиденд * 0.87. В БПИФ учитывайте скрытую комиссию TER.'),
    LessonItem('m4', 'Ступень 4', 'Фьючерсы и ГО', 'Замораживается только 15% залога (ГО), но убыток списывают каждый вечер!', 'При нехватке кэша под вариационную маржу в клиринг наступает Margin Call.'),
    LessonItem('m5', 'Ступень 5', 'Опционы и Шорты', 'В шорте убыток не ограничен. В купленном опционе риск ограничен ценой страховки.', 'Покупка Call/Put ограничивает риск премией, но Тэта-распад играет против вас.'),
  ];

  @override
  Widget build(BuildContext context) {
    final isPro = _st.isProMode;
    final nkd = (1000 * 0.12 / 365 * _sliderDays);
    final bondDrop = -(_sliderDuration * 2.0);

    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(isPro ? '🧮 Калькулятор НКД и Дюрации' : '🎛 Потрогай руками: НКД и Ставка ЦБ', style: const TextStyle(fontWeight: FontWeight.bold)),
                Text('Дней с купона: ${_sliderDays.toInt()} -> НКД: ${nkd.toStringAsFixed(2)} ₽'),
                Slider(value: _sliderDays, min: 0, max: 182, onChanged: (v) => setState(() => _sliderDays = v)),
                Text('Дюрация: ${_sliderDuration.toStringAsFixed(1)} лет (при росте ставки +2%) -> Цена: ${bondDrop.toStringAsFixed(1)}%'),
                Slider(value: _sliderDuration, min: 1, max: 10, onChanged: (v) => setState(() => _sliderDuration = v)),
              ],
            ),
          ),
        ),
        ..._modules.map((item) {
          final m = item as LessonItem;
          final done = _st.completedLessons.contains(m.id);
          return Card(
            child: ListTile(
              leading: Icon(done ? Icons.check_circle : Icons.school, color: done ? Colors.green : Colors.blueAccent),
              title: Text('${m.lvl}: ${m.title}', style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text(isPro ? m.pro : m.simple),
              trailing: ElevatedButton(onPressed: () => _st.completeLesson(m.id), child: Text(done ? 'Сдано' : 'Понял')),
            ),
          );
        }),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('🛡 4 Фильтра Профи перед сделкой', style: TextStyle(fontWeight: FontWeight.bold)),
                CheckboxListTile(value: _proFilters[0] as bool, onChanged: (v) => setState(() => _proFilters[0] = v ?? false), title: const Text('1. Понятен источник прибыли')),
                CheckboxListTile(value: _proFilters[1] as bool, onChanged: (v) => setState(() => _proFilters[1] = v ?? false), title: const Text('2. Проверена оферта и долг')),
                CheckboxListTile(value: _proFilters[2] as bool, onChanged: (v) => setState(() => _proFilters[2] = v ?? false), title: const Text('3. Посчитан безубыток с комиссией')),
                CheckboxListTile(value: _proFilters[3] as bool, onChanged: (v) => setState(() => _proFilters[3] = v ?? false), title: const Text('4. Известен план выхода (5 сигналов)')),
              ],
            ),
          ),
        ),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('📓 Дневник граблей', style: TextStyle(fontWeight: FontWeight.bold)),
                ..._st.mistakeDiary.map((item) {
                  final e = item as MistakeItem;
                  return ListTile(
                    dense: true,
                    leading: const Icon(Icons.warning_amber, color: Colors.orange),
                    title: Text('${e.asset}: ${e.error}'),
                    subtitle: Text('${e.date} | Убыток: ${e.loss} ₽'),
                  );
                }),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class SimulatorScreen extends StatefulWidget {
  final AppState state;
  const SimulatorScreen({super.key, required this.state});
  @override
  State createState() => _SimulatorScreenState();
}

class _SimulatorScreenState extends State {
  String _scenario = 'Кризис 2008 (Ипотечный обвал)';
  List _prices = [100.0, 102.0, 101.5, 104.0, 103.0];
  double? _entryPrice;
  int _qty = 0;
  Timer? _timer;
  bool _isRunning = false;
  String _newsBanner = 'Рынок спокоен. Нажмите Таймлапс или Шаг +1 день.';
  String _expectationVsReality = 'Ожидание: Рост прибыли +15% | Реальность: ждём отчёт';

  final Map _crisisPresets = {
    'Кризис 2008 (Ипотечный обвал)': [100.0, 105.0, 108.0, 98.0, 85.0, 72.0, 60.0, 65.0, 78.0, 92.0],
    'Пандемия 2020 (Локдаун и V-отскок)': [100.0, 103.0, 91.0, 75.0, 68.0, 82.0, 96.0, 112.0, 120.0, 128.0],
    'Ставка ЦБ 21% (Облигационный шторм)': [100.0, 96.0, 92.0, 88.0, 83.0, 81.0, 84.0, 87.0, 91.0, 95.0],
  };

  AppState get _appState => (widget as SimulatorScreen).state;

  void _nextStep() {
    setState(() {
      final preset = _crisisPresets[_scenario] as List;
      final idx = _prices.length % preset.length;
      final noise = (Random().nextDouble() - 0.48) * 3.0;
      final baseVal = (preset[idx] as num).toDouble();
      final nextP = (baseVal + noise).clamp(20.0, 250.0);
      final prevP = (_prices.last as num).toDouble();
      _prices.add(nextP);

      if (_prices.length % 4 == 0) {
        _pauseTimelapse();
        _newsBanner = '⚡ АВТО-ПАУЗА: Срочная новость ЦБ / Отчёт эмитента!';
        _expectationVsReality = (nextP - prevP).isNegative
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
    final currPrice = (_prices.last as num).toDouble();
    const brokerFee = 0.003;
    final breakEven = _entryPrice == null ? null : _entryPrice! * (1 + brokerFee * 2 + 0.002);
    final rawPnl = _entryPrice == null ? 0.0 : (currPrice - _entryPrice!) * _qty;
    final tax = rawPnl.isNegative ? 0.0 : rawPnl * 0.13;
    final netPnl = rawPnl - tax - ((_entryPrice ?? 0) * _qty * brokerFee);

    int redSignals = 0;
    final baseEntry = _entryPrice ?? currPrice;
    if ((currPrice - baseEntry * 0.92).isNegative) redSignals++;
    if (_expectationVsReality.contains('Негатив')) redSignals++;
    if ((baseEntry * 1.20 - currPrice).isNegative) redSignals++;

    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        DropdownButtonFormField(
          initialValue: _scenario,
          decoration: const InputDecoration(labelText: 'Исторический сценарий', border: OutlineInputBorder()),
          items: _crisisPresets.keys.map((k) => DropdownMenuItem(value: k.toString(), child: Text(k.toString()))).toList(),
          onChanged: (v) {
            if (v != null) {
              _pauseTimelapse();
              setState(() {
                _scenario = v.toString();
                _prices = [100.0, 101.0];
                _entryPrice = null;
                _qty = 0;
              });
            }
          },
        ),
        const SizedBox(height: 8),
        Card(
          color: Colors.amber.withValues(alpha: 0.15),
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_newsBanner, style: const TextStyle(fontWeight: FontWeight.bold)),
                Text('🔍 Рентген: $_expectationVsReality', style: const TextStyle(fontSize: 13)),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          height: 150,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade700), borderRadius: BorderRadius.circular(8)),
          child: CustomPaint(painter: _ChartPainter(_prices, breakEven), size: Size.infinite),
        ),
        const SizedBox(height: 8),
        Text('Цена: ${currPrice.toStringAsFixed(2)} ₽  ${breakEven != null ? "| Безубыток: ${breakEven.toStringAsFixed(2)} ₽" : ""}', style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: [
            ElevatedButton.icon(onPressed: _toggleTimelapse, icon: Icon(_isRunning ? Icons.pause : Icons.play_arrow), label: Text(_isRunning ? 'Пауза' : 'Таймлапс')),
            OutlinedButton(onPressed: _nextStep, child: const Text('Шаг +1 день')),
            ElevatedButton(
              onPressed: () => setState(() {
                _entryPrice = currPrice;
                _qty = 100;
              }),
              child: const Text('Купить 100 шт'),
            ),
            ElevatedButton(
              onPressed: _qty == 0
                  ? null
                  : () {
                      if (netPnl.isNegative) _appState.addMistake(_scenario, 'Продажа в минус на панике', netPnl);
                      setState(() {
                        _appState.virtualBalance += netPnl;
                        _entryPrice = null;
                        _qty = 0;
                      });
                    },
              child: const Text('Продать'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Card(
          child: ListTile(
            leading: Icon(Icons.circle, color: redSignals == 0 ? Colors.green : (redSignals == 1 ? Colors.amber : Colors.red)),
            title: Text('Чистый итог (с ком. и НДФЛ): ${netPnl.toStringAsFixed(1)} ₽'),
            subtitle: Text(redSignals == 0 ? 'Светофор ЗЕЛЕНЫЙ: Держим' : (redSignals == 1 ? 'ЖЕЛТЫЙ: Внимание к стопу' : 'КРАСНЫЙ: Сигнал на выход!')),
          ),
        ),
      ],
    );
  }
}

class _ChartPainter extends CustomPainter {
  final List prices;
  final double? breakEven;
  _ChartPainter(this.prices, this.breakEven);

  @override
  void paint(Canvas canvas, Size size) {
    if (prices.length == 1 || prices.isEmpty) return;
    final doubleList = prices.map((e) => (e as num).toDouble()).toList();
    final minP = doubleList.reduce(min) - 5.0;
    final maxP = doubleList.reduce(max) + 5.0;
    final paintLine = Paint()
      ..color = Colors.lightBlueAccent
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke;

    final path = Path();
    for (int i = 0; i != doubleList.length; i++) {
      final x = i * (size.width / (doubleList.length - 1));
      final y = size.height - ((doubleList[i] - minP) / (maxP - minP)) * size.height;
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    canvas.drawPath(path, paintLine);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class PortfolioScreen extends StatefulWidget {
  final AppState state;
  const PortfolioScreen({super.key, required this.state});
  @override
  State createState() => _PortfolioScreenState();
}

class _PortfolioScreenState extends State {
  double _stressRateDelta = 0.0;
  double _cashTopUp = 30000.0;
  final _tickerCtrl = TextEditingController(text: 'LKOH');
  AppState get _st => (widget as PortfolioScreen).state;

  @override
  Widget build(BuildContext context) {
    final items = _st.portfolio;
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
    final stockShareAfter = newTotal == 0 ? 0.0 : (stocksVal / newTotal * 100);

    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        Wrap(
          spacing: 6,
          children: [
            ElevatedButton(onPressed: () => _st.addAsset(_tickerCtrl.text, 'Актив ${_tickerCtrl.text}', 'stock', 10, 250.0, 0.0), child: const Text('+ Скриншот / Файл / API / Вручную')),
          ],
        ),
        const SizedBox(height: 8),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('🩺 Стресс-тест ставки ЦБ (${_stressRateDelta.toStringAsFixed(1)}%)', style: const TextStyle(fontWeight: FontWeight.bold)),
                Slider(value: _stressRateDelta, min: -5.0, max: 5.0, onChanged: (v) => setState(() => _stressRateDelta = v)),
                Text('Портфель сейчас: ${totalVal.toStringAsFixed(0)} ₽ -> После шока: ${stressedVal.toStringAsFixed(0)} ₽'),
              ],
            ),
          ),
        ),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('⚖️ Ребалансировка без налогов (До / После)', style: TextStyle(fontWeight: FontWeight.bold)),
                Slider(value: _cashTopUp, min: 5000, max: 150000, onChanged: (v) => setState(() => _cashTopUp = v)),
                Text('ДО: Акции ${stockShareBefore.toStringAsFixed(1)}% | ПОСЛЕ пополнения ${_cashTopUp.toStringAsFixed(0)} ₽ в бонды: Акции ${stockShareAfter.toStringAsFixed(1)}%'),
              ],
            ),
          ),
        ),
        ...items.map((raw) {
          final a = raw as AssetItem;
          final pnl = (a.currPrice - a.buyPrice) * a.qty;
          return Card(
            child: ListTile(
              title: Text('${a.name} (${a.ticker})'),
              subtitle: Text('${a.qty} шт по ${a.buyPrice} ₽ | Дюрация: ${a.duration}'),
              trailing: Text('${pnl.toStringAsFixed(0)} ₽', style: TextStyle(color: pnl.isNegative ? Colors.redAccent : Colors.green, fontWeight: FontWeight.bold)),
            ),
          );
        }),
      ],
    );
  }
}

class RadarScreen extends StatefulWidget {
  final AppState state;
  const RadarScreen({super.key, required this.state});
  @override
  State createState() => _RadarScreenState();
}

class _RadarScreenState extends State {
  final _newsCtrl = TextEditingController(text: 'ЦБ повысил ключевую ставку, а Сбербанк рекомендовал рекордные дивиденды');
  final _jsonBackupCtrl = TextEditingController();
  String _analysisResult = 'Нажмите кнопку для анализа влияния на ваш портфель.';
  String _backupStatus = '';
  AppState get _appState => (widget as RadarScreen).state;

  void _analyzeNews() {
    final text = _newsCtrl.text.toLowerCase();
    final List findings = [];
    if (text.contains('ставк') || text.contains('цб')) {
      findings.add('🔴 Ставка ЦБ: Риск для длинных ОФЗ 26238 (дюрация 7.8). Плюс для фонда LQDT.');
    }
    if (text.contains('дивиденд') || text.contains('сбер')) {
      findings.add('🟢 Дивиденды: Позитив для SBER, но помните про налог 13% и дивгэп.');
    }
    if (findings.isEmpty) findings.add('🟡 Нейтральный информационный шум.');
    setState(() => _analysisResult = findings.join('\n\n'));
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
                const Text('📡 Двухуровневый Инфо-Радар', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                TextField(controller: _newsCtrl, maxLines: 2, decoration: const InputDecoration(border: OutlineInputBorder())),
                const SizedBox(height: 8),
                ElevatedButton(onPressed: _analyzeNews, child: const Text('Просветить новость рентгеном')),
                const SizedBox(height: 8),
                Text(_analysisResult),
              ],
            ),
          ),
        ),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('☁️ Бэкап базы данных (JSON + Telegram)', style: TextStyle(fontWeight: FontWeight.bold)),
                Row(
                  children: [
                    ElevatedButton(
                      onPressed: () {
                        final j = _appState.exportBackupJson();
                        _jsonBackupCtrl.text = j;
                        Clipboard.setData(ClipboardData(text: j));
                        setState(() => _backupStatus = 'Скопировано!');
                      },
                      child: const Text('Экспорт JSON'),
                    ),
                    const SizedBox(width: 8),
                    OutlinedButton(
                      onPressed: () {
                        final ok = _appState.importBackupJson(_jsonBackupCtrl.text);
                        setState(() => _backupStatus = ok ? 'Восстановлено!' : 'Ошибка JSON');
                      },
                      child: const Text('Импорт JSON'),
                    ),
                  ],
                ),
                TextField(controller: _jsonBackupCtrl, decoration: const InputDecoration(labelText: 'JSON бэкап')),
                if (_backupStatus.isNotEmpty) Text(_backupStatus, style: const TextStyle(color: Colors.green)),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

