import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/offline_models.dart';
import '../services/cbt_session_manager.dart';
import '../services/adaptive_difficulty_service.dart';

class OfflineStorageService {
  static final OfflineStorageService _instance = OfflineStorageService._internal();
  factory OfflineStorageService() => _instance;
  OfflineStorageService._internal();

  static const String _sessionsBoxName = 'offline_sessions';
  static const String _progressBoxName = 'question_progress';
  static const String _settingsBoxName = 'offline_settings';

  Box? _sessionsBox;
  Box? _progressBox;
  Box? _settingsBox;
  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) return;
    await Hive.initFlutter();
    _sessionsBox = await Hive.openBox(_sessionsBoxName);
    _progressBox = await Hive.openBox(_progressBoxName);
    _settingsBox = await Hive.openBox(_settingsBoxName);
    _initialized = true;
  }

  Future<void> saveSession(CBTResult result, {String category = 'UTBK'}) async {
    if (!_initialized) await initialize();

    final session = OfflineSession.fromCbtResult(
      packageName: result.packageName,
      category: category,
      result: result,
    );

    await _sessionsBox!.put(session.id, session.toJson());

    for (final answer in result.answers) {
      await _updateQuestionProgress(answer);
    }

    await _updateAdaptivePerformance(result);
  }

  Future<void> _updateQuestionProgress(CBTAnswer answer) async {
    final raw = _progressBox!.get(answer.questionId);
    final progress = raw == null
        ? OfflineQuestionProgress(
            questionId: answer.questionId,
            subjectCode: '',
            lastAttempted: DateTime.now(),
          )
        : OfflineQuestionProgress.fromJson(Map<String, dynamic>.from(raw as Map));

    final updatedProgress = OfflineQuestionProgress(
      questionId: progress.questionId,
      subjectCode: progress.subjectCode,
      timesAttempted: progress.timesAttempted + 1,
      timesCorrect: progress.timesCorrect + (answer.isCorrect ? 1 : 0),
      lastTimeSpentSeconds: answer.timeSpentSeconds,
      lastAttempted: DateTime.now(),
    );

    await _progressBox!.put(answer.questionId, updatedProgress.toJson());
  }

  Future<void> _updateAdaptivePerformance(CBTResult result) async {
    for (final entry in result.adaptiveAnalytics.entries) {
      final subjectCode = entry.key;
      final analytics = entry.value as Map<String, dynamic>;
      AdaptiveDifficultyService().recordAnswer(
        subjectCode: subjectCode,
        isCorrect: (analytics['accuracy'] as num? ?? 0) >= 0.7,
        timeSpentSeconds: (analytics['avg_time'] as num?)?.toInt() ?? 60,
      );
    }
  }

  Future<List<OfflineSession>> getAllSessions() async {
    if (!_initialized) await initialize();
    final sessions = _sessionsBox!.values
        .map((value) => OfflineSession.fromJson(Map<String, dynamic>.from(value as Map)))
        .toList();
    sessions.sort((a, b) => b.endTime.compareTo(a.endTime));
    return sessions;
  }

  Future<List<OfflineSession>> getSessionsByCategory(String category) async {
    final sessions = await getAllSessions();
    return sessions.where((s) => s.category == category).toList();
  }

  Future<OfflineSession?> getSession(String id) async {
    if (!_initialized) await initialize();
    final raw = _sessionsBox!.get(id);
    if (raw == null) return null;
    return OfflineSession.fromJson(Map<String, dynamic>.from(raw as Map));
  }

  Future<void> markSessionSynced(String id) async {
    if (!_initialized) await initialize();
    final session = await getSession(id);
    if (session == null) return;
    await _sessionsBox!.put(id, session.copyWith(syncedToCloud: true).toJson());
  }

  Future<void> deleteSession(String id) async {
    if (!_initialized) await initialize();
    await _sessionsBox!.delete(id);
  }

  Future<void> clearAllSessions() async {
    if (!_initialized) await initialize();
    await _sessionsBox!.clear();
  }

  Future<Map<String, OfflineQuestionProgress>> getQuestionProgress() async {
    if (!_initialized) await initialize();
    return _progressBox!.toMap().map(
      (key, value) => MapEntry(
        key.toString(),
        OfflineQuestionProgress.fromJson(Map<String, dynamic>.from(value as Map)),
      ),
    );
  }

  Future<void> clearQuestionProgress() async {
    if (!_initialized) await initialize();
    await _progressBox!.clear();
  }

  Future<void> setSetting(String key, dynamic value) async {
    if (!_initialized) await initialize();
    await _settingsBox!.put(key, value);
  }

  dynamic getSetting(String key, {dynamic defaultValue}) {
    if (!_initialized) return defaultValue;
    return _settingsBox!.get(key, defaultValue: defaultValue);
  }

  Future<void> close() async {
    await _sessionsBox?.close();
    await _progressBox?.close();
    await _settingsBox?.close();
    _initialized = false;
  }
}