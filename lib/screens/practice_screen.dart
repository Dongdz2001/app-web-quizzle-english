import 'dart:math';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/vocabulary.dart';
import '../providers/vocab_provider.dart';

enum PracticeType {
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
  PracticeType _practiceType = PracticeType.fillBlank;
  int _currentIndex = 0;
  int _correctCount = 0;
  int _wrongCount = 0;
  int _streak = 0;
  int _points = 0;
  int? _selectedAnswer;
  String? _fillAnswer;
  bool _showResult = false;
  bool _isCorrect = false;
  final _random = Random();
  List<Vocabulary> _sessionWords = [];
  String? _sessionTopicId;
  PracticeType? _sessionPracticeType;

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

        _ensureSession(topicId, topic.words);
        if (_sessionWords.isEmpty) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (context.mounted) Navigator.pop(context);
          });
          return const SizedBox();
        }
        if (_currentIndex >= _sessionWords.length) {
          _currentIndex = 0;
        }
        final word = _sessionWords[_currentIndex];

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
                    _resetSession(topicId, topic.words);
                  });
                },
                itemBuilder: (_) => [
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
                        value: (_currentIndex + 1) / _sessionWords.length,
                        backgroundColor: Colors.grey[300],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('${_currentIndex + 1} / ${_sessionWords.length}'),
                          Row(
                            children: [
                              Icon(Icons.check, color: Colors.green, size: 20),
                              Text(' $_correctCount  '),
                              Icon(Icons.close, color: Colors.red, size: 20),
                              Text(' $_wrongCount'),
                              const SizedBox(width: 8),
                              Chip(
                                avatar: const Icon(Icons.local_fire_department, size: 16, color: Colors.deepOrange),
                                label: Text('Streak $_streak'),
                                visualDensity: VisualDensity.compact,
                              ),
                              const SizedBox(width: 8),
                              Chip(
                                avatar: const Icon(Icons.star, size: 16, color: Colors.amber),
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
                          duration: const Duration(milliseconds: 280),
                          transitionBuilder: (child, animation) {
                            final offsetAnimation = Tween<Offset>(
                              begin: const Offset(0, 0.04),
                              end: Offset.zero,
                            ).animate(animation);
                            return FadeTransition(
                              opacity: animation,
                              child: SlideTransition(position: offsetAnimation, child: child),
                            );
                          },
                          child: _showResult
                              ? _buildResult(context, word, _sessionWords, provider, topicId,
                                  key: const ValueKey('result'))
                              : _buildQuestion(context, word, _sessionWords, provider, topicId,
                                  key: const ValueKey('question')),
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
    {Key? key}
  ) {
    switch (_practiceType) {
      case PracticeType.fillBlank:
        return _buildFillBlank(context, word, words, provider, topicId, key: key);
      case PracticeType.matchWordMeaning:
        return _buildMatch(context, word, words, provider, topicId, key: key);
      case PracticeType.synonymAntonym:
        return _buildSynonymAntonym(context, word, words, provider, topicId, key: key);
    }
  }

  Widget _buildFillBlank(
    BuildContext context,
    Vocabulary word,
    List<Vocabulary> words,
    VocabProvider provider,
    String topicId,
    {Key? key}
  ) {
    return Column(
      key: key,
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
                  enableSuggestions: false,
                  autocorrect: false,
                  spellCheckConfiguration: const SpellCheckConfiguration.disabled(),
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
        _streak++;
        _points += 10 + (_streak - 1) * 2;
      } else {
        _wrongCount++;
        _streak = 0;
      }
    });
  }

  Widget _buildMatch(
    BuildContext context,
    Vocabulary word,
    List<Vocabulary> words,
    VocabProvider provider,
    String topicId,
    {Key? key}
  ) {
    final options = _getWrongOptions(word, words, 3);
    options.add(word.meaning);
    options.shuffle(_random);

    return Column(
      key: key,
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
                                  _streak++;
                                  _points += 10 + (_streak - 1) * 2;
                                } else {
                                  _wrongCount++;
                                  _streak = 0;
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
    {Key? key}
  ) {
    final hasSynonym = word.synonym != null && word.synonym!.isNotEmpty;
    final hasAntonym = word.antonym != null && word.antonym!.isNotEmpty;

    if (!hasSynonym && !hasAntonym) {
      return Center(
        key: key,
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
      key: key,
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
                                  _streak++;
                                  _points += 10 + (_streak - 1) * 2;
                                } else {
                                  _wrongCount++;
                                  _streak = 0;
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
    {Key? key}
  ) {
    final feedbackText = _isCorrect
        ? (_streak >= 3 ? 'Chuỗi $_streak rồi!' : 'Tuyệt vời!')
        : 'Cố lên, thử lại nhé!';
    final feedbackColor = _isCorrect ? Colors.green[50] : Colors.red[50];
    return Center(
      key: key,
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
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
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
              ),
            ),
          ),
          if (!_isCorrect) ...[
            const SizedBox(height: 16),
            Text('Đáp án: ${word.word} = ${word.meaning}'),
            if (word.synonym != null) Text('Đồng nghĩa: ${word.synonym}'),
            if (word.antonym != null) Text('Trái nghĩa: ${word.antonym}'),
          ],
          const SizedBox(height: 32),
          TextButton.icon(
            onPressed: _retryQuestion,
            icon: const Icon(Icons.refresh),
            label: const Text('Thử lại câu này'),
          ),
          const SizedBox(height: 8),
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

  void _retryQuestion() {
    setState(() {
      _selectedAnswer = null;
      _fillAnswer = null;
      _showResult = false;
    });
  }

  void _ensureSession(String topicId, List<Vocabulary> words) {
    if (_sessionTopicId != topicId ||
        _sessionPracticeType != _practiceType ||
        _sessionWords.isEmpty) {
      _resetSession(topicId, words);
    }
  }

  void _resetSession(String topicId, List<Vocabulary> words) {
    _sessionTopicId = topicId;
    _sessionPracticeType = _practiceType;
    _sessionWords = List.from(words)..shuffle(_random);
    _currentIndex = 0;
    _correctCount = 0;
    _wrongCount = 0;
    _selectedAnswer = null;
    _fillAnswer = null;
    _showResult = false;
    _streak = 0;
    _points = 0;
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
