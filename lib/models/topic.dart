import '../data/categories.dart';
import 'user_metadata.dart';
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
  
  // Metadata cho decentralized database
  CreatorMetadata? createdBy;
  DateTime? createdAt;
  CreatorMetadata? updatedBy;
  DateTime? updatedAt;

  Topic({
    required this.id,
    required this.name,
    this.description,
    this.displayName,
    this.categoryId = CategoryIds.topic,
    this.gradeLevel,
    List<Vocabulary>? words,
    this.createdBy,
    this.createdAt,
    this.updatedBy,
    this.updatedAt,
  }) : words = words ?? [];

  Topic copyWith({
    String? id,
    String? name,
    String? description,
    String? displayName,
    String? categoryId,
    int? gradeLevel,
    List<Vocabulary>? words,
    CreatorMetadata? createdBy,
    DateTime? createdAt,
    CreatorMetadata? updatedBy,
    DateTime? updatedAt,
  }) {
    return Topic(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      displayName: displayName ?? this.displayName,
      categoryId: categoryId ?? this.categoryId,
      gradeLevel: gradeLevel ?? this.gradeLevel,
      words: words ?? List.from(this.words),
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      updatedBy: updatedBy ?? this.updatedBy,
      updatedAt: updatedAt ?? this.updatedAt,
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
      'createdBy': createdBy?.toJson(),
      'createdAt': createdAt?.toIso8601String(),
      'updatedBy': updatedBy?.toJson(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  Map<String, dynamic> toFirestoreJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'displayName': displayName,
      'categoryId': categoryId,
      'gradeLevel': gradeLevel,
      'words': words.map((w) => w.toFirestoreJson()).toList(),
      'createdBy': createdBy?.toJson(),
      'createdAt': createdAt,
      'updatedBy': updatedBy?.toJson(),
      'updatedAt': updatedAt,
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
      createdBy: json['createdBy'] != null
          ? CreatorMetadata.fromJson(json['createdBy'] as Map<String, dynamic>)
          : null,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : null,
      updatedBy: json['updatedBy'] != null
          ? CreatorMetadata.fromJson(json['updatedBy'] as Map<String, dynamic>)
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'] as String)
          : null,
    );
  }

  factory Topic.fromFirestore(Map<String, dynamic> json) {
    return Topic(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      displayName: json['displayName'] as String?,
      categoryId: json['categoryId'] as String? ?? CategoryIds.topic,
      gradeLevel: json['gradeLevel'] as int?,
      words: (json['words'] as List<dynamic>?)
              ?.map((w) => Vocabulary.fromFirestore(w as Map<String, dynamic>))
              .toList() ??
          [],
      createdBy: json['createdBy'] != null
          ? CreatorMetadata.fromJson(json['createdBy'] as Map<String, dynamic>)
          : null,
      createdAt: json['createdAt'] != null
          ? (json['createdAt'] as DateTime)
          : null,
      updatedBy: json['updatedBy'] != null
          ? CreatorMetadata.fromJson(json['updatedBy'] as Map<String, dynamic>)
          : null,
      updatedAt: json['updatedAt'] != null
          ? (json['updatedAt'] as DateTime)
          : null,
    );
  }
}
