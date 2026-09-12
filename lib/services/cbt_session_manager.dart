import 'dart:async';
import 'package:flutter/foundation.dart';
import 'question_rotation_service.dart';

class CBTAnswer {
  final String questionId;
  final String selectedOption;
  final bool isCorrect;
  final int timeSpentSeconds;

  const CBTAnswer({
    required this.questionId,
    required this.selectedOption,
    required this.isCorrect,
    required this.timeSpentSeconds,
  });

  Map<String, dynamic> toJson() => {
    'question_id': questionId,
    'selected_option': selectedOption,
    'is_correct': isCorrect,
    'time_spent_seconds': timeSpentSeconds,
  };
}

class CBTResult {
  final String packageName;
  final DateTime startTime;
  final DateTime endTime;
  final List<CBTAnswer> answers;
  final int totalQuestions;
  final int correctAnswers;
  final int wrongAnswers;
  final int unanswered;
  final double score;
  final Map<String, int> subjectBreakdown;
  final Map<String, double> subjectScores;

  const CBTResult({
    required this.packageName,
    required this.startTime,
    required this.endTime,
    required this.answers,
    required this.totalQuestions,
    required this.correctAnswers,
    required this.wrongAnswers,
    required this.unanswered,
    required this.score,
    required this.subjectBreakdown,
    required this.subjectScores,
  });

  Duration get duration => endTime.difference(startTime);

  Map<String, dynamic> toJson() => {
    'package_name': packageName,
    'start_time': startTime.toIso8601String(),
    'end_time': endTime.toIso8601String(),
    'duration_seconds': duration.inSeconds,
    'answers': answers.map((a) => a.toJson()).toList(),
    'total_questions': totalQuestions,
    'correct_answers': correctAnswers,
    'wrong_answers': wrongAnswers,
    'unanswered': unanswered,
    'score': score,
    'subject_breakdown': subjectBreakdown,
    'subject_scores': subjectScores,
  };
}

class CBTSessionManager {
  final String packageName;
  final List<QuestionItem> questions;
  final int totalDurationMinutes;

  Timer? _timer;
  int _currentIndex = 0;
  int _secondsLeft = 0;
  final List<CBTAnswer> _answers = [];
  final List<int> _questionStartTimes = [];
  final DateTime _startTime = DateTime.now();
  bool _isPaused = false;
  int _pausedSecondsLeft = 0;

  CBTSessionManager({
    required this.packageName,
    required this.questions,
    this.totalDurationMinutes = 230,
  }) {
    _secondsLeft = totalDurationMinutes * 60;
    _questionStartTimes.add(DateTime.now().millisecondsSinceEpoch);
  }

  int get currentIndex => _currentIndex;
  int get totalQuestions => questions.length;
  int get secondsLeft => _secondsLeft;
  bool get isPaused => _isPaused;
  bool get isFinished => _currentIndex >= questions.length;
  List<CBTAnswer> get answers => List.unmodifiable(_answers);
  QuestionItem get currentQuestion => questions[_currentIndex];
  double get progress => (_currentIndex + 1) / questions.length;

