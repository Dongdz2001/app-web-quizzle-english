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

  // Seed demo data
  Future<void> seedDemoData() async {
    final topics = await getTopics();
    if (topics.isNotEmpty) return;

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
