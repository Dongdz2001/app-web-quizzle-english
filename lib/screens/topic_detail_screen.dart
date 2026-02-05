import 'dart:async';

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
  /// Trên mobile landscape: true = hiện AppBar, false = ẩn (vuốt xuống để hiện).
  bool _appBarVisible = false;
  Timer? _hideAppBarTimer;

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
    _hideAppBarTimer?.cancel();
    if (!kIsWeb) {
      SystemChrome.setPreferredOrientations(DeviceOrientation.values);
    }
    super.dispose();
  }

  void _showAppBarTemporarily() {
    if (!mounted) return;
    setState(() => _appBarVisible = true);
    _hideAppBarTimer?.cancel();
    _hideAppBarTimer = Timer(const Duration(seconds: 4), () {
      if (mounted) setState(() => _appBarVisible = false);
    });
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

        final isLandscape = MediaQuery.of(context).orientation == Orientation.landscape;
        final hideAppBarInLandscape = !kIsWeb && isLandscape && !_appBarVisible;

        return Scaffold(
          appBar: hideAppBarInLandscape
              ? null
              : _buildAppBar(context, topic.name, topicId, topic.words.isEmpty),
          body: Column(
                children: [
                  // Chạm vào vùng trên (landscape mobile) để hiện lại AppBar — dùng tap thay vì vuốt xuống để tránh trùng cử chỉ hệ thống
                  if (isLandscape && !kIsWeb)
                    GestureDetector(
                      onTap: _showAppBarTemporarily,
                      behavior: HitTestBehavior.translucent,
                      child: SizedBox(
                        height: 48,
                        width: double.infinity,
                        child: Center(
                          child: _appBarVisible
                              ? null
                              : Icon(
                                  Icons.keyboard_arrow_down,
                                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
                                  size: 28,
                                ),
                        ),
                      ),
                    ),
                  // Vùng đám mây: không giới hạn maxWidth, full màn hình để InteractiveViewer tự do
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
                        : LayoutBuilder(
                            builder: (context, constraints) {
                              final vw = constraints.maxWidth;
                              final vh = constraints.maxHeight;
                              final count = topic.words.length;
                              // Canvas tăng theo số từ, không giới hạn: zoom + drag để xem hết
                              double scale = 1.0;
                              if (count > 8) {
                                scale = 1.0 + (count - 8) * 0.06; // 40 từ ~2.9x, 60 từ ~4.1x
                              }
                              scale = scale.clamp(1.0, 10.0);
                              final cw = vw * scale * 1.35; // mở rộng ngang hơn để không bị kẹt
                              final ch = vh * scale;
                              return InteractiveViewer(
                                minScale: 0.3,
                                maxScale: 4.0,
                                boundaryMargin: const EdgeInsets.all(1000),
                                clipBehavior: Clip.none,
                                child: SizedBox(
                                  width: cw,
                                  height: ch,
                                  child: TopicCloudView(
                                    topicName: topic.name,
                                    words: topic.words,
                                    onWordTap: (word) => _showEditWordDialog(
                                        context, provider, topicId, word),
                                    onWordLongPress: (word) => _showWordContextMenu(
                                        context, provider, topicId, word),
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
                ],
          ),
          floatingActionButton: FloatingActionButton(
            onPressed: () => _showAddWordDialog(context, provider, topicId),
            child: const Icon(Icons.add),
          ),
        );
      },
    );
  }

  PreferredSizeWidget _buildAppBar(
    BuildContext context,
    String topicName,
    String topicId,
    bool wordsEmpty,
  ) {
    return AppBar(
      title: Text(topicName),
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: () => Navigator.pop(context),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.school_outlined),
          tooltip: 'Học',
          onPressed: wordsEmpty
              ? null
              : () => Navigator.pushNamed(context, '/learn', arguments: topicId),
        ),
        IconButton(
          icon: const Icon(Icons.fitness_center_outlined),
          tooltip: 'Luyện tập',
          onPressed: wordsEmpty
              ? null
              : () => Navigator.pushNamed(context, '/practice', arguments: topicId),
        ),
        IconButton(
          icon: const Icon(Icons.quiz_outlined),
          tooltip: 'Quiz',
          onPressed: wordsEmpty
              ? null
              : () => Navigator.pushNamed(context, '/quiz', arguments: topicId),
        ),
      ],
    );
  }

  Future<void> _showAddWordDialog(BuildContext context, VocabProvider provider, String topicId) async {
    if (!kIsWeb) {
      await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    }
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
    if (!kIsWeb) {
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);
    }
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
    if (!kIsWeb) {
      await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    }
    final result = await showDialog<Vocabulary>(
      context: context,
      builder: (_) => AddEditWordDialog(word: word),
    );
    if (!kIsWeb) {
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);
    }
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
