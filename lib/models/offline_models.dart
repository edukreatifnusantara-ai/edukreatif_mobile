import '../services/cbt_session_manager.dart';
import '../services/question_rotation_service.dart';

class OfflineSession {
  final String id;
  final String packageName;
  final String category;
  final DateTime startTime;
  final DateTime endTime;
  final int totalQuestions;
  final int correctAnswers;
  final int wrongAnswers;
  final int unansweredCount;
  final double score;
  final int durationSeconds;
  final List<OfflineAnswer> answers;
  final Map<String, dynamic> adaptiveAnalytics;
  final bool syncedToCloud;

  const OfflineSession({
    required this.id,
    required this.packageName,
    required this.category,
    required this.startTime,
    required this.endTime,
    required this.totalQuestions,
    required this.correctAnswers,
    required this.wrongAnswers,
    required this.unansweredCount,
    required this.score,
    required this.durationSeconds,
    required this.answers,
    required this.adaptiveAnalytics,
    this.syncedToCloud = false,
  });

  factory OfflineSession.fromCbtResult({
    required String packageName,
    required String category,
    required CBTResult result,
  }) {
    return OfflineSession(
      id: 'session_${DateTime.now().millisecondsSinceEpoch}',
      packageName: packageName,
      category: category,
      startTime: result.startTime,
      endTime: result.endTime,
      totalQuestions: result.totalQuestions,
      correctAnswers: result.correctAnswers,
      wrongAnswers: result.wrongAnswers,
      unansweredCount: result.unanswered,
      score: result.score,
      durationSeconds: result.duration.inSeconds,
      answers: result.answers.map(OfflineAnswer.fromCBTAnswer).toList(),
      adaptiveAnalytics: result.adaptiveAnalytics,
    );
  }

  factory OfflineSession.fromJson(Map<String, dynamic> json) => OfflineSession(
    id: json['id'] as String,
    packageName: json['package_name'] as String? ?? '',
    category: json['category'] as String? ?? '',
    startTime: DateTime.tryParse(json['start_time'] as String? ?? '') ?? DateTime.now(),
    endTime: DateTime.tryParse(json['end_time'] as String? ?? '') ?? DateTime.now(),
    totalQuestions: json['total_questions'] as int? ?? 0,
    correctAnswers: json['correct_answers'] as int? ?? 0,
    wrongAnswers: json['wrong_answers'] as int? ?? 0,
    unansweredCount: json['unanswered'] as int? ?? 0,
    score: (json['score'] as num?)?.toDouble() ?? 0.0,
    durationSeconds: json['duration_seconds'] as int? ?? 0,
    answers: ((json['answers'] as List?) ?? [])
        .map((a) => OfflineAnswer.fromJson(Map<String, dynamic>.from(a as Map)))
        .toList(),
    adaptiveAnalytics: Map<String, dynamic>.from(json['adaptive_analytics'] as Map? ?? {}),
    syncedToCloud: json['synced_to_cloud'] as bool? ?? false,
  );

  OfflineSession copyWith({bool? syncedToCloud}) => OfflineSession(
    id: id,
    packageName: packageName,
    category: category,
    startTime: startTime,
    endTime: endTime,
    totalQuestions: totalQuestions,
    correctAnswers: correctAnswers,
    wrongAnswers: wrongAnswers,
    unansweredCount: unansweredCount,
    score: score,
    durationSeconds: durationSeconds,
    answers: answers,
    adaptiveAnalytics: adaptiveAnalytics,
    syncedToCloud: syncedToCloud ?? this.syncedToCloud,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'package_name': packageName,
    'category': category,
    'start_time': startTime.toIso8601String(),
    'end_time': endTime.toIso8601String(),
    'total_questions': totalQuestions,
    'correct_answers': correctAnswers,
    'wrong_answers': wrongAnswers,
    'unanswered': unansweredCount,
    'score': score,
    'duration_seconds': durationSeconds,
    'answers': answers.map((a) => a.toJson()).toList(),
    'adaptive_analytics': adaptiveAnalytics,
    'synced_to_cloud': syncedToCloud,
  };
}

class OfflineAnswer {
  final String questionId;
  final String selectedOption;
  final bool isCorrect;
  final int timeSpentSeconds;
  final String subjectCode;
  final QuestionDifficulty difficulty;

  const OfflineAnswer({
    required this.questionId,
    required this.selectedOption,
    required this.isCorrect,
    required this.timeSpentSeconds,
    required this.subjectCode,
    required this.difficulty,
  });

  factory OfflineAnswer.fromCBTAnswer(CBTAnswer answer) => OfflineAnswer(
    questionId: answer.questionId,
    selectedOption: answer.selectedOption,
    isCorrect: answer.isCorrect,
    timeSpentSeconds: answer.timeSpentSeconds,
    subjectCode: '',
    difficulty: QuestionDifficulty.mudah,
  );

  factory OfflineAnswer.fromJson(Map<String, dynamic> json) => OfflineAnswer(
    questionId: json['question_id'] as String? ?? '',
    selectedOption: json['selected_option'] as String? ?? '',
    isCorrect: json['is_correct'] as bool? ?? false,
    timeSpentSeconds: json['time_spent_seconds'] as int? ?? 0,
    subjectCode: json['subject_code'] as String? ?? '',
    difficulty: QuestionDifficulty.values.firstWhere(
      (d) => d.name == (json['difficulty'] as String? ?? 'mudah'),
      orElse: () => QuestionDifficulty.mudah,
    ),
  );

  Map<String, dynamic> toJson() => {
    'question_id': questionId,
    'selected_option': selectedOption,
    'is_correct': isCorrect,
    'time_spent_seconds': timeSpentSeconds,
    'subject_code': subjectCode,
    'difficulty': difficulty.name,
  };
}

class OfflineQuestionProgress {
  final String questionId;
  final String subjectCode;
  final int timesAttempted;
  final int timesCorrect;
  final int lastTimeSpentSeconds;
  final DateTime lastAttempted;

  const OfflineQuestionProgress({
    required this.questionId,
    required this.subjectCode,
    this.timesAttempted = 0,
    this.timesCorrect = 0,
    this.lastTimeSpentSeconds = 0,
    required this.lastAttempted,
  });

  double get accuracy => timesAttempted > 0 ? timesCorrect / timesAttempted : 0.0;

  factory OfflineQuestionProgress.fromJson(Map<String, dynamic> json) => OfflineQuestionProgress(
    questionId: json['question_id'] as String? ?? '',
    subjectCode: json['subject_code'] as String? ?? '',
    timesAttempted: json['times_attempted'] as int? ?? 0,
    timesCorrect: json['times_correct'] as int? ?? 0,
    lastTimeSpentSeconds: json['last_time_spent_seconds'] as int? ?? 0,
    lastAttempted: DateTime.tryParse(json['last_attempted'] as String? ?? '') ?? DateTime.now(),
  );

  Map<String, dynamic> toJson() => {
    'question_id': questionId,
    'subject_code': subjectCode,
    'times_attempted': timesAttempted,
    'times_correct': timesCorrect,
    'last_time_spent_seconds': lastTimeSpentSeconds,
    'last_attempted': lastAttempted.toIso8601String(),
  };
}