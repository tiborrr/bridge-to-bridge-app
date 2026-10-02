import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:bridge_to_bridge_app/services/location_service.dart';
import 'package:bridge_to_bridge_app/models/trajectory.dart';

class FakeLocationClient implements LocationClient {
  bool serviceEnabled = true;
  LocationPermission permission = LocationPermission.always;
  Position? currentPosition;
  final StreamController<Position> positionController = StreamController<Position>.broadcast();

  @override
  Future<bool> isLocationServiceEnabled() async => serviceEnabled;

  @override
  Future<LocationPermission> checkPermission() async => permission;

  @override
  Future<LocationPermission> requestPermission() async => permission;

  @override
  Future<Position?> getCurrentPosition({LocationSettings? locationSettings}) async => currentPosition;

  @override
  Stream<Position> getPositionStream({LocationSettings? locationSettings}) => positionController.stream;

  @override
  double distanceBetween(double startLat, double startLng, double endLat, double endLng) {
    // Pure calculation without native platform channel
    // Haversine approximation
    final dLat = (endLat - startLat) * 111000;
    final dLng = (endLng - startLng) * 111000 * 0.6; // approx cos(52 deg)
    return (dLat * dLat + dLng * dLng) > 0 ? (dLat * dLat + dLng * dLng) : 0.0;
  }
}

Position createPosition({
  required double latitude,
  required double longitude,
  double speed = 1.0,
}) {
  return Position(
    latitude: latitude,
    longitude: longitude,
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
  group('LocationService', () {
    late FakeLocationClient fakeClient;
    late LocationService locationService;
    late Trajectory testTrajectory;

    setUp(() {
      fakeClient = FakeLocationClient();
      locationService = LocationService(locationClient: fakeClient);

      testTrajectory = Trajectory(
        id: 'traj-1',
        name: 'Brug tot Brug',
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
    });

    tearDown(() {
      locationService.dispose();
      fakeClient.positionController.close();
    });

    test('fetchCurrentLocation updates currentLocation when permission is granted', () async {
      fakeClient.currentPosition = createPosition(latitude: 52.2550, longitude: 6.1600);

      await locationService.fetchCurrentLocation();

      expect(locationService.currentLocation, isNotNull);
      expect(locationService.currentLocation!.latitude, equals(52.2550));
      expect(locationService.currentLocation!.longitude, equals(6.1600));
    });

    test('fetchCurrentLocation does nothing when service is disabled', () async {
      fakeClient.serviceEnabled = false;
      fakeClient.currentPosition = createPosition(latitude: 52.2550, longitude: 6.1600);

      await locationService.fetchCurrentLocation();

      expect(locationService.currentLocation, isNull);
    });

    test('simulates entire race: start line crossing, racing, finish line crossing', () async {
      final states = <RaceState>[];
      final distances = <double?>[];

      locationService.raceStateStream.listen(states.add);
      locationService.distanceToTargetStream.listen(distances.add);

      await locationService.startTracking([testTrajectory]);
      expect(locationService.currentState, equals(RaceState.waiting));

      // 1. Boat position north of start line (approaching start line)
      fakeClient.positionController.add(createPosition(latitude: 52.2520, longitude: 6.1600, speed: 2.0));
      await pumpEventQueue();

      expect(locationService.currentState, equals(RaceState.waiting));
      expect(distances.isNotEmpty, isTrue);

      // 2. Boat crosses start line moving south (52.2520 -> 52.2480)
      fakeClient.positionController.add(createPosition(latitude: 52.2480, longitude: 6.1600, speed: 2.5));
      await pumpEventQueue();

      expect(locationService.currentState, equals(RaceState.racing));
      expect(states, contains(RaceState.racing));

      // 3. Boat moves toward finish line
      fakeClient.positionController.add(createPosition(latitude: 52.2420, longitude: 6.1600, speed: 3.0));
      await pumpEventQueue();

      expect(locationService.currentState, equals(RaceState.racing));

      // 4. Boat crosses finish line moving south (52.2420 -> 52.2380)
      fakeClient.positionController.add(createPosition(latitude: 52.2380, longitude: 6.1600, speed: 3.0));
      await pumpEventQueue();

      expect(locationService.currentState, equals(RaceState.finished));
      expect(states, contains(RaceState.finished));
    });

    test('stopTracking cancels tracking and resets state', () async {
      await locationService.startTracking([testTrajectory]);
      locationService.stopTracking();

      expect(locationService.currentState, equals(RaceState.waiting));
      expect(locationService.currentTrajectory, isNull);
      expect(locationService.currentLocation, isNull);
    });
  });
}
