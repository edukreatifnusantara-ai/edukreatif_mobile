import 'dart:async';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/offline_models.dart';
import '../services/cbt_session_manager.dart';
import '../services/adaptive_difficulty_service.dart';

class OfflineStorageService {
  static final OfflineStorageService _instance = OfflineStorageService._internal();
  factory OfflineStorageService() => _instance;
  OfflineStorageService._internal();

  static const String _sessionsBox = 'offline_sessions';
  static const String _progressBox = 'question_progress';
  static const String _settingsBox = 'offline_settings';

  Box<OfflineSession>? _sessionsBoxInstance;
  Box<OfflineQuestionProgress>? _progressBoxInstance;
  Box? _settingsBoxInstance;
  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) return;
    await Hive.initFlutter();

    Hive.registerAdapter(OfflineSessionAdapter());
    Hive.registerAdapter(OfflineAnswerAdapter());
    Hive.registerAdapter(QuestionDifficultyAdapter());
    Hive.registerAdapter(OfflineQuestionProgressAdapter());

    _sessionsBoxInstance = await Hive.openBox<OfflineSession>(_sessionsBox);
    _progressBoxInstance = await Hive.openBox<OfflineQuestionProgress>(_progressBox);
    _settingsBoxInstance = await Hive.openBox(_settingsBox);

    _initialized = true;
  }

  Future<void> saveSession(CBTResult result, {String category = 'UTBK'}) async {
    if (!_initialized) await initialize();

    final session = OfflineSession.fromCbtResult(
      packageName: result.packageName,
      category: category,
      result: result,
    );

    await _sessionsBoxInstance!.put(session.id, session);

    for (final answer in result.answers) {
      await _updateQuestionProgress(answer);
    }

    await _updateAdaptivePerformance(result);
  }

  Future<void> _updateQuestionProgress(CBTAnswer answer) async {
    final progress = _progressBoxInstance!.get(answer.questionId) ??
        OfflineQuestionProgress(
          questionId: answer.questionId,
          subjectCode: '',
          lastAttempted: DateTime.now(),
        );

    final updatedProgress = OfflineQuestionProgress(
      questionId: progress.questionId,
      subjectCode: progress.subjectCode,
      timesAttempted: progress.timesAttempted + 1,
      timesCorrect: progress.timesCorrect + (answer.isCorrect ? 1 : 0),
      lastTimeSpentSeconds: answer.timeSpentSeconds,
      lastAttempted: DateTime.now(),
    );

    await _progressBoxInstance!.put(answer.questionId, updatedProgress);
  }

  Future<void> _updateAdaptivePerformance(CBTResult result) async {
    for (final entry in result.adaptiveAnalytics.entries) {
      final subjectCode = entry.key;
      final analytics = entry.value as Map<String, dynamic>;
      await AdaptiveDifficultyService().recordAnswer(
        subjectCode: subjectCode,
        isCorrect: analytics['accuracy'] >= 0.7,
        timeSpentSeconds: (analytics['avg_time'] as num?)?.toInt() ?? 60,
      );
    }
  }

  Future<List<OfflineSession>> getAllSessions() async {
    if (!_initialized) await initialize();
    return _sessionsBoxInstance!.values.toList()
      ..sort((a, b) => b.endTime.compareTo(a.endTime));
  }

  Future<List<OfflineSession>> getSessionsByCategory(String category) async {
    if (!_initialized) await initialize();
    return _sessionsBoxInstance!.values
        .where((s) => s.category == category)
        .toList()
      ..sort((a, b) => b.endTime.compareTo(a.endTime));
  }

  Future<OfflineSession?> getSession(String id) async {
    if (!_initialized) await initialize();
    return _sessionsBoxInstance!.get(id);
  }

  Future<void> markSessionSynced(String id) async {
    if (!_initialized) await initialize();
    final session = _sessionsBoxInstance!.get(id);
    if (session != null) {
      final updated = OfflineSession(
        id: session.id,
        packageName: session.packageName,
        category: session.category,
        startTime: session.startTime,
        endTime: session.endTime,
        totalQuestions: session.totalQuestions,
        correctAnswers: session.correctAnswers,
        wrongAnswers: session.wrongAnswers,
        unansweredCount: session.unansweredCount,
        score: session.score,
        durationSeconds: session.durationSeconds,
        answers: session.answers,
        adaptiveAnalytics: session.adaptiveAnalytics,
        syncedToCloud: true,
      );
      await _sessionsBoxInstance!.put(id, updated);
    }
  }

  Future<void> deleteSession(String id) async {
    if (!_initialized) await initialize();
    await _sessionsBoxInstance!.delete(id);
  }

  Future<void> clearAllSessions() async {
    if (!_initialized) await initialize();
    await _sessionsBoxInstance!.clear();
  }

  Future<Map<String, OfflineQuestionProgress>> getQuestionProgress() async {
    if (!_initialized) await initialize();
    return Map.from(_progressBoxInstance!.toMap());
  }

  Future<void> clearQuestionProgress() async {
    if (!_initialized) await initialize();
    await _progressBoxInstance!.clear();
  }

  Future<void> setSetting(String key, dynamic value) async {
    if (!_initialized) await initialize();
    await _settingsBoxInstance!.put(key, value);
  }

  dynamic getSetting(String key, {dynamic defaultValue}) {
    if (!_initialized) return defaultValue;
    return _settingsBoxInstance!.get(key, defaultValue: defaultValue);
  }

  Future<void> close() async {
    await _sessionsBoxInstance?.close();
    await _progressBoxInstance?.close();
    await _settingsBoxInstance?.close();
    _initialized = false;
  }
}