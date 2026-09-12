import 'package:flutter/material.dart';
import '../services/social_service.dart';
import '../services/offline_storage_service.dart';
import '../main.dart';

const Color green = Color(0xFF216B49);
const Color red = Color(0xFFD32F2F);

class SocialHubPage extends StatefulWidget {
  const SocialHubPage({super.key});

  @override
  State<SocialHubPage> createState() => _SocialHubPageState();
}

class _SocialHubPageState extends State<SocialHubPage> {
  late SocialService _socialService;
  late OfflineStorageService _offlineService;
  bool _isLoading = true;
  SocialProfile? _profile;
  List<StudyGroup> _publicGroups = [];
  List<Map<String, dynamic>> _leaderboard = [];
  String _selectedSubject = 'SEMUA';
  String _selectedPeriod = 'weekly';

  @override
  void initState() {
    super.initState();
    _initializeServices();
  }

  Future<void> _initializeServices() async {
    _socialService = SocialService();
    _offlineService = OfflineStorageService();
    await _socialService.initialize();
    await _offlineService.initialize();
    await _loadData();
    setState(() => _isLoading = false);
  }

  Future<void> _loadData() async {
    // Load or create profile
    final offlineSessions = await _offlineService.getAllSessions();
    final userId = 'user_${DateTime.now().millisecondsSinceEpoch}'; // Simplified for demo
    
    final profile = await _socialService.getProfile(userId);
    if (profile == null && offlineSessions.isNotEmpty) {
      // Create profile from first session
      final firstSession = offlineSessions.first;
      final newProfile = SocialProfile(
        userId: userId,
        displayName: 'Pelajar Kreativ',
        avatarUrl: 'https://via.placeholder.com/150',
        joinedDate: DateTime.now(),
      );
      await _socialService.saveProfile(newProfile);
      setState(() => _profile = newProfile);
    } else {
      setState(() => _profile = profile);
    }

    // Load public groups
    _publicGroups = await _socialService.getPublicGroups(
      subjectFilter: _selectedSubject == 'SEMUA' ? null : _selectedSubject,
      limit: 10,
    );

    // Load leaderboard
    final leaderboardData = await _socialService.getLeaderboard(
      _selectedSubject, 
      _selectedPeriod
    );
    if (leaderboardData != null) {
      setState(() => _leaderboard = leaderboardData);
    }
  }

  void _refreshData() {
    setState(() => _isLoading = true);
    _loadData().then((_) => setState(() => _isLoading = false));
  }

  void _createStudyGroup() {
    // In a real app, this would show a dialog to create a group
    // For demo, we'll create a sample group
    final userId = 'user_${DateTime.now().millisecondsSinceEpoch}';
    final newGroup = StudyGroup(
      groupId: 'group_${DateTime.now().millisecondsSinceEpoch}',
      name: 'Kelas Belajar Bersama',
      description: 'Gabung bersama untuk belajar dan saling membantu',
      creatorId: userId,
      memberIds: [userId],
      createdAt: DateTime.now(),
      subjectFocus: _selectedSubject,
      maxMembers: 20,
      isPublic: true,
    );
    
    _socialService.createGroup(newGroup).then((_) => _refreshData());
  }

