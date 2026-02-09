import 'package:cloud_firestore/cloud_firestore.dart';
import 'user_metadata.dart';

class Vocabulary {
  final String id;
  String word;
  String meaning;
  String wordForm; // base (legacy/fallback)
  
  // New granular word forms
  String? noun;
  String? verb;
  String? adjective;
  String? adverb;
  String? vEd;
  String? vIng;
  String? vSes;

  String? englishDefinition;
  String? synonym; // từ đồng nghĩa (closest)
  String? antonym; // từ trái nghĩa (opposite)
  
  // Metadata cho decentralized database
  CreatorMetadata? createdBy;
  DateTime? createdAt;
  CreatorMetadata? updatedBy;
  DateTime? updatedAt;

  Vocabulary({
    required this.id,
    required this.word,
    required this.meaning,
    this.wordForm = '',
    this.noun,
    this.verb,
    this.adjective,
    this.adverb,
    this.vEd,
    this.vIng,
    this.vSes,
    this.englishDefinition,
    this.synonym,
    this.antonym,
    this.createdBy,
    this.createdAt,
    this.updatedBy,
    this.updatedAt,
  });

  Vocabulary copyWith({
    String? id,
    String? word,
    String? meaning,
    String? wordForm,
    String? noun,
    String? verb,
    String? adjective,
    String? adverb,
    String? vEd,
    String? vIng,
    String? vSes,
    String? englishDefinition,
    String? synonym,
    String? antonym,
    CreatorMetadata? createdBy,
    DateTime? createdAt,
    CreatorMetadata? updatedBy,
    DateTime? updatedAt,
  }) {
    return Vocabulary(
      id: id ?? this.id,
      word: word ?? this.word,
      meaning: meaning ?? this.meaning,
      wordForm: wordForm ?? this.wordForm,
      noun: noun ?? this.noun,
      verb: verb ?? this.verb,
      adjective: adjective ?? this.adjective,
      adverb: adverb ?? this.adverb,
      vEd: vEd ?? this.vEd,
      vIng: vIng ?? this.vIng,
      vSes: vSes ?? this.vSes,
      englishDefinition: englishDefinition ?? this.englishDefinition,
      synonym: synonym ?? this.synonym,
      antonym: antonym ?? this.antonym,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      updatedBy: updatedBy ?? this.updatedBy,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'word': word,
      'meaning': meaning,
      'wordForm': wordForm,
      'noun': noun,
      'verb': verb,
      'adjective': adjective,
      'adverb': adverb,
      'vEd': vEd,
      'vIng': vIng,
      'vSes': vSes,
      'englishDefinition': englishDefinition,
      'synonym': synonym,
      'antonym': antonym,
      'createdBy': createdBy?.toJson(),
      'createdAt': createdAt?.toIso8601String(),
      'updatedBy': updatedBy?.toJson(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  Map<String, dynamic> toFirestoreJson() {
    return {
      'id': id,
      'word': word,
      'meaning': meaning,
      'wordForm': wordForm,
      'noun': noun,
      'verb': verb,
      'adjective': adjective,
      'adverb': adverb,
      'vEd': vEd,
      'vIng': vIng,
      'vSes': vSes,
      'englishDefinition': englishDefinition,
      'synonym': synonym,
      'antonym': antonym,
      'createdBy': createdBy?.toJson(),
      'createdAt': createdAt,
      'updatedBy': updatedBy?.toJson(),
      'updatedAt': updatedAt,
    };
  }

  factory Vocabulary.fromJson(Map<String, dynamic> json) {
    return Vocabulary(
      id: json['id'] as String,
      word: json['word'] as String,
      meaning: json['meaning'] as String,
      wordForm: json['wordForm'] as String? ?? '',
      noun: json['noun'] as String?,
      verb: json['verb'] as String?,
      adjective: json['adjective'] as String?,
      adverb: json['adverb'] as String?,
      vEd: json['vEd'] as String?,
      vIng: json['vIng'] as String?,
      vSes: json['vSes'] as String?,
      englishDefinition: json['englishDefinition'] as String?,
      synonym: json['synonym'] as String?,
      antonym: json['antonym'] as String?,
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

  factory Vocabulary.fromFirestore(Map<String, dynamic> json) {
    DateTime? parseDateTime(dynamic value) {
      if (value is Timestamp) return value.toDate();
      if (value is String) return DateTime.tryParse(value);
      if (value is DateTime) return value;
      return null;
    }

    return Vocabulary(
      id: json['id'] as String,
      word: json['word'] as String,
      meaning: json['meaning'] as String,
      wordForm: json['wordForm'] as String? ?? '',
      noun: json['noun'] as String?,
      verb: json['verb'] as String?,
      adjective: json['adjective'] as String?,
      adverb: json['adverb'] as String?,
      vEd: json['vEd'] as String?,
      vIng: json['vIng'] as String?,
      vSes: json['vSes'] as String?,
      englishDefinition: json['englishDefinition'] as String?,
      synonym: json['synonym'] as String?,
      antonym: json['antonym'] as String?,
      createdBy: json['createdBy'] != null
          ? CreatorMetadata.fromJson(json['createdBy'] as Map<String, dynamic>)
          : null,
      createdAt: parseDateTime(json['createdAt']),
      updatedBy: json['updatedBy'] != null
          ? CreatorMetadata.fromJson(json['updatedBy'] as Map<String, dynamic>)
          : null,
      updatedAt: parseDateTime(json['updatedAt']),
    );
  }
}
