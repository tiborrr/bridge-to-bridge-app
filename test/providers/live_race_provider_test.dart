import 'dart:async';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:geolocator/geolocator.dart';
import 'package:bridge_to_bridge_app/providers/live_race_provider.dart';
import 'package:bridge_to_bridge_app/services/location_service.dart';
import 'package:bridge_to_bridge_app/services/data_recording_service.dart';
import 'package:bridge_to_bridge_app/services/websocket_service.dart';
import 'package:bridge_to_bridge_app/repositories/telemetry_repository.dart';
import 'package:bridge_to_bridge_app/usecases/analyze_telemetry_usecase.dart';
import 'package:bridge_to_bridge_app/models/trajectory.dart';
import 'package:bridge_to_bridge_app/models/rowing_models.dart';
import 'package:bridge_to_bridge_app/utils/result.dart';

class MockTelemetryRepository extends Mock implements TelemetryRepository {}

class FakeLocationClient implements LocationClient {
  final StreamController<Position> positionController = StreamController<Position>.broadcast();

  @override
  Future<bool> isLocationServiceEnabled() async => true;

  @override
  Future<LocationPermission> checkPermission() async => LocationPermission.always;

  @override
  Future<LocationPermission> requestPermission() async => LocationPermission.always;

  @override
  Future<Position?> getCurrentPosition({LocationSettings? locationSettings}) async => null;

  @override
  Stream<Position> getPositionStream({LocationSettings? locationSettings}) => positionController.stream;

  @override
  double distanceBetween(double startLat, double startLng, double endLat, double endLng) => 500.0;
}

Position createPosition({required double lat, required double lng, double speed = 2.0}) {
  return Position(
    latitude: lat,
    longitude: lng,
    timestamp: DateTime.now(),
    accuracy: 5.0,
    altitude: 10.0,
    altitudeAccuracy: 1.0,
    heading: 180.0,
    headingAccuracy: 1.0,
    speed: speed,
    speedAccuracy: 0.1,
  );
}

