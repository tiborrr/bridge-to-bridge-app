class Trajectory {
  final String id;
  final String name;
  
  final String startBridgeName;
  final double startNorthLat;
  final double startNorthLng;
  final double startSouthLat;
  final double startSouthLng;
  final double startDirectionBearing;
  
  final String finishBridgeName;
  final double finishNorthLat;
  final double finishNorthLng;
  final double finishSouthLat;
  final double finishSouthLng;
  final double finishDirectionBearing;

  Trajectory({
    required this.id,
    required this.name,
    required this.startBridgeName,
    required this.startNorthLat,
    required this.startNorthLng,
    required this.startSouthLat,
    required this.startSouthLng,
    required this.startDirectionBearing,
    required this.finishBridgeName,
    required this.finishNorthLat,
    required this.finishNorthLng,
    required this.finishSouthLat,
    required this.finishSouthLng,
    required this.finishDirectionBearing,
  });

  factory Trajectory.fromJson(Map<String, dynamic> json) {
    return Trajectory(
      id: json['id'],
      name: json['name'],
      startBridgeName: json['start_bridge_name'],
      startNorthLat: json['start_north_lat'].toDouble(),
      startNorthLng: json['start_north_lng'].toDouble(),
      startSouthLat: json['start_south_lat'].toDouble(),
      startSouthLng: json['start_south_lng']?.toDouble() ?? 0.0,
      startDirectionBearing: json['start_direction_bearing']?.toDouble() ?? 0.0,
      finishBridgeName: json['finish_bridge_name'] ?? '',
      finishNorthLat: json['finish_north_lat'].toDouble(),
      finishNorthLng: json['finish_north_lng'].toDouble(),
      finishSouthLat: json['finish_south_lat'].toDouble(),
      finishSouthLng: json['finish_south_lng']?.toDouble() ?? 0.0,
      finishDirectionBearing: json['finish_direction_bearing']?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'start_bridge_name': startBridgeName,
      'start_north_lat': startNorthLat,
      'start_north_lng': startNorthLng,
      'start_south_lat': startSouthLat,
      'start_south_lng': startSouthLng,
      'start_direction_bearing': startDirectionBearing,
      'finish_bridge_name': finishBridgeName,
      'finish_north_lat': finishNorthLat,
      'finish_north_lng': finishNorthLng,
      'finish_south_lat': finishSouthLat,
      'finish_south_lng': finishSouthLng,
      'finish_direction_bearing': finishDirectionBearing,
    };
  }
}
