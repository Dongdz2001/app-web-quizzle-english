import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/topic.dart';
import '../models/user_metadata.dart' show CreatorMetadata;
import '../models/vocabulary.dart';

/// Service để quản lý database phi tập trung trên Firebase Firestore
/// 
/// Tất cả dữ liệu được lưu công khai và có metadata về người tạo/chỉnh sửa
class FirebaseService {
  static final FirebaseService _instance = FirebaseService._internal();
  factory FirebaseService() => _instance;
  FirebaseService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Collection paths
  static const String _topicsCollection = 'topics';
  static const String _usersCollection = 'users';

  /// Lấy thông tin user hiện tại hoặc tạo anonymous user
  Future<CreatorMetadata> _getCurrentUserMetadata() async {
    User? user = _auth.currentUser;
    
    if (user == null) {
      // Tạo anonymous user nếu chưa đăng nhập
      final credential = await _auth.signInAnonymously();
      user = credential.user;
    }

    if (user == null) {
      throw Exception('Failed to get or create user');
    }

    // Lấy thông tin user từ Firestore nếu có
    final userDoc = await _firestore.collection(_usersCollection).doc(user.uid).get();
    Map<String, dynamic>? userData;
    
    if (userDoc.exists) {
      userData = userDoc.data();
    } else {
      // Tạo user document mới
      userData = {
        'userId': user.uid,
        'userName': user.displayName ?? 'Anonymous User',
        'userEmail': user.email,
        'createdAt': FieldValue.serverTimestamp(),
      };
      await _firestore.collection(_usersCollection).doc(user.uid).set(userData);
    }

    return CreatorMetadata(
      userId: user.uid,
      userName: userData?['userName'] as String?,
      userEmail: userData?['userEmail'] as String?,
      userAvatarUrl: userData?['userAvatarUrl'] as String?,
    );
  }

