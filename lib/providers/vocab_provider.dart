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
  String? _userClassCode;
  bool _isAdmin = false;
  StreamSubscription<List<Topic>>? _topicsSubscription;

  List<Topic> get topics => _topics;
  Map<String, LearningProgress> get progress => _progress;
  bool get isLoading => _isLoading;
  String? get userClassCode => _userClassCode;
  bool get isAdmin => _isAdmin;

  /// Danh sách topic đã được lọc theo quyền hạn và lớp học (Độc lập dữ liệu)
  List<Topic> get filteredTopics {
    if (_isAdmin) return _topics; // Admin thấy toàn bộ dữ liệu

    // Nếu user có lớp cụ thể -> CHỈ thấy topic của lớp đó
    if (_userClassCode != null && _userClassCode!.isNotEmpty) {
      return _topics.where((t) => t.classCode == _userClassCode).toList();
    }
    
    // Nếu user chưa có lớp (trường hợp hiếm) -> Thấy các topic không gắn mã lớp
    return _topics.where((t) => t.classCode == null).toList();
  }

  void setUserProfile(String? classCode, bool isAdmin) {
    _userClassCode = classCode;
    _isAdmin = isAdmin;
    notifyListeners();
  }

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
      await _firebaseService.createTopic(topic);
    } catch (e) {
      print('Error adding topic: $e');
      rethrow;
    }
  }

  /// Cập nhật topic trên Firestore
  Future<void> updateTopic(Topic topic) async {
    try {
      await _firebaseService.updateTopic(topic);
    } catch (e) {
      print('Error updating topic: $e');
      rethrow;
    }
  }

  /// Xóa topic khỏi Firestore
  Future<void> deleteTopic(String topicId) async {
    try {
      await _firebaseService.deleteTopic(topicId);
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
    return filteredTopics.where((t) => t.categoryId == categoryId).toList();
  }

  /// Lấy danh sách topic theo lớp (gradeLevel) — chỉ dùng cho categoryId = cat_grade.
  List<Topic> getTopicsByGradeLevel(int gradeLevel) {
    return filteredTopics
        .where((t) => t.categoryId == CategoryIds.grade && t.gradeLevel == gradeLevel)
        .toList();
  }

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
      await _firebaseService.addWordToTopic(topicId, word);
      return true;
    } catch (e) {
      print('Error adding word: $e');
      return false;
    }
  }

  Future<void> updateWord(String topicId, Vocabulary word) async {
    try {
      await _firebaseService.updateWordInTopic(topicId, word);
    } catch (e) {
      print('Error updating word: $e');
      rethrow;
    }
  }

  Future<void> deleteWord(String topicId, String wordId) async {
    try {
      await _firebaseService.deleteWordFromTopic(topicId, wordId);
    } catch (e) {
      print('Error deleting word: $e');
      rethrow;
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
