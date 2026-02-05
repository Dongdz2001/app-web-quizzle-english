class Vocabulary {
  final String id;
  String word;
  String meaning;
  String wordForm; // noun, verb, adj, adv...
  String? englishDefinition;
  String? synonym; // từ đồng nghĩa (closest)
  String? antonym; // từ trái nghĩa (opposite)

  Vocabulary({
    required this.id,
    required this.word,
    required this.meaning,
    this.wordForm = '',
    this.englishDefinition,
    this.synonym,
    this.antonym,
  });

  Vocabulary copyWith({
    String? id,
    String? word,
    String? meaning,
    String? wordForm,
    String? englishDefinition,
    String? synonym,
    String? antonym,
  }) {
    return Vocabulary(
      id: id ?? this.id,
      word: word ?? this.word,
      meaning: meaning ?? this.meaning,
      wordForm: wordForm ?? this.wordForm,
      englishDefinition: englishDefinition ?? this.englishDefinition,
      synonym: synonym ?? this.synonym,
      antonym: antonym ?? this.antonym,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'word': word,
      'meaning': meaning,
      'wordForm': wordForm,
      'englishDefinition': englishDefinition,
      'synonym': synonym,
      'antonym': antonym,
    };
  }

  factory Vocabulary.fromJson(Map<String, dynamic> json) {
    return Vocabulary(
      id: json['id'] as String,
      word: json['word'] as String,
      meaning: json['meaning'] as String,
      wordForm: json['wordForm'] as String? ?? '',
      englishDefinition: json['englishDefinition'] as String?,
      synonym: json['synonym'] as String?,
      antonym: json['antonym'] as String?,
    );
  }
}
