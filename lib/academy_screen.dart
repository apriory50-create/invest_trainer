import 'dart:math';
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
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final isPro = widget.state.isProMode;
    final allLessons = <LessonItem>[...academyLessons, ...academyLessonsPart2];
    final filtered = _searchQuery.trim().isEmpty
        ? allLessons
        : allLessons
            .where((l) =>
                l.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                l.category.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                l.simpleText.toLowerCase().contains(_searchQuery.toLowerCase()))
            .toList();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 4),
          child: TextField(
            decoration: const InputDecoration(
              hintText: 'Поиск по 100 урокам (например: ОФЗ, дюрация, ИИС)...',
              prefixIcon: Icon(Icons.search),
              border: OutlineInputBorder(),
              isDense: true,
            ),
            onChanged: (val) => setState(() => _searchQuery = val),
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: filtered.length,
            itemBuilder: (context, index) {
              final lesson = filtered[index];
              final isCompleted =
                  widget.state.completedLessons.contains(lesson.id);

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
                  onTap: () => _openLessonDetail(context, lesson, isCompleted),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  void _openLessonDetail(
    BuildContext context,
    LessonItem lesson,
    bool isCompleted,
  ) {
    final isPro = widget.state.isProMode;
    // Перемешиваем варианты ответов, чтобы правильный ответ не всегда был первым
    final indices = List<int>.generate(lesson.options.length, (i) => i)
      ..shuffle(Random(lesson.id));
    int? selectedShuffledIdx;
    bool answeredCorrectly = isCompleted;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: SizedBox(
                  height: MediaQuery.of(context).size.height * 0.78,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        lesson.category,
                        style:
                            const TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        lesson.title,
                        style: const TextStyle(
                            fontSize: 19, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 12),
                      Expanded(
                        child: SingleChildScrollView(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                isPro ? lesson.proText : lesson.simpleText,
                                style: const TextStyle(
                                    fontSize: 16, height: 1.45),
                              ),
                              const Divider(height: 28),
                              const Text(
                                '📝 Проверочный вопрос:',
                                style: TextStyle(
                                    fontWeight: FontWeight.bold, fontSize: 15),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                lesson.question,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w600),
                              ),
                              const SizedBox(height: 8),
                              ...List.generate(indices.length, (shufIdx) {
                                final origIdx = indices[shufIdx];
                                final isCorrectOption =
                                    origIdx == lesson.correctIndex;
                                final isSelected =
                                    selectedShuffledIdx == shufIdx;

                                Color? tileColor;
                                if (selectedShuffledIdx != null) {
                                  if (isCorrectOption) {
                                    tileColor =
                                        Colors.green.withValues(alpha: 0.18);
                                  } else if (isSelected) {
                                    tileColor =
                                        Colors.red.withValues(alpha: 0.18);
                                  }
                                }

                                return Card(
                                  color: tileColor,
                                  margin: const EdgeInsets.only(bottom: 6),
                                  child: ListTile(
                                    dense: true,
                                    title: Text(lesson.options[origIdx]),
                                    trailing: selectedShuffledIdx == null
                                        ? null
                                        : (isCorrectOption
                                            ? const Icon(Icons.check_circle,
                                                color: Colors.green)
                                            : (isSelected
                                                ? const Icon(Icons.cancel,
                                                    color: Colors.red)
                                                : null)),
                                    onTap: () {
                                      setModalState(() {
                                        selectedShuffledIdx = shufIdx;
                                        if (isCorrectOption) {
                                          answeredCorrectly = true;
                                        }
                                      });
                                    },
                                  ),
                                );
                              }),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: answeredCorrectly
                              ? () {
                                  widget.state.completeLesson(lesson.id);
                                  Navigator.pop(ctx);
                                  ScaffoldMessenger.of(this.context)
                                      .showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                          'Урок пройден! Прогресс сохранён в памяти.'),
                                    ),
                                  );
                                }
                              : null,
                          icon: const Icon(Icons.done_all),
                          label: Text(
                            answeredCorrectly
                                ? (isCompleted
                                    ? 'Пройдено (Закрыть)'
                                    : 'Завершить и сохранить урок')
                                : 'Выберите правильный ответ выше',
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}



