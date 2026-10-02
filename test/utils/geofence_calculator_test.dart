import 'package:flutter_test/flutter_test.dart';
import 'package:bridge_to_bridge_app/utils/geofence_calculator.dart';

void main() {
  group('GeofenceCalculator', () {
    // A boundary line running East-West at latitude 52.2500 between lon 6.1500 and 6.1700
    const boundary = LineSegment(
      PointLatLng(52.2500, 6.1500),
      PointLatLng(52.2500, 6.1700),
    );

    test('detects valid crossing when moving in expected direction (North to South)', () {
      // Path moving from North (52.2550) to South (52.2450) across lon 6.1600
      const path = LineSegment(
        PointLatLng(52.2550, 6.1600),
        PointLatLng(52.2450, 6.1600),
      );

      final crossed = GeofenceCalculator.hasValidCrossing(
        boundary: boundary,
        path: path,
        expectedBearing: 180.0, // Moving south
        maxAngleDeviationDegrees: 90.0,
      );

      expect(crossed, isTrue);
    });

    test('rejects crossing when moving in opposite direction (South to North)', () {
      // Path moving South to North across boundary
      const path = LineSegment(
        PointLatLng(52.2450, 6.1600),
        PointLatLng(52.2550, 6.1600),
      );

      final crossed = GeofenceCalculator.hasValidCrossing(
        boundary: boundary,
        path: path,
        expectedBearing: 180.0, // Expected south, but moving north (~0 deg)
        maxAngleDeviationDegrees: 90.0,
      );

      expect(crossed, isFalse);
    });

    test('returns false when path does not intersect boundary', () {
      // Path completely east of the boundary segment
      const path = LineSegment(
        PointLatLng(52.2550, 6.1800),
        PointLatLng(52.2450, 6.1800),
      );

      final crossed = GeofenceCalculator.hasValidCrossing(
        boundary: boundary,
        path: path,
        expectedBearing: 180.0,
      );

      expect(crossed, isFalse);
    });

    test('returns false when path does not reach boundary', () {
      // Path stops North of the boundary
      const path = LineSegment(
        PointLatLng(52.2600, 6.1600),
        PointLatLng(52.2510, 6.1600),
      );

      final crossed = GeofenceCalculator.hasValidCrossing(
        boundary: boundary,
        path: path,
        expectedBearing: 180.0,
      );

      expect(crossed, isFalse);
    });

    test('handles 360-degree wrap-around for bearings near North (0/360)', () {
      // Boundary East-West at lat 52.25
      // Boat moving slightly North-North-West (from 52.2450, 6.1600 to 52.2550, 6.1595)
      // Bearing will be around 357 degrees
      const path = LineSegment(
        PointLatLng(52.2450, 6.1600),
        PointLatLng(52.2550, 6.1595),
      );

      // Expected bearing is 5 degrees (North-North-East)
      // Difference between 357 and 5 degrees is ~8 degrees, well within 45 degrees
      final crossed = GeofenceCalculator.hasValidCrossing(
        boundary: boundary,
        path: path,
        expectedBearing: 5.0,
        maxAngleDeviationDegrees: 45.0,
      );

      expect(crossed, isTrue);
    });

    test('rejects crossing when angle deviation exceeds maxAngleDeviationDegrees', () {
      // Path moving South-West (bearing ~225)
      const path = LineSegment(
        PointLatLng(52.2550, 6.1650),
        PointLatLng(52.2450, 6.1550),
      );

      // Expected bearing 135 (South-East). Difference is ~90 degrees.
      // If maxAngleDeviation is 45, it should be rejected.
      final crossed = GeofenceCalculator.hasValidCrossing(
        boundary: boundary,
        path: path,
        expectedBearing: 135.0,
        maxAngleDeviationDegrees: 45.0,
      );

      expect(crossed, isFalse);
    });
  });
}
