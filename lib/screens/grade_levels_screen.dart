import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/categories.dart';
import '../providers/vocab_provider.dart';

/// Màn chọn lớp (1-12) cho "Từ vựng theo lớp" — từ HomeScreen tap vào "Từ vựng theo lớp" → vào đây.
/// Web và mobile dùng chung; tap vào lớp → CategoryTopicsScreen với gradeLevel filter.
class GradeLevelsScreen extends StatelessWidget {
  const GradeLevelsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Từ vựng theo lớp'),
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

          final isNarrow = MediaQuery.of(context).size.width < 600;
          return Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 900),
              child: Padding(
                padding: EdgeInsets.all(isNarrow ? 16 : 24),
                child: isNarrow
                    ? _buildMobileGrid(context, provider)
                    : _buildWebGrid(context, provider),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildMobileGrid(BuildContext context, VocabProvider provider) {
    return GridView.count(
      crossAxisCount: 3,
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 0.9,
      padding: const EdgeInsets.only(bottom: 24),
      children: List.generate(12, (index) {
        final grade = index + 1;
        return _GradeCard(
          grade: grade,
          topicCount: provider.getTopicsByGradeLevel(grade).length,
          onTap: () => Navigator.pushNamed(
            context,
            '/category-topics',
            arguments: {'categoryId': CategoryIds.grade, 'gradeLevel': grade},
          ),
        );
      }),
    );
  }

  Widget _buildWebGrid(BuildContext context, VocabProvider provider) {
    return GridView.count(
      crossAxisCount: kIsWeb ? 4 : 3,
      mainAxisSpacing: 16,
      crossAxisSpacing: 16,
      childAspectRatio: 1.0,
      padding: const EdgeInsets.only(bottom: 24),
      children: List.generate(12, (index) {
        final grade = index + 1;
        return _GradeCard(
          grade: grade,
          topicCount: provider.getTopicsByGradeLevel(grade).length,
          onTap: () => Navigator.pushNamed(
            context,
            '/category-topics',
            arguments: {'categoryId': CategoryIds.grade, 'gradeLevel': grade},
          ),
        );
      }),
    );
  }
}

class _GradeCard extends StatelessWidget {
  final int grade;
  final int topicCount;
  final VoidCallback onTap;

  const _GradeCard({
    required this.grade,
    required this.topicCount,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.school,
                size: 32,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(height: 4),
              Text(
                'Lớp $grade',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '$topicCount topic',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
