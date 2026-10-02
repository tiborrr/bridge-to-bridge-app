import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:bridge_to_bridge_app/models/trajectory.dart';
import 'package:bridge_to_bridge_app/widgets/live_race_map.dart';

void main() {
  final testTrajectory = Trajectory(
    id: 'test_trajectory',
    name: 'Brug tot Brug Test',
    startBridgeName: 'Wilhelminabrug',
    startNorthLat: 52.256,
    startNorthLng: 6.144,
    startSouthLat: 52.255,
    startSouthLng: 6.145,
    startDirectionBearing: 190.0,
    finishBridgeName: 'Spoorfietsbrug',
    finishNorthLat: 52.240,
    finishNorthLng: 6.155,
    finishSouthLat: 52.239,
    finishSouthLng: 6.156,
    finishDirectionBearing: 175.0,
  );

  testWidgets('LiveRaceMap renders map layers, start/finish badges, and controls', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: LiveRaceMap(
            trajectory: testTrajectory,
            boatPosition: const LatLng(52.2500, 6.1480),
            boatHeading: 185.0,
            boatSpeedKmh: 14.5,
            traveledPath: const [
              LatLng(52.2555, 6.1445),
              LatLng(52.2500, 6.1480),
            ],
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Verify FlutterMap is rendered
    expect(find.byType(FlutterMap), findsOneWidget);

    // Verify START and FINISH badges
    expect(find.text('START'), findsOneWidget);
    expect(find.text('FINISH'), findsOneWidget);

    // Verify boat speed tag
    expect(find.text('14.5 km/u'), findsOneWidget);

    // Verify map controls (zoom in, zoom out, auto-follow)
    expect(find.byTooltip('Inzoomen'), findsOneWidget);
    expect(find.byTooltip('Uitzoomen'), findsOneWidget);
    expect(find.byTooltip('Boot volgen'), findsOneWidget);
    expect(find.byIcon(Icons.gps_fixed), findsOneWidget);
  });

  testWidgets('LiveRaceMap auto-follow button toggles state on tap', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: LiveRaceMap(
            trajectory: testTrajectory,
            boatPosition: const LatLng(52.2500, 6.1480),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Initially auto-following
    expect(find.byIcon(Icons.gps_fixed), findsOneWidget);
    expect(find.byTooltip('Boot volgen'), findsOneWidget);

    // Tap to toggle off
    await tester.tap(find.byTooltip('Boot volgen'));
    await tester.pumpAndSettle();

    // Now showing my_location with 'Centreer op boot'
    expect(find.byIcon(Icons.my_location), findsOneWidget);
    expect(find.byTooltip('Centreer op boot'), findsOneWidget);

    // Tap to toggle back on
    await tester.tap(find.byTooltip('Centreer op boot'));
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.gps_fixed), findsOneWidget);
  });

  testWidgets('LiveRaceMap renders top and bottom overlays when provided', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: LiveRaceMap(
            trajectory: testTrajectory,
            topOverlay: const Text('CUSTOM_TOP_HUD'),
            bottomOverlay: const Text('CUSTOM_BOTTOM_BAR'),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('CUSTOM_TOP_HUD'), findsOneWidget);
    expect(find.text('CUSTOM_BOTTOM_BAR'), findsOneWidget);
  });
}
