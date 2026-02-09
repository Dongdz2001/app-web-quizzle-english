import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/vocab_provider.dart';

class ProgressScreen extends StatelessWidget {
  const ProgressScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tiến trình học'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Consumer<VocabProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          final topicsToShow = provider.filteredTopics;
          if (topicsToShow.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.analytics_outlined, size: 80, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    'Chưa có dữ liệu học',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ],
              ),
            );
          }

          int totalCorrect = 0;
          int totalWrong = 0;
          int totalWords = 0;
          for (final topic in topicsToShow) {
            final p = provider.progress[topic.id];
            if (p != null) {
              totalCorrect += p.correctCount;
              totalWrong += p.wrongCount;
              totalWords += p.totalWords;
            }
          }
          final totalAnswered = totalCorrect + totalWrong;
          final overallAccuracy = totalAnswered > 0 ? (totalCorrect / totalAnswered * 100).round() : 0;

          return Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 900),
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        children: [
                          Text(
                            'Tổng quan',
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                          const SizedBox(height: 24),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              _buildStatItem(
                                context,
                                Icons.menu_book,
                                'Từ vựng',
                                '$totalWords',
                              ),
                              _buildStatItem(
                                context,
                                Icons.check_circle,
                                'Đúng',
                                '$totalCorrect',
                              ),
                              _buildStatItem(
                                context,
                                Icons.cancel,
                                'Sai',
                                '$totalWrong',
                              ),
                              _buildStatItem(
                                context,
                                Icons.percent,
                                'Độ chính xác',
                                '$overallAccuracy%',
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Theo topic',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 12),
                  ...topicsToShow.map((topic) {
                    final progress = provider.progress[topic.id];
                    if (progress == null) return const SizedBox();
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(16),
                        leading: CircleAvatar(
                          backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                          child: Text(
                            '${(progress.progressPercent * 100).round()}%',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.onPrimaryContainer,
                            ),
                          ),
                        ),
                        title: Text(
                          topic.name,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 8),
                            LinearProgressIndicator(
                              value: progress.progressPercent,
                              backgroundColor: Colors.grey[300],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '${progress.learnedWords}/${progress.totalWords} từ | '
                              'Đúng: ${progress.correctCount} | Sai: ${progress.wrongCount} | '
                              'Độ chính xác: ${(progress.accuracy * 100).round()}%',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                        onTap: () => Navigator.pushNamed(
                          context,
                          '/topic',
                          arguments: topic.id,
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatItem(
    BuildContext context,
    IconData icon,
    String label,
    String value,
  ) {
    return Column(
      children: [
        Icon(icon, size: 32, color: Theme.of(context).colorScheme.primary),
        const SizedBox(height: 8),
        Text(
          value,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }
}
