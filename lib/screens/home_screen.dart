import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

import '../models/topic.dart';
import '../providers/vocab_provider.dart';
import 'add_edit_topic_dialog.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ghi Nhớ Từ Vựng'),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (value) async {
              if (value == 'progress') {
                Navigator.pushNamed(context, '/progress');
              } else if (value == 'reset') {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (_) => AlertDialog(
                    title: const Text('Reset dữ liệu?'),
                    content: const Text(
                      'Xóa toàn bộ dữ liệu và load lại demo (40 từ Gia đình, v.v.). Tiến trình học sẽ mất.',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text('Hủy'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(context, true),
                        child: Text('Reset', style: TextStyle(color: Colors.red[700])),
                      ),
                    ],
                  ),
                );
                if (confirm == true && context.mounted) {
                  await context.read<VocabProvider>().resetData();
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Đã reset dữ liệu')),
                    );
                  }
                }
              }
            },
            itemBuilder: (_) => [
              const PopupMenuItem(value: 'progress', child: Row(children: [Icon(Icons.analytics), SizedBox(width: 8), Text('Tiến trình')])),
              const PopupMenuItem(value: 'reset', child: Row(children: [Icon(Icons.refresh), SizedBox(width: 8), Text('Reset dữ liệu demo')])),
            ],
          ),
        ],
      ),
      body: Consumer<VocabProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.topics.isEmpty) {
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
                        Icon(Icons.menu_book, size: 80, color: Colors.grey[400]),
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
                itemCount: provider.topics.length,
                itemBuilder: (context, index) {
                  final topic = provider.topics[index];
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
                            final result = await showDialog<Topic>(
                              context: context,
                              builder: (_) => AddEditTopicDialog(topic: topic),
                            );
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
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await showDialog<Topic>(
            context: context,
            builder: (_) => AddEditTopicDialog(
              topic: Topic(
                id: const Uuid().v4(),
                name: '',
                description: '',
              ),
            ),
          );
          if (result != null && result.name.isNotEmpty) {
            context.read<VocabProvider>().addTopic(result);
          }
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
