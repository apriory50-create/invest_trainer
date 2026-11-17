import 'package:flutter/material.dart';
import 'services/bond_calculator.dart';
import 'services/storage_service.dart';
import 'services/ai_risk_analyzer.dart';

void main() {
  runApp(const InvestTrainerApp());
}

class InvestTrainerApp extends StatelessWidget {
  const InvestTrainerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Invest Trainer',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: const MainHomeScreen(),
    );
  }
}

class MainHomeScreen extends StatefulWidget {
  const MainHomeScreen({super.key});

  @override
  State<MainHomeScreen> createState() => _MainHomeScreenState();
}

class _MainHomeScreenState extends State<MainHomeScreen> {
  int _currentIndex = 0;
  bool isProMode = false;
  double balance = 100000.0;
  List<int> completedLessons = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    double loadedBalance = await StorageService.loadBalance();
    List<int> loadedLessons = await StorageService.loadCompletedLessons();
    setState(() {
      balance = loadedBalance;
      completedLessons = loadedLessons;
    });
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> screens = [
      AcademyScreen(
        completedLessons: completedLessons,
        onLessonComplete: (id) async {
          setState(() {
            if (!completedLessons.contains(id)) completedLessons.add(id);
          });
          await StorageService.saveCompletedLessons(completedLessons);
        },
      ),
      SimulatorScreen(isProMode: isProMode),
      PortfolioScreen(balance: balance),
      const NewsAiScreen(),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(isProMode ? 'Invest Trainer [PRO Terminal]' : 'Invest Trainer [Новичок]'),
        actions: [
          IconButton(
            icon: Icon(isProMode ? Icons.school : Icons.rocket_launch),
            tooltip: 'Переключить режим интерфейса',
            onPressed: () {
              setState(() {
                isProMode = !isProMode;
              });
            },
          ),
        ],
      ),
      body: screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.book), label: 'Академия'),
          BottomNavigationBarItem(icon: Icon(Icons.show_chart), label: 'Рынок'),
          BottomNavigationBarItem(icon: Icon(Icons.account_balance_wallet), label: 'Портфель'),
          BottomNavigationBarItem(icon: Icon(Icons.newspaper), label: 'Новости & ИИ'),
        ],
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
      ),
    );
  }
}

class AcademyScreen extends StatelessWidget {
  final List<int> completedLessons;
  final Function(int) onLessonComplete;

  const AcademyScreen({super.key, required this.completedLessons, required this.onLessonComplete});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: 10,
      itemBuilder: (context, index) {
        int lessonId = index + 1;
        bool isDone = completedLessons.contains(lessonId);
        return ListTile(
          leading: Icon(isDone ? Icons.check_circle : Icons.radio_button_unchecked, color: isDone ? Colors.green : Colors.grey),
          title: Text('Урок $lessonId: Основы инвестирования'),
          subtitle: Text(isDone ? 'Пройдено' : 'Нажмите, чтобы изучить концепцию'),
          trailing: ElevatedButton(
            onPressed: () => onLessonComplete(lessonId),
            child: Text(isDone ? 'Повторить' : 'Пройти'),
          ),
        );
      },
    );
  }
}

class SimulatorScreen extends StatelessWidget {
  final bool isProMode;
  const SimulatorScreen({super.key, required this.isProMode});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.trending_up, size: 64, color: Colors.blue),
          const SizedBox(height: 16),
          Text(isProMode ? 'Профессиональный рыночный терминал' : 'Симулятор котировок ОФЗ и Акций', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          const Text('Здесь можно отрабатывать торговые стратегии.'),
        ],
      ),
    );
  }
}

class PortfolioScreen extends StatelessWidget {
  final double balance;
  const PortfolioScreen({super.key, required this.balance});

  @override
  Widget build(BuildContext context) {
    double nkd = BondCalculator.calculateNKD(nominal: 1000, couponRate: 7.0, lastCouponDate: DateTime(2026, 09, 15), settlementDate: DateTime.now());
    double ytm = BondCalculator.calculateYTM(currentPrice: 850, nominal: 1000, couponRate: 7.0, yearsToMaturity: 5.0);

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Свободный баланс:', style: TextStyle(color: Colors.grey)),
                  Text('${balance.toStringAsFixed(2)} ₽', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          const Text('Анализ облигации в портфеле (ОФЗ):', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          ListTile(
            title: const Text('ОФЗ 26238 (Пример расчета)'),
            subtitle: Text('НКД: $nkd ₽ | Доходность YTM: $ytm%'),
            trailing: const Icon(Icons.analytics),
          ),
        ],
      ),
    );
  }
}

class NewsAiScreen extends StatefulWidget {
  const NewsAiScreen({super.key});

  @override
  State<NewsAiScreen> createState() => _NewsAiScreenState();
}

class _NewsAiScreenState extends State<NewsAiScreen> {
  final String sampleNews = 'ЦБ РФ неожиданно повысил ключевую ставку из-за инфляционного давления';
  String selectedTicker = 'OFZ 26238';

  @override
  Widget build(BuildContext context) {
    final analysis = AiRiskAnalyzer.analyzeNews(newsTitle: sampleNews, ticker: selectedTicker);

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Последние новости рынка:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Text(sampleNews, style: const TextStyle(fontSize: 14)),
            ),
          ),
          const SizedBox(height: 20),
          DropdownButton<String>(
            value: selectedTicker,
            items: ['OFZ 26238', 'SBER', 'LKOH'].map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
            onChanged: (val) => setState(() => selectedTicker = val!),
          ),
          const SizedBox(height: 10),
          Card(
            color: analysis.sentiment == 'Негативно' ? Colors.red.shade50 : Colors.blue.shade50,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('ИИ-Вердикт для $selectedTicker: ${analysis.sentiment}', style: TextStyle(fontWeight: FontWeight.bold, color: analysis.sentiment == 'Негативно' ? Colors.red : Colors.blue)),
                  const SizedBox(height: 6),
                  Text('Оценка риска: ${analysis.riskScore}%'),
                  const SizedBox(height: 6),
                  Text(analysis.summary),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}









