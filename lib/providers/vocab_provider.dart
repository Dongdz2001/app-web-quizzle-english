import 'package:flutter/foundation.dart';

import '../models/learning_progress.dart';
import '../models/topic.dart';
import '../models/vocabulary.dart';
import '../services/storage_service.dart';

class VocabProvider extends ChangeNotifier {
  final StorageService _storage = StorageService();

  List<Topic> _topics = [];
  Map<String, LearningProgress> _progress = {};
  bool _isLoading = true;

  List<Topic> get topics => _topics;
  Map<String, LearningProgress> get progress => _progress;
  bool get isLoading => _isLoading;

  Future<void> loadData() async {
    _isLoading = true;
    notifyListeners();

    await _storage.init();
    await _storage.seedDemoData();
    _topics = await _storage.getTopics();
    _progress = await _storage.getProgress();

    for (final topic in _topics) {
      if (!_progress.containsKey(topic.id)) {
        _progress[topic.id] = LearningProgress(
          topicId: topic.id,
          totalWords: topic.words.length,
        );
      } else {
        _progress[topic.id]!.totalWords = topic.words.length;
      }
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> addTopic(Topic topic) async {
    _topics.add(topic);
    _progress[topic.id] = LearningProgress(
      topicId: topic.id,
      totalWords: topic.words.length,
    );
    await _storage.saveTopics(_topics);
    await _storage.saveProgress(_progress);
    notifyListeners();
  }

  Future<void> updateTopic(Topic topic) async {
    final index = _topics.indexWhere((t) => t.id == topic.id);
    if (index >= 0) {
      _topics[index] = topic;
      _progress[topic.id]!.totalWords = topic.words.length;
      await _storage.saveTopics(_topics);
      await _storage.saveProgress(_progress);
      notifyListeners();
    }
  }

  Future<void> deleteTopic(String topicId) async {
    _topics.removeWhere((t) => t.id == topicId);
    _progress.remove(topicId);
    await _storage.saveTopics(_topics);
    await _storage.saveProgress(_progress);
    notifyListeners();
  }

  Topic? getTopic(String id) {
    try {
      return _topics.firstWhere((t) => t.id == id);
    } catch (_) {
      return null;
    }
  }

  /// Thêm từ vựng vào 1 chủ đề.
  /// Trả về `true` nếu thêm thành công, `false` nếu từ đã tồn tại.
  Future<bool> addWord(String topicId, Vocabulary word) async {
    final topic = getTopic(topicId);
    if (topic == null) return false;

    // Kiểm tra trùng theo từ tiếng Anh (không phân biệt hoa thường, đã trim)
    final newWord = word.word.trim().toLowerCase();
    final exists = topic.words.any(
      (w) => w.word.trim().toLowerCase() == newWord,
    );

    if (exists) {
      return false;
    }

    topic.words.add(word);
    _progress[topicId]!.totalWords = topic.words.length;
    await _storage.saveTopics(_topics);
    await _storage.saveProgress(_progress);
    notifyListeners();

    return true;
  }

  Future<void> updateWord(String topicId, Vocabulary word) async {
    final topic = getTopic(topicId);
    if (topic != null) {
      final index = topic.words.indexWhere((w) => w.id == word.id);
      if (index >= 0) {
        topic.words[index] = word;
        await _storage.saveTopics(_topics);
        notifyListeners();
      }
    }
  }

  Future<void> deleteWord(String topicId, String wordId) async {
    final topic = getTopic(topicId);
    if (topic != null) {
      topic.words.removeWhere((w) => w.id == wordId);
      _progress[topicId]!.totalWords = topic.words.length;
      await _storage.saveTopics(_topics);
      await _storage.saveProgress(_progress);
      notifyListeners();
    }
  }

  void updateProgress(String topicId, {int correct = 0, int wrong = 0}) {
    final p = _progress[topicId];
    if (p != null) {
      p.correctCount += correct;
      p.wrongCount += wrong;
      p.learnedWords = (p.learnedWords + correct + wrong).clamp(0, p.totalWords);
      p.lastStudyTime = DateTime.now();
      _storage.saveProgress(_progress);
      notifyListeners();
    }
  }

  Future<void> saveProgress() async {
    await _storage.saveProgress(_progress);
    notifyListeners();
  }
}
