import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:bridge_to_bridge_app/utils/stroke_rate_calculator.dart';

void main() {
  group('StrokeRateCalculator', () {
    test('Calculates SPM correctly from accelerometer CSV', () async {
      // 1. Load CSV data
      final file = File('test/input/lsm6dso_LSM6DSO_Accelerometer_Non-wakeup.csv');
      expect(await file.exists(), isTrue, reason: 'Test CSV file not found');

      final lines = await file.readAsLines();
      final data = <AccelerometerData>[];

      // Skip header line
      for (int i = 1; i < lines.length; i++) {
        final row = lines[i];
        if (row.trim().isEmpty) continue;

        final parts = row.split(',');
        if (parts.length >= 4) {
          final timestamp = int.tryParse(parts[0]);
          final x = double.tryParse(parts[1]);
          final y = double.tryParse(parts[2]);
          final z = double.tryParse(parts[3]);

          if (timestamp != null && x != null && y != null && z != null) {
            data.add(AccelerometerData(
              timestamp: timestamp,
              x: x,
              y: y,
              z: z,
            ));
          }
        }
      }

      expect(data.isNotEmpty, isTrue, reason: 'Failed to parse CSV data');

      // 2. Calculate SPM
      final spm = StrokeRateCalculator.calculateSPM(data);

      // 3. Verify
      expect(spm, isNotNull);
      
      // Based on the Python test, the calculated SPM using autocorrelation is ~34.3
      // We'll allow a small margin of error due to rounding or exact data boundaries
      expect(spm!, closeTo(34.3, 1.0));
    });

    test('Returns null when data is empty', () {
      expect(StrokeRateCalculator.calculateSPM([]), isNull);
    });

    test('Returns null when data has insufficient samples', () {
      final data = List.generate(5, (i) => AccelerometerData(
        timestamp: i * 10,
        x: 0, y: 0, z: 9.8,
      ));
      expect(StrokeRateCalculator.calculateSPM(data), isNull);
    });
  });
}
