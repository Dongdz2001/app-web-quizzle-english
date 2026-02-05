class LearningProgress {
  final String topicId;
  int totalWords;
  int learnedWords;
  int correctCount;
  int wrongCount;
  DateTime lastStudyTime;

  LearningProgress({
    required this.topicId,
    this.totalWords = 0,
    this.learnedWords = 0,
    this.correctCount = 0,
    this.wrongCount = 0,
    DateTime? lastStudyTime,
  }) : lastStudyTime = lastStudyTime ?? DateTime.now();

  double get accuracy {
    final total = correctCount + wrongCount;
    if (total == 0) return 0;
    return correctCount / total;
  }

  double get progressPercent {
    if (totalWords == 0) return 0;
    return learnedWords / totalWords;
  }

  Map<String, dynamic> toJson() {
    return {
      'topicId': topicId,
      'totalWords': totalWords,
      'learnedWords': learnedWords,
      'correctCount': correctCount,
      'wrongCount': wrongCount,
      'lastStudyTime': lastStudyTime.toIso8601String(),
    };
  }

  factory LearningProgress.fromJson(Map<String, dynamic> json) {
    return LearningProgress(
      topicId: json['topicId'] as String,
      totalWords: json['totalWords'] as int? ?? 0,
      learnedWords: json['learnedWords'] as int? ?? 0,
      correctCount: json['correctCount'] as int? ?? 0,
      wrongCount: json['wrongCount'] as int? ?? 0,
      lastStudyTime: json['lastStudyTime'] != null
          ? DateTime.parse(json['lastStudyTime'] as String)
          : DateTime.now(),
    );
  }
}
