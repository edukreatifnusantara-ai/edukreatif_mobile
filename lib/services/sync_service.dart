import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/offline_models.dart';
import '../services/offline_storage_service.dart';

class SyncService {
  static final SyncService _instance = SyncService._internal();
  factory SyncService() => _instance;
  SyncService._internal();

  static const String _baseUrl = String.fromEnvironment('EDUKREATIF_API_BASE_URL');
  static const String _syncEndpoint = '/sync/sessions';
  static const String _authTokenKey = 'sync_auth_token';

  late String _authToken;

  Future<void> initialize() async {
    _authToken = OfflineStorageService().getSetting(_authTokenKey, defaultValue: '') as String;
  }

  Future<bool> login({required String email, required String password}) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'password': password,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _authToken = data['token'] as String;
        OfflineStorageService().setSetting(_authTokenKey, _authToken);
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  Future<List<OfflineSession>> fetchSyncedSessions() async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl$_syncEndpoint'),
        headers: {
          'Authorization': 'Bearer $_authToken',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final sessions = (data['sessions'] as List)
            .map((s) => OfflineSession.fromJson(Map<String, dynamic>.from(s)))
            .toList();
        return sessions;
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  Future<bool> syncSessions() async {
    if (_authToken.isEmpty) return false;

    try {
      final storage = OfflineStorageService();
      final unsyncedSessions = await storage.getAllSessions()
          .then((sessions) => sessions.where((s) => !s.syncedToCloud).toList());

      if (unsyncedSessions.isEmpty) return true;

      final response = await http.post(
        Uri.parse('$_baseUrl$_syncEndpoint'),
        headers: {
          'Authorization': 'Bearer $_authToken',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'sessions': unsyncedSessions.map((s) => s.toJson()).toList(),
        }),
      );

      if (response.statusCode == 200) {
        for (final session in unsyncedSessions) {
          await storage.markSessionSynced(session.id);
        }
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  Future<bool> logout() async {
    try {
      await http.post(
        Uri.parse('$_baseUrl/logout'),
        headers: {
          'Authorization': 'Bearer $_authToken',
        },
      );
      OfflineStorageService().setSetting(_authTokenKey, '');
      _authToken = '';
      return true;
    } catch (e) {
      return false;
    }
  }

  bool get isLoggedIn => _authToken.isNotEmpty;

  Future<bool> ensureLoggedIn() async {
    if (_authToken.isNotEmpty) return true;
    return false;
  }
}