void main() {
  group('LiveRaceProvider', () {
    late MockTelemetryRepository mockTelemetryRepo;
    late FakeLocationClient fakeLocationClient;
    late LocationService locationService;
    late DataRecordingService dataRecordingService;
    late AnalyzeTelemetryUseCase analyzeUseCase;
    late Trajectory testTrajectory;
    late Directory tempDir;

    late StreamController<UserAccelerometerEvent> accelController;
    late StreamController<GyroscopeEvent> gyroController;
    late StreamController<TeamData> teamDataController;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('live_race_test');
      mockTelemetryRepo = MockTelemetryRepository();
      fakeLocationClient = FakeLocationClient();
      locationService = LocationService(locationClient: fakeLocationClient);
      dataRecordingService = DataRecordingService(directoryProvider: () async => tempDir);
      analyzeUseCase = AnalyzeTelemetryUseCase();

      accelController = StreamController<UserAccelerometerEvent>.broadcast();
      gyroController = StreamController<GyroscopeEvent>.broadcast();
      teamDataController = StreamController<TeamData>.broadcast();

      testTrajectory = Trajectory(
        id: 'traj-1',
        name: 'Deventer Race',
        startBridgeName: 'Wilhelminabrug',
        startNorthLat: 52.2500,
        startNorthLng: 6.1500,
        startSouthLat: 52.2500,
        startSouthLng: 6.1700,
        startDirectionBearing: 180.0,
        finishBridgeName: 'Spoorfietsbrug',
        finishNorthLat: 52.2400,
        finishNorthLng: 6.1500,
        finishSouthLat: 52.2400,
        finishSouthLng: 6.1700,
        finishDirectionBearing: 180.0,
      );

      when(() => mockTelemetryRepo.getLiveDashboard()).thenAnswer(
        (_) async => Success(LiveTelemetry(
          speedKmh: 12.5,
          strokeRate: 32,
          heartRate: 155,
          distanceKm: 1.2,
          timeLeadSeconds: 5,
          userProgressPercent: 50,
          opponentProgressPercent: 48,
          opponent: TeamInfo(id: 'opp-1', name: 'Opponent', boatType: 'Sloep'),
        )),
      );
      when(() => mockTelemetryRepo.connectToTeam(any())).thenReturn(null);
      when(() => mockTelemetryRepo.disconnectTeam()).thenReturn(null);
      when(() => mockTelemetryRepo.sendTelemetry(any())).thenReturn(null);
      when(() => mockTelemetryRepo.teamDataStream).thenAnswer((_) => teamDataController.stream);
      when(() => mockTelemetryRepo.saveRaceSession(
        teamId: any(named: 'teamId'),
        trajectoryId: any(named: 'trajectoryId'),
        startTime: any(named: 'startTime'),
        endTime: any(named: 'endTime'),
        totalTimeSeconds: any(named: 'totalTimeSeconds'),
        averageSpeedKmh: any(named: 'averageSpeedKmh'),
        averageStrokeRate: any(named: 'averageStrokeRate'),
      )).thenAnswer((_) async => Success(HistorySession(
        id: 'session-1',
        date: DateTime.now(),
        segmentName: 'Deventer Race',
        timeStr: '02:00',
        averageSpeedKmh: 14.0,
        averageStrokeRate: 30,
      )));
    });

    tearDown(() async {
      await accelController.close();
      await gyroController.close();
      await teamDataController.close();
      fakeLocationClient.positionController.close();
      locationService.dispose();
      if (tempDir.existsSync()) {
        tempDir.deleteSync(recursive: true);
      }
    });

    test('initializes with waiting state and receives sensor streams', () async {
      final provider = LiveRaceProvider(
        mockTelemetryRepo,
        locationService,
        analyzeUseCase,
        dataRecordingService,
        testTrajectory,
        accelerometerStream: accelController.stream,
        gyroscopeStream: gyroController.stream,
        analysisInterval: null, // manual analysis trigger in test
      );
      await pumpEventQueue();

      expect(provider.raceState, equals(RaceState.waiting));
      expect(provider.targetLabel, equals('TOT AAN DE START'));

      // Send sensor events
      accelController.add(UserAccelerometerEvent(0.1, 0.2, 9.8, DateTime.now()));
      gyroController.add(GyroscopeEvent(0.01, 0.02, 0.03, DateTime.now()));
      await pumpEventQueue();

      verify(() => mockTelemetryRepo.connectToTeam(any())).called(1);

      provider.dispose();
    });

    test('advances through race lifecycle (waiting -> racing -> finished) and saves session', () async {
      final provider = LiveRaceProvider(
        mockTelemetryRepo,
        locationService,
        analyzeUseCase,
        dataRecordingService,
        testTrajectory,
        accelerometerStream: accelController.stream,
        gyroscopeStream: gyroController.stream,
        analysisInterval: null,
      );
      await pumpEventQueue();

      expect(provider.raceState, equals(RaceState.waiting));

      // 1. Boat north of start line
      fakeLocationClient.positionController.add(createPosition(lat: 52.2550, lng: 6.1600));
      await pumpEventQueue();
      expect(provider.raceState, equals(RaceState.waiting));

      // 2. Boat crosses start line
      fakeLocationClient.positionController.add(createPosition(lat: 52.2450, lng: 6.1600));
      await pumpEventQueue();
      expect(provider.raceState, equals(RaceState.racing));
      expect(provider.targetLabel, equals('TOT AAN DE FINISH'));
      expect(dataRecordingService.isRecording, isTrue);

      // 3. Boat crosses finish line
      fakeLocationClient.positionController.add(createPosition(lat: 52.2350, lng: 6.1600));
      await pumpEventQueue();
      expect(provider.raceState, equals(RaceState.finished));
      expect(provider.targetLabel, equals('RACE VOLTOOID'));
      expect(provider.progressPercent, equals(1.0));
      expect(dataRecordingService.isRecording, isFalse);

      // Verify race session was saved
      verify(() => mockTelemetryRepo.saveRaceSession(
        teamId: any(named: 'teamId'),
        trajectoryId: testTrajectory.id,
        startTime: any(named: 'startTime'),
        endTime: any(named: 'endTime'),
        totalTimeSeconds: any(named: 'totalTimeSeconds'),
        averageSpeedKmh: any(named: 'averageSpeedKmh'),
        averageStrokeRate: any(named: 'averageStrokeRate'),
      )).called(1);

      provider.dispose();
    });

    test('updates live telemetry when team data stream emits', () async {
      final provider = LiveRaceProvider(
        mockTelemetryRepo,
        locationService,
        analyzeUseCase,
        dataRecordingService,
        testTrajectory,
        accelerometerStream: accelController.stream,
        gyroscopeStream: gyroController.stream,
        analysisInterval: null,
      );
      await pumpEventQueue();

      teamDataController.add(TeamData(
        strokeSpm: 34.0,
        seatPrecisions: [SeatPrecision(seat: 1, side: 'SB', offsetMs: -12.0)],
      ));
      await pumpEventQueue();

      expect(provider.currentTeamData, isNotNull);
      expect(provider.currentTeamData!.strokeSpm, equals(34.0));
      expect(provider.currentTeamData!.seatPrecisions.first.seat, equals(1));

      provider.dispose();
    });
  });
}
