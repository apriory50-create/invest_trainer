import 'package:flutter/material.dart';
import 'app_state.dart';
import 'academy_data.dart';
import 'academy_part2.dart';

class AcademyScreen extends StatefulWidget {
  final AppState state;
  const AcademyScreen({super.key, required this.state});

  @override
  State<AcademyScreen> createState() => _AcademyScreenState();
}

class _AcademyScreenState extends State<AcademyScreen> {
  @override
  Widget build(BuildContext context) {
    final isPro = widget.state.isProMode;
    final allLessons = [...academyLessonsPart1, ...academyLessonsPart2];
    final completedCount = widget.state.completedLessons.length;

    return Scaffold(
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            color: Colors.blue.shade50,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Прогресс: $completedCount из ${allLessons.length}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  isPro ? 'Режим: ПРОФИ' : 'Режим: НОВИЧОК',
                  style: TextStyle(
                    color: isPro ? Colors.deepPurple : Colors.blue.shade800,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: allLessons.length,
              itemBuilder: (context, index) {
                final lesson = allLessons[index];
                final isCompleted = widget.state.completedLessons.contains(lesson.id);

                return Card(
                  margin: const EdgeInsets.only(bottom: 10),
                  child: ListTile(
                    leading: Icon(
                      isCompleted ? Icons.check_circle : Icons.school,
                      color: isCompleted ? Colors.green : Colors.blue,
                    ),
                    title: Text(
                      lesson.title,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Text(
                        isPro ? lesson.proText : lesson.simpleText,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      _openLessonDetail(context, lesson, isCompleted);
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _openLessonDetail(BuildContext context, dynamic lesson, bool isCompleted) {
    final isPro = widget.state.isProMode;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) {
        return Container(
          padding: const EdgeInsets.all(20),
          height: MediaQuery.of(context).size.height * 0.75,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                lesson.title,
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: SingleChildScrollView(
                  child: Text(
                    isPro ? lesson.proText : lesson.simpleText,
                    style: const TextStyle(fontSize: 16, height: 1.4),
                  ),
                ),
              ),
              const Divider(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    widget.state.completeLesson(lesson.id.toString());
                    setState(() {});
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Урок пройден! Прогресс сохранен.')),
                    );
                  },
                  icon: Icon(isCompleted ? Icons.check : Icons.done),
                  label: Text(isCompleted ? 'Пройдено (повторить)' : 'Отметить как пройденное'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}



