import 'package:flutter/material.dart';
import '../models/news_item.dart';
import '../services/ai_api_service.dart';
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
    setState(() => _isLoading = true);
    try {
      final sources = await NewsSourceService.getSources();
      final List<NewsItem> fetched = [...NewsItem.getInitialNews()];

      for (final source in sources) {
        final sourceNews = await NewsSourceService.fetchNewsFromSource(source);
        fetched.addAll(sourceNews);
      }

      if (!mounted) return;
      setState(() {
        _newsList = fetched;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  void _addRandomNews() {
    final randNews = NewsFilterService.generateRandomMarketNews();
    setState(() {
      _newsList.insert(0, randNews);
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Сгенерирована случайная новость дня!')),
    );
  }

  Future<void> _showAiAnalysis(NewsItem news) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    final prompt =
        'Проанализируй новость для моего инвест-портфеля. Сентимент, риски, вердикт (покупать/продавать/держать).\nЗаголовок: ${news.title}\nТекст: ${news.content}';
    final analysisResult = await AiApiService.analyzeText(prompt);

    if (!mounted) return;
    Navigator.pop(context);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('ИИ-анализ: ${news.title}'),
        content: SingleChildScrollView(child: Text(analysisResult)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Закрыть'),
          ),
        ],
      ),
    );
  }

  void _openSettingsDialog() {
    final keyController = TextEditingController();
    final urlController = TextEditingController();
    final channelNameController = TextEditingController();
    final channelUrlController = TextEditingController();

    AiApiService.getApiKey().then((val) => keyController.text = val);
    AiApiService.getApiUrl().then((val) => urlController.text = val);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Настройки ИИ и Каналов'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'API-ключ ИИ (OpenAI / совместимый):',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              TextField(
                controller: keyController,
                obscureText: true,
                decoration: const InputDecoration(hintText: 'sk-...'),
              ),
              const SizedBox(height: 10),
              const Text(
                'API URL (эндпоинт):',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              TextField(
                controller: urlController,
                decoration: const InputDecoration(
                  hintText: 'https://api.openai.com/v1/chat/completions',
                ),
              ),
              const Divider(height: 30),
              const Text(
                'Добавить новый канал новостей:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              TextField(
                controller: channelNameController,
                decoration: const InputDecoration(
                  hintText: 'Название (например, Мой Telegram/RSS)',
                ),
              ),
              TextField(
                controller: channelUrlController,
                decoration: const InputDecoration(hintText: 'URL (https://...)'),
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
                keyController.text.trim(),
                urlController.text.trim(),
              );
              if (channelNameController.text.trim().isNotEmpty &&
                  channelUrlController.text.trim().isNotEmpty) {
                await NewsSourceService.addSource(
                  channelNameController.text.trim(),
                  channelUrlController.text.trim(),
                  'http',
                );
                _loadCustomSourcesNews();
              }
              if (!mounted) return;
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Настройки сохранены!')),
              );
            },
            child: const Text('Сохранить'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final displayedNews = _onlyPortfolio
        ? NewsFilterService.getNewsForPortfolio(_newsList, widget.portfolioTickers)
        : _newsList;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(10, 8, 10, 4),
          child: Row(
            children: [
              FilterChip(
                label: const Text('По портфелю'),
                selected: _onlyPortfolio,
                onSelected: (val) => setState(() => _onlyPortfolio = val),
              ),
              const Spacer(),
              ElevatedButton.icon(
                onPressed: _addRandomNews,
                icon: const Icon(Icons.bolt, size: 18),
                label: const Text('Новость дня'),
              ),
              const SizedBox(width: 4),
              IconButton(
                icon: const Icon(Icons.settings),
                onPressed: _openSettingsDialog,
                tooltip: 'Настройки API и каналов',
              ),
            ],
          ),
        ),
        if (_isLoading) const LinearProgressIndicator(),
        Expanded(
          child: ListView.builder(
            itemCount: displayedNews.length,
            itemBuilder: (context, index) {
              final item = displayedNews[index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            item.source,
                            style: const TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                          Chip(
                            label: Text(
                              item.sentiment,
                              style: const TextStyle(fontSize: 10, color: Colors.white),
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
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(item.summary, style: const TextStyle(fontSize: 14)),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 4,
                        children: item.affectedTickers
                            .map(
                              (t) => Chip(
                                label: Text(t, style: const TextStyle(fontSize: 10)),
                                visualDensity: VisualDensity.compact,
                              ),
                            )
                            .toList(),
                      ),
                      const SizedBox(height: 8),
                      Align(
                        alignment: Alignment.centerRight,
                        child: ElevatedButton.icon(
                          onPressed: () => _showAiAnalysis(item),
                          icon: const Icon(Icons.psychology, size: 16),
                          label: const Text('Спросить ИИ'),
                        ),
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