  /// Lấy tất cả topics từ Firestore
  Future<List<Topic>> getAllTopics() async {
    try {
      final snapshot = await _firestore
          .collection(_topicsCollection)
          .orderBy('createdAt', descending: false)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id; // Đảm bảo có id từ document ID
        return Topic.fromFirestore(data);
      }).toList();
    } catch (e) {
      print('Error getting topics from Firestore: $e');
      return [];
    }
  }

  /// Lắng nghe thay đổi real-time của topics
  Stream<List<Topic>> topicsStream() {
    return _firestore
        .collection(_topicsCollection)
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return Topic.fromFirestore(data);
      }).toList();
    });
  }

  /// Lấy topic theo ID
  Future<Topic?> getTopic(String topicId) async {
    try {
      final doc = await _firestore.collection(_topicsCollection).doc(topicId).get();
      if (!doc.exists) return null;
      
      final data = doc.data()!;
      data['id'] = doc.id;
      return Topic.fromFirestore(data);
    } catch (e) {
      print('Error getting topic: $e');
      return null;
    }
  }

  /// Tạo topic mới
  Future<Topic> createTopic(Topic topic) async {
    try {
      final userMetadata = await _getCurrentUserMetadata();
      final now = DateTime.now();

      final topicData = topic.toFirestoreJson();
      topicData['createdBy'] = userMetadata.toJson();
      topicData['createdAt'] = now;
      topicData['updatedBy'] = userMetadata.toJson();
      topicData['updatedAt'] = now;

      // Thêm metadata cho từng word trong topic
      if (topicData['words'] != null) {
        final words = topicData['words'] as List;
        topicData['words'] = words.map((word) {
          final wordData = Map<String, dynamic>.from(word);
          wordData['createdBy'] = userMetadata.toJson();
          wordData['createdAt'] = now;
          wordData['updatedBy'] = userMetadata.toJson();
          wordData['updatedAt'] = now;
          return wordData;
        }).toList();
      }

      final docRef = await _firestore.collection(_topicsCollection).add(topicData);
      
      // Trả về topic đã được gắn metadata
      return topic.copyWith(
        id: docRef.id,
        createdBy: userMetadata,
        createdAt: now,
        updatedBy: userMetadata,
        updatedAt: now,
      );
    } catch (e) {
      print('Error creating topic: $e');
      rethrow;
    }
  }

  /// Cập nhật topic
  Future<void> updateTopic(Topic topic) async {
    try {
      final userMetadata = await _getCurrentUserMetadata();
      final now = DateTime.now();

      final topicData = topic.toFirestoreJson();
      topicData['updatedBy'] = userMetadata.toJson();
      topicData['updatedAt'] = now;

      // Cập nhật metadata cho words được chỉnh sửa
      if (topicData['words'] != null) {
        final words = topicData['words'] as List;
        topicData['words'] = words.map((word) {
          final wordData = Map<String, dynamic>.from(word);
          // Nếu word chưa có createdAt, nghĩa là word mới
          if (wordData['createdAt'] == null) {
            wordData['createdBy'] = userMetadata.toJson();
            wordData['createdAt'] = now;
          }
          wordData['updatedBy'] = userMetadata.toJson();
          wordData['updatedAt'] = now;
          return wordData;
        }).toList();
      }

      await _firestore.collection(_topicsCollection).doc(topic.id).update(topicData);
    } catch (e) {
      print('Error updating topic: $e');
      rethrow;
    }
  }

  /// Xóa topic
  Future<void> deleteTopic(String topicId) async {
    try {
      await _firestore.collection(_topicsCollection).doc(topicId).delete();
    } catch (e) {
      print('Error deleting topic: $e');
      rethrow;
    }
  }

  /// Thêm word vào topic. Trả về word kèm metadata người tạo.
  Future<Vocabulary> addWordToTopic(String topicId, Vocabulary word) async {
    try {
      final userMetadata = await _getCurrentUserMetadata();
      final now = DateTime.now();

      final topicDoc = await _firestore.collection(_topicsCollection).doc(topicId).get();
      if (!topicDoc.exists) {
        throw Exception('Topic not found');
      }

      final topicData = topicDoc.data()!;
      final words = List<Map<String, dynamic>>.from(topicData['words'] ?? []);

      final wordData = word.toFirestoreJson();
      wordData['createdBy'] = userMetadata.toJson();
      wordData['createdAt'] = now;
      wordData['updatedBy'] = userMetadata.toJson();
      wordData['updatedAt'] = now;

      words.add(wordData);

      await _firestore.collection(_topicsCollection).doc(topicId).update({
        'words': words,
        'updatedBy': userMetadata.toJson(),
        'updatedAt': now,
      });

      return word.copyWith(
        createdBy: userMetadata,
        createdAt: now,
        updatedBy: userMetadata,
        updatedAt: now,
      );
    } catch (e) {
      print('Error adding word to topic: $e');
      rethrow;
    }
  }

  /// Cập nhật word trong topic
  Future<void> updateWordInTopic(String topicId, Vocabulary word) async {
    try {
      final userMetadata = await _getCurrentUserMetadata();
      final now = DateTime.now();

      final topicDoc = await _firestore.collection(_topicsCollection).doc(topicId).get();
      if (!topicDoc.exists) {
        throw Exception('Topic not found');
      }

      final topicData = topicDoc.data()!;
      final words = List<Map<String, dynamic>>.from(topicData['words'] ?? []);

      final wordIndex = words.indexWhere((w) => w['id'] == word.id);
      if (wordIndex == -1) {
        throw Exception('Word not found in topic');
      }

      final wordData = Map<String, dynamic>.from(words[wordIndex]);
      wordData.addAll(word.toFirestoreJson());
      wordData['updatedBy'] = userMetadata.toJson();
      wordData['updatedAt'] = now;

      words[wordIndex] = wordData;

      await _firestore.collection(_topicsCollection).doc(topicId).update({
        'words': words,
        'updatedBy': userMetadata.toJson(),
        'updatedAt': now,
      });
    } catch (e) {
      print('Error updating word in topic: $e');
      rethrow;
    }
  }

  /// Xóa word khỏi topic
  Future<void> deleteWordFromTopic(String topicId, String wordId) async {
    try {
      final userMetadata = await _getCurrentUserMetadata();
      final now = DateTime.now();

      final topicDoc = await _firestore.collection(_topicsCollection).doc(topicId).get();
      if (!topicDoc.exists) {
        throw Exception('Topic not found');
      }

      final topicData = topicDoc.data()!;
      final words = List<Map<String, dynamic>>.from(topicData['words'] ?? []);

      words.removeWhere((w) => w['id'] == wordId);

      await _firestore.collection(_topicsCollection).doc(topicId).update({
        'words': words,
        'updatedBy': userMetadata.toJson(),
        'updatedAt': now,
      });
    } catch (e) {
      print('Error deleting word from topic: $e');
      rethrow;
    }
  }

  /// Lọc topics theo category
  Future<List<Topic>> getTopicsByCategory(String categoryId) async {
    try {
      final snapshot = await _firestore
          .collection(_topicsCollection)
          .where('categoryId', isEqualTo: categoryId)
          .orderBy('createdAt', descending: false)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return Topic.fromFirestore(data);
      }).toList();
    } catch (e) {
      print('Error getting topics by category: $e');
      return [];
    }
  }

  /// Lọc topics theo grade level
  Future<List<Topic>> getTopicsByGradeLevel(int gradeLevel) async {
    try {
      final snapshot = await _firestore
          .collection(_topicsCollection)
          .where('gradeLevel', isEqualTo: gradeLevel)
          .orderBy('createdAt', descending: false)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return Topic.fromFirestore(data);
      }).toList();
    } catch (e) {
      print('Error getting topics by grade level: $e');
      return [];
    }
  }

  /// Cập nhật thông tin user
  Future<void> updateUserInfo({
    String? userName,
    String? userEmail,
    String? userAvatarUrl,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      final updateData = <String, dynamic>{};
      if (userName != null) updateData['userName'] = userName;
      if (userEmail != null) updateData['userEmail'] = userEmail;
      if (userAvatarUrl != null) updateData['userAvatarUrl'] = userAvatarUrl;
      updateData['updatedAt'] = FieldValue.serverTimestamp();

      await _firestore.collection(_usersCollection).doc(user.uid).update(updateData);
    } catch (e) {
      print('Error updating user info: $e');
      rethrow;
    }
  }
}
