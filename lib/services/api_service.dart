import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_appauth/flutter_appauth.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../models/rowing_models.dart';
import '../models/trajectory.dart';
import '../models/user_models.dart';
import '../utils/result.dart';

class ApiException implements Exception {
  final int statusCode;
  final String message;

  ApiException(this.statusCode, this.message);

  @override
  String toString() {
    return 'ApiException ($statusCode): $message';
  }
}

class AuthenticatedClient extends http.BaseClient {
  final ApiService apiService;
  final http.Client _inner;

  AuthenticatedClient(this.apiService, this._inner);

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    final token = await apiService.getValidToken();
    if (token != null) {
      request.headers['Authorization'] = 'Bearer $token';
    }
    return _inner.send(request);
  }
}

class ApiService {
  static String get baseUrl => '${dotenv.env['API_BASE_URL'] ?? 'https://brug-tot-brug.casteleijn.com'}/api/v1';
  static String get keycloakUrl => dotenv.env['KEYCLOAK_URL'] ?? 'https://auth.brug-tot-brug.casteleijn.com/realms/bridge-realm';
  static const String clientId = 'bridge-client';
  static const String redirectUrl = 'bridgeapp://login-callback';
  static String get discoveryUrl => '$keycloakUrl/.well-known/openid-configuration';

  final FlutterAppAuth _appAuth;
  final FlutterSecureStorage _secureStorage;
  late final AuthenticatedClient _httpClient;
  final http.Client _baseHttpClient;

  ApiService({
    FlutterAppAuth? appAuth,
    FlutterSecureStorage? secureStorage,
    http.Client? httpClient,
  })  : _appAuth = appAuth ?? const FlutterAppAuth(),
        _secureStorage = secureStorage ?? const FlutterSecureStorage(),
        _baseHttpClient = httpClient ?? http.Client() {
    _httpClient = AuthenticatedClient(this, _baseHttpClient);
  }

  String? _accessToken;
  String? _refreshToken;
  DateTime? _accessTokenExpiration;
  Future<bool>? _refreshFuture;

