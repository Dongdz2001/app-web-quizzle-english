import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show RenderBox, RenderStack;
import 'package:flutter_tts/flutter_tts.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

import '../models/topic.dart';
import '../models/vocabulary.dart';
import '../providers/vocab_provider.dart';
import '../utils/web_speech_stub.dart'
    if (dart.library.html) '../utils/web_speech.dart'
    as web_speech;
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

  /// Tooltip nổi ngay dưới con trỏ (web), không bị zoom.
  String? _guideText;
  Offset? _guidePosition;

  final FlutterTts _flutterTts = FlutterTts();
  final AudioPlayer _audioPlayer = AudioPlayer();

  @override
  void initState() {
    super.initState();
    _initTts();
  }

  @override
  void dispose() {
    _hideAppBarTimer?.cancel();
    try {
      _flutterTts.stop();
    } catch (_) {}
    try {
      _audioPlayer.dispose();
    } catch (_) {}
    super.dispose();
  }

  Future<void> _initTts() async {
    try {
      await _flutterTts.setLanguage('en-US');
      await _flutterTts.setSpeechRate(0.45);
    } catch (_) {
      // Trên web/một số thiết bị có thể không hỗ trợ đầy đủ
    }
  }

  /// Google TTS URL (miễn phí, dùng trên mobile — không CORS).
  static String _googleTtsUrl(String text, {String tl = 'en'}) {
    final q = Uri.encodeComponent(text);
    return 'https://translate.google.com/translate_tts?ie=UTF-8&q=$q&tl=$tl&client=tw-ob';
  }

  /// Click đơn: web = Web Speech API, mobile = Google TTS URL rồi FlutterTts.
  Future<void> _speakWord(Vocabulary word) async {
    try {
      await _flutterTts.stop();
    } catch (_) {}
    try {
      await _audioPlayer.stop();
    } catch (_) {}

    try {
      if (kIsWeb) {
        final ok = await web_speech.speakText(word.word, lang: 'en-US');
        if (ok) return;
      } else {
        await _audioPlayer.play(UrlSource(_googleTtsUrl(word.word, tl: 'en')));
        return;
      }
    } catch (_) {}

    try {
      await _flutterTts.speak(word.word);
    } catch (_) {}
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
      builder: (BuildContext context, VocabProvider provider, Widget? _) {
        final topic = provider.getTopic(topicId);
        if (topic == null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (context.mounted) Navigator.pop(context);
          });
          return const SizedBox();
        }

        final width = MediaQuery.of(context).size.width;
        final isMobile = width < 600;
        final isLandscape =
            MediaQuery.of(context).orientation == Orientation.landscape;

        // Hide AppBar in landscape on mobile only if using cloud view (not list view)
        final hideAppBarInLandscape =
            !kIsWeb && isLandscape && !_appBarVisible && !isMobile;

        return Scaffold(
          extendBodyBehindAppBar: kIsWeb,
          appBar: hideAppBarInLandscape
              ? null
              : _buildAppBar(context, topic, topicId),
          body: Stack(
            children: [
              if (kIsWeb)
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.blue.shade100,
                          Colors.blue.shade50,
                        ],
                      ),
                    ),
                  ),
                ),
              Column(
                children: [
                  if (kIsWeb) const SizedBox(height: kToolbarHeight + 20),
                  // App bar reveal gesture (only for landscape cloud view)
                  if (!isMobile && isLandscape && !kIsWeb)
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
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurface.withOpacity(0.5),
                                  size: 28,
                                ),
                        ),
                      ),
                    ),

                  // Main Content
                  Expanded(
                    child: topic.words.isEmpty
                        ? _buildEmptyState(context, provider, topicId)
                        : (isMobile
                              ? _buildMobileListView(
                                  context,
                                  provider,
                                  topicId,
                                  topic.words,
                                )
                              : _buildCloudView(
                                  context,
                                  provider,
                                  topicId,
                                  topic,
                                )),
                  ),
                ],
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

  Widget _buildEmptyState(
    BuildContext context,
    VocabProvider provider,
    String topicId,
  ) {
    return Center(
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
    );
  }

  Widget _buildMobileListView(
    BuildContext context,
    VocabProvider provider,
    String topicId,
    List<Vocabulary> words,
  ) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: words.length,
      itemBuilder: (context, index) {
        final word = words[index];
        return Card(
          elevation: 2,
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 8,
            ),
            title: Text(
              word.word,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.blue,
              ),
            ),
            trailing: IconButton(
              icon: const Icon(Icons.info_outline, color: Colors.indigo),
              onPressed: () => _showWordMeaning(context, word),
            ),
            onTap: () => _speakWord(word).catchError((_) {}),
            onLongPress: () =>
                _showWordContextMenu(context, provider, topicId, word),
          ),
        );
      },
    );
  }

  void _showWordMeaning(BuildContext context, Vocabulary word) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          word.word,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.blue,
            fontSize: 24,
          ),
          textAlign: TextAlign.center,
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Divider(),
              const SizedBox(height: 16),

              // Meaning (Tiếng Việt)
              _buildDetailInfoItem(
                context,
                label: 'Nghĩa Tiếng Việt',
                content: word.meaning,
                icon: Icons.translate,
                color: Colors.indigo,
              ),

              // Word forms (N, V, Adj, Adv)
              if ((word.noun ?? '').isNotEmpty ||
                  (word.verb ?? '').isNotEmpty ||
                  (word.adjective ?? '').isNotEmpty ||
                  (word.adverb ?? '').isNotEmpty)
                _buildDetailInfoItem(
                  context,
                  label: 'Loại từ & Từ loại khác',
                  content: [
                    if ((word.noun ?? '').isNotEmpty) "Noun: ${word.noun}",
                    if ((word.verb ?? '').isNotEmpty) "Verb: ${word.verb}",
                    if ((word.adjective ?? '').isNotEmpty)
                      "Adj: ${word.adjective}",
                    if ((word.adverb ?? '').isNotEmpty) "Adv: ${word.adverb}",
                  ].join('\n'),
                  icon: Icons.category,
                  color: Colors.orange,
                ),

              // Verb forms (v-ed, v-ing, v-s/es)
              if ((word.vEd ?? '').isNotEmpty ||
                  (word.vIng ?? '').isNotEmpty ||
                  (word.vSes ?? '').isNotEmpty)
                _buildDetailInfoItem(
                  context,
                  label: 'Dạng của động từ',
                  content: [
                    if ((word.vEd ?? '').isNotEmpty) "V-ed: ${word.vEd}",
                    if ((word.vIng ?? '').isNotEmpty) "V-ing: ${word.vIng}",
                    if ((word.vSes ?? '').isNotEmpty) "V-s/es: ${word.vSes}",
                  ].join('\n'),
                  icon: Icons.extension,
                  color: Colors.teal,
                ),

              // English Definition
              if (word.englishDefinition != null &&
                  word.englishDefinition!.isNotEmpty)
                _buildDetailInfoItem(
                  context,
                  label: 'Phiên âm',
                  content: word.englishDefinition!,
                  backgroundColor: Colors.blue[50], // Highlight
                  icon: Icons.phonelink_ring,
                  color: Colors.blue,
                ),

              // Synonym (Từ đồng nghĩa)
              if (word.synonym != null && word.synonym!.isNotEmpty)
                _buildDetailInfoItem(
                  context,
                  label: 'Từ đồng nghĩa',
                  content: word.synonym!,
                  icon: Icons.compare_arrows,
                  color: Colors.green,
                ),

              // Antonym (Từ trái nghĩa)
              if (word.antonym != null && word.antonym!.isNotEmpty)
                _buildDetailInfoItem(
                  context,
                  label: 'Từ trái nghĩa',
                  content: word.antonym!,
                  icon: Icons.swap_horiz,
                  color: Colors.red,
                ),

              // Creator Info
              if (word.createdBy?.userName != null &&
                  word.createdBy!.userName!.isNotEmpty)
                _buildDetailInfoItem(
                  context,
                  label: 'Người tạo',
                  content: word.createdBy!.userName!,
                  icon: Icons.person_outline,
                  color: Colors.teal,
                ),

              // Created At
              if (word.createdAt != null)
                _buildDetailInfoItem(
                  context,
                  label: 'Ngày tạo',
                  content:
                      "${word.createdAt!.day}/${word.createdAt!.month}/${word.createdAt!.year}",
                  icon: Icons.calendar_today_outlined,
                  color: Colors.blueGrey,
                ),

              const SizedBox(height: 16),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Đóng', style: TextStyle(fontSize: 16)),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailInfoItem(
    BuildContext context, {
    required String label,
    required String content,
    IconData? icon,
    Color? color,
    Color? backgroundColor,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: backgroundColor ?? Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (icon != null) ...[
                Icon(icon, size: 18, color: color ?? Colors.grey[700]),
                const SizedBox(width: 8),
              ],
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: color ?? Colors.grey[700],
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            content,
            style: const TextStyle(
              fontSize: 16,
              height: 1.4,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCloudView(
    BuildContext context,
    VocabProvider provider,
    String topicId,
    dynamic topic,
  ) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final vw = constraints.maxWidth;
        final vh = constraints.maxHeight;
        final count = topic.words.length;
        // Canvas tăng theo số từ, không giới hạn: zoom + drag để xem hết
        double scale = 1.0;
        if (count > 8) {
          scale = 1.0 + (count - 8) * 0.06; // 40 từ ~2.9x, 60 từ ~4.1x
        }
        scale = scale.clamp(1.0, 10.0);
        final extraW = kIsWeb ? 0.0 : (vw * scale * 0.2);
        final extraH = kIsWeb ? 0.0 : (vh * scale * 0.2);
        final cw =
            vw * scale * 1.35 + extraW * 2; // mở rộng ngang hơn để không bị kẹt
        final ch = vh * scale + extraH * 2;
        return Stack(
          clipBehavior: Clip.none,
          children: [
            InteractiveViewer(
              minScale: 0.3,
              maxScale: 4.0,
              boundaryMargin: const EdgeInsets.all(1000),
              clipBehavior: Clip.none,
              child: SizedBox(
                width: cw,
                height: ch,
                child: TopicCloudView(
                  topicName: topic.displayName ?? topic.name,
                  words: topic.words,
                  categoryId: topic.categoryId,
                  onWordTap: (word) {
                    _speakWord(word).catchError((_) {});
                  },
                  onWordDoubleTap: (word) =>
                      _showEditWordDialog(context, provider, topicId, word),
                  onWordLongPress: (word) =>
                      _showWordContextMenu(context, provider, topicId, word),
                  onGuideTextChanged: kIsWeb
                      ? (String? text, Offset? position) => setState(() {
                          _guideText = text;
                          _guidePosition = position;
                        })
                      : null,
                ),
              ),
            ),
            if (kIsWeb)
              Positioned.fill(
                child: IgnorePointer(
                  child: Builder(
                    builder: (BuildContext context) {
                      try {
                        if (_guideText == null) return const SizedBox.shrink();
                        final stackBox =
                            context
                                    .findAncestorRenderObjectOfType<
                                      RenderStack
                                    >()
                                as RenderBox?;
                        final localPos =
                            stackBox != null && _guidePosition != null
                            ? stackBox.globalToLocal(_guidePosition!)
                            : null;
                        if (localPos == null) return const SizedBox.shrink();
                        const offsetBelowCursor = 16.0;
                        return Stack(
                          clipBehavior: Clip.none,
                          children: [
                            Positioned(
                              left: localPos.dx,
                              top: localPos.dy + offsetBelowCursor,
                              child: TopicCloudGuideHint(text: _guideText),
                            ),
                          ],
                        );
                      } catch (_) {
                        return const SizedBox.shrink();
                      }
                    },
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  PreferredSizeWidget _buildAppBar(
    BuildContext context,
    Topic topic,
    String topicId,
  ) {
    final wordsEmpty = topic.words.isEmpty;
    return AppBar(
      backgroundColor: kIsWeb ? Colors.transparent : null,
      elevation: kIsWeb ? 0 : null,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: () => Navigator.pop(context),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.bar_chart),
          tooltip: 'Thống kê đóng góp',
          onPressed: () => _showTopicStatsDialog(context, topic),
        ),
        IconButton(
          icon: const Icon(Icons.school_outlined),
          tooltip: 'Học',
          onPressed: wordsEmpty
              ? null
              : () =>
                    Navigator.pushNamed(context, '/learn', arguments: topicId),
        ),
        IconButton(
          icon: const Icon(Icons.fitness_center_outlined),
          tooltip: 'Luyện tập',
          onPressed: wordsEmpty
              ? null
              : () => Navigator.pushNamed(
                  context,
                  '/practice',
                  arguments: topicId,
                ),
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

  Future<void> _showTopicStatsDialog(BuildContext context, Topic topic) async {
    showDialog(
      context: context,
      builder: (ctx) => FutureBuilder<List<Map<String, dynamic>>>(
        future: _loadTopicContributions(topic),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return AlertDialog(
              content: const SizedBox(
                width: 320,
                height: 200,
                child: Center(child: CircularProgressIndicator()),
              ),
            );
          }
          if (snapshot.hasError) {
            return AlertDialog(
              title: const Text('Lỗi'),
              content: Text('Không thể tải thống kê: ${snapshot.error}'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Đóng'),
                ),
              ],
            );
          }

          final data = snapshot.data ?? [];
          final maxCount = data.isEmpty ? 1 : data.map((e) => e['count'] as int).fold(0, (a, b) => a > b ? a : b);
          final maxWords = maxCount > 0 ? maxCount : 1;

          return AlertDialog(
            title: Row(
              children: [
                const Icon(Icons.bar_chart, color: Colors.blue),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Đóng góp trong ${topic.name}',
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            content: SizedBox(
              width: MediaQuery.of(ctx).size.width.clamp(320, 520),
              height: MediaQuery.of(ctx).size.height.clamp(220, 500),
              child: data.isEmpty
                  ? Center(
                      child: Text(
                        topic.classCode != null && topic.classCode!.isNotEmpty
                            ? 'Chưa có đóng góp nào trong topic này.'
                            : 'Topic này chưa có classCode để thống kê theo lớp.',
                        textAlign: TextAlign.center,
                      ),
                    )
                  : SizedBox(
                      width: (64 * data.length.clamp(0, 10)).toDouble(),
                      height: 260,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        mainAxisSize: MainAxisSize.min,
                        children: data.take(10).map((e) {
                          final name = e['name'] as String? ?? '?';
                          final count = e['count'] as int;
                          final ratio = count / maxWords;
                          final barHeight = (160 * ratio).clamp(count > 0 ? 6.0 : 0.0, 160.0);
                          final words = (name).split(' ');
                          final lines = <String>[];
                          for (var i = 0; i < words.length; i += 2) {
                            lines.add(words.skip(i).take(2).join(' '));
                          }
                          final nameDisplay = lines.join('\n');
                          return Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 6),
                            child: SizedBox(
                              width: 52,
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  Text(
                                    '$count',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: Theme.of(ctx).colorScheme.primary,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Container(
                                    width: 40,
                                    height: barHeight,
                                    decoration: BoxDecoration(
                                      color: Theme.of(ctx).colorScheme.primary.withOpacity(0.7),
                                      borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  SizedBox(
                                    height: 36,
                                    child: Align(
                                      alignment: Alignment.topCenter,
                                      child: Text(
                                        nameDisplay,
                                        style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w500),
                                        maxLines: 3,
                                        overflow: TextOverflow.ellipsis,
                                        textAlign: TextAlign.center,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Đóng'),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<List<Map<String, dynamic>>> _loadTopicContributions(Topic topic) async {
    final wordCountByUserId = <String, int>{};
    final userIdToNameFromWords = <String, String>{};
    for (final word in topic.words) {
      final userId = word.createdBy?.userId;
      if (userId != null) {
        wordCountByUserId[userId] = (wordCountByUserId[userId] ?? 0) + 1;
        if (!userIdToNameFromWords.containsKey(userId)) {
          userIdToNameFromWords[userId] = word.createdBy?.userName ?? word.createdBy?.userEmail ?? userId;
        }
      }
    }

    if (topic.classCode == null || topic.classCode!.isEmpty) {
      return wordCountByUserId.entries
          .map((e) => {'name': userIdToNameFromWords[e.key] ?? e.key, 'count': e.value})
          .toList()
        ..sort((a, b) => (b['count'] as int).compareTo(a['count'] as int));
    }

    final usersSnapshot = await FirebaseFirestore.instance
        .collection('users')
        .where('classCode', isEqualTo: topic.classCode)
        .get();

    final result = <Map<String, dynamic>>[];
    for (final doc in usersSnapshot.docs) {
      final data = doc.data();
      final userId = doc.id;
      final userName = data['userName'] as String? ?? data['userEmail'] as String? ?? 'Chưa có tên';
      final count = wordCountByUserId[userId] ?? 0;
      result.add({'name': userName, 'count': count});
    }

    result.sort((a, b) => (b['count'] as int).compareTo(a['count'] as int));
    return result;
  }

  Future<void> _showAddWordDialog(
    BuildContext context,
    VocabProvider provider,
    String topicId,
  ) async {
    final result = await showDialog<Vocabulary>(
      context: context,
      builder: (_) => AddEditWordDialog(
        word: Vocabulary(id: Uuid().v4(), word: '', meaning: ''),
      ),
    );
    if (result != null && result.word.trim().isNotEmpty) {
      final added = await provider.addWord(topicId, result);
      if (!added && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Từ này đã tồn tại trong chủ đề')),
        );
      }
    }
  }

  bool get _isAdmin {
    final user = FirebaseAuth.instance.currentUser;
    return user?.email?.toLowerCase() == 'adminchi@gmail.com';
  }

  void _showWordContextMenu(
    BuildContext context,
    VocabProvider provider,
    String topicId,
    Vocabulary word,
  ) {
    if (!_isAdmin) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Chỉ Admin mới có quyền sửa hoặc xóa từ vựng'),
        ),
      );
      return;
    }

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
    if (!_isAdmin) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Chỉ Admin mới có quyền sửa hoặc xóa từ vựng'),
        ),
      );
      return;
    }

    final result = await showDialog<Vocabulary>(
      context: context,
      builder: (_) => AddEditWordDialog(
        word: word,
        onDelete: (w) async => provider.deleteWord(topicId, w.id),
      ),
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
    if (!_isAdmin) return;

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
