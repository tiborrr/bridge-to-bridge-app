import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../models/trajectory.dart';

class TrajectoryMapPreview extends StatelessWidget {
  final Trajectory trajectory;
  final double height;

  const TrajectoryMapPreview({super.key, required this.trajectory, this.height = 128});

  @override
  Widget build(BuildContext context) {
    // Calculate bounding box
    final lats = [
      trajectory.startNorthLat,
      trajectory.startSouthLat,
      trajectory.finishNorthLat,
      trajectory.finishSouthLat,
    ];
    final lngs = [
      trajectory.startNorthLng,
      trajectory.startSouthLng,
      trajectory.finishNorthLng,
      trajectory.finishSouthLng,
    ];

    final minLat = lats.reduce((a, b) => a < b ? a : b);
    final maxLat = lats.reduce((a, b) => a > b ? a : b);
    final minLng = lngs.reduce((a, b) => a < b ? a : b);
    final maxLng = lngs.reduce((a, b) => a > b ? a : b);

    final bounds = LatLngBounds(
      LatLng(minLat, minLng),
      LatLng(maxLat, maxLng),
    );

    return SizedBox(
      height: height,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: FlutterMap(
          options: MapOptions(
            initialCameraFit: CameraFit.bounds(
              bounds: bounds,
              padding: const EdgeInsets.all(16.0),
            ),
            interactionOptions: const InteractionOptions(flags: InteractiveFlag.none),
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.casteleijn.bridge_to_bridge',
            ),
            PolylineLayer(
              polylines: [
                // Start line
                Polyline(
                  points: [
                    LatLng(trajectory.startNorthLat, trajectory.startNorthLng),
                    LatLng(trajectory.startSouthLat, trajectory.startSouthLng),
                  ],
                  color: Colors.green,
                  strokeWidth: 4.0,
                ),
                // Finish line
                Polyline(
                  points: [
                    LatLng(trajectory.finishNorthLat, trajectory.finishNorthLng),
                    LatLng(trajectory.finishSouthLat, trajectory.finishSouthLng),
                  ],
                  color: Colors.red,
                  strokeWidth: 4.0,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
