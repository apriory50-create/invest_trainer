import 'package:flutter/material.dart';
import 'widgets/portfolio_stress_test.dart';

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
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
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

  final List<Widget> _screens = [
    const Center(child: Text('🎓 Академия инвестиций (100 уроков загружено)', style: TextStyle(fontSize: 16))),
    const Center(child: Text('📈 Симулятор торгов и MOEX Radar', style: TextStyle(fontSize: 16))),
    const PortfolioStressTestScreen(),
    const Center(child: Text('🤖 AI Новости и Анализ рисков', style: TextStyle(fontSize: 16))),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Invest Trainer 🚀'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: _screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.blue,
        unselectedItemColor: Colors.grey,
        onTap: (index) => setState(() => _currentIndex = index),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.school), label: 'Академия'),
          BottomNavigationBarItem(icon: Icon(Icons.show_chart), label: 'Симулятор'),
          BottomNavigationBarItem(icon: Icon(Icons.security), label: 'Стресс-тест'),
          BottomNavigationBarItem(icon: Icon(Icons.psychology), label: 'ИИ Анализ'),
        ],
      ),
    );
  }
}










