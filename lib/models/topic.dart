import '../data/categories.dart';
import 'vocabulary.dart';

class Topic {
  final String id;
  String name;
  String? description;
  /// Tên hiển thị ở tâm cụm (có thể có \n để xuống dòng). Nếu null thì dùng name.
  String? displayName;
  /// ID nhóm: cat_topic, cat_grade, cat_grammar, cat_idiom, cat_ipa
  String categoryId;
  /// Lớp học (1-12) — chỉ dùng khi categoryId = cat_grade
  int? gradeLevel;
  final List<Vocabulary> words;

  Topic({
    required this.id,
    required this.name,
    this.description,
    this.displayName,
    this.categoryId = CategoryIds.topic,
    this.gradeLevel,
    List<Vocabulary>? words,
  }) : words = words ?? [];

  Topic copyWith({
    String? id,
    String? name,
    String? description,
    String? displayName,
    String? categoryId,
    int? gradeLevel,
    List<Vocabulary>? words,
  }) {
    return Topic(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      displayName: displayName ?? this.displayName,
      categoryId: categoryId ?? this.categoryId,
      gradeLevel: gradeLevel ?? this.gradeLevel,
      words: words ?? List.from(this.words),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'displayName': displayName,
      'categoryId': categoryId,
      'gradeLevel': gradeLevel,
      'words': words.map((w) => w.toJson()).toList(),
    };
  }

  factory Topic.fromJson(Map<String, dynamic> json) {
    return Topic(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      displayName: json['displayName'] as String?,
      categoryId: json['categoryId'] as String? ?? CategoryIds.topic,
      gradeLevel: json['gradeLevel'] as int?,
      words: (json['words'] as List<dynamic>?)
              ?.map((w) => Vocabulary.fromJson(w as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}
