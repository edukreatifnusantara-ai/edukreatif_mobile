import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'question_rotation_service.dart';

enum AdaptiveAction { increase, decrease, maintain }

class UserPerformance {
  final String subjectCode;
  int totalAnswered;
  int correctCount;
  int consecutiveCorrect;
  int consecutiveWrong;
  double avgTimePerQuestion;
  QuestionDifficulty currentDifficulty;
  DateTime lastUpdated;

  UserPerformance({
    required this.subjectCode,
    this.totalAnswered = 0,
    this.correctCount = 0,
    this.consecutiveCorrect = 0,
    this.consecutiveWrong = 0,
    this.avgTimePerQuestion = 0.0,
    this.currentDifficulty = QuestionDifficulty.mudah,
    DateTime? lastUpdated,
  }) : lastUpdated = lastUpdated ?? DateTime.now();

  double get accuracy => totalAnswered > 0 ? correctCount / totalAnswered : 0.0;

  Map<String, dynamic> toJson() => {
    'subject_code': subjectCode,
    'total_answered': totalAnswered,
    'correct_count': correctCount,
    'consecutive_correct': consecutiveCorrect,
    'consecutive_wrong': consecutiveWrong,
    'avg_time_per_question': avgTimePerQuestion,
    'current_difficulty': currentDifficulty.name,
    'last_updated': lastUpdated.toIso8601String(),
  };

  factory UserPerformance.fromJson(Map<String, dynamic> json) => UserPerformance(
    subjectCode: json['subject_code'] as String,
    totalAnswered: json['total_answered'] as int? ?? 0,
    correctCount: json['correct_count'] as int? ?? 0,
    consecutiveCorrect: json['consecutive_correct'] as int? ?? 0,
    consecutiveWrong: json['consecutive_wrong'] as int? ?? 0,
    avgTimePerQuestion: (json['avg_time_per_question'] as num?)?.toDouble() ?? 0.0,
    currentDifficulty: QuestionDifficulty.values.firstWhere(
      (d) => d.name == (json['current_difficulty'] as String? ?? 'mudah'),
      orElse: () => QuestionDifficulty.mudah,
    ),
    lastUpdated: DateTime.tryParse(json['last_updated'] as String? ?? '') ?? DateTime.now(),
  );

  UserPerformance copyWith({
    int? totalAnswered,
    int? correctCount,
    int? consecutiveCorrect,
    int? consecutiveWrong,
    double? avgTimePerQuestion,
    QuestionDifficulty? currentDifficulty,
    DateTime? lastUpdated,
  }) => UserPerformance(
    subjectCode: subjectCode,
    totalAnswered: totalAnswered ?? this.totalAnswered,
    correctCount: correctCount ?? this.correctCount,
    consecutiveCorrect: consecutiveCorrect ?? this.consecutiveCorrect,
    consecutiveWrong: consecutiveWrong ?? this.consecutiveWrong,
    avgTimePerQuestion: avgTimePerQuestion ?? this.avgTimePerQuestion,
    currentDifficulty: currentDifficulty ?? this.currentDifficulty,
    lastUpdated: lastUpdated ?? DateTime.now(),
  );
}

class AdaptiveDifficultyService {
  static final AdaptiveDifficultyService _instance = AdaptiveDifficultyService._internal();
  factory AdaptiveDifficultyService() => _instance;
  AdaptiveDifficultyService._internal();

