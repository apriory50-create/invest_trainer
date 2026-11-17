import 'package:flutter/material.dart';
import 'app_state.dart';
import 'academy_screen.dart';
import 'simulator_screen.dart';
import 'portfolio_screen.dart';
import 'radar_screen.dart';
import 'screens/news_ai_screen.dart';

void main() {
  runApp(const InvestTrainerApp());
}

class InvestTrainerApp extends StatelessWidget {
  const InvestTrainerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Invest Trainer 🚀',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const MainContainer(),
    );
  }
}

class MainContainer extends StatefulWidget {
  const MainContainer({super.key});

  @override
  State<MainContainer> createState() => _MainContainerState();
}

class _MainContainerState extends State<MainContainer> {
  final AppState _appState = AppState();
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final List<Widget> pages = [
      AcademyScreen(state: _appState),
      SimulatorScreen(state: _appState),
      PortfolioScreen(state: _appState),
      RadarScreen(state: _appState),
      const NewsAiScreen(portfolioTickers: ['SBER', 'LKOH', 'SU26238']),
    ];

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blue.shade100,
        title: const Text('Invest Trainer 🚀'),
        actions: [
          IconButton(
            icon: Icon(_appState.isProMode ? Icons.star : Icons.star_border),
            tooltip: 'Режим Профи',
            onPressed: () {
              setState(() {
                _appState.isProMode = !_appState.isProMode;
              });
            },
          ),
        ],
      ),
      body: pages[_currentIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.school),
            label: 'Академия',
          ),
          NavigationDestination(
            icon: Icon(Icons.show_chart),
            label: 'Симулятор',
          ),
          NavigationDestination(
            icon: Icon(Icons.account_balance_wallet),
            label: 'Портфель',
          ),
          NavigationDestination(
            icon: Icon(Icons.radar),
            label: 'Радар',
          ),
          NavigationDestination(
            icon: Icon(Icons.psychology),
            label: 'ИИ Новости',
          ),
        ],
      ),
    );
  }
}













