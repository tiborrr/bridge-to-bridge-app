import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../models/trajectory.dart';

/// Interactive live race map rendering the river trajectory, start/finish bridge lines,
/// real-time boat location, orientation heading, and traveled breadcrumb trail.
class LiveRaceMap extends StatefulWidget {
  final Trajectory trajectory;
  final LatLng? boatPosition;
  final double boatHeading;
  final double boatSpeedKmh;
  final List<LatLng> traveledPath;
  final Widget? topOverlay;
  final Widget? bottomOverlay;
  final bool autoFollowBoat;

  const LiveRaceMap({
    super.key,
    required this.trajectory,
    this.boatPosition,
    this.boatHeading = 0.0,
    this.boatSpeedKmh = 0.0,
    this.traveledPath = const [],
    this.topOverlay,
    this.bottomOverlay,
    this.autoFollowBoat = true,
  });

  @override
  State<LiveRaceMap> createState() => _LiveRaceMapState();
}

class _LiveRaceMapState extends State<LiveRaceMap> {
  late final MapController _mapController;
  bool _autoFollow = true;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    _autoFollow = widget.autoFollowBoat;
  }

  @override
  void didUpdateWidget(covariant LiveRaceMap oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_autoFollow && widget.boatPosition != null) {
      if (oldWidget.boatPosition == null ||
          oldWidget.boatPosition!.latitude != widget.boatPosition!.latitude ||
          oldWidget.boatPosition!.longitude != widget.boatPosition!.longitude) {
        _mapController.move(widget.boatPosition!, _mapController.camera.zoom);
      }
    }
  }

  LatLng get _startCenter => LatLng(
        (widget.trajectory.startNorthLat + widget.trajectory.startSouthLat) / 2,
        (widget.trajectory.startNorthLng + widget.trajectory.startSouthLng) / 2,
      );

  LatLng get _finishCenter => LatLng(
        (widget.trajectory.finishNorthLat + widget.trajectory.finishSouthLat) / 2,
        (widget.trajectory.finishNorthLng + widget.trajectory.finishSouthLng) / 2,
      );

  @override
  Widget build(BuildContext context) {
    final startP1 = LatLng(widget.trajectory.startNorthLat, widget.trajectory.startNorthLng);
    final startP2 = LatLng(widget.trajectory.startSouthLat, widget.trajectory.startSouthLng);

    final finishP1 = LatLng(widget.trajectory.finishNorthLat, widget.trajectory.finishNorthLng);
    final finishP2 = LatLng(widget.trajectory.finishSouthLat, widget.trajectory.finishSouthLng);

    final effectiveBoatPos = widget.boatPosition ?? _startCenter;

    return Stack(
      children: [
        FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            initialCenter: effectiveBoatPos,
            initialZoom: 14.5,
            minZoom: 11.0,
            maxZoom: 18.0,
            onPositionChanged: (camera, hasGesture) {
              if (hasGesture && _autoFollow) {
                setState(() => _autoFollow = false);
              }
            },
          ),
          children: [
            // Map tiles (CartoDB Voyager)
            TileLayer(
              urlTemplate: 'https://{s}.basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}.png',
              subdomains: const ['a', 'b', 'c', 'd'],
              tileProvider: NetworkTileProvider(),
            ),

            // Course Line connecting start and finish centers
            PolylineLayer(
              polylines: [
                // Planned ideal route line
                Polyline(
                  points: [_startCenter, _finishCenter],
                  strokeWidth: 2.5,
                  color: Colors.white24,
                ),
                // Traveled Path (Breadcrumb trail)
                if (widget.traveledPath.length >= 2)
                  Polyline(
                    points: widget.traveledPath,
                    strokeWidth: 4.5,
                    color: const Color(0xFFF2994A),
                  ),
                // Start Bridge Gate
                Polyline(
                  points: [startP1, startP2],
                  strokeWidth: 5.0,
                  color: const Color(0xFF27AE60),
                ),
                // Finish Bridge Gate
                Polyline(
                  points: [finishP1, finishP2],
                  strokeWidth: 5.0,
                  color: const Color(0xFFEB5757),
                ),
              ],
            ),

            // Markers: Start, Finish, and Live Boat
            MarkerLayer(
              markers: [
                // Start Bridge Badge
                Marker(
                  point: _startCenter,
                  width: 110,
                  height: 44,
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF27AE60),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: const [
                          BoxShadow(color: Colors.black45, blurRadius: 4, offset: Offset(0, 2)),
                        ],
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.flag, color: Colors.white, size: 14),
                          SizedBox(width: 4),
                          Text(
                            'START',
                            style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // Finish Bridge Badge
                Marker(
                  point: _finishCenter,
                  width: 110,
                  height: 44,
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEB5757),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: const [
                          BoxShadow(color: Colors.black45, blurRadius: 4, offset: Offset(0, 2)),
                        ],
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.sports_score, color: Colors.white, size: 14),
                          SizedBox(width: 4),
                          Text(
                            'FINISH',
                            style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // Boat Marker
                Marker(
                  point: effectiveBoatPos,
                  width: 80,
                  height: 80,
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Speed Pill
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFF021C4B),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: const Color(0xFFF2994A), width: 1),
                          ),
                          child: Text(
                            '${widget.boatSpeedKmh.toStringAsFixed(1)} km/u',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(height: 2),
                        // Directional Boat Icon
                        Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: const Color(0xFFF2994A).withValues(alpha: 0.25),
                            border: Border.all(color: const Color(0xFFF2994A), width: 2),
                            boxShadow: const [
                              BoxShadow(color: Colors.black45, blurRadius: 4, offset: Offset(0, 2)),
                            ],
                          ),
                          child: Center(
                            child: Transform.rotate(
                              angle: (widget.boatHeading * (3.141592653589793 / 180.0)),
                              child: const Icon(
                                Icons.navigation,
                                color: Colors.white,
                                size: 22,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),

        // Top Overlay (HUD telemetry)
        if (widget.topOverlay != null)
          Positioned(
            top: 12,
            left: 16,
            right: 16,
            child: widget.topOverlay!,
          ),

        // Bottom Map Action Buttons (Recenter / Zoom)
        Positioned(
          right: 16,
          bottom: widget.bottomOverlay != null ? 140 : 24,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Follow/Recenter button
              FloatingActionButton.small(
                heroTag: 'recenter_map',
                backgroundColor: _autoFollow ? const Color(0xFF27AE60) : Colors.white,
                foregroundColor: _autoFollow ? Colors.white : const Color(0xFF021C4B),
                tooltip: _autoFollow ? 'Boot volgen' : 'Centreer op boot',
                onPressed: () {
                  setState(() {
                    _autoFollow = !_autoFollow;
                    if (_autoFollow && widget.boatPosition != null) {
                      _mapController.move(widget.boatPosition!, _mapController.camera.zoom);
                    }
                  });
                },
                child: Icon(_autoFollow ? Icons.gps_fixed : Icons.my_location),
              ),
              const SizedBox(height: 8),
              // Zoom In
              FloatingActionButton.small(
                heroTag: 'zoom_in',
                backgroundColor: Colors.white,
                foregroundColor: const Color(0xFF021C4B),
                tooltip: 'Inzoomen',
                onPressed: () {
                  _mapController.move(_mapController.camera.center, _mapController.camera.zoom + 1);
                },
                child: const Icon(Icons.add),
              ),
              const SizedBox(height: 8),
              // Zoom Out
              FloatingActionButton.small(
                heroTag: 'zoom_out',
                backgroundColor: Colors.white,
                foregroundColor: const Color(0xFF021C4B),
                tooltip: 'Uitzoomen',
                onPressed: () {
                  _mapController.move(_mapController.camera.center, _mapController.camera.zoom - 1);
                },
                child: const Icon(Icons.remove),
              ),
            ],
          ),
        ),

        // Bottom Overlay (Progress / Action bar)
        if (widget.bottomOverlay != null)
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: widget.bottomOverlay!,
          ),
      ],
    );
  }
}
