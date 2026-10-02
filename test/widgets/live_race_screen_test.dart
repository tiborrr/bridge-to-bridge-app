import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:geolocator/geolocator.dart';
import 'package:bridge_to_bridge_app/providers/live_race_provider.dart';
import 'package:bridge_to_bridge_app/services/location_service.dart';
import 'package:bridge_to_bridge_app/services/data_recording_service.dart';
import 'package:bridge_to_bridge_app/repositories/telemetry_repository.dart';
import 'package:bridge_to_bridge_app/usecases/analyze_telemetry_usecase.dart';
import 'package:bridge_to_bridge_app/models/trajectory.dart';
import 'package:bridge_to_bridge_app/models/rowing_models.dart';
import 'package:bridge_to_bridge_app/utils/result.dart';
import 'package:bridge_to_bridge_app/screens/live_race_screen.dart';
import 'package:bridge_to_bridge_app/widgets/live_race_map.dart';

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

void main() {
  testWidgets('LiveRaceScreen toggles between METRICS and KAART view', (tester) async {
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final mockTelemetryRepo = MockTelemetryRepository();
    final fakeLocationClient = FakeLocationClient();
    final locationService = LocationService(locationClient: fakeLocationClient);
    final analyzeUseCase = AnalyzeTelemetryUseCase();
    final dataRecordingService = DataRecordingService();

    final testTrajectory = Trajectory(
      id: 'test_trajectory',
      name: 'Brug tot Brug Test',
      startBridgeName: 'Wilhelminabrug',
      startNorthLat: 52.256,
      startNorthLng: 6.144,
      startSouthLat: 52.255,
      startSouthLng: 6.145,
      startDirectionBearing: 190.0,
      finishBridgeName: 'Spoorfietsbrug',
      finishNorthLat: 52.240,
      finishNorthLng: 6.155,
      finishSouthLat: 52.239,
      finishSouthLng: 6.156,
      finishDirectionBearing: 175.0,
    );

    when(() => mockTelemetryRepo.getLiveDashboard()).thenAnswer(
      (_) async => Success(LiveTelemetry(
        speedKmh: 12.4,
        strokeRate: 32,
        heartRate: 155,
        distanceKm: 0.45,
        timeLeadSeconds: 3,
        userProgressPercent: 25,
        opponentProgressPercent: 23,
        opponent: TeamInfo(id: 'rival_1', name: 'Rival Boat', boatType: 'C4+'),
      )),
    );
    when(() => mockTelemetryRepo.connectToTeam(any())).thenReturn(null);
    when(() => mockTelemetryRepo.teamDataStream).thenAnswer((_) => const Stream.empty());
    when(() => mockTelemetryRepo.disconnectTeam()).thenReturn(null);

    final accelStream = StreamController<UserAccelerometerEvent>.broadcast();
    final gyroStream = StreamController<GyroscopeEvent>.broadcast();

    final provider = LiveRaceProvider(
      mockTelemetryRepo,
      locationService,
      analyzeUseCase,
      dataRecordingService,
      testTrajectory,
      accelerometerStream: accelStream.stream,
      gyroscopeStream: gyroStream.stream,
      analysisInterval: null,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: ChangeNotifierProvider<LiveRaceProvider>.value(
          value: provider,
          child: LiveRaceScreen(onStop: () {}),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // In initial METRICS view:
    expect(find.text('METRICS'), findsOneWidget);
    expect(find.text('KAART'), findsOneWidget);
    expect(find.text('SNELHEID'), findsOneWidget);
    expect(find.text('SLAGTEMPO'), findsOneWidget);
    expect(find.byType(LiveRaceMap), findsNothing);

    // Switch to KAART view:
    await tester.tap(find.text('KAART'));
    await tester.pumpAndSettle();

    // Now LiveRaceMap is visible!
    expect(find.byType(LiveRaceMap), findsOneWidget);
    expect(find.text('START'), findsOneWidget);

    // Switch back to METRICS:
    await tester.tap(find.text('METRICS'));
    await tester.pumpAndSettle();

    expect(find.byType(LiveRaceMap), findsNothing);
    expect(find.text('SNELHEID'), findsOneWidget);

    provider.dispose();
    await accelStream.close();
    await gyroStream.close();
  });
}
