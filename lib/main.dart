import 'package:flutter/material.dart';
import 'academy_data.dart';

void main() => runApp(const InvestApp());

class InvestApp extends StatefulWidget {
  const InvestApp({super.key});
  @override
  State<InvestApp> createState() => _InvestAppState();
}

class _InvestAppState extends State<InvestApp> {
  int _themeIndex = 0; // 0: Тёмная, 1: Светлая, 2: Изумрудная
  bool _isPro = false;
  int _tab = 0;
  final Set<int> _doneLessons = {};
  double _keyRate = 21.0;
  double _bondPrice = 820.0;
  double _coupon = 120.0;
  double _crashPercent = 0.0;

  ThemeData _buildTheme() {
    if (_themeIndex == 1) {
      return ThemeData.light(useMaterial3: true).copyWith(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blueAccent),
      );
    }
    final bg = _themeIndex == 2 ? const Color(0xFF071E18) : const Color(0xFF0F172A);
    final card = _themeIndex == 2 ? const Color(0xFF0E2F26) : const Color(0xFF1E293B);
    final seed = _themeIndex == 2 ? Colors.tealAccent : Colors.indigoAccent;
    return ThemeData.dark(useMaterial3: true).copyWith(
      scaffoldBackgroundColor: bg,
      cardTheme: CardThemeData(color: card),
      colorScheme: ColorScheme.fromSeed(seedColor: seed, brightness: Brightness.dark),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pages = [_buildAcademy(), _buildRadar(), _buildSimulator(), _buildPortfolio()];
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Invest Trainer',
      theme: _buildTheme(),
      home: Scaffold(
        appBar: AppBar(
          title: Text(_isPro ? 'INVEST PRO' : 'Инвестор с нуля'),
          actions: [
            Row(
              children: [
                Text(_isPro ? 'ПРОФИ' : 'НОВИЧОК', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                Switch(value: _isPro, onChanged: (v) => setState(() => _isPro = v)),
              ],
            ),
            IconButton(
              icon: const Icon(Icons.palette_outlined),
              onPressed: () => setState(() => _themeIndex = (_themeIndex + 1) % 3),
            ),
          ],
        ),
        body: pages[_tab],
        bottomNavigationBar: NavigationBar(
          selectedIndex: _tab,
          onDestinationSelected: (i) => setState(() => _tab = i),
          destinations: const [
            NavigationDestination(icon: Icon(Icons.school_outlined), label: 'Академия'),
            NavigationDestination(icon: Icon(Icons.radar), label: 'MOEX Радар'),
            NavigationDestination(icon: Icon(Icons.calculate_outlined), label: 'Тренажер'),
            NavigationDestination(icon: Icon(Icons.pie_chart_outline), label: 'Портфель'),
          ],
        ),
      ),
    );
  }