  static const String _prefsKey = 'adaptive_difficulty_performance';
  final Map<String, UserPerformance> _performances = {};
  SharedPreferences? _prefs;

  Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
    await _loadFromPrefs();
  }

  Future<void> _loadFromPrefs() async {
    if (_prefs == null) return;
    final jsonStr = _prefs!.getString(_prefsKey);
    if (jsonStr == null) return;

    try {
      final Map<String, dynamic> data = jsonDecode(jsonStr);
      for (final entry in data.entries) {
        _performances[entry.key] = UserPerformance.fromJson(Map<String, dynamic>.from(entry.value as Map));
      }
    } catch (_) {
      _performances.clear();
    }
  }

  Future<void> _saveToPrefs() async {
    if (_prefs == null) return;
    final data = _performances.map((k, v) => MapEntry(k, v.toJson()));
    await _prefs!.setString(_prefsKey, jsonEncode(data));
  }

  UserPerformance getPerformance(String subjectCode) {
    return _performances.putIfAbsent(subjectCode, () => UserPerformance(subjectCode: subjectCode));
  }

  void recordAnswer({
    required String subjectCode,
    required bool isCorrect,
    required int timeSpentSeconds,
  }) {
    final perf = getPerformance(subjectCode);
    final newTotal = perf.totalAnswered + 1;
    final newCorrect = perf.correctCount + (isCorrect ? 1 : 0);
    final newConsecutiveCorrect = isCorrect ? perf.consecutiveCorrect + 1 : 0;
    final newConsecutiveWrong = isCorrect ? 0 : perf.consecutiveWrong + 1;

    final newAvgTime = ((perf.avgTimePerQuestion * perf.totalAnswered) + timeSpentSeconds) / newTotal;

    _performances[subjectCode] = perf.copyWith(
      totalAnswered: newTotal,
      correctCount: newCorrect,
      consecutiveCorrect: newConsecutiveCorrect,
      consecutiveWrong: newConsecutiveWrong,
      avgTimePerQuestion: newAvgTime,
    );
    _saveToPrefs();
  }

  AdaptiveAction determineDifficultyChange(String subjectCode) {
    final perf = getPerformance(subjectCode);

    if (perf.totalAnswered < 5) return AdaptiveAction.maintain;

    if (perf.consecutiveCorrect >= 3 && perf.accuracy >= 0.8) {
      if (perf.currentDifficulty == QuestionDifficulty.mudah) return AdaptiveAction.increase;
      if (perf.currentDifficulty == QuestionDifficulty.sedang) return AdaptiveAction.increase;
    }

    if (perf.consecutiveWrong >= 2 || perf.accuracy < 0.4) {
      if (perf.currentDifficulty == QuestionDifficulty.sulit) return AdaptiveAction.decrease;
      if (perf.currentDifficulty == QuestionDifficulty.sedang) return AdaptiveAction.decrease;
    }

    if (perf.accuracy >= 0.7 && perf.consecutiveCorrect >= 2 && perf.currentDifficulty != QuestionDifficulty.sulit) {
      return AdaptiveAction.increase;
    }

    if (perf.accuracy < 0.5 && perf.consecutiveWrong >= 1 && perf.currentDifficulty != QuestionDifficulty.mudah) {
      return AdaptiveAction.decrease;
    }

    return AdaptiveAction.maintain;
  }

  QuestionDifficulty getRecommendedDifficulty(String subjectCode) {
    final perf = getPerformance(subjectCode);
    final action = determineDifficultyChange(subjectCode);

    switch (action) {
      case AdaptiveAction.increase:
        return _nextDifficulty(perf.currentDifficulty);
      case AdaptiveAction.decrease:
        return _previousDifficulty(perf.currentDifficulty);
      case AdaptiveAction.maintain:
      default:
        return perf.currentDifficulty;
    }
  }

  QuestionDifficulty _nextDifficulty(QuestionDifficulty current) {
    switch (current) {
      case QuestionDifficulty.mudah:
        return QuestionDifficulty.sedang;
      case QuestionDifficulty.sedang:
        return QuestionDifficulty.sulit;
      case QuestionDifficulty.sulit:
        return QuestionDifficulty.sulit;
    }
  }

  QuestionDifficulty _previousDifficulty(QuestionDifficulty current) {
    switch (current) {
      case QuestionDifficulty.mudah:
        return QuestionDifficulty.mudah;
      case QuestionDifficulty.sedang:
        return QuestionDifficulty.mudah;
      case QuestionDifficulty.sulit:
        return QuestionDifficulty.sedang;
    }
  }

  void applyDifficultyChange(String subjectCode) {
    final perf = getPerformance(subjectCode);
    final recommended = getRecommendedDifficulty(subjectCode);
    if (recommended != perf.currentDifficulty) {
      _performances[subjectCode] = perf.copyWith(currentDifficulty: recommended);
      _saveToPrefs();
    }
  }

  Map<QuestionDifficulty, double> getDynamicWeights(String subjectCode) {
    final recommended = getRecommendedDifficulty(subjectCode);

    switch (recommended) {
      case QuestionDifficulty.mudah:
        return {
          QuestionDifficulty.mudah: 0.6,
          QuestionDifficulty.sedang: 0.3,
          QuestionDifficulty.sulit: 0.1,
        };
      case QuestionDifficulty.sedang:
        return {
          QuestionDifficulty.mudah: 0.3,
          QuestionDifficulty.sedang: 0.5,
          QuestionDifficulty.sulit: 0.2,
        };
      case QuestionDifficulty.sulit:
        return {
          QuestionDifficulty.mudah: 0.1,
          QuestionDifficulty.sedang: 0.3,
          QuestionDifficulty.sulit: 0.6,
        };
    }
  }

  Map<String, dynamic> getAnalytics() {
    return {
      'subjects': _performances.map((k, v) => MapEntry(k, {
        'accuracy': v.accuracy,
        'total_answered': v.totalAnswered,
        'current_difficulty': v.currentDifficulty.name,
        'avg_time': v.avgTimePerQuestion,
      })),
      'overall_accuracy': _performances.isEmpty
          ? 0.0
          : _performances.values.map((p) => p.accuracy).reduce((a, b) => a + b) / _performances.length,
    };
  }

  void resetSubject(String subjectCode) {
    _performances.remove(subjectCode);
    _saveToPrefs();
  }

  void resetAll() {
    _performances.clear();
    _saveToPrefs();
  }
}