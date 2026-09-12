import 'dart:math';
import 'question_rotation_service.dart';

class QuestionVariation {
  final String originalId;
  final String variationId;
  final String question;
  final List<String> options;
  final int answer;
  final String explanation;
  final String variationType; // numeric, contextual, name-based
  final Map<String, dynamic> metadata;

  const QuestionVariation({
    required this.originalId,
    required this.variationId,
    required this.question,
    required this.options,
    required this.answer,
    required this.explanation,
    required this.variationType,
    required this.metadata,
  });

  Map<String, dynamic> toJson() => {
    'id': variationId,
    'original_id': originalId,
    'subject_code': metadata['subject_code'],
    'subject': metadata['subject'],
    'question': question,
    'options': options,
    'answer': answer,
    'explanation': explanation,
    'difficulty': metadata['difficulty'],
    'variation_type': variationType,
    'metadata': metadata,
  };
}

class QuestionVariationGenerator {
  static final QuestionVariationGenerator _instance = QuestionVariationGenerator._internal();
  factory QuestionVariationGenerator() => _instance;
  QuestionVariationGenerator._internal();

  final Random _random = Random();
  final List<QuestionVariation> _generatedVariations = [];

  static const List<String> _nameVariations = [
    'Andi', 'Budi', 'Citra', 'Dewi', 'Eka', 'Farah', 'Gino', 'Hana', 'Ivan', 'Joko',
    'Karina', 'Lena', 'Maya', 'Nino', 'Oka', 'Putri', 'Qori', 'Rini', 'Sita', 'Toni',
  ];

  static const List<String> _places = [
    'Jakarta', 'Bandung', 'Surabaya', 'Medan', 'Semarang',
    'Makassar', 'Yogyakarta', 'Palembang', 'Tangerang', 'Depok',
  ];

  static const List<String> _objects = [
    'buku', 'pensil', 'tas', 'meja', 'kursi', 'papan tulis', 'kelas', 'sekolah',
    'laptop', 'ponsel', 'sepatu', 'jam', 'kacamata', 'dompet', 'kaos',
  ];

  static const Map<String, List<int>> _numericRanges = {
    'age': [5, 80],
    'price': [1000, 1000000],
    'count': [1, 100],
    'time': [1, 24],
    'distance': [1, 1000],
    'weight': [1, 500],
  };

  QuestionVariation generateNumericVariation(
    String originalId,
    String question,
    List<String> options,
    int answer,
    String explanation,
    Map<String, dynamic> metadata, {
    String rangeType = 'count',
    int multiplier = 1,
  }) {
    final range = _numericRanges[rangeType] ?? _numericRanges['count']!;
    final modifier = _random.nextInt(range[1] - range[0]) + range[0];
    final variationId = '${originalId}_num_${_generatedVariations.length}';

    String modifiedQuestion = question;
    List<String> modifiedOptions = [];

    for (final option in options) {
      String modifiedOption = option;
      final numberPattern = RegExp(r'\b(\d+)\b');
      final matches = numberPattern.allMatches(option);

      for (final match in matches) {
        final num = int.parse(match.group(1)!);
        final newNum = (num * multiplier + modifier).toInt();
        modifiedOption = modifiedOption.replaceFirst(RegExp(r'\b' + num.toString() + r'\b'), newNum.toString());
      }
      modifiedOptions.add(modifiedOption);
    }

    final questionMatches = numberPattern.allMatches(question);
    for (final match in questionMatches) {
      final num = int.parse(match.group(1)!);
      final newNum = (num * multiplier + modifier).toInt();
      modifiedQuestion = modifiedQuestion.replaceFirst(RegExp(r'\b' + num.toString() + r'\b'), newNum.toString());
    }

    String modifiedExplanation = explanation;
    final explanationMatches = numberPattern.allMatches(explanation);
    for (final match in explanationMatches) {
      final num = int.parse(match.group(1)!);
      final newNum = (num * multiplier + modifier).toInt();
      modifiedExplanation = modifiedExplanation.replaceFirst(RegExp(r'\b' + num.toString() + r'\b'), newNum.toString());
    }

    final variation = QuestionVariation(
      originalId: originalId,
      variationId: variationId,
      question: modifiedQuestion,
      options: modifiedOptions,
      answer: answer,
      explanation: modifiedExplanation,
      variationType: 'numeric',
      metadata: {
        ...metadata,
        'variation_modifier': modifier,
        'variation_range': rangeType,
      },
    );

    _generatedVariations.add(variation);
    return variation;
  }

