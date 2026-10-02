import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:bridge_to_bridge_app/usecases/analyze_telemetry_usecase.dart';
import 'package:bridge_to_bridge_app/utils/stroke_rate_calculator.dart';
import 'package:bridge_to_bridge_app/utils/catch_rotation_calculator.dart';

void main() {
  group('AnalyzeTelemetryUseCase', () {
    late AnalyzeTelemetryUseCase useCase;

    setUp(() {
      useCase = AnalyzeTelemetryUseCase();
    });

    test('returns empty result when buffer has fewer than 50 items', () {
      final accel = List.generate(
        30,
        (i) => AccelerometerData(timestamp: i * 10, x: 0, y: 0, z: 9.8),
      );
      final gyro = <GyroscopeData>[];

      final result = useCase.execute(
        accelBuffer: accel,
        gyroBuffer: gyro,
        pitchOffset: 0.0,
        rollOffset: 0.0,
      );

      expect(result.spm, isNull);
      expect(result.pitch, isNull);
      expect(result.roll, isNull);
    });

    test('returns null SPM when data has no periodic motion (flatline)', () {
      // 100 samples with identical magnitude (flatline / no stroke)
      final accel = List.generate(
        100,
        (i) => AccelerometerData(timestamp: i * 10, x: 0, y: 0, z: 9.8),
      );
      final gyro = List.generate(
        100,
        (i) => GyroscopeData(timestamp: i * 10, x: 0, y: 0, z: 0),
      );

      final result = useCase.execute(
        accelBuffer: accel,
        gyroBuffer: gyro,
        pitchOffset: 0.0,
        rollOffset: 0.0,
      );

      expect(result.spm, isNull);
      expect(result.pitch, isNull);
      expect(result.roll, isNull);
    });

    test('correctly computes metrics and applies pitch/roll offsets with real rowing data', () async {
      // 1. Load Accel CSV
      final accelFile = File('test/input/lsm6dso_LSM6DSO_Accelerometer_Non-wakeup.csv');
      final accelLines = await accelFile.readAsLines();
      final accelData = <AccelerometerData>[];
      for (int i = 1; i < accelLines.length; i++) {
        final parts = accelLines[i].split(',');
        if (parts.length >= 4) {
          final t = int.tryParse(parts[0]);
          final x = double.tryParse(parts[1]);
          final y = double.tryParse(parts[2]);
          final z = double.tryParse(parts[3]);
          if (t != null && x != null && y != null && z != null) {
            accelData.add(AccelerometerData(timestamp: t, x: x, y: y, z: z));
          }
        }
      }

      // 2. Load Gyro CSV
      final gyroFile = File('test/input/lsm6dso_LSM6DSO_Gyroscope_Non-wakeup.csv');
      final gyroLines = await gyroFile.readAsLines();
      final gyroData = <GyroscopeData>[];
      for (int i = 1; i < gyroLines.length; i++) {
        final parts = gyroLines[i].split(',');
        if (parts.length >= 4) {
          final t = int.tryParse(parts[0]);
          final x = double.tryParse(parts[1]);
          final y = double.tryParse(parts[2]);
          final z = double.tryParse(parts[3]);
          if (t != null && x != null && y != null && z != null) {
            gyroData.add(GyroscopeData(timestamp: t, x: x, y: y, z: z));
          }
        }
      }

      // 3. Execute with zero offsets
      final rawResult = useCase.execute(
        accelBuffer: accelData,
        gyroBuffer: gyroData,
        pitchOffset: 0.0,
        rollOffset: 0.0,
      );

      expect(rawResult.spm, isNotNull);
      expect(rawResult.spm!, closeTo(34.3, 1.0));
      expect(rawResult.pitch, isNotNull);
      expect(rawResult.roll, isNotNull);
      expect(rawResult.pickInTimeMs, isNotNull);
      expect(rawResult.pickInTimeMs!, greaterThan(0));

      // 4. Execute with calibration offsets and verify offset subtraction
      const double pitchOffset = 5.5;
      const double rollOffset = -2.3;

      final calibratedResult = useCase.execute(
        accelBuffer: accelData,
        gyroBuffer: gyroData,
        pitchOffset: pitchOffset,
        rollOffset: rollOffset,
      );

      expect(calibratedResult.spm, equals(rawResult.spm));
      expect(calibratedResult.pitch!, closeTo(rawResult.pitch! - pitchOffset, 0.0001));
      expect(calibratedResult.roll!, closeTo(rawResult.roll! - rollOffset, 0.0001));

      if (rawResult.pickOutPitch != null) {
        expect(calibratedResult.pickOutPitch!, closeTo(rawResult.pickOutPitch! - pitchOffset, 0.0001));
      }
      if (rawResult.pickOutRoll != null) {
        expect(calibratedResult.pickOutRoll!, closeTo(rawResult.pickOutRoll! - rollOffset, 0.0001));
      }
    });
  });
}
