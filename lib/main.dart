import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import 'theme.dart';
import 'screens/dashboard_container.dart';
import 'screens/leaderboard_screen.dart';
import 'screens/history_screen.dart';
import 'services/api_service.dart';
import 'services/location_service.dart';
import 'services/websocket_service.dart';
import 'services/data_recording_service.dart';
import 'repositories/trajectory_repository.dart';
import 'repositories/telemetry_repository.dart';
import 'widgets/gpx_simulation_controls.dart';
import 'router.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");

  runApp(
    MultiProvider(
      providers: [
        Provider<ApiService>(create: (_) => ApiService()),
        ChangeNotifierProvider<LocationService>(create: (_) => LocationService()),
        Provider<WebsocketService>(create: (_) => WebsocketService()),
        Provider<DataRecordingService>(create: (_) => DataRecordingService()),
        ProxyProvider<ApiService, TrajectoryRepository>(
          update: (context, apiService, previous) => TrajectoryRepository(apiService),
        ),
        ProxyProvider2<ApiService, WebsocketService, TelemetryRepository>(
          update: (context, apiService, websocketService, previous) => TelemetryRepository(apiService, websocketService),
        ),
      ],
      child: const BridgeToBridgeApp(),
    ),
  );
}

class BridgeToBridgeApp extends StatelessWidget {
  const BridgeToBridgeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Bridge to Bridge',
      theme: AppTheme.lightTheme,
      routerConfig: appRouter,
    );
  }
}

class MainNavigationScreen extends StatefulWidget {
  final int initialIndex;
  const MainNavigationScreen({super.key, this.initialIndex = 0});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  late int _currentIndex;
  bool _hideNavBar = false;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<LocationService>().fetchCurrentLocation();
    });
  }

  void _toggleNavBar(bool hide) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        setState(() {
          _hideNavBar = hide;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final locationService = context.watch<LocationService>();
    final isSimulation = locationService.isSimulationMode;

    final List<Widget> screens = [
      DashboardContainer(onHideNavBar: _toggleNavBar),
      const HistoryScreen(),
      const LeaderboardScreen(),
    ];

    return Scaffold(
      body: Stack(
        children: [
          SelectionArea(child: screens[_currentIndex]),
          if (isSimulation)
            Positioned(
              left: 12,
              right: 12,
              bottom: _hideNavBar ? 16 : 80,
              child: const GpxSimulationControls(margin: EdgeInsets.zero),
            ),
        ],
      ),
      bottomNavigationBar: _hideNavBar
          ? null
          : NavigationBar(
              selectedIndex: _currentIndex,
              onDestinationSelected: (index) {
                setState(() {
                  _currentIndex = index;
                });
              },
              destinations: const [
                NavigationDestination(
                  icon: Icon(Icons.timer_outlined),
                  selectedIcon: Icon(Icons.timer),
                  label: 'Training',
                ),
                NavigationDestination(
                  icon: Icon(Icons.history_outlined),
                  selectedIcon: Icon(Icons.history),
                  label: 'Historie',
                ),
                NavigationDestination(
                  icon: Icon(Icons.leaderboard_outlined),
                  selectedIcon: Icon(Icons.leaderboard),
                  label: 'Ranglijst',
                ),
              ],
            ),
    );
  }
}
