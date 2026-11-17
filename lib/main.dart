import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'services/ai_api_service.dart';
import 'services/news_source_service.dart';
import 'screens/news_ai_screen.dart';
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
  final List portfolioTickers = ['SBER', 'LKOH', 'OFZ', 'SU26238'];
  
  // Множество для хранения пройденных уроков
  final Set<int> _completedLessons = {};

  @override
  void initState() {
    super.initState();
    _loadProgress();
  }

  // Загрузка прогресса из SharedPreferences
  Future<void> _loadProgress() async {
    final prefs = await SharedPreferences.getInstance();
    final completedList = prefs.getStringList('completed_lessons') ?? [];
    setState(() {
      _completedLessons.clear();
      for (var idStr in completedList) {
        final id = int.tryParse(idStr);
        if (id != null) _completedLessons.add(id);
      }
    });
  }

  // Сохранение прогресса
  Future<void> _saveProgress() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      'completed_lessons',
      _completedLessons.map((e) => e.toString()).toList(),
    );
  }

  void _toggleLessonCompleted(int index) {
    setState(() {
      if (_completedLessons.contains(index)) {
        _completedLessons.remove(index);
      } else {
        _completedLessons.add(index);
      }
    });
    _saveProgress();
  }

  @override
  Widget build(BuildContext context) {
    final allAcademyLessons = [];
    allAcademyLessons.addAll(academyLessons);
    allAcademyLessons.addAll(academyLessonsPart2);

    final screens = [
      // 0. Новости и ИИ Анализ
      NewsAiScreen(portfolioTickers: portfolioTickers.cast<String>()),
      
      // 1. Академия инвестиций с прогрессом и квизами
      Scaffold(
        appBar: AppBar(
          title: Text('🎓 Академия (${_completedLessons.length}/${allAcademyLessons.length} изучено)'),
        ),
        body: ListView.builder(
          itemCount: allAcademyLessons.length,
          itemBuilder: (context, index) {
            final lesson = allAcademyLessons[index];
            final isCompleted = _completedLessons.contains(index);
            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              color: isCompleted ? Colors.green.shade50 : Colors.white,
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: isCompleted ? Colors.green : Colors.grey.shade200,
                  child: Text(
                    '${index + 1}',
                    style: TextStyle(
                      color: isCompleted ? Colors.white : Colors.black,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
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
                trailing: Icon(
                  isCompleted ? Icons.check_circle : Icons.arrow_forward_ios,
                  color: isCompleted ? Colors.green : Colors.grey,
                  size: 20,
                ),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => LessonDetailScreen(
                        lessonNumber: index + 1,
                        title: lesson['title'] ?? 'Урок ${index + 1}',
                        content: lesson['content'] ?? 'Содержимое урока...',
                        isCompleted: isCompleted,
                        onToggleComplete: () {
                          _toggleLessonCompleted(index);
                        },
                      ),
                    ),
                  );
                },
              ),
            );
          },
        ),
      ),

      // 2. Портфель и Калькулятор ОФЗ (Расширенный симулятор)
      const OfzCalculatorScreen(),

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
            label: 'Портфель/ОФЗ',
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

// Экран урока с квизом / проверкой знаний
class LessonDetailScreen extends StatefulWidget {
  final int lessonNumber;
  final String title;
  final String content;
  final bool isCompleted;
  final VoidCallback onToggleComplete;

  const LessonDetailScreen({
    super.key,
    required this.lessonNumber,
    required this.title,
    required this.content,
    required this.isCompleted,
    required this.onToggleComplete,
  });

  @override
  State<LessonDetailScreen> createState() => _LessonDetailScreenState();
}

class _LessonDetailScreenState extends State<LessonDetailScreen> {
  int? _selectedAnswer;
  bool _answered = false;

