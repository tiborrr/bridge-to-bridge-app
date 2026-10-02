import 'dart:async';
import '../models/rowing_models.dart';
import '../services/api_service.dart';
import '../services/websocket_service.dart';
import '../utils/result.dart';

class TelemetryRepository {
  final ApiService _apiService;
  final WebsocketService _websocketService;

  TelemetryRepository(this._apiService, this._websocketService);

  Future<Result<LiveTelemetry, Exception>> getLiveDashboard() async {
    return await _apiService.fetchLiveDashboard();
  }

  Future<Result<List<LeaderboardEntry>, Exception>> getLeaderboard({String? trajectoryId}) async {
    return await _apiService.fetchLeaderboard(trajectoryId: trajectoryId);
  }

  Future<Result<List<HistorySession>, Exception>> getHistory() async {
    return await _apiService.fetchHistory();
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
    return await _apiService.saveRaceSession(
      teamId: teamId,
      trajectoryId: trajectoryId,
      startTime: startTime,
      endTime: endTime,
      totalTimeSeconds: totalTimeSeconds,
      averageSpeedKmh: averageSpeedKmh,
      averageStrokeRate: averageStrokeRate,
    );
  }

  // Websocket Passthroughs
  void connectToTeam(String teamId) {
    _websocketService.connect(teamId);
  }

  void disconnectTeam() {
    _websocketService.disconnect();
  }

  void sendTelemetry(Map<String, dynamic> payload) {
    _websocketService.sendTelemetry(payload);
  }

  Stream<TeamData> get teamDataStream => _websocketService.teamDataStream;
}
