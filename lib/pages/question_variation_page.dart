import 'package:flutter/material.dart';
import '../services/question_variation_generator.dart';
import '../services/question_rotation_service.dart';
import '../main.dart';

class QuestionVariationPage extends StatefulWidget {
  const QuestionVariationPage({super.key});

  @override
  State<QuestionVariationPage> createState() => _QuestionVariationPageState();
}

class _QuestionVariationPageState extends State<QuestionVariationPage> {
  final _generator = QuestionVariationGenerator();
  final _rotationService = QuestionRotationService();
  List<QuestionItem> _questions = [];
  String _selectedSubject = 'PU';
  int _variationsPerType = 3;
  bool _isGenerating = false;
  List<QuestionVariation> _generatedVariations = [];
  String _status = 'Pilih subtes dan klik Generate';

  @override
  void initState() {
    super.initState();
    _loadQuestions();
  }

  Future<void> _loadQuestions() async {
    await _rotationService.initialize();
    setState(() {
      _questions = _rotationService.getQuestionsByDifficulty('PU', QuestionDifficulty.mudah);
    });
  }

  Future<void> _generateVariations() async {
    if (_questions.isEmpty) return;

    setState(() {
      _isGenerating = true;
      _status = 'Generating variations...';
      _generatedVariations = [];
    });

    try {
      final variations = <QuestionVariation>[];

      for (final q in _questions) {
        final metadata = {
          'subject_code': q.subjectCode,
          'subject': q.subject,
          'difficulty': q.difficulty.name,
          'source_number': q.sourceNumber,
        };

        final questionVariations = _generator.generateMultipleVariations(
          q.id,
          q.question,
          q.options.values.toList(),
          _getAnswerIndex(q.answer, q.options),
          q.explanation,
          metadata,
          numVariationsPerType: _variationsPerType,
        );

        variations.addAll(questionVariations);
      }

      setState(() {
        _generatedVariations = variations;
        _isGenerating = false;
        _status = 'Generated ${variations.length} variations from ${_questions.length} questions';
      });
    } catch (e) {
      setState(() {
        _isGenerating = false;
        _status = 'Error: $e';
      });
    }
  }

  int _getAnswerIndex(String answer, Map<String, String> options) {
    final keys = options.keys.toList();
    return keys.indexOf(answer);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Question Variation Generator'),
        foregroundColor: navy,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Generate Question Variations',
                      style: TextStyle(color: navy, fontSize: 18, fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'AI Worker creates numeric, name, and contextual variations to expand question pool without manual entry.',
                      style: TextStyle(color: Colors.black54),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: _selectedSubject,
                      decoration: const InputDecoration(
                        labelText: 'Subtes',
                        border: OutlineInputBorder(),
                      ),
                      items: [
                        'PU', 'PPU', 'PBM', 'PK', 'LBI', 'LBE', 'PM'
                      ].map((code) => DropdownMenuItem(
                        value: code,
                        child: Text('$code - ${QuestionRotationService.subjectNames[code] ?? code}'),
                      )).toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedSubject = value!;
                          _questions = _rotationService.getQuestionsByDifficulty(value, QuestionDifficulty.mudah);
                        });
                      },
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        const Text('Variations per type: '),
                        DropdownButton<int>(
                          value: _variationsPerType,
                          items: [1, 2, 3, 4, 5].map((v) => DropdownMenuItem(value: v, child: Text('$v'))).toList(),
                          onChanged: (v) => setState(() => _variationsPerType = v!),
                        ),
                        const SizedBox(width: 20),
                        const Text('Types: Numeric, Name, Contextual'),
                      ],
                    ),
                    const SizedBox(height: 16),
                    FilledButton.icon(
                      onPressed: _isGenerating ? null : _generateVariations,
                      icon: _isGenerating
                          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                          : const Icon(Icons.auto_awesome),
                      label: Text(_isGenerating ? 'Generating...' : 'Generate Variations'),
                      style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(50)),
                    ),
                    const SizedBox(height: 12),
                    Text(_status, style: const TextStyle(color: Colors.black54, fontSize: 13)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            if (_generatedVariations.isNotEmpty) ...[
              const Text(
                'Generated Variations',
                style: TextStyle(color: navy, fontSize: 18, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 12),
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _generatedVariations.length > 10 ? 10 : _generatedVariations.length,
                itemBuilder: (context, index) {
                  final v = _generatedVariations[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Chip(
                                label: Text(v.variationType, style: const TextStyle(fontSize: 10)),
                                backgroundColor: _getVariationColor(v.variationType).withOpacity(0.2),
                                labelStyle: TextStyle(color: _getVariationColor(v.variationType)),
                              ),
                              const SizedBox(width: 8),
                              Text('Original: ${v.originalId}', style: const TextStyle(fontSize: 12, color: Colors.black54)),
                              const Spacer(),
                              Text('${v.metadata['subject_code'] ?? ''} - ${v.metadata['difficulty'] ?? ''}',
                                  style: const TextStyle(fontSize: 11, color: blue)),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Text(v.question, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                          const SizedBox(height: 8),
                          ...v.options.asMap().entries.map((e) {
                            final isCorrect = e.key == v.answer;
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 4),
                              child: Row(
                                children: [
                                  CircleAvatar(
                                    radius: 10,
                                    backgroundColor: isCorrect ? Colors.green : Colors.transparent,
                                    child: Text(
                                      String.fromCharCode(65 + e.key),
                                      style: TextStyle(
                                        color: isCorrect ? Colors.white : navy,
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(child: Text(e.value, style: const TextStyle(fontSize: 12))),
                                ],
                              ),
                            );
                          }),
                        ],
                      ),
                    ),
                  );
                },
              ),
              if (_generatedVariations.length > 10)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Text(
                    'Showing 10 of ${_generatedVariations.length} variations',
                    style: const TextStyle(color: Colors.black54, fontSize: 12),
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }

  Color _getVariationColor(String type) {
    switch (type) {
      case 'numeric':
        return Colors.blue;
      case 'name-based':
        return Colors.purple;
      case 'contextual':
        return Colors.teal;
      default:
        return Colors.grey;
    }
  }
}