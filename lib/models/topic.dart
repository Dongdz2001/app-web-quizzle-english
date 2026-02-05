import 'vocabulary.dart';

class Topic {
  final String id;
  String name;
  String? description;
  final List<Vocabulary> words;

  Topic({
    required this.id,
    required this.name,
    this.description,
    List<Vocabulary>? words,
  }) : words = words ?? [];

  Topic copyWith({
    String? id,
    String? name,
    String? description,
    List<Vocabulary>? words,
  }) {
    return Topic(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      words: words ?? List.from(this.words),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'words': words.map((w) => w.toJson()).toList(),
    };
  }

  factory Topic.fromJson(Map<String, dynamic> json) {
    return Topic(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      words: (json['words'] as List<dynamic>?)
              ?.map((w) => Vocabulary.fromJson(w as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}
