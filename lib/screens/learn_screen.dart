import 'dart:math';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/vocabulary.dart';
import '../providers/vocab_provider.dart';

class LearnScreen extends StatefulWidget {
  const LearnScreen({super.key});

  @override
  State<LearnScreen> createState() => _LearnScreenState();
}

class _LearnScreenState extends State<LearnScreen> {
  int _currentIndex = 0;
  bool _showMeaning = false;
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
            title: Text('Học: ${topic.name}'),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => Navigator.pop(context),
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
                        value: (_currentIndex + 1) / words.length,
                        backgroundColor: Colors.grey[300],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        '${_currentIndex + 1} / ${words.length}',
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                      const Spacer(),
                      Card(
                        margin: const EdgeInsets.symmetric(horizontal: 16),
                        child: Padding(
                          padding: const EdgeInsets.all(32),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
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
                                  child: Chip(
                                    label: Text(word.wordForm),
                                  ),
                                ),
                              const SizedBox(height: 24),
                              GestureDetector(
                                onTap: () => setState(() => _showMeaning = !_showMeaning),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  padding: const EdgeInsets.all(20),
                                  decoration: BoxDecoration(
                                    color: _showMeaning
                                        ? Theme.of(context).colorScheme.primaryContainer
                                        : Colors.grey[200],
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: _showMeaning
                                      ? Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              word.meaning,
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .titleLarge
                                                  ?.copyWith(
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                            ),
                                            if (word.englishDefinition != null &&
                                                word.englishDefinition!.isNotEmpty) ...[
                                              const SizedBox(height: 12),
                                              Text(
                                                'Phiên âm: ${word.englishDefinition!}',
                                                style: Theme.of(context)
                                                    .textTheme
                                                    .bodyMedium
                                                    ?.copyWith(
                                                      fontStyle: FontStyle.italic,
                                                    ),
                                              ),
                                            ],
                                            if (word.synonym != null &&
                                                word.synonym!.isNotEmpty) ...[
                                              const SizedBox(height: 8),
                                              Row(
                                                children: [
                                                  const Icon(Icons.sync_alt, size: 18),
                                                  const SizedBox(width: 8),
                                                  Text('Đồng nghĩa: ${word.synonym}'),
                                                ],
                                              ),
                                            ],
                                            if (word.antonym != null &&
                                                word.antonym!.isNotEmpty) ...[
                                              const SizedBox(height: 4),
                                              Row(
                                                children: [
                                                  const Icon(Icons.compare_arrows, size: 18),
                                                  const SizedBox(width: 8),
                                                  Text('Trái nghĩa: ${word.antonym}'),
                                                ],
                                              ),
                                            ],
                                          ],
                                        )
                                      : Row(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Icon(Icons.touch_app),
                                            const SizedBox(width: 8),
                                            Text(
                                              'Nhấn để xem nghĩa',
                                              style: TextStyle(color: Colors.grey[600]),
                                            ),
                                          ],
                                        ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const Spacer(),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          ElevatedButton.icon(
                            onPressed: _currentIndex > 0
                                ? () {
                                    setState(() {
                                      _currentIndex--;
                                      _showMeaning = false;
                                    });
                                  }
                                : null,
                            icon: const Icon(Icons.arrow_back),
                            label: const Text('Trước'),
                          ),
                          ElevatedButton.icon(
                            onPressed: _currentIndex < words.length - 1
                                ? () {
                                    setState(() {
                                      _currentIndex++;
                                      _showMeaning = false;
                                    });
                                  }
                                : null,
                            icon: const Icon(Icons.arrow_forward),
                            label: const Text('Sau'),
                          ),
                        ],
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
}
