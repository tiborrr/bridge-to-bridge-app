import 'package:latlong2/latlong.dart';

class TrajectoryGeometryUtils {
  static final Distance _distance = const Distance();

  static List<LatLng> getArrowHead(LatLng p1, LatLng p2, double bearing) {
    final midLat = (p1.latitude + p2.latitude) / 2;
    final midLng = (p1.longitude + p2.longitude) / 2;
    final midpoint = LatLng(midLat, midLng);

    final arrowBase = _distance.offset(midpoint, -20, bearing); 
    final arrowTip = _distance.offset(midpoint, 80, bearing); 
    final leftWing = _distance.offset(arrowBase, 40, (bearing - 135) % 360);
    final rightWing = _distance.offset(arrowBase, 40, (bearing + 135) % 360);

    return [leftWing, arrowTip, rightWing];
  }
}
