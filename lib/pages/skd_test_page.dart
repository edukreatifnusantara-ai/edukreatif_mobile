import 'dart:async';

import 'package:flutter/material.dart';
import '../services/skd_test_session.dart';
import '../main.dart';

class SKDTestPage extends StatefulWidget {
  final String category; // TIU, TWK, TKP
  final List<Map<String, dynamic>> questions;
  final String title;
  final int durationMinutes;

  const SKDTestPage({
    super.key,
    required this.category,
    required this.questions,
    required this.title,
    this.durationMinutes = 100,
  });

  @override
  State<SKDTestPage> createState() => _SKDTestPageState();
}

class _SKDTestPageState extends State<SKDTestPage> {
  late SKDTestSession _session;
  bool _showNavigation = false;
  late Timer _timer;

  @override
  void initState() {
    super.initState();
    _initializeSession();
  }

  void _initializeSession() {
    _session = SKDTestSession(
      category: widget.category,
      questions: widget.questions,
      totalDurationMinutes: widget.durationMinutes,
      enableAdaptive: true,
    );
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        setState(() {
          if (_session.tick()) {
            _timer.cancel();
            _finishTest();
          }
        });
      }
    });
  }

  void _answerQuestion(String option) {
    _session.answerQuestion(option);
    setState(() {});
  }

  void _skipQuestion() {
    _session.skipQuestion();
    setState(() {});
  }

  void _goToQuestion(int index) {
    _session.goToQuestion(index);
    setState(() => _showNavigation = false);
  }

  void _finishTest() {
    final result = _session.finish();
    _timer.cancel();
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => SKDResultPage(result: result),
      ),
    );
  }

  void _confirmFinish() {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Selesaikan Test?'),
        content: const Text('Yakin ingin mengakhiri sesi?'),
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
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final question = _session.currentQuestion;
    final options = question['options'] as List<dynamic>? ?? [];
    final progress = _session.progress;

    return WillPopScope(
      onWillPop: () async {
        _confirmFinish();
        return false;
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.title),
          foregroundColor: navy,
          actions: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Text(
                _session.formattedTime,
                style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
              ),
            ),
            IconButton(
              icon: Icon(_showNavigation ? Icons.close : Icons.grid_view),
              onPressed: () => setState(() => _showNavigation = !_showNavigation),
            ),
          ],
        ),
        body: Stack(
          children: [
            ListView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
              children: [
                Row(
                  children: [
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
                      '${_session.currentIndex + 1} / ${_session.totalQuestions}',
                      style: const TextStyle(color: navy, fontWeight: FontWeight.w800),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  question['question'] as String? ?? '',
                  style: const TextStyle(
                    color: navy,
                    fontSize: 17,
                    height: 1.45,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 18),
                ...List<String>.from(
                  List.generate(
                    options.length,
                    (i) => String.fromCharCode(65 + i),
                  ),
                ).asMap().entries.map((entry) {
                  final key = entry.value;
                  final index = entry.key;
                  final optionText = options[index].toString();
                  
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Material(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      child: InkWell(
                        onTap: () => _answerQuestion(key),
                        borderRadius: BorderRadius.circular(14),
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.shade300),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 32,
                                height: 32,
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  color: Colors.transparent,
                                  shape: BoxShape.circle,
                                  border: Border.all(color: Colors.grey.shade400, width: 2),
                                ),
                                child: Text(key, style: const TextStyle(fontWeight: FontWeight.bold)),
                              ),
                              const SizedBox(width: 14),
                              Expanded(child: Text(optionText, style: const TextStyle(fontSize: 15))),
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
                        onPressed: _session.currentIndex > 0
                            ? () => _session.goToQuestion(_session.currentIndex - 1)
                            : null,
                        icon: const Icon(Icons.chevron_left),
                        label: const Text('Sebelumnya'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: _session.currentIndex < _session.totalQuestions - 1
                            ? () => _session.goToQuestion(_session.currentIndex + 1)
                            : _finishTest,
                        icon: Icon(_session.currentIndex < _session.totalQuestions - 1
                            ? Icons.chevron_right
                            : Icons.check_circle),
                        label: Text(_session.currentIndex < _session.totalQuestions - 1
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
                  label: const Text('Lewati'),
                  style: OutlinedButton.styleFrom(foregroundColor: orange),
                ),
              ],
            ),
            if (_showNavigation) _buildNavigationOverlay(),
          ],
        ),
      ),
    );
  }

  Widget _buildNavigationOverlay() {
    final navData = _session.getNavigationData();
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
                  const Text('Navigasi', style: TextStyle(color: navy, fontSize: 18, fontWeight: FontWeight.bold)),
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
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: navData.map((e) {
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
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class SKDResultPage extends StatelessWidget {
  final SKDResult result;

  const SKDResultPage({super.key, required this.result});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Hasil Test'), foregroundColor: navy),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(color: navy, borderRadius: BorderRadius.circular(22)),
            child: Column(
              children: [
                const Text('Skor', style: TextStyle(color: Colors.white70, fontSize: 14)),
                const SizedBox(height: 8),
                Text(
                  '${result.score.toStringAsFixed(1)}%',
                  style: const TextStyle(color: Colors.white, fontSize: 48, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 8),
                Text(
                  '${result.correctAnswers} benar · ${result.wrongAnswers} salah · ${result.unansweredCount} tidak dijawab',
                  style: const TextStyle(color: Colors.white70),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.timer, color: orange, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      '${result.duration.inMinutes}m ${result.duration.inSeconds.remainder(60)}s',
                      style: const TextStyle(color: orange, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ],
            ),
          ),
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