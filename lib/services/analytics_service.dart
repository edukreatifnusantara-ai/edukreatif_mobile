import 'package:flutter/material.dart';
import '../services/adaptive_difficulty_service.dart';
import '../services/question_rotation_service.dart';
import '../main.dart';

class QuestionAnalytics {
  final String subjectCode;
  final String subjectName;
  final int totalAttempted;
  final int correctCount;
  final int wrongCount;
  final double accuracy;
  final double avgTimeSeconds;
  final List<TopicPerformance> topicBreakdown;
  final List<MissedQuestion> frequentMisses;

  const QuestionAnalytics({
    required this.subjectCode,
    required this.subjectName,
    required this.totalAttempted,
    required this.correctCount,
    required this.wrongCount,
    required this.accuracy,
    required this.avgTimeSeconds,
    required this.topicBreakdown,
    required this.frequentMisses,
  });
}

class TopicPerformance {
  final String topicName;
  final int attempted;
  final int correct;
  final double accuracy;
  final double avgTime;

  const TopicPerformance({
    required this.topicName,
    required this.attempted,
    required this.correct,
    required this.accuracy,
    required this.avgTime,
  });
}

class MissedQuestion {
  final String questionId;
  final String question;
  final int missCount;
  final double missRate;
  final List<String> commonWrongAnswers;

  const MissedQuestion({
    required this.questionId,
    required this.question,
    required this.missCount,
    required this.missRate,
    required this.commonWrongAnswers,
  });
}

class AnalyticsService {
  static final AnalyticsService _instance = AnalyticsService._internal();
  factory AnalyticsService() => _instance;
  AnalyticsService._internal();

  final Map<String, Map<String, dynamic>> _sessionHistory = {};
  final Map<String, List<Map<String, dynamic>>> _questionMissLog = {};

  void recordSessionResult({
    required String sessionId,
    required String subjectCode,
    required int totalQuestions,
    required int correctAnswers,
    required int wrongAnswers,
    required int timeSpentSeconds,
    required List<Map<String, dynamic>> answers,
  }) {
    _sessionHistory[sessionId] = {
      'subject_code': subjectCode,
      'timestamp': DateTime.now().toIso8601String(),
      'total_questions': totalQuestions,
      'correct_answers': correctAnswers,
      'wrong_answers': wrongAnswers,
      'duration_seconds': timeSpentSeconds,
      'accuracy': totalQuestions > 0 ? correctAnswers / totalQuestions : 0.0,
      'answers': answers,
    };

    for (final answer in answers) {
      if (!answer['is_correct'] as bool) {
        final questionId = answer['question_id'] as String;
        _questionMissLog[questionId] ??= [];
        _questionMissLog[questionId]!.add({
          'session_id': sessionId,
          'selected_option': answer['selected_option'],
          'timestamp': DateTime.now().toIso8601String(),
        });
      }
    }
  }

  QuestionAnalytics getSubjectAnalytics(String subjectCode) {
    int totalAttempted = 0;
    int correctCount = 0;
    int wrongCount = 0;
    double totalTime = 0;
    final topicMap = <String, List<Map<String, dynamic>>>{};

    for (final session in _sessionHistory.values) {
      if (session['subject_code'] != subjectCode) continue;

      totalAttempted += session['total_questions'] as int;
      correctCount += session['correct_answers'] as int;
      wrongCount += session['wrong_answers'] as int;
      totalTime += session['duration_seconds'] as int;
    }

    final accuracy = totalAttempted > 0 ? correctCount / totalAttempted : 0.0;
    final avgTime = totalAttempted > 0 ? totalTime / totalAttempted : 0.0;

    final topicBreakdown = topicMap.entries.map((e) {
      final correct = e.value.where((q) => q['is_correct'] == true).length;
      final topicAccuracy = e.value.isNotEmpty ? correct / e.value.length : 0.0;
      final topicAvgTime = e.value.isNotEmpty
          ? e.value.fold<int>(0, (sum, q) => sum + (q['time_spent_seconds'] as int)) / e.value.length
          : 0.0;
      return TopicPerformance(
        topicName: e.key,
        attempted: e.value.length,
        correct: correct,
        accuracy: topicAccuracy,
        avgTime: topicAvgTime,
      );
    }).toList();

    final frequentMisses = _getFrequentMisses(subjectCode, 5);

    final subjectName = QuestionRotationService.subjectNames[subjectCode] ?? subjectCode;

    return QuestionAnalytics(
      subjectCode: subjectCode,
      subjectName: subjectName,
      totalAttempted: totalAttempted,
      correctCount: correctCount,
      wrongCount: wrongCount,
      accuracy: accuracy,
      avgTimeSeconds: avgTime,
      topicBreakdown: topicBreakdown,
      frequentMisses: frequentMisses,
    );
  }

  List<MissedQuestion> _getFrequentMisses(String subjectCode, int limit) {
    final missedQuestions = <String, int>{};
    for (final entry in _questionMissLog.entries) {
      missedQuestions[entry.key] = entry.value.length;
    }

    final sorted = missedQuestions.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return sorted.take(limit).map((e) {
      final missCount = e.value;
      final missRate = (missCount / (_sessionHistory.length * 5)).clamp(0.0, 1.0);
      return MissedQuestion(
        questionId: e.key,
        question: 'Q${e.key}',
        missCount: missCount,
        missRate: missRate,
        commonWrongAnswers: [],
      );
    }).toList();
  }

  Map<String, dynamic> getOverallStats() {
    int totalSessions = _sessionHistory.length;
    double totalAccuracy = 0;
    int totalTimeSpent = 0;
    final subjectStats = <String, Map<String, dynamic>>{};

    for (final session in _sessionHistory.values) {
      totalAccuracy += session['accuracy'] as double;
      totalTimeSpent += session['duration_seconds'] as int;
      final subject = session['subject_code'] as String;
      subjectStats.putIfAbsent(subject, () => {
        'attempts': 0,
        'total_correct': 0,
        'total_questions': 0,
      });
      subjectStats[subject]!['attempts'] = (subjectStats[subject]!['attempts'] as int) + 1;
      subjectStats[subject]!['total_correct'] = (subjectStats[subject]!['total_correct'] as int) + (session['correct_answers'] as int);
      subjectStats[subject]!['total_questions'] = (subjectStats[subject]!['total_questions'] as int) + (session['total_questions'] as int);
    }

    return {
      'total_sessions': totalSessions,
      'avg_accuracy': totalSessions > 0 ? totalAccuracy / totalSessions : 0.0,
      'total_time_minutes': totalTimeSpent ~/ 60,
      'subject_stats': subjectStats,
    };
  }

  void clearHistory() {
    _sessionHistory.clear();
    _questionMissLog.clear();
  }
}