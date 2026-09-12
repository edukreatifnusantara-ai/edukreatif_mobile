import 'dart:convert';
import 'package:flutter/services.dart';
import 'question_rotation_service.dart';
import 'adaptive_difficulty_service.dart';

class SKDTestSession {
  final String category; // TIU, TWK, TKP
  final List<Map<String, dynamic>> questions;
  final int totalDurationMinutes;
  final bool enableAdaptive;

  int _currentIndex = 0;
  int _secondsLeft = 0;
  final List<String> _answers = [];
  final Map<String, int> _categoryCorrect = {};
  final Map<String, int> _categoryTotal = {};
  DateTime? _startTime;
  DateTime? _endTime;

  SKDTestSession({
    required this.category,
    required this.questions,
    this.totalDurationMinutes = 100,
    this.enableAdaptive = true,
  }) {
    _secondsLeft = totalDurationMinutes * 60;
    _startTime = DateTime.now();
  }

  int get currentIndex => _currentIndex;
  int get totalQuestions => questions.length;
  int get secondsLeft => _secondsLeft;
  bool get isFinished => _currentIndex >= questions.length;
  Map<String, dynamic> get currentQuestion => questions[_currentIndex];
  double get progress => (_currentIndex + 1) / questions.length;

  String get formattedTime {
    final minutes = (_secondsLeft ~/ 60).toString().padLeft(2, '0');
    final seconds = (_secondsLeft % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  void answerQuestion(String selectedOption) {
    final question = currentQuestion;
    final correctAnswer = question['answer']?.toString() ?? '';
    final isCorrect = selectedOption == correctAnswer;

    _answers.add(selectedOption);

    if (enableAdaptive) {
      final subCategory = question['category'] as String? ?? category;
      _categoryTotal[subCategory] = (_categoryTotal[subCategory] ?? 0) + 1;
      if (isCorrect) {
        _categoryCorrect[subCategory] = (_categoryCorrect[subCategory] ?? 0) + 1;
        AdaptiveDifficultyService().recordAnswer(
          subjectCode: subCategory,
          isCorrect: true,
          timeSpentSeconds: 60,
        );
      } else {
        AdaptiveDifficultyService().recordAnswer(
          subjectCode: subCategory,
          isCorrect: false,
          timeSpentSeconds: 60,
        );
      }
    }

    if (_currentIndex < questions.length - 1) {
      _currentIndex++;
    }
  }

  void skipQuestion() {
    final question = currentQuestion;
    _answers.add('');

    if (enableAdaptive) {
      final subCategory = question['category'] as String? ?? category;
      _categoryTotal[subCategory] = (_categoryTotal[subCategory] ?? 0) + 1;
      AdaptiveDifficultyService().recordAnswer(
        subjectCode: subCategory,
        isCorrect: false,
        timeSpentSeconds: 60,
      );
    }

    if (_currentIndex < questions.length - 1) {
      _currentIndex++;
    }
  }

  void goToQuestion(int index) {
    if (index >= 0 && index < questions.length) {
      _currentIndex = index;
    }
  }

  SKDResult finish() {
    _endTime = DateTime.now();

    int correct = 0;
    int wrong = 0;
    int unanswered = 0;

    for (int i = 0; i < questions.length; i++) {
      final q = questions[i];
      final correctAnswer = q['answer']?.toString() ?? '';

      if (i < _answers.length) {
        final ans = _answers[i];
        if (ans.isEmpty) {
          unanswered++;
        } else if (ans == correctAnswer) {
          correct++;
        } else {
          wrong++;
        }
      } else {
        unanswered++;
      }
    }

    final score = totalQuestions > 0 ? (correct / totalQuestions * 100) : 0.0;
    final duration = _endTime!.difference(_startTime!);

    if (enableAdaptive) {
      for (final subCategory in _categoryTotal.keys) {
        AdaptiveDifficultyService().applyDifficultyChange(subCategory);
      }
    }

    return SKDResult(
      category: category,
      startTime: _startTime!,
      endTime: _endTime!,
      totalQuestions: totalQuestions,
      correctAnswers: correct,
      wrongAnswers: wrong,
      unansweredCount: unanswered,
      score: score,
      duration: duration,
      categoryBreakdown: Map.from(_categoryTotal),
      categoryCorrect: Map.from(_categoryCorrect),
    );
  }

  List<Map<String, dynamic>> getNavigationData() {
    return List.generate(questions.length, (index) {
      String status = 'unanswered';
      if (index < _answers.length) {
        final ans = _answers[index];
        final q = questions[index];
        final correctAnswer = q['answer']?.toString() ?? '';
        if (ans.isEmpty) {
          status = 'skipped';
        } else if (ans == correctAnswer) {
          status = 'correct';
        } else {
          status = 'wrong';
        }
      }
      if (index == _currentIndex) status = 'current';

      return {
        'index': index,
        'number': index + 1,
        'status': status,
      };
    });
  }
}

class SKDResult {
  final String category;
  final DateTime startTime;
  final DateTime endTime;
  final int totalQuestions;
  final int correctAnswers;
  final int wrongAnswers;
  final int unansweredCount;
  final double score;
  final Duration duration;
  final Map<String, int> categoryBreakdown;
  final Map<String, int> categoryCorrect;

  const SKDResult({
    required this.category,
    required this.startTime,
    required this.endTime,
    required this.totalQuestions,
    required this.correctAnswers,
    required this.wrongAnswers,
    required this.unansweredCount,
    required this.score,
    required this.duration,
    required this.categoryBreakdown,
    required this.categoryCorrect,
  });

  Map<String, dynamic> toJson() => {
    'category': category,
    'start_time': startTime.toIso8601String(),
    'end_time': endTime.toIso8601String(),
    'total_questions': totalQuestions,
    'correct_answers': correctAnswers,
    'wrong_answers': wrongAnswers,
    'unanswered': unansweredCount,
    'score': score,
    'duration_seconds': duration.inSeconds,
    'category_breakdown': categoryBreakdown,
    'category_correct': categoryCorrect,
  };
}