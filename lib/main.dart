import 'package:flutter/material.dart';
import 'services/ai_api_service.dart';
import 'services/news_source_service.dart';
import 'screens/news_ai_screen.dart';
// Импортируем наши уроки академии
import 'academy_data.dart';
import 'academy_part2.dart';

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

  // Портфель пользователя
  final List<String> portfolioTickers = ['SBER', 'LKOH', 'OFZ', 'SU26238'];

  @override
  Widget build(BuildContext context) {
    // Объединяем все уроки из двух файлов в один список
    final List> allAcademyLessons = [
      ...academyLessons,
      ...academyLessonsPart2,
    ];

    final List<Widget> screens = [
      // 0. Новости и ИИ Анализ
      NewsAiScreen(portfolioTickers: portfolioTickers),
      
      // 1. Академия инвестиций (100 уроков)
      Scaffold(
        appBar: AppBar(title: Text('🎓 Академия (${allAcademyLessons.length} уроков)')),
        body: ListView.builder(
          itemCount: allAcademyLessons.length,
          itemBuilder: (context, index) {
            final lesson = allAcademyLessons[index];
            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.green.shade100,
                  child: Text('${index + 1}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                ),
                title: Text(
                  lesson['title'] ?? 'Урок ${index + 1}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text(
                  lesson['description'] ?? 'Нажмите, чтобы изучить материал',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => LessonDetailScreen(
                        lessonNumber: index + 1,
                        title: lesson['title'] ?? 'Урок ${index + 1}',
                        content: lesson['content'] ?? 'Содержимое урока загружается...',
                      ),
                    ),
                  );
                },
              ),
            );
          },
        ),
      ),

      // 2. Портфель и Калькулятор ОФЗ
      Scaffold(
        appBar: AppBar(title: const Text('💼 Портфель и ОФЗ')),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const Card(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Стоимость портфеля', style: TextStyle(color: Colors.grey)),
                    SizedBox(height: 8),
                    Text('154 320 ₽', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
                    SizedBox(height: 12),
                    Text('Доходность: +12.4% (год)', style: TextStyle(color: Colors.green, fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text('Активы в портфеле:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            ...portfolioTickers.map((ticker) => Card(
              child: ListTile(
                leading: const Icon(Icons.show_chart, color: Colors.blue),
                title: Text(ticker),
                subtitle: const Text('Актив добавлен в систему мониторинга'),
                trailing: const Text('В портфеле', style: TextStyle(color: Colors.grey)),
              ),
            )),
          ],
        ),
      ),

      // 3. Радар рынка и кейсы
      Scaffold(
        appBar: AppBar(title: const Text('📡 Радар рынка')),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: const [
            Card(
              child: ListTile(
                leading: Icon(Icons.radar, color: Colors.orange, size: 36),
                title: Text('Симулятор рыночных событий'),
                subtitle: Text('Анализируйте кейсы, принимайте решения и проверяйте стресс-тест портфеля.'),
              ),
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

// Вспомогательный экран для чтения конкретного урока
class LessonDetailScreen extends StatelessWidget {
  final int lessonNumber;
  final String title;
  final String content;

  const LessonDetailScreen({
    super.key,
    required this.lessonNumber,
    required this.title,
    required this.content,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Урок №$lessonNumber'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 16),
            Text(
              content,
              style: const TextStyle(fontSize: 16, height: 1.5),
            ),
          ],
        ),
      ),
    );
  }
}








