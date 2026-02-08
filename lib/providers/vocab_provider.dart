import 'dart:async';
import 'package:flutter/foundation.dart';

import '../data/categories.dart';
import '../models/learning_progress.dart';
import '../models/topic.dart';
import '../models/vocabulary.dart';
import '../services/firebase_service.dart';

class VocabProvider extends ChangeNotifier {
  final FirebaseService _firebaseService = FirebaseService();

  List<Topic> _topics = [];
  Map<String, LearningProgress> _progress = {};
  bool _isLoading = true;
  StreamSubscription<List<Topic>>? _topicsSubscription;

  List<Topic> get topics => _topics;
  Map<String, LearningProgress> get progress => _progress;
  bool get isLoading => _isLoading;

  @override
  void dispose() {
    _topicsSubscription?.cancel();
    super.dispose();
  }

  /// Bắt đầu đồng bộ dữ liệu Realtime từ Firestore
  Future<void> loadData() async {
    // Hủy subscription cũ nếu có
    await _topicsSubscription?.cancel();

    _isLoading = true;
    notifyListeners();

    // Lắng nghe Stream từ Firestore (Realtime)
    _topicsSubscription = _firebaseService.topicsStream().listen(
      (updatedTopics) {
        _topics = updatedTopics;
        
        // Cập nhật progress dựa trên số lượng từ mới nhất
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
        notifyListeners(); // Thông báo cho UI vẽ lại (đám mây sẽ hiện từ mới ngay)
      },
      onError: (e) {
        print('Error in topics stream: $e');
        _isLoading = false;
        notifyListeners();
      },
    );
  }

  /// Thêm topic mới lên Firestore
  Future<void> addTopic(Topic topic) async {
    try {
      // Tạo topic trên Firestore và nhận lại topic kèm metadata
      final savedTopic = await _firebaseService.createTopic(topic);
      
      _topics.add(savedTopic);
      _progress[savedTopic.id] = LearningProgress(
        topicId: savedTopic.id,
        totalWords: savedTopic.words.length,
      );
      
      notifyListeners();
    } catch (e) {
      print('Error adding topic: $e');
      rethrow;
    }
  }

  /// Cập nhật topic trên Firestore
  Future<void> updateTopic(Topic topic) async {
    try {
      await _firebaseService.updateTopic(topic);
      
      final index = _topics.indexWhere((t) => t.id == topic.id);
      if (index >= 0) {
        _topics[index] = topic;
        _progress[topic.id]!.totalWords = topic.words.length;
        notifyListeners();
      }
    } catch (e) {
      print('Error updating topic: $e');
      rethrow;
    }
  }

  /// Xóa topic khỏi Firestore
  Future<void> deleteTopic(String topicId) async {
    try {
      await _firebaseService.deleteTopic(topicId);
      
      _topics.removeWhere((t) => t.id == topicId);
      _progress.remove(topicId);
      notifyListeners();
    } catch (e) {
      print('Error deleting topic: $e');
      rethrow;
    }
  }

  Topic? getTopic(String id) {
    try {
      return _topics.firstWhere((t) => t.id == id);
    } catch (_) {
      return null;
    }
  }

  /// Lấy danh sách topic theo nhóm (categoryId).
  List<Topic> getTopicsByCategory(String categoryId) {
    return _topics.where((t) => t.categoryId == categoryId).toList();
  }

  /// Lấy danh sách topic theo lớp (gradeLevel) — chỉ dùng cho categoryId = cat_grade.
  List<Topic> getTopicsByGradeLevel(int gradeLevel) {
    return _topics
        .where((t) => t.categoryId == CategoryIds.grade && t.gradeLevel == gradeLevel)
        .toList();
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

    try {
      // Gửi lên Firestore và nhận lại từ có đầy đủ thông tin người tạo (userName)
      final savedWord = await _firebaseService.addWordToTopic(topicId, word);
      
      topic.words.add(savedWord);
      _progress[topicId]!.totalWords = topic.words.length;
      notifyListeners();

      return true;
    } catch (e) {
      print('Error adding word: $e');
      return false;
    }
  }

  /// Cập nhật từ vựng
  Future<void> updateWord(String topicId, Vocabulary word) async {
    final topic = getTopic(topicId);
    if (topic != null) {
      final index = topic.words.indexWhere((w) => w.id == word.id);
      if (index >= 0) {
        try {
          await _firebaseService.updateWordInTopic(topicId, word);
          
          topic.words[index] = word;
          notifyListeners();
        } catch (e) {
          print('Error updating word: $e');
          rethrow;
        }
      }
    }
  }

  /// Xóa từ vựng
  Future<void> deleteWord(String topicId, String wordId) async {
    final topic = getTopic(topicId);
    if (topic != null) {
      try {
        await _firebaseService.deleteWordFromTopic(topicId, wordId);
        
        topic.words.removeWhere((w) => w.id == wordId);
        _progress[topicId]!.totalWords = topic.words.length;
        notifyListeners();
      } catch (e) {
        print('Error deleting word: $e');
        rethrow;
      }
    }
  }

  /// Cập nhật tiến trình học tập
  void updateProgress(String topicId, {int correct = 0, int wrong = 0}) {
    final p = _progress[topicId];
    if (p != null) {
      p.correctCount += correct;
      p.wrongCount += wrong;
      p.learnedWords = (p.learnedWords + correct + wrong).clamp(0, p.totalWords);
      p.lastStudyTime = DateTime.now();
      
      // TODO: Lưu progress lên Firestore
      // await _firebaseService.updateUserProgress(userId, topicId, p);
      
      notifyListeners();
    }
  }

  /// Lưu tiến trình
  Future<void> saveProgress() async {
    // TODO: Implement save progress to Firestore
    notifyListeners();
  }

  /// Reset dữ liệu (không còn seed demo nữa)
  Future<void> resetData() async {
    _topics = [];
    _progress = {};
    await loadData();
  }
}
