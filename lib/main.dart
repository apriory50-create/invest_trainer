import 'package:flutter/material.dart';
// Импортируем наши сервисы и экраны
import 'services/ai_api_service.dart';
import 'services/news_source_service.dart';
import 'screens/news_ai_screen.dart';

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
      home: const MainMenuScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class MainMenuScreen extends StatelessWidget {
  const MainMenuScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Invest Trainer 📈'),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          Card(
            elevation: 4,
            child: ListTile(
              leading: const Icon(Icons.newspaper, color: Colors.blue, size: 36),
              title: const Text('Новости и ИИ Анализ', style: TextStyle(fontWeight: FontWeight.bold)),
              subtitle: const Text('Лента новостей, фильтры по портфелю и AI-ассистент'),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const NewsAiScreen()),
                );
              },
            ),
          ),
          const SizedBox(height: 12),
          // Здесь можно добавить другие разделы (Академия, Портфель, Симулятор)
          ListTile(
            leading: const Icon(Icons.school, color: Colors.green),
            title: const Text('Академия инвестиций'),
            subtitle: const Text('100 уроков от новичка до профи'),
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Академия уже доступна в проекте!')),
              );
            },
          ),
        ],
      ),
    );
  }
}







