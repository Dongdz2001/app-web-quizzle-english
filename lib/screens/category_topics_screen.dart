import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show SystemChrome, DeviceOrientation;
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

import '../data/categories.dart';
import '../models/topic.dart';
import '../providers/vocab_provider.dart';
import 'add_edit_topic_dialog.dart';

/// Màn danh sách topic của một nhóm (category) — từ HomeScreen tap vào nhóm → vào đây.
/// Web và mobile dùng chung; hiển thị danh sách topic, có thể thêm/sửa/xóa topic trong nhóm này.
class CategoryTopicsScreen extends StatelessWidget {
  const CategoryTopicsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)!.settings.arguments;
    String? categoryId;
    int? gradeLevel;

    if (args is String) {
      categoryId = args;
    } else if (args is Map<String, dynamic>) {
      categoryId = args['categoryId'] as String?;
      gradeLevel = args['gradeLevel'] as int?;
    }

    if (categoryId == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) Navigator.pop(context);
      });
      return const Scaffold(body: SizedBox());
    }

    final category = kCategories.firstWhere(
      (c) => c.id == categoryId,
      orElse: () => kCategories.first,
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(gradeLevel != null ? 'Lớp $gradeLevel' : category.name),
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

          // Nếu là "Từ vựng theo lớp" và chưa chọn lớp → hiển thị 12 lớp để chọn
          if (categoryId == CategoryIds.grade && gradeLevel == null) {
            return _buildGradeLevelsGrid(context, provider);
          }

          final topics = gradeLevel != null
              ? provider.getTopicsByGradeLevel(gradeLevel)
              : provider.getTopicsByCategory(categoryId!);

          if (topics.isEmpty) {
            return Align(
              alignment: Alignment.topCenter,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 900),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(category.icon, size: 80, color: Colors.grey[400]),
                        const SizedBox(height: 16),
                        Text(
                          'Chưa có topic nào',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Nhấn + để thêm topic mới',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }

          return Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 900),
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: topics.length,
                itemBuilder: (context, index) {
                  final topic = topics[index];
                  final progress = provider.progress[topic.id];
                  final hasDescription = (topic.description?.isNotEmpty ?? false);

                  Widget? subtitle;
                  if (hasDescription || progress != null) {
                    subtitle = Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (hasDescription)
                          Text(
                            topic.description!,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: Colors.grey[700],
                            ),
                          ),
                        if (progress != null) ...[
                          const SizedBox(height: 8),
                          LinearProgressIndicator(
                            value: progress.progressPercent,
                            backgroundColor: Colors.grey[300],
                          ),
                        ],
                      ],
                    );
                  }
                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: ListTile(
                      contentPadding: const EdgeInsets.all(16),
                      leading: CircleAvatar(
                        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                        child: Text(
                          '${topic.words.length}',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.onPrimaryContainer,
                          ),
                        ),
                      ),
                      title: Text(
                        topic.name,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: subtitle,
                      trailing: PopupMenuButton<String>(
                        onSelected: (value) async {
                          if (value == 'edit') {
                            if (!kIsWeb) {
                              await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
                            }
                            final result = await showDialog<Topic>(
                              context: context,
                              builder: (_) => AddEditTopicDialog(topic: topic),
                            );
                            if (!kIsWeb) {
                              SystemChrome.setPreferredOrientations(DeviceOrientation.values);
                            }
                            if (result != null) {
                              provider.updateTopic(result);
                            }
                          } else if (value == 'delete') {
                            final confirm = await showDialog<bool>(
                              context: context,
                              builder: (_) => AlertDialog(
                                title: const Text('Xóa topic?'),
                                content: Text(
                                  'Bạn có chắc muốn xóa "${topic.name}"?',
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(context, false),
                                    child: const Text('Hủy'),
                                  ),
                                  TextButton(
                                    onPressed: () => Navigator.pop(context, true),
                                    child: Text(
                                      'Xóa',
                                      style: TextStyle(color: Colors.red[700]),
                                    ),
                                  ),
                                ],
                              ),
                            );
                            if (confirm == true) {
                              provider.deleteTopic(topic.id);
                            }
                          }
                        },
                        itemBuilder: (_) => [
                          const PopupMenuItem(
                            value: 'edit',
                            child: Row(
                              children: [
                                Icon(Icons.edit),
                                SizedBox(width: 8),
                                Text('Sửa'),
                              ],
                            ),
                          ),
                          const PopupMenuItem(
                            value: 'delete',
                            child: Row(
                              children: [
                                Icon(Icons.delete, color: Colors.red),
                                SizedBox(width: 8),
                                Text('Xóa', style: TextStyle(color: Colors.red)),
                              ],
                            ),
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
                },
              ),
            ),
          );
        },
      ),
      floatingActionButton: categoryId == CategoryIds.grade && gradeLevel == null
          ? null
          : FloatingActionButton(
              onPressed: () async {
                if (!kIsWeb) {
                  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
                }
                final provider = context.read<VocabProvider>();
                final result = await showDialog<Topic>(
                  context: context,
                  builder: (_) => AddEditTopicDialog(
                    topic: Topic(
                      id: const Uuid().v4(),
                      name: '',
                      description: '',
                      categoryId: categoryId!,
                      gradeLevel: gradeLevel,
                      classCode: provider.userClassCode,
                    ),
                  ),
                );
                if (!kIsWeb) {
                  SystemChrome.setPreferredOrientations(DeviceOrientation.values);
                }
                if (result != null && result.name.isNotEmpty) {
                  context.read<VocabProvider>().addTopic(result);
                }
              },
              child: const Icon(Icons.add),
            ),
    );
  }

  Widget _buildGradeLevelsGrid(BuildContext context, VocabProvider provider) {
    final isNarrow = MediaQuery.of(context).size.width < 600;
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 900),
        child: Padding(
          padding: EdgeInsets.all(isNarrow ? 16 : 24),
          child: isNarrow
              ? GridView.count(
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
                      onTap: () => Navigator.pushReplacementNamed(
                        context,
                        '/category-topics',
                        arguments: {'categoryId': CategoryIds.grade, 'gradeLevel': grade},
                      ),
                    );
                  }),
                )
              : GridView.count(
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
                      onTap: () => Navigator.pushReplacementNamed(
                        context,
                        '/category-topics',
                        arguments: {'categoryId': CategoryIds.grade, 'gradeLevel': grade},
                      ),
                    );
                  }),
                ),
        ),
      ),
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
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.school,
                size: 40,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(height: 8),
              Text(
                'Lớp $grade',
                textAlign: TextAlign.center,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
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
