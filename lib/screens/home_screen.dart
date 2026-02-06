import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/categories.dart';
import '../providers/vocab_provider.dart';

/// Màn chính: chia nhóm topic — 5 nhóm (Từ vựng theo chủ đề, theo lớp, Ngữ pháp, Idiom, Phát âm IPA).
/// Web và mobile dùng chung; tap vào nhóm → màn danh sách topic của nhóm đó.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ghi Nhớ Từ Vựng'),
        actions: [
          IconButton(
            icon: const Icon(Icons.analytics_outlined),
            tooltip: 'Tiến trình',
            onPressed: () => Navigator.pushNamed(context, '/progress'),
          ),
        ],
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
                child: isNarrow ? _buildMobileGrid(context, provider) : _buildWebGrid(context, provider),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildMobileGrid(BuildContext context, VocabProvider provider) {
    return GridView.count(
      crossAxisCount: 2,
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 0.95,
      padding: const EdgeInsets.only(bottom: 24),
      children: kCategories.map((cat) => _CategoryCard(
        category: cat,
        topicCount: cat.id == CategoryIds.grade
            ? provider.topics.where((t) => t.categoryId == CategoryIds.grade).length
            : provider.getTopicsByCategory(cat.id).length,
        onTap: () {
          if (cat.id == CategoryIds.grade) {
            Navigator.pushNamed(context, '/grade-levels');
          } else {
            Navigator.pushNamed(
              context,
              '/category-topics',
              arguments: cat.id,
            );
          }
        },
      )).toList(),
    );
  }

  Widget _buildWebGrid(BuildContext context, VocabProvider provider) {
    return GridView.count(
      crossAxisCount: kIsWeb ? 3 : 2,
      mainAxisSpacing: 16,
      crossAxisSpacing: 16,
      childAspectRatio: 1.1,
      padding: const EdgeInsets.only(bottom: 24),
      children: kCategories.map((cat) => _CategoryCard(
        category: cat,
        topicCount: cat.id == CategoryIds.grade
            ? provider.topics.where((t) => t.categoryId == CategoryIds.grade).length
            : provider.getTopicsByCategory(cat.id).length,
        onTap: () {
          if (cat.id == CategoryIds.grade) {
            Navigator.pushNamed(context, '/grade-levels');
          } else {
            Navigator.pushNamed(
              context,
              '/category-topics',
              arguments: cat.id,
            );
          }
        },
      )).toList(),
    );
  }
}

class _CategoryCard extends StatelessWidget {
  final AppCategory category;
  final int topicCount;
  final VoidCallback onTap;

  const _CategoryCard({
    required this.category,
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
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                category.icon,
                size: 48,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(height: 12),
              Text(
                category.name,
                textAlign: TextAlign.center,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),
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
