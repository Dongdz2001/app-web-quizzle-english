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
  int? _selectedAnswer; // ignore: unused_field - used for answer tracking
  bool _showResult = false;
  bool _isCorrect = false;
  List<Vocabulary> _quizWords = [];
  List<List<String>> _options = [];
  final _random = Random();

  @override
  Widget build(BuildContext context) {
    final topicId = ModalRoute.of(context)!.settings.arguments as String?;
    if (topicId == null) {
      Navigator.pop(context);
      return const SizedBox();
    }

    return Consumer<VocabProvider>(
      builder: (context, provider, _) {
        final topic = provider.getTopic(topicId);
        if (topic == null || topic.words.isEmpty) {
          Navigator.pop(context);
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
                      LinearProgressIndicator(
                        value: (_currentIndex + 1) / _quizWords.length,
                        backgroundColor: Colors.grey[300],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Câu ${_currentIndex + 1} / ${_quizWords.length}'),
                          Row(
                            children: [
                              Icon(Icons.check, color: Colors.green, size: 20),
                              Text(' $_correctCount  '),
                              Icon(Icons.close, color: Colors.red, size: 20),
                              Text(' $_wrongCount'),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      Expanded(
                        child: _showResult
                            ? _buildAnswerResult(context, word, provider, topicId)
                            : _buildQuestion(context, word, options, provider, topicId),
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
    String topicId,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                Text(
                  'Chọn nghĩa đúng cho từ:',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 16),
                Text(
                  word.word,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                  textAlign: TextAlign.center,
                ),
                if (word.wordForm.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Chip(label: Text(word.wordForm)),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),
        ...options.asMap().entries.map((e) {
          final index = e.key;
          final option = e.value;
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: ElevatedButton(
              onPressed: () {
                final correct = option == word.meaning;
                setState(() {
                  _selectedAnswer = index;
                  _showResult = true;
                  _isCorrect = correct;
                  if (correct) _correctCount++;
                  else _wrongCount++;
                });
              },
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.all(16),
                alignment: Alignment.centerLeft,
              ),
              child: Text(option),
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
    String topicId,
  ) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            _isCorrect ? Icons.check_circle : Icons.cancel,
            size: 80,
            color: _isCorrect ? Colors.green : Colors.red,
          ),
          const SizedBox(height: 24),
          Text(
            _isCorrect ? 'Đúng!' : 'Sai!',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: _isCorrect ? Colors.green : Colors.red,
                  fontWeight: FontWeight.bold,
                ),
          ),
          if (!_isCorrect) ...[
            const SizedBox(height: 16),
            Text('Đáp án đúng: ${word.meaning}'),
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

    return Scaffold(
      appBar: AppBar(
        title: Text('Kết quả Quiz: $topicName'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Center(
        child: Padding(
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
              const SizedBox(height: 24),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      Text(
                        '$percent%',
                        style: Theme.of(context).textTheme.displayMedium?.copyWith(
                              color: percent >= 70 ? Colors.green : Colors.orange,
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.check, color: Colors.green),
                          Text(' Đúng: $_correctCount   '),
                          Icon(Icons.close, color: Colors.red),
                          Text(' Sai: $_wrongCount'),
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
                    _selectedAnswer = null;
                    _showResult = false;
                    _quizWords = [];
                    _options = [];
                  });
                },
                icon: const Icon(Icons.refresh),
                label: const Text('Làm lại'),
              ),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.list),
                label: const Text('Về topic'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showExitConfirm(BuildContext context, VocabProvider provider, String topicId) async {
    if (_correctCount > 0 || _wrongCount > 0) {
      provider.updateProgress(topicId, correct: _correctCount, wrong: _wrongCount);
    }
    Navigator.pop(context);
  }
}
