import 'package:flutter/material.dart';
import '../services/analytics_service.dart';
import '../services/adaptive_difficulty_service.dart';
import '../main.dart';

class AnalyticsPage extends StatefulWidget {
  final String? initialSubject;

  const AnalyticsPage({super.key, this.initialSubject});

  @override
  State<AnalyticsPage> createState() => _AnalyticsPageState();
}

class _AnalyticsPageState extends State<AnalyticsPage> {
  late AnalyticsService _analytics;
  late AdaptiveDifficultyService _adaptive;
  String _selectedSubject = 'SEMUA';
  int _tabIndex = 0;

  @override
  void initState() {
    super.initState();
    _analytics = AnalyticsService();
    _adaptive = AdaptiveDifficultyService();
  }

  @override
  Widget build(BuildContext context) {
    final overallStats = _analytics.getOverallStats();
    final avgAccuracy = (overallStats['avg_accuracy'] as double * 100).toStringAsFixed(1);
    final totalSessions = overallStats['total_sessions'] as int;
    final totalMinutes = overallStats['total_time_minutes'] as int;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Analytics & Progress'),
        foregroundColor: navy,
      ),
      body: _tabIndex == 0
          ? _buildOverviewTab(avgAccuracy, totalSessions, totalMinutes, overallStats)
          : _buildDetailTab(),
    );
  }

  Widget _buildOverviewTab(String avgAccuracy, int totalSessions, int totalMinutes, Map<String, dynamic> overallStats) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Performance Overview',
            style: TextStyle(color: navy, fontSize: 20, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: navy,
              borderRadius: BorderRadius.circular(22),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Column(
                  children: [
                    const Text('Avg Accuracy', style: TextStyle(color: Colors.white70, fontSize: 12)),
                    const SizedBox(height: 8),
                    Text(
                      '$avgAccuracy%',
                      style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w800),
                    ),
                  ],
                ),
                Column(
                  children: [
                    const Text('Sessions', style: TextStyle(color: Colors.white70, fontSize: 12)),
                    const SizedBox(height: 8),
                    Text(
                      '$totalSessions',
                      style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w800),
                    ),
                  ],
                ),
                Column(
                  children: [
                    const Text('Total Time', style: TextStyle(color: Colors.white70, fontSize: 12)),
                    const SizedBox(height: 8),
                    Text(
                      '${totalMinutes}m',
                      style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w800),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Per Subject',
            style: TextStyle(color: navy, fontSize: 18, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 12),
          ...(overallStats['subject_stats'] as Map<String, dynamic>).entries.map((entry) {
            final subject = entry.key;
            final stats = entry.value as Map<String, dynamic>;
            final accuracy = stats['total_questions'] > 0
                ? (stats['total_correct'] as int) / (stats['total_questions'] as int) * 100
                : 0.0;
            final subjectName = _getSubjectName(subject);

            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              subjectName,
                              style: const TextStyle(color: navy, fontWeight: FontWeight.bold),
                            ),
                          ),
                          Text(
                            '${accuracy.toStringAsFixed(1)}%',
                            style: TextStyle(
                              color: accuracy >= 70 ? Colors.green : (accuracy >= 50 ? orange : Colors.red),
                              fontWeight: FontWeight.w800,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      LinearProgressIndicator(
                        value: accuracy / 100,
                        minHeight: 8,
                        backgroundColor: const Color(0xFFE7ECF7),
                        valueColor: AlwaysStoppedAnimation(
                          accuracy >= 70 ? Colors.green : (accuracy >= 50 ? orange : Colors.red),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${stats['total_correct']} / ${stats['total_questions']} correct · ${stats['attempts']} attempt(s)',
                        style: const TextStyle(color: Colors.black54, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: () => setState(() => _tabIndex = 1),
            style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(50)),
            child: const Text('View Detailed Analysis'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailTab() {
    final analyticsData = _analytics.getSubjectAnalytics(_selectedSubject);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => setState(() => _tabIndex = 0),
              ),
              Expanded(
                child: Text(
                  'Detailed: ${analyticsData.subjectName}',
                  style: const TextStyle(color: navy, fontSize: 18, fontWeight: FontWeight.w800),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: const Color(0xFFEAF1FF),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Column(
                  children: [
                    const Text('Accuracy', style: TextStyle(fontSize: 12)),
                    const SizedBox(height: 6),
                    Text(
                      '${(analyticsData.accuracy * 100).toStringAsFixed(1)}%',
                      style: const TextStyle(color: navy, fontSize: 20, fontWeight: FontWeight.w800),
                    ),
                  ],
                ),
                Column(
                  children: [
                    const Text('Attempts', style: TextStyle(fontSize: 12)),
                    const SizedBox(height: 6),
                    Text(
                      '${analyticsData.totalAttempted}',
                      style: const TextStyle(color: navy, fontSize: 20, fontWeight: FontWeight.w800),
                    ),
                  ],
                ),
                Column(
                  children: [
                    const Text('Avg Time', style: TextStyle(fontSize: 12)),
                    const SizedBox(height: 6),
                    Text(
                      '${analyticsData.avgTimeSeconds.toStringAsFixed(0)}s',
                      style: const TextStyle(color: navy, fontSize: 20, fontWeight: FontWeight.w800),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Frequently Missed',
            style: TextStyle(color: navy, fontSize: 16, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 12),
          if (analyticsData.frequentMisses.isEmpty)
            const Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Text('No missed questions yet', style: TextStyle(color: Colors.black54)),
              ),
            )
          else
            ...analyticsData.frequentMisses.map((missed) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                'Q${missed.questionId}',
                                style: const TextStyle(color: navy, fontWeight: FontWeight.bold),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.red.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                'Missed ${missed.missCount}x',
                                style: const TextStyle(color: Colors.red, fontSize: 12, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        LinearProgressIndicator(
                          value: missed.missRate,
                          minHeight: 4,
                          backgroundColor: Colors.grey.shade300,
                          valueColor: const AlwaysStoppedAnimation(Colors.red),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: () => setState(() => _tabIndex = 0),
            style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(50)),
            child: const Text('Back to Overview'),
          ),
        ],
      ),
    );
  }

  String _getSubjectName(String code) {
    const names = {
      'PU': 'Penalaran Umum',
      'PPU': 'Pengetahuan & Pemahaman Umum',
      'PBM': 'Pemahaman Bacaan & Menulis',
      'PK': 'Pengetahuan Kuantitatif',
      'LBI': 'Literasi Bahasa Indonesia',
      'LBE': 'Literasi Bahasa Inggris',
      'PM': 'Penalaran Matematika',
      'TIU': 'Tes Intelegensi Umum',
      'TWK': 'Tes Wawasan Kebangsaan',
      'TKP': 'Tes Karakteristik Pribadi',
    };
    return names[code] ?? code;
  }
}