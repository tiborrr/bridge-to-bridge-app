import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import '../utils/geofence_calculator.dart';
import '../models/trajectory.dart';
import 'gpx_replay_location_client.dart';

enum RaceState {
  waiting,
  racing,
  finished,
}

abstract class LocationClient {
  Future<bool> isLocationServiceEnabled();
  Future<LocationPermission> checkPermission();
  Future<LocationPermission> requestPermission();
  Future<Position?> getCurrentPosition({LocationSettings? locationSettings});
  Stream<Position> getPositionStream({LocationSettings? locationSettings});
  double distanceBetween(double startLatitude, double startLongitude, double endLatitude, double endLongitude);
}

class GeolocatorLocationClient implements LocationClient {
  const GeolocatorLocationClient();

  @override
  Future<bool> isLocationServiceEnabled() => Geolocator.isLocationServiceEnabled();

  @override
  Future<LocationPermission> checkPermission() => Geolocator.checkPermission();

  @override
  Future<LocationPermission> requestPermission() => Geolocator.requestPermission();

  @override
  Future<Position?> getCurrentPosition({LocationSettings? locationSettings}) =>
      Geolocator.getCurrentPosition(locationSettings: locationSettings);

  @override
  Stream<Position> getPositionStream({LocationSettings? locationSettings}) =>
      Geolocator.getPositionStream(locationSettings: locationSettings);

  @override
  double distanceBetween(
    double startLatitude,
    double startLongitude,
    double endLatitude,
    double endLongitude,
  ) =>
      Geolocator.distanceBetween(startLatitude, startLongitude, endLatitude, endLongitude);
}

class LocationService extends ChangeNotifier {
  LocationClient _locationClient;

  LocationService({LocationClient? locationClient})
      : _locationClient = locationClient ?? const GeolocatorLocationClient();

  LocationClient get locationClient => _locationClient;
  bool get isSimulationMode => _locationClient is GpxReplayLocationClient;
  GpxReplayLocationClient? get replayClient =>
      _locationClient is GpxReplayLocationClient ? _locationClient as GpxReplayLocationClient : null;

  PointLatLng? _previousLocation;
  PointLatLng? get currentLocation => _previousLocation;
  Position? _lastPosition;
  Position? get lastPosition => _lastPosition;
  double get currentHeading => _lastPosition?.heading ?? 0.0;
  double get currentSpeedKmh =>
      (_lastPosition != null && _lastPosition!.speed > 0) ? _lastPosition!.speed * 3.6 : 0.0;

  RaceState currentState = RaceState.waiting;
  Trajectory? currentTrajectory;
  
  final _raceStateController = StreamController<RaceState>.broadcast();
  Stream<RaceState> get raceStateStream => _raceStateController.stream;

  final _distanceTargetController = StreamController<double?>.broadcast();
  Stream<double?> get distanceToTargetStream => _distanceTargetController.stream;

  StreamSubscription<Position>? _positionSubscription;
  List<Trajectory> activeTrajectories = [];

  void setLocationClient(LocationClient client) {
    _locationClient = client;
    if (_positionSubscription != null && activeTrajectories.isNotEmpty) {
      final trajectories = List<Trajectory>.from(activeTrajectories);
      _positionSubscription?.cancel();
      _positionSubscription = null;
      startTracking(trajectories);
    }
    notifyListeners();
  }

  Future<void> enableGpxSimulation({
    String assetPath = 'assets/gpx/bridge_to_bridge.gpx',
    Duration baseInterval = const Duration(milliseconds: 500),
    double speedMultiplier = 1.0,
  }) async {
    final client = await GpxReplayLocationClient.fromAsset(
      assetPath,
      baseInterval: baseInterval,
      speedMultiplier: speedMultiplier,
    );
    setLocationClient(client);
  }

  void disableGpxSimulation() {
    if (_locationClient is GpxReplayLocationClient) {
      (_locationClient as GpxReplayLocationClient).dispose();
    }
    setLocationClient(const GeolocatorLocationClient());
  }

  double distanceBetween(
    double startLatitude,
    double startLongitude,
    double endLatitude,
    double endLongitude,
  ) {
    return _locationClient.distanceBetween(
      startLatitude,
      startLongitude,
      endLatitude,
      endLongitude,
    );
  }

  Future<void> fetchCurrentLocation() async {
    bool serviceEnabled = await _locationClient.isLocationServiceEnabled();
    if (!serviceEnabled) return;

    LocationPermission permission = await _locationClient.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await _locationClient.requestPermission();
      if (permission == LocationPermission.denied) return;
    }
    
    if (permission == LocationPermission.deniedForever) return;

