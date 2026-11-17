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

  void _showHowToUseDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('📖 Как пользоваться приложением'),
        content: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '1. 🎓 Академия (100 уроков)',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Text(
                'Нажмите на любой урок, прочитайте правило, ответьте на мини-вопрос и нажмите зелёную кнопку «Завершить урок». Звёздочка ⭐ вверху переключает язык между «Новичком» и «Профи».',
              ),
              SizedBox(height: 10),
              Text(
                '2. 📈 Симулятор рынка',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Text(
                'Выберите кризис (2008, 2020 или ставку 21%), нажимайте «Шаг +1 день» или «Таймлапс». Покупайте и продавайте виртуальные лоты — тренируйтесь без риска потерять реальные деньги.',
              ),
              SizedBox(height: 10),
              Text(
                '3. 💼 Портфель и Стресс-тест',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Text(
                'Добавляйте свои акции и ОФЗ. Двигайте ползунок «Ставка ЦБ», чтобы увидеть, как изменится цена портфеля, и используйте расчёт ребалансировки при пополнении.',
              ),
              SizedBox(height: 10),
              Text(
                '4. 📡 Радар и 🧠 ИИ Новости',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Text(
                'В «Радаре» вставьте любую новость из Telegram — приложение покажет её влияние на ваши бумаги. В «ИИ Новостях» фильтруйте события по портфелю.',
              ),
            ],
          ),
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Понятно, поехали!'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _appState,
      builder: (context, _) {
        final List<Widget> pages = [
          AcademyScreen(state: _appState),
          SimulatorScreen(state: _appState),
          PortfolioScreen(state: _appState),
          RadarScreen(state: _appState),
          NewsAiScreen(portfolioTickers: _appState.portfolioTickers),
        ];

        return Scaffold(
          appBar: AppBar(
            backgroundColor: Colors.blue.shade100,
            title: const Text('Invest Trainer 🚀'),
            actions: [
              IconButton(
                icon: const Icon(Icons.help_outline),
                tooltip: 'Как пользоваться',
                onPressed: _showHowToUseDialog,
              ),
              IconButton(
                icon: Icon(_appState.isProMode ? Icons.star : Icons.star_border),
                tooltip: _appState.isProMode ? 'Режим Профи (вкл)' : 'Режим Новичка',
                onPressed: () {
                  _appState.toggleProMode();
                },
              ),
            ],
          ),
          body: IndexedStack(
            index: _currentIndex,
            children: pages,
          ),
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
      },
    );
  }
}













