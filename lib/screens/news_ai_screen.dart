import 'package:flutter/material.dart';
import '../models/news_item.dart';
import '../services/ai_api_service.dart';
import '../services/ai_risk_analyzer.dart';
import '../services/news_filter_service.dart';
import '../services/news_source_service.dart';

class NewsAiScreen extends StatefulWidget {
  final List<String> portfolioTickers;

  const NewsAiScreen({super.key, required this.portfolioTickers});

  @override
  State<NewsAiScreen> createState() => _NewsAiScreenState();
}

class _NewsAiScreenState extends State<NewsAiScreen> {
  List<NewsItem> _newsList = NewsItem.getInitialNews();
  bool _onlyPortfolio = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadCustomSourcesNews();
  }

  Future<void> _loadCustomSourcesNews() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    final sources = await NewsSourceService.getSources();
    final fetched = <NewsItem>[...NewsItem.getInitialNews()];

    for (final source in sources) {
      final sourceNews = await NewsSourceService.fetchNewsFromSource(source);
      fetched.addAll(sourceNews);
    }

    if (!mounted) return;
    setState(() {
      _newsList = fetched;
      _isLoading = false;
    });
  }

  void _addRandomNews() {
    final randNews = NewsFilterService.generateRandomMarketNews();
    setState(() {
      _newsList.insert(0, randNews);
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Добавлен учебный новостной сценарий!')),
    );
  }

  void _showAiAnalysis(NewsItem news) async {
    final primaryTicker = news.affectedTickers.isNotEmpty
        ? news.affectedTickers.first
        : 'MOEX';
    final localResult = AiRiskAnalyzer.analyzeNews(
      newsTitle: '${news.title} ${news.summary}',
      ticker: primaryTicker,
    );

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    final prompt =
        'Проанализируй новость для моего инвест-портфеля (${widget.portfolioTickers.join(", ")}). Сентимент, риски, влияние.\nЗаголовок: ${news.title}\nТекст: ${news.content}';
    final analysisResult = await AiApiService.analyzeText(prompt);

    if (!mounted) return;
    Navigator.pop(context);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Разбор: ${news.title}', style: const TextStyle(fontSize: 16)),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.blue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '⚡ Офлайн-оценка ($primaryTicker): ${localResult.sentiment} (Риск: ${localResult.riskScore.toStringAsFixed(0)}/100)\n${localResult.summary}',
                  style: const TextStyle(fontSize: 13),
                ),
              ),
              const Divider(height: 20),
              const Text(
                '🤖 Ответ внешнего ИИ API:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),
              Text(analysisResult),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Закрыть'),
          ),
        ],
      ),
    );
  }

  Future<void> _openSettingsDialog() async {
    final currentKey = await AiApiService.getApiKey();
    final currentUrl = await AiApiService.getApiUrl();
    bool rememberKey = await AiApiService.getRememberKeyPreference();

    final keyController = TextEditingController(text: currentKey);
    final urlController = TextEditingController(text: currentUrl);
    final channelNameController = TextEditingController();
    final channelUrlController = TextEditingController();

    if (!mounted) return;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Настройки ИИ и RSS-каналов'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'API-ключ ИИ (OpenAI-совместимый):',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                TextField(
                  controller: keyController,
                  obscureText: true,
                  decoration: const InputDecoration(hintText: 'sk-...'),
                ),
                CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text(
                    'Сохранить ключ на устройстве (иначе хранится только до закрытия приложения)',
                    style: TextStyle(fontSize: 12),
                  ),
                  value: rememberKey,
                  onChanged: (v) =>
                      setDialogState(() => rememberKey = v ?? false),
                ),
                const SizedBox(height: 6),
                const Text(
                  'API URL (только HTTPS):',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                TextField(
                  controller: urlController,
                  decoration: const InputDecoration(
                    hintText: 'https://api.openai.com/v1/chat/completions',
                  ),
                ),
                const Divider(height: 24),
                const Text(
                  'Добавить RSS-канал новостей:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                TextField(
                  controller: channelNameController,
                  decoration: const InputDecoration(
                    hintText: 'Название (например, Финам RSS)',
                  ),
                ),
                TextField(
                  controller: channelUrlController,
                  decoration: const InputDecoration(
                    hintText: 'https://.../rss',
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Отмена'),
            ),
            ElevatedButton(
              onPressed: () async {
                await AiApiService.saveSettings(
                  keyController.text,
                  urlController.text,
                  rememberOnDevice: rememberKey,
                );
                if (channelNameController.text.trim().isNotEmpty &&
                    channelUrlController.text.trim().isNotEmpty) {
                  await NewsSourceService.addSource(
                    channelNameController.text.trim(),
                    channelUrlController.text.trim(),
                    'rss',
                  );
                  _loadCustomSourcesNews();
                }
                if (!ctx.mounted) return;
                Navigator.pop(ctx);
                ScaffoldMessenger.of(this.context).showSnackBar(
                  SnackBar(
                    content: Text(
                      rememberKey
                          ? 'Настройки сохранены на устройстве.'
                          : 'Ключ сохранён только в памяти на текущую сессию.',
                    ),
                  ),
                );
              },
              child: const Text('Сохранить'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final displayedNews = _onlyPortfolio
        ? NewsFilterService.getNewsForPortfolio(
            _newsList,
            widget.portfolioTickers,
          )
        : _newsList;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(10, 8, 10, 4),
          child: Wrap(
            spacing: 8,
            runSpacing: 6,
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              FilterChip(
                label: Text(
                  'По портфелю (${widget.portfolioTickers.join(", ")})',
                  style: const TextStyle(fontSize: 12),
                ),
                selected: _onlyPortfolio,
                onSelected: (val) => setState(() => _onlyPortfolio = val),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ElevatedButton.icon(
                    onPressed: _addRandomNews,
                    icon: const Icon(Icons.bolt, size: 16),
                    label: const Text('Событие'),
                  ),
                  IconButton(
                    icon: const Icon(Icons.refresh),
                    tooltip: 'Обновить RSS-ленты',
                    onPressed: _loadCustomSourcesNews,
                  ),
                  IconButton(
                    icon: const Icon(Icons.settings),
                    tooltip: 'Настройки ИИ и RSS',
                    onPressed: _openSettingsDialog,
                  ),
                ],
              ),
            ],
          ),
        ),
        if (_isLoading) const LinearProgressIndicator(),
        Expanded(
          child: displayedNews.isEmpty
              ? const Center(
                  child: Padding(
                    padding: EdgeInsets.all(20),
                    child: Text(
                      'По бумагам вашего портфеля новостей в ленте пока нет. Выключите фильтр «По портфелю» или нажмите «Событие».',
                      textAlign: TextAlign.center,
                    ),
                  ),
                )
              : ListView.builder(
                  itemCount: displayedNews.length,
                  itemBuilder: (context, index) {
                    final item = displayedNews[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Flexible(
                                  child: Text(
                                    item.source,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                Chip(
                                  label: Text(
                                    item.sentiment,
                                    style: const TextStyle(
                                      fontSize: 10,
                                      color: Colors.white,
                                    ),
                                  ),
                                  backgroundColor: item.sentiment == 'positive'
                                      ? Colors.green
                                      : (item.sentiment == 'negative'
                                          ? Colors.red
                                          : Colors.blueGrey),
                                  visualDensity: VisualDensity.compact,
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              item.title,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              item.summary,
                              style: const TextStyle(fontSize: 14),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Wrap(
                                    spacing: 4,
                                    children: item.affectedTickers
                                        .map(
                                          (t) => Chip(
                                            label: Text(
                                              t,
                                              style:
                                                  const TextStyle(fontSize: 10),
                                            ),
                                            visualDensity:
                                                VisualDensity.compact,
                                          ),
                                        )
                                        .toList(),
                                  ),
                                ),
                                ElevatedButton.icon(
                                  onPressed: () => _showAiAnalysis(item),
                                  icon: const Icon(Icons.psychology, size: 16),
                                  label: const Text('Разбор ИИ'),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}
