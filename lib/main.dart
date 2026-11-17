import 'package:flutter/material.dart';
import 'services/ai_api_service.dart';
import 'services/news_source_service.dart';
import 'screens/news_ai_screen.dart';

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
      home: const MainNavigationScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;

  final List<String> portfolioTickers = ['SBER', 'LKOH', 'OFZ', 'SU26238'];

  @override
  Widget build(BuildContext context) {
    final List<Widget> screens = [
      // 0. Новости и ИИ Анализ
      NewsAiScreen(portfolioTickers: portfolioTickers),
      
      // 1. Академия инвестиций
      Scaffold(
        appBar: AppBar(title: const Text('🎓 Академия инвестиций')),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: const [
            ListTile(
              leading: Icon(Icons.menu_book, color: Colors.green),
            title: Text('Уроки 1-100'),
            subtitle: Text('Полный курс обучения от базы до облигаций ОФЗ и акций'),
            ),
          ],
        ),
      ),

      // 2. Портфель и Калькулятор
      Scaffold(
        appBar: AppBar(title: const Text('💼 Портфель и ОФЗ')),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: const [
            ListTile(
              leading: Icon(Icons.pie_chart, color: Colors.blue),
              title: Text('Мой портфель активов'),
              subtitle: Text('Тикеры: SBER, LKOH, OFZ, SU26238'),
            ),
          ],
        ),
      ),

      // 3. Радар рынка
      Scaffold(
        appBar: AppBar(title: const Text('📡 Радар рынка')),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: const [
            ListTile(
              leading: Icon(Icons.radar, color: Colors.orange),
              title: Text('Рыночные кейсы и симуляции'),
              subtitle: Text('Анализ ситуаций и стресс-тест портфеля'),
            ),
          ],
        ),
      ),
    ];

    return Scaffold(
      body: screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.blue,
        unselectedItemColor: Colors.grey,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.newspaper),
            label: 'Новости',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.school),
            label: 'Академия',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.pie_chart),
            label: 'Портфель',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.radar),
            label: 'Радар',
          ),
        ],
      ),
    );
  }
}








