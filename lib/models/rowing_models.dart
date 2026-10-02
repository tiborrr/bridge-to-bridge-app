class TeamInfo {
  final String id;
  final String name;
  final String boatType;

  TeamInfo({required this.id, required this.name, required this.boatType});

  factory TeamInfo.fromJson(Map<String, dynamic> json) {
    return TeamInfo(
      id: json['id'],
      name: json['name'],
      boatType: json['boat_type'],
    );
  }
}

class LeaderboardEntry {
  final int position;
  final TeamInfo team;
  final String windConditions;
  final String weatherConditions;
  final String timeStr;

  LeaderboardEntry({
    required this.position,
    required this.team,
    required this.windConditions,
    required this.weatherConditions,
    required this.timeStr,
  });

  factory LeaderboardEntry.fromJson(Map<String, dynamic> json) {
    return LeaderboardEntry(
      position: json['position'],
      team: TeamInfo.fromJson(json['team']),
      windConditions: json['wind_conditions'],
      weatherConditions: json['weather_conditions'],
      timeStr: json['time_str'],
    );
  }
}

class LiveTelemetry {
  final double speedKmh;
  final int strokeRate;
  final int heartRate;
  final double distanceKm;
  final int timeLeadSeconds;
  final int userProgressPercent;
  final int opponentProgressPercent;
  final TeamInfo opponent;

  LiveTelemetry({
    required this.speedKmh,
    required this.strokeRate,
    required this.heartRate,
    required this.distanceKm,
    required this.timeLeadSeconds,
    required this.userProgressPercent,
    required this.opponentProgressPercent,
    required this.opponent,
  });

  factory LiveTelemetry.fromJson(Map<String, dynamic> json) {
    return LiveTelemetry(
      speedKmh: json['speed_kmh'].toDouble(),
      strokeRate: json['stroke_rate'],
      heartRate: json['heart_rate'],
      distanceKm: json['distance_km'].toDouble(),
      timeLeadSeconds: json['time_lead_seconds'],
      userProgressPercent: json['user_progress_percent'],
      opponentProgressPercent: json['opponent_progress_percent'],
      opponent: TeamInfo.fromJson(json['opponent']),
    );
  }
}

class HistorySession {
  final String id;
  final DateTime date;
  final String segmentName;
  final String timeStr;
  final double averageSpeedKmh;
  final int averageStrokeRate;

  HistorySession({
    required this.id,
    required this.date,
    required this.segmentName,
    required this.timeStr,
    required this.averageSpeedKmh,
    required this.averageStrokeRate,
  });

  factory HistorySession.fromJson(Map<String, dynamic> json) {
    return HistorySession(
      id: json['id'],
      date: DateTime.parse(json['date']),
      segmentName: json['segment_name'],
      timeStr: json['time_str'],
      averageSpeedKmh: json['average_speed_kmh'].toDouble(),
      averageStrokeRate: json['average_stroke_rate'],
    );
  }
}
