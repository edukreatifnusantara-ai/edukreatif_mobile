import 'dart:convert';
import 'package:flutter/services.dart';
import 'question_rotation_service.dart';

class SKDQuestionBank {
  static final SKDQuestionBank _instance = SKDQuestionBank._internal();
  factory SKDQuestionBank() => _instance;
  SKDQuestionBank._internal();

  final List<Map<String, dynamic>> _questions = [];
  final Set<String> _shownIds = {};
  final List<Map<String, dynamic>> _reserve = [];
  final Map<String, List<Map<String, dynamic>>> _groupedByCategory = {};

  final Map<String, String> _categoryNames = {
    'TIU': 'Tes Intelegensi Umum',
    'TWK': 'Tes Wawasan Kebangsaan',
    'TKP': 'Tes Karakteristik Pribadi',
  };

  Future<void> initialize() async {
    await _loadQuestions();
  }

  Future<void> _loadQuestions() async {
    try {
      final raw = jsonDecode(await rootBundle.loadString('assets/utbk_questions.json')) as Map<String, dynamic>;
      final questions = (raw['questions'] as List<dynamic>)
          .map((item) => Map<String, dynamic>.from(item as Map))
          .toList();

      for (final q in questions) {
        _questions.add(q);
        _reserve.add(q);
        final cat = _categorizeQuestion(q);
        _groupedByCategory[cat] ??= [];
        _groupedByCategory[cat]?.add(q);
      }
    } catch (e) {
      _questions.clear();
      _reserve.clear();
      _groupedByCategory.clear();
    }
  }

  String _categorizeQuestion(Map<String, dynamic> q) {
    final code = q['subject_code'] as String? ?? '';
    switch (code) {
      case 'PU':
        return 'TIU';
      case 'PPU':
      case 'PBM':
        return 'TWK';
      case 'PK':
      case 'PM':
        return 'TIU';
      case 'LBE':
      case 'LBI':
        return 'TWK';
      default:
        return 'TKP';
    }
  }

  List<Map<String, dynamic>> getRotatedQuestions({
    required String category,
    required int count,
    bool allowRepeats = false,
  }) {
    if (_questions.isEmpty) return <Map<String, dynamic>>[];

    final bank = _groupedByCategory[category] ?? <Map<String, dynamic>>[];
    if (bank.isEmpty) return <Map<String, dynamic>>[];

    final available = allowRepeats
        ? List.from(bank)
        : bank.where((q) => !_shownIds.contains(q['id']?.toString() ?? q['source_number'].toString())).toList();

    if (available.isEmpty) {
      resetRotation(category);
      return getRotatedQuestions(category: category, count: count, allowRepeats: allowRepeats);
    }

    available.shuffle();

    final selected = available.take(count).cast<Map<String, dynamic>>().toList();

    if (!allowRepeats) {
      for (final q in selected) {
        _shownIds.add(q['id']?.toString() ?? q['source_number'].toString());
        _reserve.removeWhere((r) => r['id'] == q['id'] && r['source_number'] == q['source_number']);
      }
    }

    return selected;
  }

  List<Map<String, dynamic>> getMixedQuestions({
    required Map<String, int> categoryCounts,
  }) {
    final result = <Map<String, dynamic>>[];
    for (final entry in categoryCounts.entries) {
      final questions = getRotatedQuestions(category: entry.key, count: entry.value);
      result.addAll(questions);
    }
    result.shuffle();
    return result;
  }

  void resetRotation(String category) {
    _shownIds.clear();
    _reserve.clear();
    final bank = _groupedByCategory[category] ?? [];
    _reserve.addAll(bank);
  }

  void resetAllRotations() {
    _shownIds.clear();
    _reserve.clear();
    _reserve.addAll(_questions);
  }

  int getRemainingCount(String category) {
    final bank = _groupedByCategory[category] ?? [];
    return bank.where((q) => !_shownIds.contains(q['id']?.toString() ?? q['source_number'].toString())).length;
  }
}