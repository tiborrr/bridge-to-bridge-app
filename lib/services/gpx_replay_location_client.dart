import 'dart:async';
import 'package:flutter/services.dart' show rootBundle;
import 'package:geolocator/geolocator.dart';
import '../utils/gpx_parser.dart';
import 'location_service.dart';

class GpxReplayLocationClient implements LocationClient {
  final List<GpxPoint> points;
  final Duration baseInterval;
  final double defaultSpeedMps;
  final bool loop;

  double speedMultiplier = 1.0;
  int _currentIndex = 0;
  bool _isPlaying = false;
  Timer? _timer;

  final StreamController<Position> _positionController = StreamController<Position>.broadcast();
  final StreamController<int> _progressController = StreamController<int>.broadcast();

  GpxReplayLocationClient({
    required this.points,
    this.baseInterval = const Duration(milliseconds: 500),
    this.defaultSpeedMps = 3.5, // ~12.6 km/h (rowing pace)
    this.loop = false,
  });

  static Future<GpxReplayLocationClient> fromAsset(
    String assetPath, {
    Duration baseInterval = const Duration(milliseconds: 500),
    double speedMultiplier = 1.0,
    bool loop = false,
  }) async {
    final gpxString = await rootBundle.loadString(assetPath);
    final points = GpxParser.parse(gpxString);
    final client = GpxReplayLocationClient(
      points: points,
      baseInterval: baseInterval,
      loop: loop,
    );
    client.setSpeedMultiplier(speedMultiplier);
    return client;
  }

  int get currentIndex => _currentIndex;
  int get totalPoints => points.length;
  bool get isPlaying => _isPlaying;
  Stream<int> get progressStream => _progressController.stream;

  Position? _currentPosition;

  @override
  Future<bool> isLocationServiceEnabled() async => true;

  @override
  Future<LocationPermission> checkPermission() async => LocationPermission.always;

  @override
  Future<LocationPermission> requestPermission() async => LocationPermission.always;

  @override
  Future<Position?> getCurrentPosition({LocationSettings? locationSettings}) async {
    if (points.isEmpty) return null;
    return _buildPosition(_currentIndex);
  }

  @override
  Stream<Position> getPositionStream({LocationSettings? locationSettings}) {
    // If we have points and stream hasn't emitted yet, emit current position immediately upon listen
    if (points.isNotEmpty && _currentPosition == null) {
      _currentPosition = _buildPosition(_currentIndex);
    }
    return _positionController.stream;
  }

  @override
  double distanceBetween(double startLat, double startLng, double endLat, double endLng) {
    return GpxParser.calculateDistance(startLat, startLng, endLat, endLng);
  }

  Position? step() {
    if (points.isEmpty) return null;
    if (_currentIndex >= points.length) {
      if (loop) {
        _currentIndex = 0;
      } else {
        pause();
        return _currentPosition;
      }
    }

    final pos = _buildPosition(_currentIndex);
    _currentPosition = pos;
    _positionController.add(pos);
    _progressController.add(_currentIndex);
    _currentIndex++;

    return pos;
  }

  void play() {
    if (points.isEmpty || _isPlaying) return;
    _isPlaying = true;
    _scheduleNextTick();
  }

  void pause() {
    _timer?.cancel();
    _timer = null;
    _isPlaying = false;
  }

  void reset() {
    pause();
    _currentIndex = 0;
    if (points.isNotEmpty) {
      _currentPosition = _buildPosition(0);
      _positionController.add(_currentPosition!);
      _progressController.add(0);
    }
  }

  void seek(int index) {
    if (points.isEmpty) return;
    _currentIndex = index.clamp(0, points.length - 1);
    final pos = _buildPosition(_currentIndex);
    _currentPosition = pos;
    _positionController.add(pos);
    _progressController.add(_currentIndex);
  }

  void setSpeedMultiplier(double multiplier) {
    if (multiplier <= 0) return;
    speedMultiplier = multiplier;
    if (_isPlaying) {
      _timer?.cancel();
      _scheduleNextTick();
    }
  }

  void _scheduleNextTick() {
    if (!_isPlaying) return;
    final intervalMs = (baseInterval.inMilliseconds / speedMultiplier).round().clamp(50, 10000);
    _timer = Timer(Duration(milliseconds: intervalMs), () {
      if (!_isPlaying) return;
      if (_currentIndex >= points.length) {
        if (loop) {
          _currentIndex = 0;
        } else {
          pause();
          return;
        }
      }
      step();
      _scheduleNextTick();
    });
  }

  Position _buildPosition(int index) {
    final clampedIndex = index.clamp(0, points.length - 1);
    final current = points[clampedIndex];
    final next = clampedIndex < points.length - 1 ? points[clampedIndex + 1] : null;
    final prev = clampedIndex > 0 ? points[clampedIndex - 1] : null;

    double heading = 0.0;
    if (next != null) {
      heading = GpxParser.calculateBearing(current.latitude, current.longitude, next.latitude, next.longitude);
    } else if (prev != null) {
      heading = GpxParser.calculateBearing(prev.latitude, prev.longitude, current.latitude, current.longitude);
    }

    double speed = defaultSpeedMps;
    if (prev != null && current.time != null && prev.time != null) {
      final seconds = current.time!.difference(prev.time!).inMilliseconds / 1000.0;
      if (seconds > 0) {
        final distance = GpxParser.calculateDistance(prev.latitude, prev.longitude, current.latitude, current.longitude);
        speed = distance / seconds;
      }
    }

    return Position(
      latitude: current.latitude,
      longitude: current.longitude,
      timestamp: current.time ?? DateTime.now(),
      accuracy: 3.0,
      altitude: current.elevation ?? 0.0,
      altitudeAccuracy: 1.0,
      heading: heading,
      headingAccuracy: 1.0,
      speed: speed,
      speedAccuracy: 0.1,
    );
  }

  void dispose() {
    pause();
    _positionController.close();
    _progressController.close();
  }
}
