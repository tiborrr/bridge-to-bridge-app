import '../utils/stroke_rate_calculator.dart';
import '../utils/catch_rotation_calculator.dart';

class TelemetryAnalysisResult {
  final double? spm;
  final double? pitch;
  final double? roll;
  final int? pickInTimeMs;
  final double? pickOutPitch;
  final double? pickOutRoll;
  final int? pickOutTimeMs;

  TelemetryAnalysisResult({
    this.spm,
    this.pitch,
    this.roll,
    this.pickInTimeMs,
    this.pickOutPitch,
    this.pickOutRoll,
    this.pickOutTimeMs,
  });
}

class AnalyzeTelemetryUseCase {
  TelemetryAnalysisResult execute({
    required List<AccelerometerData> accelBuffer,
    required List<GyroscopeData> gyroBuffer,
    required double pitchOffset,
    required double rollOffset,
  }) {
    if (accelBuffer.length < 50) {
      return TelemetryAnalysisResult(spm: null, pitch: null, roll: null);
    }

    final accelData = List<AccelerometerData>.from(accelBuffer);
    final gyroData = List<GyroscopeData>.from(gyroBuffer);

    double? spm = StrokeRateCalculator.calculateSPM(accelData);
    
    if (spm != null && spm > 0) {
      final strokes = CatchRotationCalculator.calculateStrokes(accelData, gyroData, spm);
      
      if (strokes.isNotEmpty) {
        final lastStroke = strokes.last;
        return TelemetryAnalysisResult(
          spm: spm,
          pitch: lastStroke.pickIn.pitch - pitchOffset,
          roll: lastStroke.pickIn.roll - rollOffset,
          pickInTimeMs: lastStroke.pickIn.timestamp,
          pickOutPitch: lastStroke.pickOut != null ? lastStroke.pickOut!.pitch - pitchOffset : null,
          pickOutRoll: lastStroke.pickOut != null ? lastStroke.pickOut!.roll - rollOffset : null,
          pickOutTimeMs: lastStroke.pickOut?.timestamp,
        );
      }
      return TelemetryAnalysisResult(spm: spm);
    }
    
    return TelemetryAnalysisResult();
  }
}
