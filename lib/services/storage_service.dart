import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/learning_progress.dart';
import '../models/topic.dart';
import '../models/vocabulary.dart';

class StorageService {
  static const String _topicsKey = 'vocab_topics';
  static const String _progressKey = 'vocab_progress';

  late SharedPreferences _prefs;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  // Topics
  Future<List<Topic>> getTopics() async {
    final jsonString = _prefs.getString(_topicsKey);
    if (jsonString == null) return [];
    try {
      final List<dynamic> jsonList = jsonDecode(jsonString) as List<dynamic>;
      return jsonList
          .map((j) => Topic.fromJson(j as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> saveTopics(List<Topic> topics) async {
    final jsonList = topics.map((t) => t.toJson()).toList();
    await _prefs.setString(_topicsKey, jsonEncode(jsonList));
  }

  // Progress
  Future<Map<String, LearningProgress>> getProgress() async {
    final jsonString = _prefs.getString(_progressKey);
    if (jsonString == null) return {};
    try {
      final Map<String, dynamic> jsonMap =
          jsonDecode(jsonString) as Map<String, dynamic>;
      return jsonMap.map(
        (k, v) => MapEntry(k, LearningProgress.fromJson(v as Map<String, dynamic>)),
      );
    } catch (_) {
      return {};
    }
  }

  Future<void> saveProgress(Map<String, LearningProgress> progress) async {
    final jsonMap = progress.map(
      (k, v) => MapEntry(k, v.toJson()),
    );
    await _prefs.setString(_progressKey, jsonEncode(jsonMap));
  }

  /// Xóa toàn bộ dữ liệu (topics + progress) để seed lại demo mới.
  Future<void> clearAllData() async {
    await init();
    await _prefs.remove(_topicsKey);
    await _prefs.remove(_progressKey);
  }

  // Seed demo data
  Future<void> seedDemoData() async {
    final topics = await getTopics();
    // Migration: nếu demo-1 chỉ có 3 từ (bản cũ), thay bằng demo 40 từ
    if (topics.isNotEmpty) {
      final giaDinh = topics.where((t) => t.id == 'demo-1').firstOrNull;
      if (giaDinh == null || giaDinh.words.length >= 40) return;
      // Cần cập nhật demo Gia đình lên 40 từ
    }

    final demoTopics = [
      Topic(
        id: 'demo-1',
        name: 'Gia đình',
        description: 'Từ vựng về gia đình',
        words: [
          Vocabulary(
            id: 'w1',
            word: 'family',
            meaning: 'gia đình',
            wordForm: 'noun',
            englishDefinition: 'a group of people related by blood or marriage',
            synonym: 'household',
            antonym: '',
          ),
          Vocabulary(
            id: 'w2',
            word: 'parents',
            meaning: 'cha mẹ',
            wordForm: 'noun',
            synonym: 'father and mother',
            antonym: 'children',
          ),
          Vocabulary(
            id: 'w3',
            word: 'sibling',
            meaning: 'anh chị em ruột',
            wordForm: 'noun',
            synonym: 'brother or sister',
            antonym: '',
          ),
          Vocabulary(
            id: 'w1-4',
            word: 'father',
            meaning: 'cha, bố',
            wordForm: 'noun',
            englishDefinition: 'a male parent',
            synonym: 'dad',
            antonym: 'mother',
          ),
          Vocabulary(
            id: 'w1-5',
            word: 'mother',
            meaning: 'mẹ',
            wordForm: 'noun',
            englishDefinition: 'a female parent',
            synonym: 'mom',
            antonym: 'father',
          ),
          Vocabulary(
            id: 'w1-6',
            word: 'brother',
            meaning: 'anh trai, em trai',
            wordForm: 'noun',
            synonym: 'sibling',
            antonym: 'sister',
          ),
          Vocabulary(
            id: 'w1-7',
            word: 'sister',
            meaning: 'chị gái, em gái',
            wordForm: 'noun',
            synonym: 'sibling',
            antonym: 'brother',
          ),
          Vocabulary(
            id: 'w1-8',
            word: 'son',
            meaning: 'con trai',
            wordForm: 'noun',
            antonym: 'daughter',
          ),
          Vocabulary(
            id: 'w1-9',
            word: 'daughter',
            meaning: 'con gái',
            wordForm: 'noun',
            antonym: 'son',
          ),
          Vocabulary(
            id: 'w1-10',
            word: 'grandfather',
            meaning: 'ông',
            wordForm: 'noun',
            synonym: 'grandpa',
            antonym: 'grandmother',
          ),
          Vocabulary(
            id: 'w1-11',
            word: 'grandmother',
            meaning: 'bà',
            wordForm: 'noun',
            synonym: 'grandma',
            antonym: 'grandfather',
          ),
          Vocabulary(
            id: 'w1-12',
            word: 'uncle',
            meaning: 'chú, bác, cậu',
            wordForm: 'noun',
            antonym: 'aunt',
          ),
          Vocabulary(
            id: 'w1-13',
            word: 'aunt',
            meaning: 'cô, dì, bác gái',
            wordForm: 'noun',
            antonym: 'uncle',
          ),
          Vocabulary(
            id: 'w1-14',
            word: 'cousin',
            meaning: 'anh chị em họ',
            wordForm: 'noun',
          ),
          Vocabulary(
            id: 'w1-15',
            word: 'nephew',
            meaning: 'cháu trai',
            wordForm: 'noun',
            antonym: 'niece',
          ),
          Vocabulary(
            id: 'w1-16',
            word: 'niece',
            meaning: 'cháu gái',
            wordForm: 'noun',
            antonym: 'nephew',
          ),
          Vocabulary(
            id: 'w1-17',
            word: 'husband',
            meaning: 'chồng',
            wordForm: 'noun',
            antonym: 'wife',
          ),
          Vocabulary(
            id: 'w1-18',
            word: 'wife',
            meaning: 'vợ',
            wordForm: 'noun',
            antonym: 'husband',
          ),
          Vocabulary(
            id: 'w1-19',
            word: 'relative',
            meaning: 'họ hàng',
            wordForm: 'noun',
            englishDefinition: 'a person connected by blood or marriage',
            synonym: 'family member',
          ),
          Vocabulary(
            id: 'w1-20',
            word: 'generation',
            meaning: 'thế hệ',
            wordForm: 'noun',
            englishDefinition: 'all people born around the same time',
          ),
          Vocabulary(
            id: 'w1-21',
            word: 'grandson',
            meaning: 'cháu trai (con của con)',
            wordForm: 'noun',
            antonym: 'granddaughter',
          ),
          Vocabulary(
            id: 'w1-22',
            word: 'granddaughter',
            meaning: 'cháu gái (con của con)',
            wordForm: 'noun',
            antonym: 'grandson',
          ),
          Vocabulary(
            id: 'w1-23',
            word: 'father-in-law',
            meaning: 'bố chồng/vợ',
            wordForm: 'noun',
            antonym: 'mother-in-law',
          ),
          Vocabulary(
            id: 'w1-24',
            word: 'mother-in-law',
            meaning: 'mẹ chồng/vợ',
            wordForm: 'noun',
            antonym: 'father-in-law',
          ),
          Vocabulary(
            id: 'w1-25',
            word: 'son-in-law',
            meaning: 'con rể',
            wordForm: 'noun',
            antonym: 'daughter-in-law',
          ),
          Vocabulary(
            id: 'w1-26',
            word: 'daughter-in-law',
            meaning: 'con dâu',
            wordForm: 'noun',
            antonym: 'son-in-law',
          ),
          Vocabulary(
            id: 'w1-27',
            word: 'stepfather',
            meaning: 'bố dượng',
            wordForm: 'noun',
          ),
          Vocabulary(
            id: 'w1-28',
            word: 'stepmother',
            meaning: 'mẹ kế',
            wordForm: 'noun',
          ),
          Vocabulary(
            id: 'w1-29',
            word: 'stepbrother',
            meaning: 'anh/em trai cùng cha/mẹ khác mẹ/cha',
            wordForm: 'noun',
          ),
          Vocabulary(
            id: 'w1-30',
            word: 'stepsister',
            meaning: 'chị/em gái cùng cha/mẹ khác mẹ/cha',
            wordForm: 'noun',
          ),
          Vocabulary(
            id: 'w1-31',
            word: 'twin',
            meaning: 'sinh đôi',
            wordForm: 'noun',
          ),
          Vocabulary(
            id: 'w1-32',
            word: 'ancestor',
            meaning: 'tổ tiên',
            wordForm: 'noun',
            antonym: 'descendant',
          ),
          Vocabulary(
            id: 'w1-33',
            word: 'descendant',
            meaning: 'hậu duệ, con cháu',
            wordForm: 'noun',
            antonym: 'ancestor',
          ),
          Vocabulary(
            id: 'w1-34',
            word: 'household',
            meaning: 'hộ gia đình',
            wordForm: 'noun',
            synonym: 'family',
          ),
          Vocabulary(
            id: 'w1-35',
            word: 'inheritance',
            meaning: 'tài sản thừa kế',
            wordForm: 'noun',
          ),
          Vocabulary(
            id: 'w1-36',
            word: 'marriage',
            meaning: 'hôn nhân',
            wordForm: 'noun',
            antonym: 'divorce',
          ),
          Vocabulary(
            id: 'w1-37',
            word: 'divorce',
            meaning: 'ly hôn',
            wordForm: 'noun',
            antonym: 'marriage',
          ),
          Vocabulary(
            id: 'w1-38',
            word: 'wedding',
            meaning: 'đám cưới',
            wordForm: 'noun',
          ),
          Vocabulary(
            id: 'w1-39',
            word: 'reunion',
            meaning: 'sum họp gia đình',
            wordForm: 'noun',
          ),
          Vocabulary(
            id: 'w1-40',
            word: 'birth',
            meaning: 'sự sinh ra',
            wordForm: 'noun',
            antonym: 'death',
          ),
        ],
      ),
      Topic(
        id: 'demo-2',
        name: 'Công việc',
        description: 'Từ vựng về công việc',
        words: [
          Vocabulary(
            id: 'w4',
            word: 'career',
            meaning: 'sự nghiệp',
            wordForm: 'noun',
            synonym: 'profession',
            antonym: '',
          ),
          Vocabulary(
            id: 'w5',
            word: 'colleague',
            meaning: 'đồng nghiệp',
            wordForm: 'noun',
            synonym: 'coworker',
            antonym: 'boss',
          ),
        ],
      ),
    ];

    await saveTopics(demoTopics);
  }
}