  @override
  Widget build(BuildContext context) {
    // Простой демонстрационный мини-тест для урока
    final bool hasQuiz = widget.lessonNumber % 5 == 0; // Каждый 5-й урок с квизом

    return Scaffold(
      appBar: AppBar(
        title: Text('Урок №${widget.lessonNumber}'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          Text(
            widget.title,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 16),
          Text(
            widget.content,
            style: const TextStyle(fontSize: 16, height: 1.5),
          ),
          const SizedBox(height: 24),

          // Блок квиза (если предусмотрен)
          if (hasQuiz) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '🧠 Проверка знаний (Квиз)',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  const Text('Какой главный вывод можно сделать из этого урока?'),
                  const SizedBox(height: 12),
                  RadioListTile<int>(
                    title: const Text('Диверсификация и риск-менеджмент превыше всего'),
                    value: 0,
                    groupValue: _selectedAnswer,
                    onChanged: _answered ? null : (val) => setState(() => _selectedAnswer = val),
                  ),
                  RadioListTile<int>(
                    title: const Text('Нужно вкладывать всё в один актив'),
                    value: 1,
                    groupValue: _selectedAnswer,
                    onChanged: _answered ? null : (val) => setState(() => _selectedAnswer = val),
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: (_selectedAnswer == null || _answered)
                        ? null
                        : () {
                            setState(() {
                              _answered = true;
                            });
                          },
                    child: const Text('Ответить'),
                  ),
                  if (_answered) ...[
                    const SizedBox(height: 8),
                    Text(
                      _selectedAnswer == 0
                          ? '✅ Верно! Отличный результат.'
                          : '❌ Неверно. Правильный вариант: первый.',
                      style: TextStyle(
                        color: _selectedAnswer == 0 ? Colors.green : Colors.red,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],

          // Кнопка отметки о прохождении
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: widget.isCompleted ? Colors.green : Colors.blue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              onPressed: () {
                widget.onToggleComplete();
                Navigator.pop(context);
              },
              icon: Icon(widget.isCompleted ? Icons.check : Icons.school),
              label: Text(
                widget.isCompleted ? 'Пройдено (Нажмите чтобы отменить)' : 'Завершить урок',
                style: const TextStyle(fontSize: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Расширенный калькулятор ОФЗ и портфеля
class OfzCalculatorScreen extends StatefulWidget {
  const OfzCalculatorScreen({super.key});

  @override
  State<OfzCalculatorScreen> createState() => _OfzCalculatorScreenState();
}

class _OfzCalculatorScreenState extends State<OfzCalculatorScreen> {
  double _nominal = 1000.0;
  double _coupon = 75.0;
  int _years = 3;

  @override
  Widget build(BuildContext context) {
    // Простой расчет доходности ОФЗ
    double totalCoupon = _coupon * _years;
    double totalIncome = _nominal + totalCoupon;
    double annualYield = ((_coupon / _nominal) * 100);

    return Scaffold(
      appBar: AppBar(title: const Text('💼 Портфель и Калькулятор ОФЗ')),
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
          const Text('🧮 Симулятор и Калькулятор ОФЗ', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Номинал облигации: ${_nominal.toStringAsFixed(0)} ₽'),
                  Slider(
                    min: 500,
                    max: 10000,
                    divisions: 19,
                    value: _nominal,
                    onChanged: (v) => setState(() => _nominal = v),
                  ),
                  Text('Годовой купон: ${_coupon.toStringAsFixed(0)} ₽ (${annualYield.toStringAsFixed(1)}%)'),
                  Slider(
                    min: 10,
                    max: 200,
                    divisions: 19,
                    value: _coupon,
                    onChanged: (v) => setState(() => _coupon = v),
                  ),
                  Text('Срок инвестирования: $_years лет'),
                  Slider(
                    min: 1,
                    max: 10,
                    divisions: 9,
                    value: _years.toDouble(),
                    onChanged: (v) => setState(() => _years = v.toInt()),
                  ),
                  const Divider(),
                  const SizedBox(height: 8),
                  Text('Итоговый капитал через $_years лет: ${totalIncome.toStringAsFixed(0)} ₽',
                      style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue)),
                  Text('Суммарные выплаты по купонам: +${totalCoupon.toStringAsFixed(0)} ₽',
                      style: const TextStyle(color: Colors.green)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}









