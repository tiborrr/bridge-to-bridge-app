import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class SeatPrecision {
  final int seat;
  final String? side;
  final double offsetMs;

  SeatPrecision({required this.seat, this.side, required this.offsetMs});

  factory SeatPrecision.fromJson(Map<String, dynamic> json) {
    return SeatPrecision(
      seat: int.parse(json['seat'].toString()),
      side: json['side'],
      offsetMs: (json['offset_ms'] ?? 0).toDouble(),
    );
  }
}

class TeamData {
  final double strokeSpm;
  final List<SeatPrecision> seatPrecisions;

  TeamData({required this.strokeSpm, required this.seatPrecisions});

  factory TeamData.fromJson(Map<String, dynamic> json) {
    var precisionsList = json['seat_precisions'] as List? ?? [];
    return TeamData(
      strokeSpm: (json['stroke_spm'] ?? 0).toDouble(),
      seatPrecisions: precisionsList.map((e) => SeatPrecision.fromJson(e)).toList(),
    );
  }
}

class WebsocketService {
  WebSocketChannel? _channel;
  final _teamDataController = StreamController<TeamData>.broadcast();

  Stream<TeamData> get teamDataStream => _teamDataController.stream;

  void connect(String teamId) {
    final String baseUrl = dotenv.env['API_BASE_URL'] ?? 'https://brug-tot-brug.casteleijn.com';
    final String wsUrl = baseUrl.replaceFirst('http', 'ws');
    
    try {
      _channel = WebSocketChannel.connect(Uri.parse('$wsUrl/ws/team/$teamId'));
      
      _channel!.stream.listen((message) {
        try {
          final data = jsonDecode(message);
          if (data['type'] == 'team_update') {
            _teamDataController.add(TeamData.fromJson(data));
          }
        } catch (e) {
          debugPrint('Error parsing websocket message: $e');
        }
      }, onError: (error) {
        debugPrint('Websocket Error: $error');
      }, onDone: () {
        debugPrint('Websocket closed');
      });
    } catch (e) {
      debugPrint('Failed to connect to websocket: $e');
    }
  }

  void sendTelemetry(Map<String, dynamic> payload) {
    if (_channel != null) {
      _channel!.sink.add(jsonEncode(payload));
    }
  }

  void disconnect() {
    _channel?.sink.close();
    _channel = null;
  }
}