  QuestionVariation generateNameVariation(
    String originalId,
    String question,
    List<String> options,
    int answer,
    String explanation,
    Map<String, dynamic> metadata,
  ) {
    final variationId = '${originalId}_name_${_generatedVariations.length}';
    final nameMap = <String, String>{};

    for (final original in _nameVariations) {
      nameMap[original] = _nameVariations[_random.nextInt(_nameVariations.length)];
    }

    String modifiedQuestion = question;
    List<String> modifiedOptions = [];
    String modifiedExplanation = explanation;

    for (final entry in nameMap.entries) {
      modifiedQuestion = modifiedQuestion.replaceAll(entry.key, entry.value);
      modifiedExplanation = modifiedExplanation.replaceAll(entry.key, entry.value);
    }

    for (final option in options) {
      String modifiedOption = option;
      for (final entry in nameMap.entries) {
        modifiedOption = modifiedOption.replaceAll(entry.key, entry.value);
      }
      modifiedOptions.add(modifiedOption);
    }

    final variation = QuestionVariation(
      originalId: originalId,
      variationId: variationId,
      question: modifiedQuestion,
      options: modifiedOptions,
      answer: answer,
      explanation: modifiedExplanation,
      variationType: 'name-based',
      metadata: {
        ...metadata,
        'name_map': nameMap,
      },
    );

    _generatedVariations.add(variation);
    return variation;
  }

  QuestionVariation generateContextualVariation(
    String originalId,
    String question,
    List<String> options,
    int answer,
    String explanation,
    Map<String, dynamic> metadata,
  ) {
    final variationId = '${originalId}_ctx_${_generatedVariations.length}';

    String modifiedQuestion = question;
    String modifiedExplanation = explanation;

    final placeMap = <String, String>{};
    for (final original in _places) {
      if (modifiedQuestion.contains(original)) {
        final newPlace = _places[_random.nextInt(_places.length)];
        placeMap[original] = newPlace;
        modifiedQuestion = modifiedQuestion.replaceAll(original, newPlace);
        modifiedExplanation = modifiedExplanation.replaceAll(original, newPlace);
      }
    }

    final objectMap = <String, String>{};
    for (final original in _objects) {
      if (modifiedQuestion.contains(original)) {
        final newObject = _objects[_random.nextInt(_objects.length)];
        objectMap[original] = newObject;
        modifiedQuestion = modifiedQuestion.replaceAll(original, newObject);
        modifiedExplanation = modifiedExplanation.replaceAll(original, newObject);
      }
    }

    List<String> modifiedOptions = options.map((option) {
      String modified = option;
      for (final entry in placeMap.entries) {
        modified = modified.replaceAll(entry.key, entry.value);
      }
      for (final entry in objectMap.entries) {
        modified = modified.replaceAll(entry.key, entry.value);
      }
      return modified;
    }).toList();

    final variation = QuestionVariation(
      originalId: originalId,
      variationId: variationId,
      question: modifiedQuestion,
      options: modifiedOptions,
      answer: answer,
      explanation: modifiedExplanation,
      variationType: 'contextual',
      metadata: {
        ...metadata,
        'place_map': placeMap,
        'object_map': objectMap,
      },
    );

    _generatedVariations.add(variation);
    return variation;
  }

  List<QuestionVariation> generateMultipleVariations(
    String originalId,
    String question,
    List<String> options,
    int answer,
    String explanation,
    Map<String, dynamic> metadata, {
    int numVariationsPerType = 3,
  }) {
    final variations = <QuestionVariation>[];

    // Generate numeric variations
    for (int i = 0; i < numVariationsPerType; i++) {
      final multiplier = 1 + _random.nextDouble() * 0.5;
      variations.add(
        generateNumericVariation(
          originalId,
          question,
          options,
          answer,
          explanation,
          metadata,
          multiplier: multiplier.toInt() + 1,
        ),
      );
    }

    // Generate name-based variations
    for (int i = 0; i < numVariationsPerType; i++) {
      variations.add(
        generateNameVariation(originalId, question, options, answer, explanation, metadata),
      );
    }

    // Generate contextual variations
    for (int i = 0; i < numVariationsPerType; i++) {
      variations.add(
        generateContextualVariation(originalId, question, options, answer, explanation, metadata),
      );
    }

    return variations;
  }

  List<QuestionVariation> getAllGeneratedVariations() {
    return List.unmodifiable(_generatedVariations);
  }

  void clearGeneratedVariations() {
    _generatedVariations.clear();
  }

  int getTotalGeneratedCount() {
    return _generatedVariations.length;
  }
}