import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:bridge_to_bridge_app/utils/stroke_rate_calculator.dart';
import 'package:bridge_to_bridge_app/utils/catch_rotation_calculator.dart';

void main() {
  group('CatchRotationCalculator', () {
    test('Calculates catch rotations correctly from synced CSV data', () async {
      // 1. Load Accelerometer Data
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

      // 2. Load Gyroscope Data
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

      // 3. First, calculate SPM (needed for catch peak windowing)
      final expectedSpm = StrokeRateCalculator.calculateSPM(accelData);
      expect(expectedSpm, isNotNull);

      // 4. Calculate Strokes
      final strokes = CatchRotationCalculator.calculateStrokes(
        accelData,
        gyroData,
        expectedSpm!,
      );

      // We expect around 9-10 strokes based on our Python analysis
      expect(strokes.length, inInclusiveRange(8, 12));

      // Check the output values are sensible numbers
      for (var stroke in strokes) {
        final pickIn = stroke.pickIn;
        expect(pickIn.timestamp, greaterThan(0));
        expect(pickIn.pitch, isNotNull);
        expect(pickIn.roll, isNotNull);
        
        // Pitch and roll should be valid degrees
        expect(pickIn.pitch.isNaN, isFalse);
        expect(pickIn.roll.isNaN, isFalse);
        expect(pickIn.pitch.isInfinite, isFalse);
        expect(pickIn.roll.isInfinite, isFalse);

        if (stroke.pickOut != null) {
          final pickOut = stroke.pickOut!;
          expect(pickOut.timestamp, greaterThanOrEqualTo(pickIn.timestamp));
          expect(pickOut.pitch.isNaN, isFalse);
          expect(pickOut.roll.isNaN, isFalse);
          expect(pickOut.pitch.isInfinite, isFalse);
          expect(pickOut.roll.isInfinite, isFalse);
        }
      }
    });

    test('Returns empty when data is empty', () {
      expect(CatchRotationCalculator.calculateStrokes([], [], 30.0), isEmpty);
    });
  });
}
