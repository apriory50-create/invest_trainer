import 'package:flutter/material.dart';
import 'app_state.dart';

class AcademyScreen extends StatefulWidget {
  final AppState state;
  const AcademyScreen({super.key, required this.state});

  @override
  State<AcademyScreen> createState() => _AcademyScreenState();
}

class _AcademyScreenState extends State<AcademyScreen> {
  double _sliderDays = 45;
  double _sliderDuration = 5.0;
  double _sliderRateChange = 2.0;
  final List<bool> _proFilters = [false, false, false, false];

  final List> _modules = [
    {'id': 'm1', 'lvl': 'Ступень 1', 'title': 'ОФЗ, купоны и ловушка НКД', 'simple': 'Облигация — это расписка. Если продать её раньше купона, покупатель вернёт тебе накопленные за каждый день копейки (НКД).', 'pro': 'НКД = (Номинал × Ставка купона / 365) × Дни от последнего купона. Учитывайте налог 13% на купон и тело при расчёте YTM.'},
    {'id': 'm2', 'lvl': 'Ступень 2', 'title': 'Дюрация и Оферта (Корп. бонды)', 'simple': 'Дюрация показывает, на сколько процентов упадёт цена бумаги, если ЦБ поднимет ставку на 1%. Оферта — день, когда цену могут сбросить до 0.01%.', 'pro': 'Модифицированная дюрация определяет чувствительность цены к Δ ставки ЦБ: ΔP ≈ -D × Δr. Пропуск пут-оферты лишает права досрочного погашения по номиналу.'},
    {'id': 'm3', 'lvl': 'Ступень 3', 'title': 'Акции, Дивгэпы и БПИФ/Паи', 'simple': 'После выплаты дивидендов акция утром падает ровно на сумму выплаты (дивгэп). Паи БПИФ берут скрытую комиссию каждый день.', 'pro': 'Величина дивгэпа обычно равна Дивиденд × 0.87 (за вычетом НДФЛ). В БПИФ контролируйте СЧА и инфраструктурный TER.'},
    {'id': 'm4', 'lvl': 'Ступень 4', 'title': 'Фьючерсы, ГО и Вариационная маржа', 'simple': 'Покупаешь контракт, замораживая только 15% залога (ГО). Но прибыль и убыток списывают со счёта каждый вечер!', 'pro': 'Гарантийное обеспечение (ГО) даёт встроенное плечо. При нехватке свободного кэша под вариационную маржу в клиринг наступает Margin Call.'},
    {'id': 'm5', 'lvl': 'Ступень 5', 'title': 'Опционы, Шорты и Плечи', 'simple': 'Шорт — продажа чужой акции в долг (убыток не ограничен). Купленный опцион — страховка, где риск ограничен только ценой страховки.', 'pro': 'Короткая позиция несёт риск Short Squeeze и платы за перенос. Покупка Call/Put ограничивает риск премией (Тэта-распад против покупателя).'},
  ];

  @override
  Widget build(BuildContext context) {
    final isPro = widget.state.isProMode;
    final nkd = (1000 * 0.12 / 365 * _sliderDays);
    final bondDrop = -(_sliderDuration * _sliderRateChange);

    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(isPro ? '🧮 Калькулятор НКД и ΔP Дюрации' : '🎛 Потрогай руками: НКД и Ставка ЦБ', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 8),
                Text('Дней с прошлого купона: ${_sliderDays.toInt()} ➔ Накопленный НКД: ${nkd.toStringAsFixed(2)} ₽'),
                Slider(value: _sliderDays, min: 0, max: 182, onChanged: (v) => setState(() => _sliderDays = v)),
                Text('Дюрация: ${_sliderDuration.toStringAsFixed(1)} лет | Рост ставки ЦБ: +${_sliderRateChange.toStringAsFixed(1)}%'),
                Slider(value: _sliderDuration, min: 1, max: 10, onChanged: (v) => setState(() => _sliderDuration = v)),
                Text('Итог для цены тела облигации: ${bondDrop.toStringAsFixed(1)}%', style: TextStyle(fontWeight: FontWeight.bold, color: bondDrop < -5 ? Colors.redAccent : Colors.orange)),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        ..._modules.map((m) {
          final done = widget.state.completedLessons.contains(m['id']);
          return Card(
            child: ListTile(
              leading: Icon(done ? Icons.check_circle : Icons.school, color: done ? Colors.green : Colors.blueAccent),
              title: Text('${m['lvl']}: ${m['title']}', style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(isPro ? m['pro']! : m['simple']!),
              ),
              trailing: ElevatedButton(
                onPressed: () => widget.state.completeLesson(m['id']!),
                child: Text(done ? 'Сдано' : 'Понял'),
              ),
            ),
          );
        }),
        const SizedBox(height: 8),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('🛡 4 Фильтра Профи перед сделкой', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                CheckboxListTile(value: _proFilters[0], onChanged: (v) => setState(() => _proFilters[0] = v!), title: const Text('1. Понятен источник прибыли (купон / дивы / переоценка)')),
                CheckboxListTile(value: _proFilters[1], onChanged: (v) => setState(() => _proFilters[1] = v!), title: const Text('2. Проверена дата оферты и долговая нагрузка (NetDebt/EBITDA)')),
                CheckboxListTile(value: _proFilters[2], onChanged: (v) => setState(() => _proFilters[2] = v!), title: const Text('3. Посчитана точка безубыточности с комиссией и НДФЛ 13%')),
                CheckboxListTile(value: _proFilters[3], onChanged: (v) => setState(() => _proFilters[3] = v!), title: const Text('4. Заранее известна точка выхода по 5 сигналам')),
                if (_proFilters.every((e) => e))
                  const Text('✅ Все фильтры пройдены! Сделка разрешена.', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        Card(
          color: Colors.red.withValues(alpha: 0.12),
          child: ListTile(
            leading: const Icon(Icons.local_fire_department, color: Colors.redAccent, size: 32),
            title: const Text('⚔️ БОСС: Ловушка купона 0.01% по оферте', style: TextStyle(fontWeight: FontWeight.bold)),
            subtitle: const Text('Корпоративная облигация даёт 22% годовых, через 5 дней оферта. Твои действия?'),
            trailing: ElevatedButton(
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (_) => AlertDialog(
                    title: const Text('Экзамен Босса'),
                    content: const Text('Если не подать заявление брокеру за 3–5 дней до оферты, эмитент имеет право назначить новый купон 0.01% годовых, и бумага рухнет на 30%. Верный ответ: не покупать или подать на погашение!'),
                    actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Запомнил!'))],
                  ),
                );
              },
              child: const Text('Бой'),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('📓 Дневник граблей (мои ошибки)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                ...widget.state.mistakeDiary.map((e) => ListTile(
                      dense: true,
                      leading: const Icon(Icons.warning_amber, color: Colors.orange),
                      title: Text('${e['asset']}: ${e['error']}'),
                      subtitle: Text('Дата: ${e['date']} | Результат: ${e['loss']} ₽'),
                    )),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
