import 'dart:math';
import 'package:bridge_to_bridge_app/utils/stroke_rate_calculator.dart';

class GyroscopeData {
  final int timestamp;
  final double x; // rad/s
  final double y;
  final double z;

  GyroscopeData({
    required this.timestamp,
    required this.x,
    required this.y,
    required this.z,
  });
}

class OrientationData {
  final int timestamp;
  final double pitch; // degrees
  final double roll;  // degrees

  OrientationData({
    required this.timestamp,
    required this.pitch,
    required this.roll,
  });
}

class StrokeCycleData {
  final OrientationData pickIn;
  final OrientationData? pickOut;

  StrokeCycleData({required this.pickIn, this.pickOut});
}

class CatchRotationCalculator {
  static const double _alpha = 0.98; // Complementary filter constant

  /// Calculates the rotation (pitch/roll) of the paddle at the moment of each stroke catch and finish.
  /// Requires synchronized lists of [accelData] and [gyroData].
  static List<StrokeCycleData> calculateStrokes(
    List<AccelerometerData> accelData,
    List<GyroscopeData> gyroData,
    double expectedSpm,
  ) {
    if (accelData.isEmpty || gyroData.isEmpty || expectedSpm <= 0) {
      return [];
    }

    // 1. Sync data arrays by timestamp
    // Assuming they are sampled at similar rates, we will align them.
    List<OrientationData> orientations = [];
    double currentPitch = 0.0;
    double currentRoll = 0.0;
    int lastTime = accelData.first.timestamp;

    Map<int, GyroscopeData> gyroMap = {
      for (var g in gyroData) g.timestamp: g
    };

    List<double> accelMags = [];
    List<int> accelTimes = [];

    for (var a in accelData) {
      // Find closest gyro data, or exact match
      // For simplicity, we just look up the exact timestamp or skip if not perfectly synced.
      // In a real app, you might interpolate or find nearest.
      var g = gyroMap[a.timestamp];
      if (g == null) continue;

      double dt = (a.timestamp - lastTime) / 1000.0; // seconds
      if (dt <= 0 || dt > 0.5) dt = 0.01; // fallback for first sample or big gaps
      lastTime = a.timestamp;

      // Accel based angles (in degrees)
      double accelPitch = atan2(a.y, sqrt(a.x * a.x + a.z * a.z)) * 180 / pi;
      double accelRoll = atan2(-a.x, a.z) * 180 / pi;

      // Integrate gyro (rad/s to degrees)
      double gyroPitchDelta = g.x * (180 / pi) * dt;
      double gyroRollDelta = g.y * (180 / pi) * dt;

      // Complementary Filter
      currentPitch = _alpha * (currentPitch + gyroPitchDelta) + (1.0 - _alpha) * accelPitch;
      currentRoll = _alpha * (currentRoll + gyroRollDelta) + (1.0 - _alpha) * accelRoll;

      orientations.add(OrientationData(
        timestamp: a.timestamp,
        pitch: currentPitch,
        roll: currentRoll,
      ));

      accelMags.add(a.magnitude);
      accelTimes.add(a.timestamp);
    }

    if (accelMags.isEmpty) return [];

    // 2. Detect Catch Peaks
    double periodMs = (60.0 / expectedSpm) * 1000.0;
    double minPeakDistanceMs = periodMs * 0.7; // 70% of stroke period
    double meanMag = accelMags.reduce((a, b) => a + b) / accelMags.length;
    List<double> centered = accelMags.map((m) => m - meanMag).toList();

    List<int> catchIndices = [];
    int lastPeakTime = -minPeakDistanceMs.toInt();
    double threshold = 2.0; // Minimal acceleration delta for a stroke

    for (int i = 1; i < centered.length - 1; i++) {
      if (centered[i] > threshold && centered[i] > centered[i - 1] && centered[i] > centered[i + 1]) {
        if (accelTimes[i] - lastPeakTime >= minPeakDistanceMs) {
          // Verify it's a local maximum in a small window
          bool isMax = true;
          int window = 10;
          for (int j = max(0, i - window); j < min(centered.length, i + window); j++) {
            if (centered[j] > centered[i]) {
              isMax = false;
              break;
            }
          }

          if (isMax) {
            catchIndices.add(i);
            lastPeakTime = accelTimes[i];
          }
        }
      }
    }

    List<StrokeCycleData> strokes = [];
    for (int i = 0; i < catchIndices.length; i++) {
      int catchIdx = catchIndices[i];
      int nextCatchIdx = (i < catchIndices.length - 1) ? catchIndices[i + 1] : orientations.length - 1;
      
      // Look for the pick out (finish) between this catch and the next catch.
      // Usually, the finish is the point of minimum (or maximum, depending on mount) pitch.
      // We assume it occurs in the first 70% of the period between catches.
      int searchEndIdx = catchIdx + ((nextCatchIdx - catchIdx) * 0.7).toInt();
      if (searchEndIdx >= orientations.length) searchEndIdx = orientations.length - 1;
      
      int pickOutIdx = catchIdx;
      double minPitch = orientations[catchIdx].pitch;
      
      for (int j = catchIdx + 1; j <= searchEndIdx; j++) {
        if (orientations[j].pitch < minPitch) {
          minPitch = orientations[j].pitch;
          pickOutIdx = j;
        }
      }
      
      strokes.add(StrokeCycleData(
        pickIn: orientations[catchIdx],
        pickOut: pickOutIdx > catchIdx ? orientations[pickOutIdx] : null,
      ));
    }

    return strokes;
  }
}
