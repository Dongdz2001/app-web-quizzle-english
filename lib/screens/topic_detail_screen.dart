import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

import '../models/vocabulary.dart';
import '../providers/vocab_provider.dart';
import '../widgets/topic_cloud_view.dart';
import 'add_edit_word_dialog.dart';

class TopicDetailScreen extends StatefulWidget {
  const TopicDetailScreen({super.key});

  @override
  State<TopicDetailScreen> createState() => _TopicDetailScreenState();
}

class _TopicDetailScreenState extends State<TopicDetailScreen> {
  @override
  void initState() {
    super.initState();
    if (!kIsWeb) {
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);
    }
  }

  @override
  void dispose() {
    if (!kIsWeb) {
      SystemChrome.setPreferredOrientations(DeviceOrientation.values);
    }
    super.dispose();
  }

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
        if (topic == null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (context.mounted) Navigator.pop(context);
          });
          return const SizedBox();
        }

        return Scaffold(
          appBar: AppBar(
            title: Text(topic.name),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => Navigator.pop(context),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.play_circle_outline),
                onPressed: topic.words.isEmpty
                    ? null
                    : () => Navigator.pushNamed(
                          context,
                          '/learn',
                          arguments: topicId,
                        ),
              ),
              IconButton(
                icon: Icon(Icons.extension),
                onPressed: topic.words.isEmpty
                    ? null
                    : () => Navigator.pushNamed(
                          context,
                          '/practice',
                          arguments: topicId,
                        ),
              ),
              IconButton(
                icon: const Icon(Icons.quiz_outlined),
                onPressed: topic.words.isEmpty
                    ? null
                    : () => Navigator.pushNamed(
                          context,
                          '/quiz',
                          arguments: topicId,
                        ),
              ),
            ],
          ),
          body: Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 900),
              child: Column(
                children: [
                  if ((topic.description?.isNotEmpty ?? false))
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                      alignment: Alignment.centerLeft,
                      child: Text(
                        topic.description!,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ),
                  _buildActionButtons(context, topicId, topic.words),
                  Expanded(
                    child: topic.words.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.book_outlined, size: 64, color: Colors.grey[400]),
                                const SizedBox(height: 16),
                                Text(
                                  'Chưa có từ vựng nào',
                                  style: Theme.of(context).textTheme.titleMedium,
                                ),
                                const SizedBox(height: 8),
                                ElevatedButton.icon(
                                  onPressed: () => _showAddWordDialog(context, provider, topicId),
                                  icon: const Icon(Icons.add),
                                  label: const Text('Thêm từ vựng'),
                                ),
                              ],
                            ),
                          )
                        : TopicCloudView(
                            topicName: topic.name,
                            words: topic.words,
                            onWordTap: (word) => _showEditWordDialog(
                                context, provider, topicId, word),
                            onWordLongPress: (word) => _showWordContextMenu(
                                context, provider, topicId, word),
                          ),
                  ),
                ],
              ),
            ),
          ),
          floatingActionButton: FloatingActionButton(
            onPressed: () => _showAddWordDialog(context, provider, topicId),
            child: const Icon(Icons.add),
          ),
        );
      },
    );
  }

  Widget _buildActionButtons(BuildContext context, String topicId, List<Vocabulary> words) {
    if (words.isEmpty) return const SizedBox();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest.withAlpha(128),
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () => Navigator.pushNamed(context, '/learn', arguments: topicId),
              icon: const Icon(Icons.school),
              label: const Text('Học'),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () => Navigator.pushNamed(context, '/practice', arguments: topicId),
              icon: Icon(Icons.extension),
              label: const Text('Luyện tập'),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () => Navigator.pushNamed(context, '/quiz', arguments: topicId),
              icon: const Icon(Icons.quiz),
              label: const Text('Quiz'),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showAddWordDialog(BuildContext context, VocabProvider provider, String topicId) async {
    final result = await showDialog<Vocabulary>(
      context: context,
      builder: (_) => AddEditWordDialog(
        word: Vocabulary(
          id: Uuid().v4(),
          word: '',
          meaning: '',
        ),
      ),
    );
    if (result != null && result.word.isNotEmpty && result.meaning.isNotEmpty) {
      final added = await provider.addWord(topicId, result);
      if (!added && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Từ này đã tồn tại trong chủ đề')),
        );
      }
    }
  }

  void _showWordContextMenu(
    BuildContext context,
    VocabProvider provider,
    String topicId,
    Vocabulary word,
  ) {
    showModalBottomSheet(
      context: context,
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit),
              title: const Text('Sửa'),
              onTap: () {
                Navigator.pop(context);
                _showEditWordDialog(context, provider, topicId, word);
              },
            ),
            ListTile(
              leading: Icon(Icons.delete, color: Colors.red[400]),
              title: Text('Xóa', style: TextStyle(color: Colors.red[700])),
              onTap: () {
                Navigator.pop(context);
                _confirmDelete(context, provider, topicId, word);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showEditWordDialog(
    BuildContext context,
    VocabProvider provider,
    String topicId,
    Vocabulary word,
  ) async {
    final result = await showDialog<Vocabulary>(
      context: context,
      builder: (_) => AddEditWordDialog(word: word),
    );
    if (result != null) {
      provider.updateWord(topicId, result);
    }
  }

  Future<void> _confirmDelete(
    BuildContext context,
    VocabProvider provider,
    String topicId,
    Vocabulary word,
  ) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Xóa từ vựng?'),
        content: Text('Bạn có chắc muốn xóa "${word.word}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Xóa', style: TextStyle(color: Colors.red[700])),
          ),
        ],
      ),
    );
    if (confirm == true) {
      provider.deleteWord(topicId, word.id);
    }
  }
}
