import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:sensors_plus/sensors_plus.dart';
import '../models/rowing_models.dart';
import '../models/trajectory.dart';
import '../repositories/telemetry_repository.dart';
import '../services/location_service.dart';
import '../services/websocket_service.dart';
import '../usecases/analyze_telemetry_usecase.dart';
import '../utils/result.dart';
import '../utils/stroke_rate_calculator.dart';
import '../utils/catch_rotation_calculator.dart';
import '../services/data_recording_service.dart';

class LiveRaceProvider extends ChangeNotifier {
  final TelemetryRepository _telemetryRepository;
  final LocationService _locationService;
  final AnalyzeTelemetryUseCase _analyzeUseCase;
  final DataRecordingService _dataRecordingService;
  final Trajectory selectedTrajectory;
  final int? seatNumber;
  final String? side;
  final Duration? analysisInterval;

  LiveRaceProvider(
    this._telemetryRepository, 
    this._locationService, 
    this._analyzeUseCase, 
    this._dataRecordingService,
    this.selectedTrajectory, {
    this.seatNumber, 
    this.side,
    this.analysisInterval = const Duration(seconds: 2),
    Stream<UserAccelerometerEvent>? accelerometerStream,
    Stream<GyroscopeEvent>? gyroscopeStream,
    bool autoStart = true,
  }) {
    if (autoStart) {
      _init(
        accelerometerStream: accelerometerStream,
        gyroscopeStream: gyroscopeStream,
      );
    }
  }

  Future<Result<LiveTelemetry, Exception>>? liveTelemetryFuture;

  final List<AccelerometerData> _accelBuffer = [];
  final List<GyroscopeData> _gyroBuffer = [];
  StreamSubscription<UserAccelerometerEvent>? _accelSubscription;
  StreamSubscription<GyroscopeEvent>? _gyroSubscription;
  StreamSubscription<RaceState>? _raceStateSubscription;
  StreamSubscription<double?>? _distanceSubscription;
  StreamSubscription<TeamData>? _teamDataSubscription;
  Timer? _analysisTimer;

  TelemetryAnalysisResult? currentMetrics;

  double _pitchOffset = 0.0;
  double _rollOffset = 0.0;

  RaceState raceState = RaceState.waiting;
  Trajectory? currentTrajectory;
  double? currentDistanceToTarget;
  double? initialDistanceToStart;
  double? totalRaceDistance;
  TeamData? currentTeamData;
  DateTime? _raceStartTime;

  String get targetLabel {
    if (raceState == RaceState.waiting) return "TOT AAN DE START";
    if (raceState == RaceState.racing) return "TOT AAN DE FINISH";
    return "RACE VOLTOOID";
  }

  String get distanceText {
    if (currentDistanceToTarget == null) return "--";
    if (currentDistanceToTarget! > 1000) {
      return "${(currentDistanceToTarget! / 1000).toStringAsFixed(1)} km";
    }
    return "${currentDistanceToTarget!.toStringAsFixed(0)} m";
  }

  double get progressPercent {
    if (raceState == RaceState.finished) return 1.0;
    if (currentDistanceToTarget == null) return 0.0;
    
    if (raceState == RaceState.waiting) {
      if (initialDistanceToStart == null || initialDistanceToStart! == 0) return 0.0;
      double progress = 1.0 - (currentDistanceToTarget! / initialDistanceToStart!);
      return progress.clamp(0.0, 1.0);
    } else if (raceState == RaceState.racing) {
      if (totalRaceDistance == null || totalRaceDistance! == 0) return 0.0;
      double progress = 1.0 - (currentDistanceToTarget! / totalRaceDistance!);
      return progress.clamp(0.0, 1.0);
    }
    return 0.0;
  }

