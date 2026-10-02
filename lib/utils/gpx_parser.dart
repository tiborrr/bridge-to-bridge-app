import 'dart:math' as math;

class GpxPoint {
  final double latitude;
  final double longitude;
  final double? elevation;
  final DateTime? time;

  const GpxPoint({
    required this.latitude,
    required this.longitude,
    this.elevation,
    this.time,
  });

  @override
  String toString() => 'GpxPoint(lat: $latitude, lon: $longitude, ele: $elevation, time: $time)';
}

class GpxParser {
  static List<GpxPoint> parse(String gpxString) {
    final points = <GpxPoint>[];
    
    // Match each <trkpt ...>...</trkpt> block
    final trkptRegex = RegExp(r'<trkpt\s+([^>]+)>(.*?)</trkpt>', dotAll: true);
    final latRegex = RegExp(r'lat="([^"]+)"');
    final lonRegex = RegExp(r'lon="([^"]+)"');
    final eleRegex = RegExp(r'<ele>([^<]+)</ele>');
    final timeRegex = RegExp(r'<time>([^<]+)</time>');

    final matches = trkptRegex.allMatches(gpxString);
    for (final match in matches) {
      final attributes = match.group(1) ?? '';
      final body = match.group(2) ?? '';

      final latMatch = latRegex.firstMatch(attributes);
      final lonMatch = lonRegex.firstMatch(attributes);
      if (latMatch == null || lonMatch == null) continue;

      final lat = double.tryParse(latMatch.group(1)!);
      final lon = double.tryParse(lonMatch.group(1)!);
      if (lat == null || lon == null) continue;

      double? elevation;
      final eleMatch = eleRegex.firstMatch(body);
      if (eleMatch != null) {
        elevation = double.tryParse(eleMatch.group(1)!);
      }

      DateTime? time;
      final timeMatch = timeRegex.firstMatch(body);
      if (timeMatch != null) {
        time = DateTime.tryParse(timeMatch.group(1)!);
      }

      points.add(GpxPoint(
        latitude: lat,
        longitude: lon,
        elevation: elevation,
        time: time,
      ));
    }

    return points;
  }

  static double calculateDistance(double startLat, double startLng, double endLat, double endLng) {
    const earthRadius = 6371000.0; // meters
    final dLat = (endLat - startLat) * math.pi / 180.0;
    final dLng = (endLng - startLng) * math.pi / 180.0;

    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(startLat * math.pi / 180.0) *
            math.cos(endLat * math.pi / 180.0) *
            math.sin(dLng / 2) *
            math.sin(dLng / 2);
    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return earthRadius * c;
  }

  static double calculateBearing(double startLat, double startLng, double endLat, double endLng) {
    final lat1 = startLat * math.pi / 180.0;
    final lat2 = endLat * math.pi / 180.0;
    final dLon = (endLng - startLng) * math.pi / 180.0;

    final y = math.sin(dLon) * math.cos(lat2);
    final x = math.cos(lat1) * math.sin(lat2) -
        math.sin(lat1) * math.cos(lat2) * math.cos(dLon);
    final radians = math.atan2(y, x);
    return (radians * 180.0 / math.pi + 360.0) % 360.0;
  }
}
