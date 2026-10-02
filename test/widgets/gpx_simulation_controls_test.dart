import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:bridge_to_bridge_app/services/location_service.dart';
import 'package:bridge_to_bridge_app/services/gpx_replay_location_client.dart';
import 'package:bridge_to_bridge_app/utils/gpx_parser.dart';
import 'package:bridge_to_bridge_app/widgets/gpx_simulation_controls.dart';

void main() {
  testWidgets('GpxSimulationControls renders and reacts to play/step/reset', (tester) async {
    final points = [
      const GpxPoint(latitude: 52.256, longitude: 6.144),
      const GpxPoint(latitude: 52.255, longitude: 6.145),
      const GpxPoint(latitude: 52.254, longitude: 6.146),
      const GpxPoint(latitude: 52.253, longitude: 6.147),
    ];
    final replayClient = GpxReplayLocationClient(points: points);
    final locationService = LocationService(locationClient: replayClient);

    await tester.pumpWidget(
      MaterialApp(
        home: ChangeNotifierProvider<LocationService>.value(
          value: locationService,
          child: const Scaffold(
            body: GpxSimulationControls(),
          ),
        ),
      ),
    );

    // Initial render check
    expect(find.text('GPX SIMULATIE'), findsOneWidget);
    expect(find.text('[0/4]'), findsOneWidget);

    // Tap step forward
    final stepForwardFinder = find.byTooltip('Stap vooruit');
    expect(stepForwardFinder, findsOneWidget);
    await tester.tap(stepForwardFinder);
    await tester.pump();

    expect(find.text('[1/4]'), findsOneWidget);

    // Tap step forward again
    await tester.tap(stepForwardFinder);
    await tester.pump();
    expect(find.text('[2/4]'), findsOneWidget);

    // Tap step back
    final stepBackFinder = find.byTooltip('Stap terug');
    expect(stepBackFinder, findsOneWidget);
    await tester.tap(stepBackFinder);
    await tester.pump();
    expect(find.text('[1/4]'), findsOneWidget);

    // Tap reset
    final resetFinder = find.byTooltip('Reset naar start');
    expect(resetFinder, findsOneWidget);
    await tester.tap(resetFinder);
    await tester.pump();
    expect(find.text('[0/4]'), findsOneWidget);

    locationService.dispose();
  });
}
