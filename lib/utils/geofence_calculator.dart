import 'dart:math';

class PointLatLng {
  final double latitude;
  final double longitude;

  const PointLatLng(this.latitude, this.longitude);
}

class LineSegment {
  final PointLatLng start;
  final PointLatLng end;

  const LineSegment(this.start, this.end);
}

class GeofenceCalculator {
  static const double earthRadiusMeters = 6371000;

  /// Detects if the [path] crosses the [boundary] line segment.
  /// Validates [expectedBearing] and ensures the crossing angle is within [maxAngleDeviationDegrees] of the expected crossing direction.
  static bool hasValidCrossing({
    required LineSegment boundary,
    required LineSegment path,
    required double expectedBearing,
    double maxAngleDeviationDegrees = 90.0,
  }) {
    // 1. Check if the segments intersect
    if (!_doSegmentsIntersect(boundary, path)) {
      return false;
    }

    // 2. Check if the movement direction matches the expected race direction
    final actualBearing = _calculateBearing(path.start, path.end);
    
    double diff = (actualBearing - expectedBearing).abs();
    if (diff > 180) {
      diff = 360 - diff;
    }

    if (diff > maxAngleDeviationDegrees) {
      return false; // Crossed in the wrong direction (e.g. going upstream instead of downstream)
    }

    return true;
  }

  static double _calculateBearing(PointLatLng start, PointLatLng end) {
    double startLat = start.latitude * pi / 180.0;
    double startLng = start.longitude * pi / 180.0;
    double endLat = end.latitude * pi / 180.0;
    double endLng = end.longitude * pi / 180.0;

    double dLng = endLng - startLng;

    double y = sin(dLng) * cos(endLat);
    double x = cos(startLat) * sin(endLat) -
        sin(startLat) * cos(endLat) * cos(dLng);

    double bearing = atan2(y, x) * 180.0 / pi;
    return (bearing + 360.0) % 360.0;
  }

  /// 2D Segment Intersection for Lat/Lng
  static bool _doSegmentsIntersect(LineSegment s1, LineSegment s2) {
    PointLatLng p1 = s1.start;
    PointLatLng q1 = s1.end;
    PointLatLng p2 = s2.start;
    PointLatLng q2 = s2.end;

    int o1 = _orientation(p1, q1, p2);
    int o2 = _orientation(p1, q1, q2);
    int o3 = _orientation(p2, q2, p1);
    int o4 = _orientation(p2, q2, q1);

    if (o1 != o2 && o3 != o4) return true;

    if (o1 == 0 && _onSegment(p1, p2, q1)) return true;
    if (o2 == 0 && _onSegment(p1, q2, q1)) return true;
    if (o3 == 0 && _onSegment(p2, p1, q2)) return true;
    if (o4 == 0 && _onSegment(p2, q1, q2)) return true;

    return false;
  }

  static int _orientation(PointLatLng p, PointLatLng q, PointLatLng r) {
    double val = (q.latitude - p.latitude) * (r.longitude - q.longitude) -
        (q.longitude - p.longitude) * (r.latitude - q.latitude);
    if (val == 0) return 0;
    return (val > 0) ? 1 : 2;
  }

  static bool _onSegment(PointLatLng p, PointLatLng q, PointLatLng r) {
    return q.longitude <= max(p.longitude, r.longitude) &&
        q.longitude >= min(p.longitude, r.longitude) &&
        q.latitude <= max(p.latitude, r.latitude) &&
        q.latitude >= min(p.latitude, r.latitude);
  }
}