  void _challengeFriend() {
    // In a real app, this would show a friend list and challenge options
    // For demo, we'll create a sample challenge
    final challengerId = 'user_${DateTime.now().millisecondsSinceEpoch}';
    final challenge = Challenge(
      challengeId: 'challenge_${DateTime.now().millisecondsSinceEpoch}',
      challengerId: challengerId,
      opponentIds: ['friend_1', 'friend_2'],
      challengeType: 'cbt',
      challengeData: {
        'subject': _selectedSubject,
        'questionCount': 20,
        'durationMinutes': 30,
      },
      createdAt: DateTime.now(),
      expiresAt: DateTime.now().add(const Duration(days: 3)),
      status: 'pending',
    );
    
    _socialService.createChallenge(challenge).then((_) => _refreshData());
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Komunitas Belajar'),
        foregroundColor: navy,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshData,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _profile == null
          ? const Center(child: Text('Memuat profil...'))
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Profile header
                _buildProfileHeader(),
                const SizedBox(height: 24),
                
                // Quick actions
                _buildQuickActions(),
                const SizedBox(height: 24),
                
                // Leaderboard
                _buildLeaderboardSection(),
                const SizedBox(height: 24),
                
                // Study groups
                _buildStudyGroupsSection(),
                const SizedBox(height: 24),
                
                // Challenges
                _buildChallengesSection(),
              ],
            ),
    );
  }

  Widget _buildProfileHeader() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              radius: 30,
              backgroundImage: _profile!.avatarUrl.isNotEmpty
                  ? NetworkImage(_profile!.avatarUrl)
                  : null,
              child: _profile!.avatarUrl.isEmpty
                  ? const Icon(Icons.person, size: 30, color: blue)
                  : null,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _profile!.displayName,
                    style: const TextStyle(
                      color: navy,
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Level ${_profile!.level} • ${_profile!.totalPoints} poin',
                    style: const TextStyle(color: Colors.black54, fontSize: 14),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Chip(
                        label: Text('${_profile!.badges.length} Badges'),
                        backgroundColor: orange.withOpacity(0.2),
                        labelStyle: const TextStyle(color: orange),
                      ),
                      const SizedBox(width: 8),
                      Chip(
                        label: Text('${DateTime.now().difference(_profile!.joinedDate).inDays} hari bergabung'),
                        backgroundColor: blue.withOpacity(0.2),
                        labelStyle: const TextStyle(color: blue),
                      ),
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

  Widget _buildQuickActions() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Tindakan Cepat',
              style: TextStyle(color: navy, fontSize: 18, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _createStudyGroup,
                    icon: const Icon(Icons.group_add),
                    label: const Text('Buat Kelas Belajar'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: blue,
                      foregroundColor: Colors.white,
                      minimumSize: const Size.fromHeight(48),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _challengeFriend,
                    icon: const Icon(Icons.people_alt),
                    label: const Text('Tantang Teman'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: orange,
                      foregroundColor: Colors.white,
                      minimumSize: const Size.fromHeight(48),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLeaderboardSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Peringkat Mingguan',
              style: TextStyle(color: navy, fontSize: 18, fontWeight: FontWeight.w800),
            ),
            DropdownButton<String>(
              value: _selectedSubject,
              items: [
                'SEMUA',
                'PU', 'PPU', 'PBM', 'PK', 'LBI', 'LBE', 'PM',
                'TIU', 'TWK', 'TKP'
              ].map((subject) => DropdownMenuItem(
                value: subject,
                child: Text('$subject - ${_getSubjectName(subject)}'),
              )).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedSubject = value!;
                  _loadLeaderboard();
                });
              },
            ),
          ],
        ),
        const SizedBox(height: 8),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              DropdownButton<String>(
                value: _selectedPeriod,
                items: [
                  'daily',
                  'weekly',
                  'monthly',
                  'all_time'
                ].map((period) => DropdownMenuItem(
                  value: period,
                  child: Text(_getPeriodName(period)),
                )).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedPeriod = value!;
                    _loadLeaderboard();
                  });
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        _leaderboard.isEmpty
            ? const Center(
                child: Text(
                  'Belum ada data peringkat',
                  style: TextStyle(color: Colors.black54, fontSize: 16),
                ),
              )
            : ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _leaderboard.length > 10 ? 10 : _leaderboard.length,
                itemBuilder: (context, index) {
                  final entry = _leaderboard[index];
                  final rank = index + 1;
                  final isCurrentUser = entry['user_id'] == _profile!.userId;
                  
                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    decoration: BoxDecoration(
                      color: isCurrentUser ? blue.withOpacity(0.1) : Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isCurrentUser ? blue : Colors.grey.shade300,
                        width: isCurrentUser ? 2 : 1,
                      ),
                    ),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: 
                            rank <= 3 
                                ? [Colors.red, Colors.orange, Colors.green][rank - 1] 
                                : Colors.grey,
                        child: Text(
                          '$rank',
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                      ),
                      title: Text(
                        entry['display_name'] ?? 'Anonim',
                        style: TextStyle(
                          fontWeight: isCurrentUser ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                      subtitle: Text('${entry['score']?.toStringAsFixed(1)}% • ${entry['time']}m'),
                      trailing: isCurrentUser
                          ? const Icon(Icons.verified, color: green)
                          : null,
                    ),
                  );
                },
              ),
      ],
    );
  }

  void _loadLeaderboard() async {
    final leaderboardData = await _socialService.getLeaderboard(
      _selectedSubject, 
      _selectedPeriod
    );
    if (leaderboardData != null && mounted) {
      setState(() => _leaderboard = leaderboardData);
    }
  }

  Widget _buildStudyGroupsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Kelas Belajar Populer',
              style: TextStyle(color: navy, fontSize: 18, fontWeight: FontWeight.w800),
            ),
            TextButton(
              onPressed: () => _showAllGroups(),
              child: const Text('Lihat Semua'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        _publicGroups.isEmpty
            ? const Center(
                child: Text(
                  'Belum ada kelas belajar',
                  style: TextStyle(color: Colors.black54, fontSize: 16),
                ),
              )
            : ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _publicGroups.length,
                itemBuilder: (context, index) {
                  final group = _publicGroups[index];
                  final isMember = group.memberIds.contains(_profile!.userId);
                  
                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: blue.withOpacity(0.2),
                        child: Text(
                          '${group.memberIds.length}/${group.maxMembers}',
                          style: const TextStyle(color: blue, fontWeight: FontWeight.bold),
                        ),
                      ),
                      title: Text(
                        group.name,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(group.description),
                          const SizedBox(height: 4),
                          Text(
                            'Fokus: ${_getSubjectName(group.subjectFocus)} • ${DateTime.now().difference(group.createdAt).inDays} hari lalu',
                            style: const TextStyle(fontSize: 12, color: Colors.black54),
                          ),
                        ],
                      ),
                      trailing: isMember
                          ? const Icon(Icons.check_circle, color: green)
                          : ElevatedButton(
                              onPressed: () => _joinGroup(group.groupId),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: blue,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              ),
                              child: const Text('Gabung'),
                            ),
                    ),
                  );
                },
              ),
      ],
    );
  }

  void _joinGroup(String groupId) {
    _socialService.joinGroup(groupId, _profile!.userId).then((_) => _refreshData());
  }

  void _showAllGroups() {
    // In a real app, this would navigate to a full groups list page
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Fitur lengkap kelas belajar akan segera hadir')),
    );
  }

  Widget _buildChallengesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Tantangan Aktif',
              style: TextStyle(color: navy, fontSize: 18, fontWeight: FontWeight.w800),
            ),
            TextButton(
              onPressed: () => _showAllChallenges(),
              child: const Text('Lihat Semua'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        FutureBuilder<List<Challenge>>(
          future: _socialService.getPendingChallengesForUser(_profile!.userId),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
            }
            final challenges = snapshot.data ?? [];
            
            return challenges.isEmpty
                ? const Center(
                    child: Text(
                      'Tidak ada tantangan yang menunggu',
                      style: TextStyle(color: Colors.black54, fontSize: 16),
                    ),
                  )
                : ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: challenges.length,
                    itemBuilder: (context, index) {
                      final challenge = challenges[index];
                      
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: orange.withOpacity(0.2),
                            child: const Icon(Icons.people_alt, color: orange),
                          ),
                          title: Text(
                            'Tantangan CBT',
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Dari: ${_getDisplayName(challenge.challengerId)}',
                                style: const TextStyle(fontSize: 12),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Waktu tersisa: ${challenge.expiresAt?.difference(DateTime.now()).inHours ?? 0} jam',
                                style: const TextStyle(fontSize: 12, color: Colors.black54),
                              ),
                            ],
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              TextButton(
                                onPressed: () => _acceptChallenge(challenge.challengeId),
                                child: const Text('Terima'),
                                style: TextButton.styleFrom(
                                  foregroundColor: green,
                                ),
                              ),
                              const SizedBox(width: 4),
                              TextButton(
                                onPressed: () => _declineChallenge(challenge.challengeId),
                                child: const Text('Tolak'),
                                style: TextButton.styleFrom(
                                  foregroundColor: red,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
          },
        ),
      ],
    );
  }

  void _acceptChallenge(String challengeId) {
    _socialService.acceptChallenge(challengeId, _profile!.userId).then((_) => _refreshData());
  }

  void _declineChallenge(String challengeId) {
    // In a real app, we might move to completed or delete
    // For simplicity, we'll just remove it
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Fitur penolakan tantangan akan segera hadir')),
    );
  }

  void _showAllChallenges() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Fitur lengkap tantangan akan segera hadir')),
    );
  }

  String _getSubjectName(String code) {
    const names = {
      'SEMUA': 'Semua Subtes',
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

  String _getPeriodName(String period) {
    const names = {
      'daily': 'Harian',
      'weekly': 'Mingguan',
      'monthly': 'Bulanan',
      'all_time': 'Selama Ini',
    };
    return names[period] ?? period;
  }

  String _getDisplayName(String userId) {
    // In a real app, we'd look up the profile
    if (userId == _profile!.userId) {
      return 'Anda';
    }
    return 'Teman';
  }
}