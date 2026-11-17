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
      debugShowCheckedModeBanner: false,
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
    const AcademyTab(),
    const SimulatorTab(),
    const PortfolioStressTestScreen(portfolioValue: 150000.0),
    const AiAnalysisTab(),
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

// Вкладка Академии
class AcademyTab extends StatelessWidget {
  const AcademyTab({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text('Академия инвестиций', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        const Text('Изучите основы от нуля до профессионального портфеля.', style: TextStyle(color: Colors.grey)),
        const SizedBox(height: 16),
        _buildLessonCard(context, 'Урок 1: Что такое акции и облигации?', 'Основы фондового рынка для новичков.'),
        _buildLessonCard(context, 'Урок 2: Купоны и НКД по ОФЗ', 'Как работают государственные облигации.'),
        _buildLessonCard(context, 'Урок 3: Диверсификация портфеля', 'Почему нельзя хранить все яйца в одной корзине.'),
      ],
    );
  }

  Widget _buildLessonCard(BuildContext context, String title, String subtitle) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: const Icon(Icons.menu_book, color: Colors.blue),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: () {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Открываем: $title')),
          );
        },
      ),
    );
  }
}

// Вкладка Симулятора
class SimulatorTab extends StatelessWidget {
  const SimulatorTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Симулятор торгов и MOEX', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text('Индекс Мосбиржи (IMOEX)', style: TextStyle(color: Colors.grey)),
                  SizedBox(height: 4),
                  Text('2,745.50 ₽  (+1.2%)', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.green)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Вкладка ИИ Анализа
class AiAnalysisTab extends StatelessWidget {
  const AiAnalysisTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('ИИ Анализ новостей и рисков', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          Card(
            color: Colors.blue.shade50,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text('🤖 Рекомендация ИИ-наставника:', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue)),
                  SizedBox(height: 8),
                  Text('Текущая ключевая ставка ЦБ стабильна. Рекомендуется удерживать до 40% портфеля в коротких ОФЗ для защиты капитала.'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}