  void _init({
    Stream<UserAccelerometerEvent>? accelerometerStream,
    Stream<GyroscopeEvent>? gyroscopeStream,
  }) {
    liveTelemetryFuture = _telemetryRepository.getLiveDashboard();
    _startSensors(
      accelerometerStream: accelerometerStream,
      gyroscopeStream: gyroscopeStream,
    );
    if (analysisInterval != null) {
      _analysisTimer = Timer.periodic(analysisInterval!, (_) {
        analyzeData();
      });
    }

    raceState = _locationService.currentState;
    currentTrajectory = selectedTrajectory;
    
    // Start tracking ONLY the selected trajectory
    _locationService.startTracking([selectedTrajectory]);
    
    _raceStateSubscription = _locationService.raceStateStream.listen((state) async {
      final oldState = raceState;
      raceState = state;
      
      if (oldState == RaceState.waiting && state == RaceState.racing) {
        _raceStartTime = DateTime.now();
        _dataRecordingService.startRecording('session_${_raceStartTime!.millisecondsSinceEpoch}');
      }
      
      if (state == RaceState.racing && currentTrajectory != null) {
        final startCenterLat = (currentTrajectory!.startNorthLat + currentTrajectory!.startSouthLat) / 2;
        final startCenterLng = (currentTrajectory!.startNorthLng + currentTrajectory!.startSouthLng) / 2;
        final finishCenterLat = (currentTrajectory!.finishNorthLat + currentTrajectory!.finishSouthLat) / 2;
        final finishCenterLng = (currentTrajectory!.finishNorthLng + currentTrajectory!.finishSouthLng) / 2;
        totalRaceDistance = _locationService.distanceBetween(startCenterLat, startCenterLng, finishCenterLat, finishCenterLng);
      }
      
      if (oldState == RaceState.racing && state == RaceState.finished && currentTrajectory != null && _raceStartTime != null) {
        await _dataRecordingService.stopRecording();
        
        final endTime = DateTime.now();
        final totalSeconds = endTime.difference(_raceStartTime!).inSeconds.toDouble();
        
        // Simplified metrics for MVP
        final averageSpeedKmh = totalRaceDistance != null && totalSeconds > 0 
            ? (totalRaceDistance! / 1000) / (totalSeconds / 3600) 
            : 14.0;
        final averageStrokeRate = currentMetrics?.spm ?? 30.0;
        
        // Try to find the user's team, default to a fallback if none found
        String teamId = "00000000-0000-0000-0000-000000000000"; // Fallback
        
        // Save the session
        await _telemetryRepository.saveRaceSession(
          teamId: teamId,
          trajectoryId: currentTrajectory!.id,
          startTime: _raceStartTime!,
          endTime: endTime,
          totalTimeSeconds: totalSeconds,
          averageSpeedKmh: averageSpeedKmh,
          averageStrokeRate: averageStrokeRate,
        );
      }
      notifyListeners();
    });

    _distanceSubscription = _locationService.distanceToTargetStream.listen((distance) {
      currentDistanceToTarget = distance;
      if (raceState == RaceState.waiting && initialDistanceToStart == null && distance != null) {
        initialDistanceToStart = distance;
      }
      notifyListeners();
    });

    _telemetryRepository.connectToTeam("team_brug_tot_brug"); // Hardcoded team ID for MVP
    _teamDataSubscription = _telemetryRepository.teamDataStream.listen((data) {
      currentTeamData = data;
      notifyListeners();
    });
  }

  double _lastGyroX = 0;
  double _lastGyroY = 0;
  double _lastGyroZ = 0;

  void _startSensors({
    Stream<UserAccelerometerEvent>? accelerometerStream,
    Stream<GyroscopeEvent>? gyroscopeStream,
  }) {
    final accelStream = accelerometerStream ??
        userAccelerometerEventStream(samplingPeriod: const Duration(milliseconds: 10));
    final gyroStream = gyroscopeStream ??
        gyroscopeEventStream(samplingPeriod: const Duration(milliseconds: 10));

    _accelSubscription = accelStream.listen((event) {
      final now = DateTime.now().millisecondsSinceEpoch;
      _accelBuffer.add(AccelerometerData(timestamp: now, x: event.x, y: event.y, z: event.z));
      if (_accelBuffer.length > 1000) _accelBuffer.removeAt(0);
      
      final loc = _locationService.currentLocation;
      _dataRecordingService.addDataPoint(
        timestamp: now,
        accelX: event.x,
        accelY: event.y,
        accelZ: event.z,
        gyroX: _lastGyroX,
        gyroY: _lastGyroY,
        gyroZ: _lastGyroZ,
        latitude: loc?.latitude ?? 0.0,
        longitude: loc?.longitude ?? 0.0,
      );
    });

    _gyroSubscription = gyroStream.listen((event) {
      final now = DateTime.now().millisecondsSinceEpoch;
      _gyroBuffer.add(GyroscopeData(timestamp: now, x: event.x, y: event.y, z: event.z));
      if (_gyroBuffer.length > 1000) _gyroBuffer.removeAt(0);
      
      _lastGyroX = event.x;
      _lastGyroY = event.y;
      _lastGyroZ = event.z;
    });
  }

  void analyzeData() {
    currentMetrics = _analyzeUseCase.execute(
      accelBuffer: _accelBuffer,
      gyroBuffer: _gyroBuffer,
      pitchOffset: _pitchOffset,
      rollOffset: _rollOffset,
    );

    if (currentMetrics?.spm != null) {
      _telemetryRepository.sendTelemetry({
        "role": seatNumber == 8 ? "stroke" : "rower",
        "seat_number": seatNumber,
        "side": side,
        "spm": currentMetrics!.spm!,
        "pick_in_time_ms": currentMetrics!.pickInTimeMs,
        "pick_out_time_ms": currentMetrics!.pickOutTimeMs,
        "pick_in_pitch": currentMetrics!.pitch,
        "pick_in_roll": currentMetrics!.roll,
        "pick_out_pitch": currentMetrics!.pickOutPitch,
        "pick_out_roll": currentMetrics!.pickOutRoll,
      });
    }
    notifyListeners();
  }

  void calibrate() {
    if (_accelBuffer.isNotEmpty) {
      final lastAccel = _accelBuffer.last;
      _pitchOffset = atan2(lastAccel.y, sqrt(lastAccel.x * lastAccel.x + lastAccel.z * lastAccel.z)) * 180 / pi;
      _rollOffset = atan2(-lastAccel.x, lastAccel.z) * 180 / pi;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _accelSubscription?.cancel();
    _gyroSubscription?.cancel();
    _analysisTimer?.cancel();
    _raceStateSubscription?.cancel();
    _distanceSubscription?.cancel();
    _teamDataSubscription?.cancel();
    _locationService.stopTracking();
    _telemetryRepository.disconnectTeam();
    super.dispose();
  }
}
