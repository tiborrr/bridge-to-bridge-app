import 'dart:math';

class AccelerometerData {
  final int timestamp; // Unix timestamp in milliseconds
  final double x;
  final double y;
  final double z;

  AccelerometerData({
    required this.timestamp,
    required this.x,
    required this.y,
    required this.z,
  });

  double get magnitude => sqrt(x * x + y * y + z * z);
}

class StrokeRateCalculator {
  /// Calculates the Stroke Rate (SPM - Strokes Per Minute) using autocorrelation.
  /// Expects [data] to be a time-series list of [AccelerometerData] ordered by time.
  static double? calculateSPM(List<AccelerometerData> data) {
    if (data.isEmpty || data.length < 10) return null;

    // 1. Calculate sample rate (fs) in Hz
    double dtMs = (data.last.timestamp - data.first.timestamp) / (data.length - 1);
    if (dtMs <= 0) return null;
    double fs = 1000.0 / dtMs;

    // 2. Extract magnitudes and subtract mean to center the signal
    List<double> mags = data.map((d) => d.magnitude).toList();
    double meanMag = mags.reduce((a, b) => a + b) / mags.length;
    List<double> centered = mags.map((m) => m - meanMag).toList();

    // 2.5 Calculate variance to check if there is actual movement
    double variance = centered.fold(0.0, (sum, val) => sum + (val * val)) / centered.length;
    if (variance < 1.5) {
      return 0.0; // Phone is mostly still or just vibrating, no active rowing
    }

    // 3. Low-pass filter (simple moving average, ~0.2s window)
    int windowSize = (0.2 * fs).round();
    if (windowSize < 1) windowSize = 1;
    
    List<double> smoothed = [];
    for (int i = 0; i < centered.length; i++) {
      int start = max(0, i - windowSize ~/ 2);
      int end = min(centered.length, i + windowSize ~/ 2 + 1); // +1 because end is exclusive in Dart sublist but we're doing manual sum
      
      double sum = 0;
      for (int j = start; j < end; j++) {
        sum += centered[j];
      }
      smoothed.add(sum / (end - start));
    }

    // 4. Autocorrelation
    int n = smoothed.length;
    // We expect stroke rates between 15 SPM and 100 SPM
    // 15 SPM -> 4 seconds per stroke
    // 100 SPM -> 0.6 seconds per stroke
    int maxLag = (4.0 * fs).round();
    int minLag = (0.6 * fs).round();

    if (maxLag >= n) {
      maxLag = n - 1; // Limit maxLag if window is too small
    }
    
    if (minLag >= maxLag) {
      return null; // Not enough data
    }

    double maxAutocorr = -double.infinity;
    int bestLag = -1;

    for (int lag = minLag; lag < maxLag; lag++) {
      double sumProd = 0;
      for (int i = 0; i < n - lag; i++) {
        sumProd += smoothed[i] * smoothed[i + lag];
      }
      
      if (sumProd > maxAutocorr) {
        maxAutocorr = sumProd;
        bestLag = lag;
      }
    }

    if (bestLag == -1) return null;

    // 5. Convert lag to SPM
    double periodSeconds = bestLag / fs;
    if (periodSeconds == 0) return null;
    
    return 60.0 / periodSeconds;
  }
}