  Widget _buildAcademy() {
    final progress = academyLessons.isEmpty ? 0.0 : _doneLessons.length / academyLessons.length;
    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Пройдено уроков: ${_doneLessons.length} из ${academyLessons.length}',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 8),
                LinearProgressIndicator(value: progress, minHeight: 8, borderRadius: BorderRadius.circular(4)),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        ...academyLessons.map((lesson) {
          final isDone = _doneLessons.contains(lesson.id);
          return Card(
            child: ExpansionTile(
              leading: Icon(
                isDone ? Icons.check_circle : Icons.play_circle_outline,
                color: isDone ? Colors.greenAccent : Colors.amberAccent,
              ),
              title: Text(lesson.title, style: const TextStyle(fontWeight: FontWeight.w600)),
              subtitle: Text(lesson.category, style: const TextStyle(fontSize: 12)),
              childrenPadding: const EdgeInsets.all(14),
              children: [
                Text(_isPro ? lesson.proText : lesson.simpleText, style: const TextStyle(fontSize: 15, height: 1.4)),
                const Divider(height: 24),
                Text('Проверка: ${lesson.question}', style: const TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                ...List.generate(lesson.options.length, (idx) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(42), alignment: Alignment.centerLeft),
                      onPressed: () {
                        final ok = idx == lesson.correctIndex;
                        if (ok) setState(() => _doneLessons.add(lesson.id));
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(ok ? 'Верно! Урок засчитан.' : 'Попробуй еще раз — перечитай подсказку выше.'),
                            backgroundColor: ok ? Colors.green.shade700 : Colors.red.shade700,
                            duration: const Duration(seconds: 2),
                          ),
                        );
                      },
                      child: Text(lesson.options[idx]),
                    ),
                  );
                }),
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _buildRadar() {
    final items = [
      ('SBER', 'Сбербанк', 'Акция', '285 ₽', '+1.4%', 'Финансовый гигант с высокими дивидендами'),
      ('LKOH', 'Лукойл', 'Акция', '7150 ₽', '+0.8%', 'Экспортер нефти, выигрывает от слабого рубля'),
      ('SU26238', 'ОФЗ 26238', 'Облигация', '520 ₽', '-0.3%', 'Длинная госбумага для фиксации ставок на годы'),
      ('SU29025', 'ОФЗ-ПК 29025', 'Флоатер', '985 ₽', '+0.1%', 'Купон плывет за ставкой ЦБ, защита от шторма'),
      ('LQDT', 'Фонд Ликвидности', 'БПИФ', '1.54 ₽', '+0.06%', 'Ежедневный доход под ставку ЦБ без просадок'),
    ];
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: items.length,
      itemBuilder: (c, i) {
        final it = items[i];
        return Card(
          child: ListTile(
            title: Text('${it.$2} (${it.$1})', style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text('${it.$3} • ${it.$6}'),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(it.$4, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                Text(it.$5, style: TextStyle(color: it.$5.startsWith('+') ? Colors.greenAccent : Colors.redAccent)),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSimulator() {
    final currentYield = (_coupon / _bondPrice) * 100;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Калькулятор ОФЗ и Ставки ЦБ', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                Text('Ключевая ставка ЦБ: ${_keyRate.toStringAsFixed(1)}%'),
                Slider(value: _keyRate, min: 5, max: 25, onChanged: (v) => setState(() => _keyRate = v)),
                Text('Цена покупки облигации: ${_bondPrice.toStringAsFixed(0)} ₽ (Номинал 1000 ₽)'),
                Slider(value: _bondPrice, min: 500, max: 1100, onChanged: (v) => setState(() => _bondPrice = v)),
                Text('Годовой купон: ${_coupon.toStringAsFixed(0)} ₽'),
                Slider(value: _coupon, min: 50, max: 220, onChanged: (v) => setState(() => _coupon = v)),
                const Divider(),
                Text('Твоя купонная доходность: ${currentYield.toStringAsFixed(2)}% годовых',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.greenAccent)),
                const SizedBox(height: 6),
                Text('При погашении государство вернет 1000 ₽. Твой бонус к телу: ${(1000 - _bondPrice).toStringAsFixed(0)} ₽.'),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPortfolio() {
    const double baseCapital = 100000;
    final stocks = 40000 * (1 - _crashPercent / 100);
    const bonds = 40000.0;
    const cash = 20000.0;
    final total = stocks + bonds + cash;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Стресс-тест портфеля (100 000 ₽)', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                Text('Обвал рынка акций: -${_crashPercent.toStringAsFixed(0)}%'),
                Slider(value: _crashPercent, min: 0, max: 50, onChanged: (v) => setState(() => _crashPercent = v)),
                Text('Итого капитал в шторм: ${total.toStringAsFixed(0)} ₽ из ${baseCapital.toStringAsFixed(0)} ₽',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text(_isPro
                    ? 'Защитная аллокация (60% бонды + кэш) удерживает просадку портфеля в пределах ${(100 - total / baseCapital * 100).toStringAsFixed(1)}% и дает ликвидность для ребалансировки.'
                    : 'Даже если акции упали на ${_crashPercent.toStringAsFixed(0)}%, твои облигации и подушка держат удар! Ты можешь спокойно докупить подешевевшие акции на распродаже.'),
              ],
            ),
          ),
        ),
      ],
    );
  }
}