    try {
      final position = await _locationClient.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.low),
      );
      if (position != null) {
        _lastPosition = position;
        _previousLocation = PointLatLng(position.latitude, position.longitude);
        notifyListeners();
      }
    } catch (_) {}
  }

  Future<void> startTracking(List<Trajectory> trajectories) async {
    activeTrajectories = trajectories;
    bool serviceEnabled = await _locationClient.isLocationServiceEnabled();
    if (!serviceEnabled) return;

    LocationPermission permission = await _locationClient.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await _locationClient.requestPermission();
      if (permission == LocationPermission.denied) return;
    }
    
    if (permission == LocationPermission.deniedForever) return;

    _positionSubscription = _locationClient.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.bestForNavigation,
        distanceFilter: 5,
      ),
    ).listen((Position position) {
      _lastPosition = position;
      final currentLocation = PointLatLng(position.latitude, position.longitude);

      if (currentState == RaceState.waiting || currentState == RaceState.racing) {
        _updateDistanceToTarget(currentLocation);
      }

      if (_previousLocation != null && position.speed > 0.5) {
        if (currentState == RaceState.waiting) {
          _checkForStartCrossing(currentLocation);
        } else if (currentState == RaceState.racing && currentTrajectory != null) {
          _checkForFinishCrossing(currentLocation);
        }
      }
      
      _previousLocation = currentLocation;
      notifyListeners();
    });
  }

  void stopTracking() {
    _positionSubscription?.cancel();
    _positionSubscription = null;
    _previousLocation = null;
    _lastPosition = null;
    currentState = RaceState.waiting;
    currentTrajectory = null;
    activeTrajectories = [];
    notifyListeners();
  }

  @override
  void dispose() {
    stopTracking();
    if (_locationClient is GpxReplayLocationClient) {
      (_locationClient as GpxReplayLocationClient).dispose();
    }
    _raceStateController.close();
    _distanceTargetController.close();
    super.dispose();
  }

  void _updateDistanceToTarget(PointLatLng currentLocation) {
    if (currentState == RaceState.waiting) {
      if (activeTrajectories.isEmpty) {
        _distanceTargetController.add(null);
        return;
      }

      double minDistance = double.infinity;
      for (var trajectory in activeTrajectories) {
        final startCenterLat = (trajectory.startNorthLat + trajectory.startSouthLat) / 2;
        final startCenterLng = (trajectory.startNorthLng + trajectory.startSouthLng) / 2;
        
        final distance = _locationClient.distanceBetween(
          currentLocation.latitude, currentLocation.longitude,
          startCenterLat, startCenterLng,
        );
        
        if (distance < minDistance) {
          minDistance = distance;
        }
      }
      _distanceTargetController.add(minDistance);
    } else if (currentState == RaceState.racing && currentTrajectory != null) {
      final finishCenterLat = (currentTrajectory!.finishNorthLat + currentTrajectory!.finishSouthLat) / 2;
      final finishCenterLng = (currentTrajectory!.finishNorthLng + currentTrajectory!.finishSouthLng) / 2;
      
      final distance = _locationClient.distanceBetween(
        currentLocation.latitude, currentLocation.longitude,
        finishCenterLat, finishCenterLng,
      );
      
      _distanceTargetController.add(distance);
    } else {
      _distanceTargetController.add(null);
    }
  }

  void _checkForStartCrossing(PointLatLng currentLocation) {
    if (_previousLocation == null) return;
    
    for (var trajectory in activeTrajectories) {
      final started = GeofenceCalculator.hasValidCrossing(
        boundary: LineSegment(
          PointLatLng(trajectory.startNorthLat, trajectory.startNorthLng),
          PointLatLng(trajectory.startSouthLat, trajectory.startSouthLng),
        ),
        path: LineSegment(_previousLocation!, currentLocation),
        expectedBearing: trajectory.startDirectionBearing,
      );

      if (started) {
        currentState = RaceState.racing;
        currentTrajectory = trajectory;
        _raceStateController.add(RaceState.racing);
        notifyListeners();
        break;
      }
    }
  }

  void _checkForFinishCrossing(PointLatLng currentLocation) {
    if (_previousLocation == null || currentTrajectory == null) return;
    
    final finished = GeofenceCalculator.hasValidCrossing(
      boundary: LineSegment(
        PointLatLng(currentTrajectory!.finishNorthLat, currentTrajectory!.finishNorthLng),
        PointLatLng(currentTrajectory!.finishSouthLat, currentTrajectory!.finishSouthLng),
      ),
      path: LineSegment(_previousLocation!, currentLocation),
      expectedBearing: currentTrajectory!.finishDirectionBearing,
    );
    
    if (finished) {
      currentState = RaceState.finished;
      _raceStateController.add(RaceState.finished);
      notifyListeners();
    }
  }
}
