import 'package:flutter/material.dart';
import 'app_state.dart';
import 'academy_screen.dart';
import 'simulator_screen.dart';
import 'portfolio_screen.dart';
import 'radar_screen.dart';

void main() {
  runApp(const InvestTrainerApp());
}

class InvestTrainerApp extends StatefulWidget {
  const InvestTrainerApp({super.key});

  @override
  State<InvestTrainerApp> createState() => _InvestTrainerAppState();
}

class _InvestTrainerAppState extends State<InvestTrainerApp> {
  final AppState _appState = AppState();
  int _tabIndex = 0;

  @override
  void initState() {
    super.initState();
    _appState.addListener(() => setState(() {}));
  }

  ThemeData _buildTheme() {
    if (_appState.themeIndex == 1) {
      return ThemeData.light(useMaterial3: true);
    } else if (_appState.themeIndex == 2) {
      return ThemeData.dark(useMaterial3: true).copyWith(scaffoldBackgroundColor: Colors.black);
    }
    return ThemeData.dark(useMaterial3: true);
  }

  void _showGlossary(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (_) => ListView(
        padding: const EdgeInsets.all(16),
        children: const [
          Text('📖 Мгновенный словарь терминов', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          Divider(),
          ListTile(title: Text('НКД (Накопленный купонный доход)'), subtitle: Text('Часть купона, которую покупатель облигации возмещает продавцу за дни владения.')),
          ListTile(title: Text('Дюрация'), subtitle: Text('Чувствительность цены облигации к изменению ставки ЦБ (1 год дюрации ≈ 1% изменения цены на 1% ставки).')),
          ListTile(title: Text('Оферта'), subtitle: Text('Дата, когда эмитент может изменить процент купона. Опасно пропускать!')),
          ListTile(title: Text('Дивгэп'), subtitle: Text('Падение цены акции в день отсечки примерно на размер выплачиваемого дивиденда.')),
          ListTile(title: Text('ГО (Гарантийное обеспечение)'), subtitle: Text('Залог (обычно 10–20%) для покупки фьючерса на срочном рынке.')),
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
                icon: Icon(_appState.isProMode ? Icons.bolt : Icons.ChildCare, color: Colors.amber),
                label: Text(_appState.isProMode ? 'ПРОФИ' : 'НОВИЧОК'),
              ),
              IconButton(
                onPressed: () => _showGlossary(ctx),
                icon: const Icon(Icons.help_outline),
                tooltip: 'Словарь терминов',
              ),
              IconButton(
                onPressed: _appState.cycleTheme,
                icon: const Icon(Icons.palette_outlined),
                tooltip: 'Сменить тему',
              ),
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