  Future<bool> initAuth() async {
    _accessToken = await _secureStorage.read(key: 'access_token');
    _refreshToken = await _secureStorage.read(key: 'refresh_token');
    final expiresStr = await _secureStorage.read(key: 'access_token_expiration');
    
    if (expiresStr != null) {
      _accessTokenExpiration = DateTime.tryParse(expiresStr);
    }

    if (_accessToken == null) return false;

    try {
      await getValidToken();
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<String?> getValidToken() async {
    if (_accessToken == null) {
      throw Exception('Je sessie is verlopen. Log alsjeblieft opnieuw in.');
    }
    
    // Check expiration using UTC and a 2-minute safety margin
    if (_accessTokenExpiration != null && DateTime.now().toUtc().isAfter(_accessTokenExpiration!.toUtc().subtract(const Duration(minutes: 2)))) {
      if (_refreshFuture != null) {
        // Wait for the ongoing refresh to complete
        await _refreshFuture;
      } else {
        // Start a new refresh and lock it
        _refreshFuture = _refreshTokens();
        try {
          await _refreshFuture;
        } finally {
          _refreshFuture = null; // Release the lock
        }
      }
    }
    
    if (_accessToken == null) {
      throw Exception('Je sessie is verlopen. Log alsjeblieft opnieuw in.');
    }
    return _accessToken;
  }

  Future<bool> _refreshTokens() async {
    if (_refreshToken == null) return false;
    
    try {
      final TokenResponse response = await _appAuth.token(TokenRequest(
        clientId,
        redirectUrl,
        discoveryUrl: discoveryUrl,
        refreshToken: _refreshToken,
        scopes: ['openid', 'profile', 'email'],
        allowInsecureConnections: true,
      ));

      if (response.accessToken != null) {
        debugPrint('Token refreshed successfully.');
        await _saveTokens(response);
        return true;
      } else {
        debugPrint('Failed to refresh token: No tokens received.');
      }
    } catch (e) {
      debugPrint('Exception during token refresh: $e');
      // Refresh failed, user needs to login again
      await logout();
    }
    return false;
  }

  Future<Result<void, Exception>> loginWithOidc() async {
    try {
      final result = await _appAuth.authorizeAndExchangeCode(
        AuthorizationTokenRequest(
          clientId,
          redirectUrl,
          discoveryUrl: discoveryUrl,
          scopes: ['openid', 'profile', 'email'],
          allowInsecureConnections: true,
        ),
      );

      if (result.accessToken != null) {
        debugPrint('Logged in successfully.');
        await _saveTokens(result);
        return const Success(null);
      } else {
        return Failure(Exception('Login was cancelled or failed without error'));
      }
    } catch (e) {
      debugPrint('Exception during login: $e');
      return Failure(Exception('Auth error: $e'));
    }
  }

  Future<void> _saveTokens(TokenResponse response) async {
    _accessToken = response.accessToken;
    _refreshToken = response.refreshToken;
    _accessTokenExpiration = response.accessTokenExpirationDateTime;

    await _secureStorage.write(key: 'access_token', value: _accessToken);
    if (_refreshToken != null) {
      await _secureStorage.write(key: 'refresh_token', value: _refreshToken);
    }
    if (_accessTokenExpiration != null) {
      await _secureStorage.write(key: 'access_token_expiration', value: _accessTokenExpiration!.toIso8601String());
    }
  }

  // --- Generic HTTP Wrappers ---

  dynamic _handleResponse(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (response.body.isEmpty) return null;
      return jsonDecode(response.body);
    } else {
      throw ApiException(response.statusCode, response.body);
    }
  }

  Future<dynamic> _get(String endpoint) async {
    final response = await _httpClient.get(Uri.parse('$baseUrl$endpoint'));
    return _handleResponse(response);
  }

  Future<dynamic> _post(String endpoint, {Map<String, dynamic>? body}) async {
    final response = await _httpClient.post(
      Uri.parse('$baseUrl$endpoint'),
      headers: {'Content-Type': 'application/json'},
      body: body != null ? jsonEncode(body) : null,
    );
    return _handleResponse(response);
  }

  Future<dynamic> _put(String endpoint, {Map<String, dynamic>? body}) async {
    final response = await _httpClient.put(
      Uri.parse('$baseUrl$endpoint'),
      headers: {'Content-Type': 'application/json'},
      body: body != null ? jsonEncode(body) : null,
    );
    return _handleResponse(response);
  }

  Future<dynamic> _delete(String endpoint) async {
    final response = await _httpClient.delete(Uri.parse('$baseUrl$endpoint'));
    return _handleResponse(response);
  }

  // --- Endpoints ---

  Future<Result<LiveTelemetry, Exception>> fetchLiveDashboard() async {
    try {
      final data = await _get('/dashboard/live');
      return Success(LiveTelemetry.fromJson(data));
    } on Exception catch (e) {
      return Failure(e);
    } catch (e) {
      return Failure(Exception(e.toString()));
    }
  }

  Future<Result<List<LeaderboardEntry>, Exception>> fetchLeaderboard({String? trajectoryId}) async {
    try {
      final endpoint = trajectoryId != null ? '/leaderboard/?trajectory_id=$trajectoryId' : '/leaderboard/';
      final data = await _get(endpoint);
      return Success(List<LeaderboardEntry>.from(data.map((model) => LeaderboardEntry.fromJson(model))));
    } on Exception catch (e) {
      return Failure(e);
    } catch (e) {
      return Failure(Exception(e.toString()));
    }
  }

  Future<Result<List<HistorySession>, Exception>> fetchHistory() async {
    try {
      final data = await _get('/history/');
      return Success(List<HistorySession>.from(data.map((model) => HistorySession.fromJson(model))));
    } on Exception catch (e) {
      return Failure(e);
    } catch (e) {
      return Failure(Exception(e.toString()));
    }
  }

  Future<Result<HistorySession, Exception>> saveRaceSession({
    required String teamId,
    required String trajectoryId,
    required DateTime startTime,
    required DateTime endTime,
    required double totalTimeSeconds,
    required double averageSpeedKmh,
    required double averageStrokeRate,
  }) async {
    try {
      final data = await _post('/history/', body: {
        'team_id': teamId,
        'trajectory_id': trajectoryId,
        'start_time': startTime.toIso8601String(),
        'end_time': endTime.toIso8601String(),
        'total_time_seconds': totalTimeSeconds,
        'average_speed_kmh': averageSpeedKmh,
        'average_stroke_rate': averageStrokeRate,
      });
      return Success(HistorySession.fromJson(data));
    } on Exception catch (e) {
      return Failure(e);
    } catch (e) {
      return Failure(Exception(e.toString()));
    }
  }

  Future<Result<List<Trajectory>, Exception>> fetchTrajectories() async {
    try {
      final data = await _get('/trajectories/');
      return Success(List<Trajectory>.from(data.map((model) => Trajectory.fromJson(model))));
    } on Exception catch (e) {
      return Failure(e);
    } catch (e) {
      return Failure(Exception(e.toString()));
    }
  }

  Future<Result<Trajectory, Exception>> createTrajectory(Trajectory trajectory) async {
    try {
      final data = await _post('/trajectories/', body: trajectory.toJson());
      return Success(Trajectory.fromJson(data));
    } on Exception catch (e) {
      return Failure(e);
    } catch (e) {
      return Failure(Exception(e.toString()));
    }
  }

  Future<Result<Trajectory, Exception>> updateTrajectory(Trajectory trajectory) async {
    try {
      final data = await _put('/trajectories/${trajectory.id}', body: trajectory.toJson());
      return Success(Trajectory.fromJson(data));
    } on Exception catch (e) {
      return Failure(e);
    } catch (e) {
      return Failure(Exception(e.toString()));
    }
  }

  Future<Result<void, Exception>> deleteTrajectory(String id) async {
    try {
      await _delete('/trajectories/$id');
      return const Success(null);
    } on Exception catch (e) {
      return Failure(e);
    } catch (e) {
      return Failure(Exception(e.toString()));
    }
  }

  // --- Users & Profiles ---

  Future<Result<UserProfile, Exception>> fetchUserProfile() async {
    try {
      final data = await _get('/users/me/preferences');
      return Success(UserProfile.fromJson(data));
    } on Exception catch (e) {
      return Failure(e);
    } catch (e) {
      return Failure(Exception(e.toString()));
    }
  }

  Future<Result<UserProfile, Exception>> updateUserProfile(UserProfile profile) async {
    try {
      final data = await _put('/users/me/preferences', body: profile.toJson());
      return Success(UserProfile.fromJson(data));
    } on Exception catch (e) {
      return Failure(e);
    } catch (e) {
      return Failure(Exception(e.toString()));
    }
  }

  // --- Teams & Invites ---

  Future<Result<List<TeamModel>, Exception>> fetchMyTeams() async {
    try {
      final data = await _get('/teams/');
      return Success(List<TeamModel>.from(data.map((model) => TeamModel.fromJson(model))));
    } on Exception catch (e) {
      return Failure(e);
    } catch (e) {
      return Failure(Exception(e.toString()));
    }
  }

  Future<Result<TeamModel, Exception>> createTeam(String name, String boatType) async {
    try {
      final data = await _post('/teams/', body: {
        'name': name,
        'boat_type': boatType,
      });
      return Success(TeamModel.fromJson(data));
    } on Exception catch (e) {
      return Failure(e);
    } catch (e) {
      return Failure(Exception(e.toString()));
    }
  }

  Future<Result<void, Exception>> inviteTeamMember(String teamId, String email) async {
    try {
      await _post('/teams/$teamId/invite', body: {'email': email});
      return const Success(null);
    } on Exception catch (e) {
      return Failure(e);
    } catch (e) {
      return Failure(Exception(e.toString()));
    }
  }

  Future<void> logout() async {
    await _secureStorage.deleteAll();
    _accessToken = null;
    _refreshToken = null;
    _accessTokenExpiration = null;
  }
}
