import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:bridge_to_bridge_app/utils/gpx_parser.dart';
import 'package:bridge_to_bridge_app/services/gpx_replay_location_client.dart';
import 'package:bridge_to_bridge_app/services/location_service.dart';
import 'package:bridge_to_bridge_app/models/trajectory.dart';

void main() {
  group('GpxParser', () {
    late String gpxContent;

    setUp(() {
      gpxContent = File('assets/gpx/bridge_to_bridge.gpx').readAsStringSync();
    });

    test('parses all trackpoints and elevations from GPX file', () {
      final points = GpxParser.parse(gpxContent);

      expect(points.length, equals(48));
      expect(points.first.latitude, closeTo(52.256144, 0.0001));
      expect(points.first.longitude, closeTo(6.144437, 0.0001));
      expect(points.first.elevation, equals(4.0));

      // Check middle point (turnaround point)
      final midPoint = points[23];
      expect(midPoint.latitude, closeTo(52.24862, 0.0001));
      expect(midPoint.longitude, closeTo(6.159771, 0.0001));
    });

    test('calculates distance and bearing correctly', () {
      // 1 deg latitude is approx 111.19 km
      final dist = GpxParser.calculateDistance(52.0, 6.0, 52.01, 6.0);
      expect(dist, closeTo(1111.9, 10.0));

      // Heading straight East is 90 deg
      final bearingEast = GpxParser.calculateBearing(52.0, 6.0, 52.0, 6.01);
      expect(bearingEast, closeTo(90.0, 1.0));

      // Heading straight South is 180 deg
      final bearingSouth = GpxParser.calculateBearing(52.01, 6.0, 52.0, 6.0);
      expect(bearingSouth, closeTo(180.0, 1.0));
    });
  });

  group('GpxReplayLocationClient', () {
    late List<GpxPoint> points;
    late GpxReplayLocationClient replayClient;

    setUp(() {
      final gpxContent = File('assets/gpx/bridge_to_bridge.gpx').readAsStringSync();
      points = GpxParser.parse(gpxContent);
      replayClient = GpxReplayLocationClient(
        points: points,
        baseInterval: const Duration(milliseconds: 50),
      );
    });

    tearDown(() {
      replayClient.dispose();
    });

    test('steps through GPX points and emits updates', () async {
      final receivedPositions = [];
      final receivedIndices = [];

      replayClient.getPositionStream().listen(receivedPositions.add);
      replayClient.progressStream.listen(receivedIndices.add);

      expect(replayClient.currentIndex, equals(0));
      expect(replayClient.totalPoints, equals(48));

      // Step 1
      final pos1 = replayClient.step();
      await pumpEventQueue();

      expect(pos1, isNotNull);
      expect(pos1!.latitude, closeTo(52.256144, 0.0001));
      expect(receivedPositions.length, equals(1));
      expect(receivedIndices.first, equals(0));

      // Step 2
      final pos2 = replayClient.step();
      await pumpEventQueue();

      expect(pos2, isNotNull);
      expect(pos2!.latitude, closeTo(52.255697, 0.0001));
      expect(receivedPositions.length, equals(2));
      expect(receivedIndices[1], equals(1));
    });

    test('seeks and resets correctly', () async {
      replayClient.seek(10);
      expect(replayClient.currentIndex, equals(10));

      replayClient.reset();
      expect(replayClient.currentIndex, equals(0));
    });

    test('drives LocationService along real GPX river track', () async {
      final locationService = LocationService(locationClient: replayClient);

      // Define a trajectory across the GPX path
      // Start line at lat 52.253 (crossing around index 8-10 heading south)
      final trajectory = Trajectory(
        id: 'traj-gpx',
        name: 'IJssel Brug tot Brug',
        startBridgeName: 'Wilhelminabrug',
        startNorthLat: 52.2530,
        startNorthLng: 6.1480,
        startSouthLat: 52.2530,
        startSouthLng: 6.1520,
        startDirectionBearing: 135.0, // heading southeast
        finishBridgeName: 'Finish Line',
        finishNorthLat: 52.2490,
        finishNorthLng: 6.1570,
        finishSouthLat: 52.2490,
        finishSouthLng: 6.1610,
        finishDirectionBearing: 135.0,
      );

      final raceStates = <RaceState>[];
      locationService.raceStateStream.listen(raceStates.add);

      await locationService.startTracking([trajectory]);
      expect(locationService.currentState, equals(RaceState.waiting));

      // Replay all points until turnaround
      for (int i = 0; i <= 24; i++) {
        replayClient.step();
        await pumpEventQueue();
      }

      // Verify that the boat transitioned from waiting -> racing -> finished
      expect(raceStates, contains(RaceState.racing));
      expect(locationService.currentState, equals(RaceState.finished));

      locationService.dispose();
    });
  });
}
