import 'dart:math';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/vocabulary.dart';
import '../providers/vocab_provider.dart';

class QuizScreen extends StatefulWidget {
  const QuizScreen({super.key});

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  int _currentIndex = 0;
  int _correctCount = 0;
  int _wrongCount = 0;
  int _streak = 0;
  int _points = 0;
  // ignore: unused_field - tracks which option was selected
  int? _selectedAnswer;
  bool _showResult = false;
  bool _isCorrect = false;
  List<Vocabulary> _quizWords = [];
  List<List<String>> _options = [];
  final _random = Random();

  @override
  Widget build(BuildContext context) {
    final topicId = ModalRoute.of(context)!.settings.arguments as String?;
    if (topicId == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) Navigator.pop(context);
      });
      return const SizedBox();
    }

    return Consumer<VocabProvider>(
      builder: (context, provider, _) {
        final topic = provider.getTopic(topicId);
        if (topic == null || topic.words.isEmpty) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (context.mounted) Navigator.pop(context);
          });
          return const SizedBox();
        }

        if (_quizWords.isEmpty) {
          _quizWords = List.from(topic.words)..shuffle(_random);
          _options = _quizWords.map((w) => _generateOptions(w, topic.words)).toList();
        }

        if (_currentIndex >= _quizWords.length) {
          provider.updateProgress(topicId, correct: _correctCount, wrong: _wrongCount);
          return _buildResultScreen(context, provider, topicId, topic.name);
        }

        final word = _quizWords[_currentIndex];
        final options = _options[_currentIndex];

        return Scaffold(
          appBar: AppBar(
            title: Text('Quiz: ${topic.name}'),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => _showExitConfirm(context, provider, topicId),
            ),
          ),
          body: SafeArea(
            child: Align(
              alignment: Alignment.topCenter,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 900),
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: LinearProgressIndicator(
                          value: (_currentIndex + 1) / _quizWords.length,
                          backgroundColor: Colors.grey[200],
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Theme.of(context).colorScheme.primary,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Câu ${_currentIndex + 1} / ${_quizWords.length}',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                          Row(
                            children: [
                              Icon(Icons.check_circle, color: Colors.green[600], size: 20),
                              Text(' $_correctCount  ', style: const TextStyle(fontWeight: FontWeight.w600)),
                              Icon(Icons.cancel, color: Colors.red[600], size: 20),
                              Text(' $_wrongCount', style: const TextStyle(fontWeight: FontWeight.w600)),
                              const SizedBox(width: 12),
                              Chip(
                                avatar: Icon(Icons.local_fire_department, size: 18, color: Colors.deepOrange[700]),
                                label: Text('Streak $_streak'),
                                visualDensity: VisualDensity.compact,
                              ),
                              const SizedBox(width: 8),
                              Chip(
                                avatar: Icon(Icons.star, size: 18, color: Colors.amber[700]),
                                label: Text('$_points'),
                                visualDensity: VisualDensity.compact,
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      Expanded(
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 300),
                          transitionBuilder: (child, animation) {
                            return FadeTransition(
                              opacity: animation,
                              child: ScaleTransition(
                                scale: Tween<double>(begin: 0.95, end: 1).animate(
                                  CurvedAnimation(parent: animation, curve: Curves.easeOut),
                                ),
                                child: child,
                              ),
                            );
                          },
                          child: _showResult
                              ? _buildAnswerResult(context, word, provider, topicId, key: const ValueKey('result'))
                              : _buildQuestion(context, word, options, provider, topicId, key: const ValueKey('question')),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  List<String> _generateOptions(Vocabulary word, List<Vocabulary> allWords) {
    final wrong = allWords
        .where((w) => w.id != word.id)
        .map((w) => w.meaning)
        .toSet()
        .toList();
    wrong.shuffle(_random);
    final options = wrong.take(3).toList();
    options.add(word.meaning);
    options.shuffle(_random);
    return options;
  }

  Widget _buildQuestion(
    BuildContext context,
    Vocabulary word,
    List<String> options,
    VocabProvider provider,
    String topicId, {
    Key? key,
  }) {
    return Column(
      key: key,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Card(
          elevation: 4,
          shadowColor: Theme.of(context).colorScheme.primary.withOpacity(0.2),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Container(
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3),
                  Theme.of(context).colorScheme.surface,
                ],
              ),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.quiz, color: Theme.of(context).colorScheme.primary, size: 24),
                    const SizedBox(width: 8),
                    Text(
                      'Chọn nghĩa đúng cho từ:',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Text(
                  word.word,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.primary,
                        letterSpacing: 0.5,
                      ),
                  textAlign: TextAlign.center,
                ),
                if (word.wordForm.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Chip(
                      label: Text(word.wordForm),
                      backgroundColor: Theme.of(context).colorScheme.secondaryContainer,
                    ),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),
        Text('Chọn đáp án:', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
        const SizedBox(height: 12),
        ...options.asMap().entries.map((e) {
          final index = e.key;
          final option = e.value;
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {
                  final correct = option == word.meaning;
                  setState(() {
                    _selectedAnswer = index;
                    _showResult = true;
                    _isCorrect = correct;
                    if (correct) {
                      _correctCount++;
                      _streak++;
                      _points += 10 + (_streak - 1) * 2;
                    } else {
                      _wrongCount++;
                      _streak = 0;
                    }
                  });
                },
                borderRadius: BorderRadius.circular(12),
                child: Ink(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade300, width: 1.5),
                    color: Colors.white,
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 4, offset: const Offset(0, 2))],
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primaryContainer,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          String.fromCharCode(65 + index),
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.onPrimaryContainer,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(child: Text(option, style: Theme.of(context).textTheme.bodyLarge)),
                      Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey[400]),
                    ],
                  ),
                ),
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildAnswerResult(
    BuildContext context,
    Vocabulary word,
    VocabProvider provider,
    String topicId, {
    Key? key,
  }  ) {
    final pointsEarned = _isCorrect ? 10 + (_streak - 1) * 2 : 0;
    final feedbackText = _isCorrect
        ? (_streak >= 3 ? 'Chuỗi $_streak! +$pointsEarned điểm' : 'Tuyệt! +$pointsEarned điểm')
        : 'Cố lên lần sau!';
    final feedbackColor = _isCorrect ? Colors.green[50] : Colors.red[50];
    return Center(
      key: key,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            _isCorrect ? Icons.celebration : Icons.sentiment_dissatisfied,
            size: 80,
            color: _isCorrect ? Colors.green[600] : Colors.red[600],
          ),
          const SizedBox(height: 24),
          Text(
            _isCorrect ? 'Đúng rồi!' : 'Sai rồi!',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: _isCorrect ? Colors.green[700] : Colors.red[700],
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              color: feedbackColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _isCorrect ? Colors.green : Colors.red, width: 1),
            ),
            child: Text(
              feedbackText,
              style: TextStyle(
                color: _isCorrect ? Colors.green[800] : Colors.red[800],
                fontWeight: FontWeight.w600,
                fontSize: 16,
              ),
            ),
          ),
          if (!_isCorrect) ...[
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text('Đáp án đúng: ${word.meaning}', style: Theme.of(context).textTheme.bodyLarge),
              ),
            ),
          ],
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: () {
              setState(() {
                _currentIndex++;
                _selectedAnswer = null;
                _showResult = false;
              });
            },
            icon: const Icon(Icons.arrow_forward),
            label: const Text('Tiếp theo'),
          ),
        ],
      ),
    );
  }

  Widget _buildResultScreen(
    BuildContext context,
    VocabProvider provider,
    String topicId,
    String topicName,
  ) {
    final total = _correctCount + _wrongCount;
    final percent = total > 0 ? (_correctCount / total * 100).round() : 0;
    final message = percent >= 90
        ? 'Xuất sắc! Bạn đã nắm vững từ vựng!'
        : percent >= 70
            ? 'Tốt lắm! Tiếp tục phát huy nhé!'
            : 'Cố gắng lên! Ôn tập thêm để cải thiện!';

    return Scaffold(
      appBar: AppBar(
        title: Text('Kết quả Quiz: $topicName'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.emoji_events, size: 80, color: Colors.amber[700]),
              const SizedBox(height: 24),
              Text(
                'Hoàn thành!',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                message,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Colors.grey[700],
                    ),
              ),
              const SizedBox(height: 24),
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      Text(
                        '$percent%',
                        style: Theme.of(context).textTheme.displayMedium?.copyWith(
                              color: percent >= 70 ? Colors.green[700] : Colors.orange[700],
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.check_circle, color: Colors.green[600]),
                          Text(' Đúng: $_correctCount   '),
                          Icon(Icons.cancel, color: Colors.red[600]),
                          Text(' Sai: $_wrongCount'),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.star, color: Colors.amber[700], size: 20),
                          Text(' Tổng điểm: $_points', style: const TextStyle(fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: () {
                  setState(() {
                    _currentIndex = 0;
                    _correctCount = 0;
                    _wrongCount = 0;
                    _streak = 0;
                    _points = 0;
                    _selectedAnswer = null;
                    _showResult = false;
                    _quizWords = [];
                    _options = [];
                  });
                },
                icon: const Icon(Icons.refresh),
                label: const Text('Làm lại'),
                style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12)),
              ),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.list),
                label: const Text('Về topic'),
                style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showExitConfirm(BuildContext context, VocabProvider provider, String topicId) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Thoát Quiz?'),
        content: Text(
          (_correctCount > 0 || _wrongCount > 0)
              ? 'Bạn đã làm $_correctCount đúng, $_wrongCount sai. Tiến độ sẽ được lưu. Bạn có chắc muốn thoát?'
              : 'Bạn có chắc muốn thoát quiz?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Tiếp tục'),
          ),
          ElevatedButton(
            onPressed: () {
              if (_correctCount > 0 || _wrongCount > 0) {
                provider.updateProgress(topicId, correct: _correctCount, wrong: _wrongCount);
              }
              Navigator.pop(ctx);
              Navigator.pop(context);
            },
            child: const Text('Thoát'),
          ),
        ],
      ),
    );
  }
}
