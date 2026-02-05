import 'dart:math';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/vocabulary.dart';
import '../providers/vocab_provider.dart';

enum PracticeType {
  chooseMeaning,
  fillBlank,
  matchWordMeaning,
  synonymAntonym,
}

class PracticeScreen extends StatefulWidget {
  const PracticeScreen({super.key});

  @override
  State<PracticeScreen> createState() => _PracticeScreenState();
}

class _PracticeScreenState extends State<PracticeScreen> {
  PracticeType _practiceType = PracticeType.chooseMeaning;
  int _currentIndex = 0;
  int _correctCount = 0;
  int _wrongCount = 0;
  int? _selectedAnswer;
  String? _fillAnswer;
  bool _showResult = false;
  bool _isCorrect = false;
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

        List<Vocabulary> words = List.from(topic.words);
        words.shuffle(_random);
        final word = words[_currentIndex];

        return Scaffold(
          appBar: AppBar(
            title: Text('Luyện tập: ${topic.name}'),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => _showExitConfirm(context, provider, topicId),
            ),
            actions: [
              PopupMenuButton<PracticeType>(
                icon: const Icon(Icons.tune),
                onSelected: (t) {
                  setState(() {
                    _practiceType = t;
                    _currentIndex = 0;
                    _correctCount = 0;
                    _wrongCount = 0;
                    _selectedAnswer = null;
                    _fillAnswer = null;
                    _showResult = false;
                  });
                },
                itemBuilder: (_) => [
                  _buildMenuItem(PracticeType.chooseMeaning, 'Chọn nghĩa đúng', Icons.check_circle),
                  _buildMenuItem(PracticeType.fillBlank, 'Điền từ', Icons.edit),
                  _buildMenuItem(PracticeType.matchWordMeaning, 'Ghép từ - nghĩa', Icons.link),
                  _buildMenuItem(PracticeType.synonymAntonym, 'Đồng nghĩa/Trái nghĩa', Icons.sync_alt),
                ],
              ),
            ],
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
                        value: (_currentIndex + 1) / words.length,
                        backgroundColor: Colors.grey[300],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('${_currentIndex + 1} / ${words.length}'),
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
                            ? _buildResult(context, word, words, provider, topicId)
                            : _buildQuestion(context, word, words, provider, topicId),
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

  PopupMenuItem<PracticeType> _buildMenuItem(PracticeType type, String label, IconData icon) {
    return PopupMenuItem(
      value: type,
      child: Row(
        children: [
          Icon(icon),
          const SizedBox(width: 8),
          Text(label),
        ],
      ),
    );
  }

  Widget _buildQuestion(
    BuildContext context,
    Vocabulary word,
    List<Vocabulary> words,
    VocabProvider provider,
    String topicId,
  ) {
    switch (_practiceType) {
      case PracticeType.chooseMeaning:
        return _buildChooseMeaning(context, word, words, provider, topicId);
      case PracticeType.fillBlank:
        return _buildFillBlank(context, word, words, provider, topicId);
      case PracticeType.matchWordMeaning:
        return _buildMatch(context, word, words, provider, topicId);
      case PracticeType.synonymAntonym:
        return _buildSynonymAntonym(context, word, words, provider, topicId);
    }
  }

  Widget _buildChooseMeaning(
    BuildContext context,
    Vocabulary word,
    List<Vocabulary> words,
    VocabProvider provider,
    String topicId,
  ) {
    final options = _getWrongOptions(word, words, 3);
    options.add(word.meaning);
    options.shuffle(_random);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                Text(
                  word.word,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
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
        Text('Chọn nghĩa đúng:', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 12),
        ...options.asMap().entries.map((e) {
          final index = e.key;
          final option = e.value;
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: ElevatedButton(
              onPressed: _selectedAnswer == null
                  ? () {
                      final correct = option == word.meaning;
                      setState(() {
                        _selectedAnswer = index;
                        _showResult = true;
                        _isCorrect = correct;
                        if (correct) {
                          _correctCount++;
                        } else {
                          _wrongCount++;
                        }
                      });
                    }
                  : null,
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

  Widget _buildFillBlank(
    BuildContext context,
    Vocabulary word,
    List<Vocabulary> words,
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
                  word.meaning,
                  style: Theme.of(context).textTheme.titleLarge,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                TextField(
                  decoration: InputDecoration(
                    hintText: 'Nhập từ tiếng Anh',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onChanged: (v) => _fillAnswer = v.trim(),
                  onSubmitted: (v) {
                    _fillAnswer = v.trim();
                    _checkFillAnswer(word, provider, topicId);
                  },
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => _checkFillAnswer(word, provider, topicId),
                  child: const Text('Kiểm tra'),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _checkFillAnswer(Vocabulary word, VocabProvider provider, String topicId) {
    final correct = (_fillAnswer ?? '').toLowerCase() == word.word.toLowerCase();
    setState(() {
      _showResult = true;
      _isCorrect = correct;
      if (correct) {
        _correctCount++;
      } else {
        _wrongCount++;
      }
    });
  }

  Widget _buildMatch(
    BuildContext context,
    Vocabulary word,
    List<Vocabulary> words,
    VocabProvider provider,
    String topicId,
  ) {
    final options = _getWrongOptions(word, words, 3);
    options.add(word.meaning);
    options.shuffle(_random);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                Text('Ghép từ với nghĩa phù hợp:', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 16),
                Text(
                  word.word,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                ),
                const SizedBox(height: 24),
                ...options.asMap().entries.map((e) {
                  final index = e.key;
                  final option = e.value;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: ElevatedButton(
                      onPressed: _selectedAnswer == null
                          ? () {
                              final correct = option == word.meaning;
                              setState(() {
                                _selectedAnswer = index;
                                _showResult = true;
                                _isCorrect = correct;
                                if (correct) {
                                  _correctCount++;
                                } else {
                                  _wrongCount++;
                                }
                              });
                            }
                          : null,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.all(16),
                        alignment: Alignment.centerLeft,
                      ),
                      child: Text(option),
                    ),
                  );
                }),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSynonymAntonym(
    BuildContext context,
    Vocabulary word,
    List<Vocabulary> words,
    VocabProvider provider,
    String topicId,
  ) {
    final hasSynonym = word.synonym != null && word.synonym!.isNotEmpty;
    final hasAntonym = word.antonym != null && word.antonym!.isNotEmpty;

    if (!hasSynonym && !hasAntonym) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.info_outline, size: 48, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'Từ này chưa có đồng nghĩa/trái nghĩa',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => _nextWord(words, provider, topicId),
              child: const Text('Tiếp theo'),
            ),
          ],
        ),
      );
    }

    final questionType = _random.nextBool() && hasSynonym
        ? 'synonym'
        : hasAntonym
            ? 'antonym'
            : 'synonym';
    final correctAnswer = questionType == 'synonym' ? word.synonym! : word.antonym!;
    final wrongOptions = words
        .where((w) =>
            w.synonym != correctAnswer &&
            w.antonym != correctAnswer &&
            w.synonym != null &&
            w.antonym != null)
        .map((w) => [_random.nextBool() ? w.synonym! : w.antonym!])
        .expand((e) => e)
        .where((e) => e != correctAnswer)
        .toSet()
        .take(3)
        .toList();
    final options = [...wrongOptions, correctAnswer]..shuffle(_random);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                Text(
                  word.word,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 16),
                Text(
                  questionType == 'synonym' ? 'Chọn từ đồng nghĩa:' : 'Chọn từ trái nghĩa:',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 16),
                ...options.asMap().entries.map((e) {
                  final index = e.key;
                  final option = e.value;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: ElevatedButton(
                      onPressed: _selectedAnswer == null
                          ? () {
                              final correct = option == correctAnswer;
                              setState(() {
                                _selectedAnswer = index;
                                _showResult = true;
                                _isCorrect = correct;
                                if (correct) {
                                  _correctCount++;
                                } else {
                                  _wrongCount++;
                                }
                              });
                            }
                          : null,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.all(16),
                        alignment: Alignment.centerLeft,
                      ),
                      child: Text(option),
                    ),
                  );
                }),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildResult(
    BuildContext context,
    Vocabulary word,
    List<Vocabulary> words,
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
            _isCorrect ? 'Đúng rồi!' : 'Sai rồi!',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: _isCorrect ? Colors.green : Colors.red,
                  fontWeight: FontWeight.bold,
                ),
          ),
          if (!_isCorrect) ...[
            const SizedBox(height: 16),
            Text('Đáp án: ${word.word} = ${word.meaning}'),
            if (word.synonym != null) Text('Đồng nghĩa: ${word.synonym}'),
            if (word.antonym != null) Text('Trái nghĩa: ${word.antonym}'),
          ],
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: () => _nextWord(words, provider, topicId),
            icon: const Icon(Icons.arrow_forward),
            label: Text(_currentIndex < words.length - 1 ? 'Tiếp theo' : 'Hoàn thành'),
          ),
        ],
      ),
    );
  }

  List<String> _getWrongOptions(Vocabulary word, List<Vocabulary> words, int count) {
    final wrong = words.where((w) => w.id != word.id).map((w) => w.meaning).toSet().toList();
    wrong.shuffle(_random);
    return wrong.take(count).toList();
  }

  void _nextWord(List<Vocabulary> words, VocabProvider provider, String topicId) {
    if (_currentIndex >= words.length - 1) {
      provider.updateProgress(topicId, correct: _correctCount, wrong: _wrongCount);
      _showCompletionDialog(provider, topicId);
      return;
    }
    setState(() {
      _currentIndex++;
      _selectedAnswer = null;
      _fillAnswer = null;
      _showResult = false;
    });
  }

  void _showCompletionDialog(VocabProvider provider, String topicId) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: const Text('Hoàn thành!'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.celebration, size: 64, color: Colors.amber[700]),
            const SizedBox(height: 16),
            Text('Đúng: $_correctCount'),
            Text('Sai: $_wrongCount'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Làm lại'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: const Text('Về topic'),
          ),
        ],
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
