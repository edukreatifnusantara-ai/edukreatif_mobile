import 'dart:convert';
import 'dart:math';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

int _fallbackQuestionId = 0;

enum QuestionDifficulty { mudah, sedang, sulit }

class QuestionItem {
  final String id;
  final String subjectCode;
  final String subject;
  final String question;
  final Map<String, String> options;
  final String answer;
  final String explanation;
  final QuestionDifficulty difficulty;
  final int sourceNumber;

  const QuestionItem({
    required this.id,
    required this.subjectCode,
    required this.subject,
    required this.question,
    required this.options,
    required this.answer,
    required this.explanation,
    required this.difficulty,
    required this.sourceNumber,
  });

  factory QuestionItem.fromJson(Map<String, dynamic> json) {
    String diffStr = (json['difficulty'] as String?)?.toLowerCase() ?? 'mudah';
    QuestionDifficulty diff;
    switch (diffStr) {
      case 'sedang':
        diff = QuestionDifficulty.sedang;
        break;
      case 'sulit':
        diff = QuestionDifficulty.sulit;
        break;
      default:
        diff = QuestionDifficulty.mudah;
    }

    return QuestionItem(
      id: json['id']?.toString() ?? json['source_number']?.toString() ?? 'generated-${_fallbackQuestionId++}',
      subjectCode: json['subject_code'] as String? ?? '',
      subject: json['subject'] as String? ?? '',
      question: json['question'] as String? ?? '',
      options: Map<String, String>.from(json['options'] as Map? ?? {}),
      answer: json['answer'] as String? ?? '',
      explanation: json['explanation'] as String? ?? '',
      difficulty: diff,
      sourceNumber: json['source_number'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'subject_code': subjectCode,
    'subject': subject,
    'question': question,
    'options': options,
    'answer': answer,
    'explanation': explanation,
    'difficulty': difficulty.name,
    'source_number': sourceNumber,
  };
}

class QuestionRotationService {
  static final QuestionRotationService _instance = QuestionRotationService._internal();
  factory QuestionRotationService() => _instance;
  QuestionRotationService._internal();

  static const String _prefsKey = 'question_rotation_state';
  final Map<String, List<QuestionItem>> _questionBanks = {};
  final Map<String, Set<String>> _shownQuestions = {};
  final Map<String, List<QuestionItem>> _reservePools = {};
  final Random _random = Random();
  SharedPreferences? _prefs;

  static const Map<String, String> subjectNames = {
    'PU': 'Penalaran Umum',
    'PPU': 'Pengetahuan dan Pemahaman Umum',
    'PBM': 'Pemahaman Bacaan dan Menulis',
    'PK': 'Pengetahuan Kuantitatif',
    'LBI': 'Literasi Bahasa Indonesia',
    'LBE': 'Literasi Bahasa Inggris',
    'PM': 'Penalaran Matematika',
  };

  static const Map<String, int> _defaultQuestionCounts = {
    'PU': 30,
    'PPU': 20,
    'PBM': 20,
    'PK': 20,
    'LBI': 30,
    'LBE': 20,
    'PM': 20,
  };

  Future<void> initialize() async {
    _prefs ??= await SharedPreferences.getInstance();
    await _loadAllBanks();
    _initializeReservePools();
    _loadRotationState();
  }

  Future<void> _loadAllBanks() async {
    try {
      final raw = jsonDecode(
        await rootBundle.loadString('assets/utbk_questions.json'),
      ) as Map<String, dynamic>;
      final questions = (raw['questions'] as List<dynamic>)
          .map((item) => QuestionItem.fromJson(Map<String, dynamic>.from(item as Map)))
          .toList();

      for (final code in subjectNames.keys) {
        _questionBanks[code] = questions
            .where((q) => q.subjectCode == code)
            .toList();
      }
      _questionBanks['SEMUA'] = questions;
    } catch (e) {
      _questionBanks['SEMUA'] = [];
      for (final code in subjectNames.keys) {
        _questionBanks[code] = [];
      }
    }
  }

  void _initializeReservePools() {
    for (final entry in _questionBanks.entries) {
      _reservePools[entry.key] = List.from(entry.value);
      _shownQuestions[entry.key] = {};
    }
  }

  List<QuestionItem> getRotatedQuestions({
    required String subjectCode,
    required int count,
    Map<QuestionDifficulty, double>? difficultyWeights,
    bool allowRepeats = false,
  }) {
    final bank = _questionBanks[subjectCode] ?? [];
    if (bank.isEmpty) return [];

    final shown = _shownQuestions[subjectCode] ?? {};
    final reserve = _reservePools[subjectCode] ?? [];

    List<QuestionItem> available = allowRepeats
        ? List.from(bank)
        : reserve.where((q) => !shown.contains(q.id)).toList();

    if (available.isEmpty) {
      _resetSubjectRotation(subjectCode);
      available = List.from(_reservePools[subjectCode] ?? []);
    }

    if (difficultyWeights != null) {
      available = _applyDifficultyWeights(available, difficultyWeights);
    }

    available.shuffle(_random);

    final selected = available.take(count).toList();

    if (!allowRepeats) {
      for (final q in selected) {
        shown.add(q.id);
        _reservePools[subjectCode]?.removeWhere((r) => r.id == q.id);
      }
      _saveRotationState();
    }

    return selected;
  }

  List<QuestionItem> _applyDifficultyWeights(
    List<QuestionItem> questions,
    Map<QuestionDifficulty, double> weights,
  ) {
    final grouped = <QuestionDifficulty, List<QuestionItem>>{
      QuestionDifficulty.mudah: [],
      QuestionDifficulty.sedang: [],
      QuestionDifficulty.sulit: [],
    };

    for (final q in questions) {
      grouped[q.difficulty]?.add(q);
    }

    final result = <QuestionItem>[];
    final totalWeight = weights.values.fold(0.0, (a, b) => a + b);

    for (final entry in weights.entries) {
      final difficulty = entry.key;
      final weight = entry.value / totalWeight;
      final pool = grouped[difficulty] ?? [];
      if (pool.isEmpty) continue;

      final targetCount = (questions.length * weight).round();
      pool.shuffle(_random);
      result.addAll(pool.take(targetCount));
    }

    return result;
  }

  List<QuestionItem> getMixedSubjectQuestions({
    required Map<String, int> subjectCounts,
    Map<QuestionDifficulty, double>? difficultyWeights,
    bool allowRepeats = false,
  }) {
    final result = <QuestionItem>[];

    for (final entry in subjectCounts.entries) {
      final subjectCode = entry.key;
      final count = entry.value;
      final questions = getRotatedQuestions(
        subjectCode: subjectCode,
        count: count,
        difficultyWeights: difficultyWeights,
        allowRepeats: allowRepeats,
      );
      result.addAll(questions);
    }

    result.shuffle(_random);
    return result;
  }

  Future<List<QuestionItem>> generateCBTPackage({
    required String packageName,
    Map<String, int>? customSubjectCounts,
    Map<QuestionDifficulty, double> difficultyWeights = const {
      QuestionDifficulty.mudah: 0.4,
      QuestionDifficulty.sedang: 0.4,
      QuestionDifficulty.sulit: 0.2,
    },
    bool allowRepeats = false,
  }) async {
    final subjectCounts = customSubjectCounts ?? _defaultQuestionCounts;
    return getMixedSubjectQuestions(
      subjectCounts: subjectCounts,
      difficultyWeights: difficultyWeights,
      allowRepeats: allowRepeats,
    );
  }

  void _resetSubjectRotation(String subjectCode) {
    _shownQuestions[subjectCode]?.clear();
    _reservePools[subjectCode] = List.from(_questionBanks[subjectCode] ?? []);
  }

  void _loadRotationState() {
    final raw = _prefs?.getString(_prefsKey);
    if (raw == null) return;
    try {
      final data = jsonDecode(raw) as Map<String, dynamic>;
      for (final entry in data.entries) {
        final shown = (entry.value as List<dynamic>).cast<String>().toSet();
        _shownQuestions[entry.key] = shown;
        _reservePools[entry.key] = (_questionBanks[entry.key] ?? [])
            .where((q) => !shown.contains(q.id))
            .toList();
      }
    } catch (_) {}
  }

  void _saveRotationState() {
    final data = _shownQuestions.map((key, value) => MapEntry(key, value.toList()));
    _prefs?.setString(_prefsKey, jsonEncode(data));
  }

  void resetAllRotations() {
    for (final code in subjectNames.keys) {
      _resetSubjectRotation(code);
    }
    _resetSubjectRotation('SEMUA');
    _clearRotationState();
  }

  void _clearRotationState() {
    _shownQuestions.clear();
    _reservePools.clear();
    _prefs?.remove(_prefsKey);
  }

  int getRemainingCount(String subjectCode) {
    final reserve = _reservePools[subjectCode] ?? [];
    final shown = _shownQuestions[subjectCode] ?? {};
    return reserve.where((q) => !shown.contains(q.id)).length;
  }

  int getTotalCount(String subjectCode) {
    return _questionBanks[subjectCode]?.length ?? 0;
  }

  Map<String, int> getRotationStats() {
    final stats = <String, int>{};
    for (final code in subjectNames.keys) {
      stats[code] = getRemainingCount(code);
    }
    stats['SEMUA'] = getRemainingCount('SEMUA');
    return stats;
  }

  List<QuestionItem> getQuestionsByDifficulty(
    String subjectCode,
    QuestionDifficulty difficulty,
  ) {
    final bank = _questionBanks[subjectCode] ?? [];
    return bank.where((q) => q.difficulty == difficulty).toList();
  }
}