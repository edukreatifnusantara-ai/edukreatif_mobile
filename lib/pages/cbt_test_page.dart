import 'package:flutter/material.dart';
import '../services/question_rotation_service.dart';
import '../services/cbt_session_manager.dart';
import '../main.dart';

class CBTTestPage extends StatefulWidget {
  final String packageName;
  final Map<String, int>? customSubjectCounts;
  final int durationMinutes;
  final Map<QuestionDifficulty, double>? difficultyWeights;

  const CBTTestPage({
    super.key,
    required this.packageName,
    this.customSubjectCounts,
    this.durationMinutes = 230,
    this.difficultyWeights,
  });

  @override
  State<CBTTestPage> createState() => _CBTTestPageState();
}

class _CBTTestPageState extends State<CBTTestPage> {
  late Future<List<QuestionItem>> _questionsFuture;
  CBTSessionManager? _session;
  bool _showNavigation = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _questionsFuture = _generateQuestions();
  }

  Future<List<QuestionItem>> _generateQuestions() async {
    await QuestionRotationService().initialize();
    return QuestionRotationService().generateCBTPackage(
      packageName: widget.packageName,
      customSubjectCounts: widget.customSubjectCounts,
      difficultyWeights: widget.difficultyWeights ??
          const {
            QuestionDifficulty.mudah: 0.4,
            QuestionDifficulty.sedang: 0.4,
            QuestionDifficulty.sulit: 0.2,
          },
    );
  }

  void _initializeSession(List<QuestionItem> questions) {
    _session = CBTSessionManager(
      packageName: widget.packageName,
      questions: questions,
      totalDurationMinutes: widget.durationMinutes,
    );
    _session!.startTimer(_onTimerTick, _onTimeUp);
    setState(() => _isLoading = false);
  }

  void _onTimerTick() => setState(() {});
  void _onTimeUp() => _finishTest();

  void _answerQuestion(String option) {
    _session?.answerQuestion(option);
    setState(() {});
  }

  void _skipQuestion() {
    _session?.skipQuestion();
    setState(() {});
  }

  void _goToQuestion(int index) {
    _session?.goToQuestion(index);
    setState(() => _showNavigation = false);
  }

  void _finishTest() {
    if (_session == null) return;
    final result = _session!.finish();
    _session!.dispose();
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => CBTResultPage(result: result),
      ),
    );
  }

  void _confirmFinish() {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Selesaikan Try Out?'),
        content: const Text('Yakin ingin mengakhiri sesi? Waktu tersisa tidak akan dikembalikan.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              _finishTest();
            },
            child: const Text('Selesai'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _session?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return FutureBuilder<List<QuestionItem>>(
        future: _questionsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }
          if (snapshot.hasError) {
            return Scaffold(
              appBar: AppBar(title: const Text('Error')),
              body: Center(child: Text('Gagal memuat soal: ${snapshot.error}')),
            );
          }
          _initializeSession(snapshot.data!);
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        },
      );
    }

    if (_session == null) {
      return const Scaffold(body: Center(child: Text('Session tidak tersedia')));
    }

    final question = _session!.currentQuestion;
    final options = question.options;
    final progress = _session!.progress;

    return WillPopScope(
      onWillPop: () async {
        _confirmFinish();
        return false;
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.packageName),
          foregroundColor: navy,
          actions: [
            IconButton(
              icon: Icon(_showNavigation ? Icons.close : Icons.grid_view),
              onPressed: () => setState(() => _showNavigation = !_showNavigation),
              tooltip: _showNavigation ? 'Tutup navigasi' : 'Navigasi soal',
            ),
            const SizedBox(width: 8),
          ],
        ),
        body: Stack(
          children: [
            ListView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
              children: [
                Row(
                  children: [
                    TextButton.icon(
                      onPressed: _confirmFinish,
                      icon: const Icon(Icons.arrow_back),
                      label: const Align(
                        alignment: Alignment.centerLeft,
                        child: Text('Ganti Paket'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: LinearProgressIndicator(
                        value: progress,
                        minHeight: 6,
                        backgroundColor: const Color(0xFFE7ECF7),
                        valueColor: const AlwaysStoppedAnimation(blue),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      '${_session!.currentIndex + 1} / ${_session!.totalQuestions}',
                      style: const TextStyle(color: navy, fontWeight: FontWeight.w800),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  question.subject,
                  style: const TextStyle(color: blue, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                Text(
                  question.question,
                  style: const TextStyle(
                    color: navy,
                    fontSize: 17,
                    height: 1.45,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 18),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
                  decoration: BoxDecoration(
                    color: _session!.secondsLeft < 300 ? Colors.red.shade50 : blue,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.timer_outlined,
                        color: _session!.secondsLeft < 300 ? Colors.red : Colors.white,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _session!.formattedTime,
                        style: TextStyle(
                          color: _session!.secondsLeft < 300 ? Colors.red : Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const Spacer(),
                      Chip(
                        label: Text(
                          question.difficulty.name.toUpperCase(),
                          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                        ),
                        backgroundColor: _getDifficultyColor(question.difficulty).withOpacity(0.2),
                        labelStyle: TextStyle(color: _getDifficultyColor(question.difficulty)),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                ...['A', 'B', 'C', 'D', 'E'].where(options.containsKey).map((key) {
                  final isSelected = _session!.answers.length > _session!.currentIndex &&
                      _session!.answers[_session!.currentIndex].selectedOption == key;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Material(
                      color: isSelected ? blue.withOpacity(0.15) : Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      child: InkWell(
                        onTap: () => _answerQuestion(key),
                        borderRadius: BorderRadius.circular(14),
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: isSelected ? blue : Colors.grey.shade300,
                              width: isSelected ? 2 : 1,
                            ),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 32,
                                height: 32,
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  color: isSelected ? blue : Colors.transparent,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: isSelected ? blue : Colors.grey.shade400,
                                    width: 2,
                                  ),
                                ),
                                child: Text(
                                  key,
                                  style: TextStyle(
                                    color: isSelected ? Colors.white : navy,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Text(
                                  options[key]!,
                                  style: TextStyle(
                                    color: isSelected ? navy : Colors.black87,
                                    fontSize: 15,
                                    height: 1.4,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                }),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _session!.currentIndex > 0
                            ? () => _session!.goToQuestion(_session!.currentIndex - 1)
                            : null,
                        icon: const Icon(Icons.chevron_left),
                        label: const Text('Sebelumnya'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: _session!.currentIndex < _session!.totalQuestions - 1
                            ? () => _session!.goToQuestion(_session!.currentIndex + 1)
                            : _finishTest,
                        icon: Icon(_session!.currentIndex < _session!.totalQuestions - 1
                            ? Icons.chevron_right
                            : Icons.check_circle),
                        label: Text(_session!.currentIndex < _session!.totalQuestions - 1
                            ? 'Selanjutnya'
                            : 'Selesai'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: _skipQuestion,
                  icon: const Icon(Icons.skip_next),
                  label: const Text('Lewati soal ini'),
                  style: OutlinedButton.styleFrom(foregroundColor: orange),
                ),
              ],
            ),
            if (_showNavigation)
              _buildNavigationOverlay(),
          ],
        ),
      ),
    );
  }

  Widget _buildNavigationOverlay() {
    final navData = _session!.getNavigationData();
    final subjects = navData
        .map((e) => e['subject'] as String)
        .toSet()
        .toList()
      ..sort();

    return Container(
      color: Colors.black54,
      child: SafeArea(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              color: Colors.white,
              child: Row(
                children: [
                  const Text('Navigasi Soal', style: TextStyle(color: navy, fontSize: 18, fontWeight: FontWeight.bold)),
                  const Spacer(),
                  TextButton.icon(
                    onPressed: () => setState(() => _showNavigation = false),
                    icon: const Icon(Icons.close, color: navy),
                    label: const Text('Tutup', style: TextStyle(color: navy)),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  for (final subject in subjects) ...[
                    Text(subject, style: const TextStyle(color: navy, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: navData
                          .where((e) => e['subject'] == subject)
                          .map((e) {
                        final index = e['index'] as int;
                        final status = e['status'] as String;
                        Color color;
                        switch (status) {
                          case 'correct':
                            color = Colors.green;
                            break;
                          case 'wrong':
                            color = Colors.red;
                            break;
                          case 'skipped':
                            color = orange;
                            break;
                          case 'current':
                            color = blue;
                            break;
                          default:
                            color = Colors.grey.shade300;
                        }
                        return GestureDetector(
                          onTap: () => _goToQuestion(index),
                          child: Container(
                            width: 40,
                            height: 40,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: status == 'current' ? blue : color.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: color, width: status == 'current' ? 2 : 1),
                            ),
                            child: Text(
                              '${e['number']}',
                              style: TextStyle(
                                color: status == 'current' ? Colors.white : color,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),
                  ],
                  const SizedBox(height: 20),
                  const Text('Legenda:', style: TextStyle(color: navy, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 16,
                    runSpacing: 8,
                    children: [
                      _legendItem('Belum dijawab', Colors.grey.shade300),
                      _legendItem('Dijawab benar', Colors.green),
                      _legendItem('Dijawab salah', Colors.red),
                      _legendItem('Dilewati', orange),
                      _legendItem('Sedang dikerjakan', blue),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _legendItem(String label, Color color) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Container(width: 16, height: 16, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(4))),
      const SizedBox(width: 6),
      Text(label, style: const TextStyle(fontSize: 12)),
    ],
  );

  Color _getDifficultyColor(QuestionDifficulty diff) {
    switch (diff) {
      case QuestionDifficulty.mudah:
        return Colors.green;
      case QuestionDifficulty.sedang:
        return orange;
      case QuestionDifficulty.sulit:
        return Colors.red;
    }
  }
}

class CBTResultPage extends StatelessWidget {
  final CBTResult result;

  const CBTResultPage({super.key, required this.result});

  @override
  Widget build(BuildContext context) {
    final duration = result.duration;
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);

    return Scaffold(
      appBar: AppBar(title: const Text('Hasil Try Out'), foregroundColor: navy),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: navy,
              borderRadius: BorderRadius.circular(22),
            ),
            child: Column(
              children: [
                const Text('Skor Keseluruhan', style: TextStyle(color: Colors.white70, fontSize: 14)),
                const SizedBox(height: 8),
                Text(
                  '${result.score.toStringAsFixed(1)}%',
                  style: const TextStyle(color: Colors.white, fontSize: 48, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 8),
                Text(
                  '${result.correctAnswers} benar · ${result.wrongAnswers} salah · ${result.unanswered} tidak dijawab',
                  style: const TextStyle(color: Colors.white70),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.timer, color: orange, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      '${hours > 0 ? '${hours}j ' : ''}${minutes}m ${seconds}s',
                      style: const TextStyle(color: orange, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          const Text('Rincian per Subtes', style: TextStyle(color: navy, fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          ...result.subjectBreakdown.entries.map((entry) {
            final subject = entry.key;
            final total = entry.value;
            final correct = result.answers
                .where((a) => result.subjectBreakdown.containsKey(subject))
                .length;
            final score = result.subjectScores[subject] ?? 0.0;
            final subjectName = QuestionRotationService().subjectNames[subject] ?? subject;
            return Card(
              margin: const EdgeInsets.only(bottom: 10),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(child: Text(subjectName, style: const TextStyle(color: navy, fontWeight: FontWeight.bold))),
                        Text('${score.toStringAsFixed(1)}%', style: TextStyle(color: score >= 70 ? Colors.green : (score >= 50 ? orange : Colors.red), fontWeight: FontWeight.bold, fontSize: 18)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    LinearProgressIndicator(
                      value: score / 100,
                      minHeight: 8,
                      backgroundColor: const Color(0xFFE7ECF7),
                      valueColor: AlwaysStoppedAnimation(score >= 70 ? Colors.green : (score >= 50 ? orange : Colors.red)),
                    ),
                    const SizedBox(height: 4),
                    Text('$correct dari $total soal benar', style: const TextStyle(color: Colors.black54, fontSize: 12)),
                  ],
                ),
              ),
            );
          }),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: () => Navigator.of(context).popUntil((route) => route.isFirst),
            icon: const Icon(Icons.home),
            label: const Text('Kembali ke Beranda'),
            style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(50)),
          ),
        ],
      ),
    );
  }
}