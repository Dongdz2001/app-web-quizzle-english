import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'providers/vocab_provider.dart';
import 'screens/category_topics_screen.dart';
import 'screens/grade_levels_screen.dart';
import 'screens/home_screen.dart';
import 'screens/learn_screen.dart';
import 'screens/practice_screen.dart';
import 'screens/progress_screen.dart';
import 'screens/quiz_screen.dart';
import 'screens/topic_detail_screen.dart';
import 'styles/app_theme.dart';

void main() {
  runApp(const VocabApp());
}

class VocabApp extends StatelessWidget {
  const VocabApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => VocabProvider()..loadData(),
      child: MaterialApp(
        title: 'Vocab Web App - Ghi Nhớ Từ Vựng',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: ThemeMode.system,
        initialRoute: '/',
        routes: {
          '/': (_) => const HomeScreen(),
          '/grade-levels': (_) => const GradeLevelsScreen(),
          '/category-topics': (_) => const CategoryTopicsScreen(),
          '/topic': (_) => const TopicDetailScreen(),
          '/learn': (_) => const LearnScreen(),
          '/practice': (_) => const PracticeScreen(),
          '/quiz': (_) => const QuizScreen(),
          '/progress': (_) => const ProgressScreen(),
        },
      ),
    );
  }
}