  String get formattedTime {
    final minutes = (_secondsLeft ~/ 60).toString().padLeft(2, '0');
    final seconds = (_secondsLeft % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  void startTimer(void Function() onTick, VoidCallback onTimeUp) {
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!isPaused) {
        if (_secondsLeft > 0) {
          _secondsLeft--;
          onTick();
        } else {
          _timer?.cancel();
          onTimeUp();
        }
      }
    });
  }

  void pauseTimer() {
    if (!_isPaused) {
      _isPaused = true;
    }
  }

  void resumeTimer() {
    if (_isPaused) {
      _isPaused = false;
    }
  }

  void answerQuestion(String selectedOption) {
    final question = currentQuestion;
    final isCorrect = selectedOption == question.answer;
    final now = DateTime.now().millisecondsSinceEpoch;
    final timeSpent = ((now - _questionStartTimes[_currentIndex]) / 1000).round();

    _answers.add(CBTAnswer(
      questionId: question.id,
      selectedOption: selectedOption,
      isCorrect: isCorrect,
      timeSpentSeconds: timeSpent,
    ));

    _moveToNext();
  }

  void skipQuestion() {
    final question = currentQuestion;
    final now = DateTime.now().millisecondsSinceEpoch;
    final timeSpent = ((now - _questionStartTimes[_currentIndex]) / 1000).round();

    _answers.add(CBTAnswer(
      questionId: question.id,
      selectedOption: '',
      isCorrect: false,
      timeSpentSeconds: timeSpent,
    ));

    _moveToNext();
  }

  void _moveToNext() {
    if (_currentIndex < questions.length - 1) {
      _currentIndex++;
      _questionStartTimes.add(DateTime.now().millisecondsSinceEpoch);
    }
  }

  void goToQuestion(int index) {
    if (index >= 0 && index < questions.length) {
      final now = DateTime.now().millisecondsSinceEpoch;
      final timeSpent = ((now - _questionStartTimes[_currentIndex]) / 1000).round();

      if (_answers.length > _currentIndex) {
        _answers[_currentIndex] = CBTAnswer(
          questionId: _answers[_currentIndex].questionId,
          selectedOption: _answers[_currentIndex].selectedOption,
          isCorrect: _answers[_currentIndex].isCorrect,
          timeSpentSeconds: timeSpent,
        );
      } else {
        _answers.add(CBTAnswer(
          questionId: currentQuestion.id,
          selectedOption: '',
          isCorrect: false,
          timeSpentSeconds: timeSpent,
        ));
      }

      _currentIndex = index;
      if (_questionStartTimes.length <= index) {
        _questionStartTimes.add(DateTime.now().millisecondsSinceEpoch);
      }
    }
  }

  CBTResult finish() {
    _timer?.cancel();
    final endTime = DateTime.now();

    int correct = 0;
    int wrong = 0;
    int unanswered = 0;
    final subjectBreakdown = <String, int>{};
    final subjectCorrect = <String, int>{};

    for (int i = 0; i < questions.length; i++) {
      final q = questions[i];
      final subject = q.subjectCode;

      subjectBreakdown[subject] = (subjectBreakdown[subject] ?? 0) + 1;

      if (i < _answers.length) {
        final ans = _answers[i];
        if (ans.selectedOption.isEmpty) {
          unanswered++;
        } else if (ans.isCorrect) {
          correct++;
          subjectCorrect[subject] = (subjectCorrect[subject] ?? 0) + 1;
        } else {
          wrong++;
        }
      } else {
        unanswered++;
      }
    }

    final subjectScores = <String, double>{};
    for (final entry in subjectBreakdown.entries) {
      final subject = entry.key;
      final total = entry.value;
      final correctCount = subjectCorrect[subject] ?? 0;
      subjectScores[subject] = total > 0 ? (correctCount / total * 100) : 0.0;
    }

    final score = totalQuestions > 0 ? (correct / totalQuestions * 100) : 0.0;

    return CBTResult(
      packageName: packageName,
      startTime: _startTime,
      endTime: endTime,
      answers: List.unmodifiable(_answers),
      totalQuestions: totalQuestions,
      correctAnswers: correct,
      wrongAnswers: wrong,
      unanswered: unanswered,
      score: score,
      subjectBreakdown: subjectBreakdown,
      subjectScores: subjectScores,
    );
  }

  List<Map<String, dynamic>> getNavigationData() {
    return List.generate(questions.length, (index) {
      String status = 'unanswered';
      if (index < _answers.length) {
        final ans = _answers[index];
        if (ans.selectedOption.isEmpty) {
          status = 'skipped';
        } else if (ans.isCorrect) {
          status = 'correct';
        } else {
          status = 'wrong';
        }
      }
      if (index == _currentIndex) status = 'current';

      return {
        'index': index,
        'number': index + 1,
        'subject': questions[index].subjectCode,
        'status': status,
      };
    });
  }

  int getRemainingCount(String subjectCode) {
    // This method requires access to rotation service; call directly on service
    return QuestionRotationService().getRemainingCount(subjectCode);
  }

  int getTotalCount(String subjectCode) {
    return QuestionRotationService().getTotalCount(subjectCode);
  }

  Map<String, int> getRotationStats() {
    return QuestionRotationService().getRotationStats();
  }

  void dispose() {
    _timer?.cancel();
  }
}