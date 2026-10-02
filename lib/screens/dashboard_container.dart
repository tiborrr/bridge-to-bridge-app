import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/live_race_provider.dart';
import '../repositories/telemetry_repository.dart';
import '../repositories/trajectory_repository.dart';
import '../services/location_service.dart';
import '../usecases/analyze_telemetry_usecase.dart';
import '../utils/result.dart';
import '../services/data_recording_service.dart';
import 'live_race_screen.dart';
import 'package:flutter/services.dart';
import 'rower_live_race_screen.dart';
import '../widgets/app_drawer.dart';
import '../models/trajectory.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

class DashboardContainer extends StatefulWidget {
  final ValueChanged<bool>? onHideNavBar;

  const DashboardContainer({super.key, this.onHideNavBar});

  @override
  State<DashboardContainer> createState() => _DashboardContainerState();
}

class _DashboardContainerState extends State<DashboardContainer> {
  static final Trajectory gpxDefaultTrajectory = Trajectory(
    id: 'gpx-deventer',
    name: 'Deventer Brug tot Brug (GPX Sim)',
    startBridgeName: 'Wilhelminabrug',
    startNorthLat: 52.2561,
    startNorthLng: 6.1430,
    startSouthLat: 52.2550,
    startSouthLng: 6.1470,
    startDirectionBearing: 135.0,
    finishBridgeName: 'Spoorfietsbrug',
    finishNorthLat: 52.2490,
    finishNorthLng: 6.1570,
    finishSouthLat: 52.2485,
    finishSouthLng: 6.1605,
    finishDirectionBearing: 135.0,
  );

  String? _selectedRole;
  int? _seatNumber;
  String? _side;
  Trajectory? _selectedTrajectory;
  List<Trajectory> _trajectories = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTrajectories();
  }

  Future<void> _loadTrajectories() async {
    final repo = context.read<TrajectoryRepository>();
    final result = await repo.getTrajectories();
    
    if (!mounted) return;
    setState(() {
      switch (result) {
        case Success(value: final data):
          _trajectories = data;
          if (_trajectories.isNotEmpty) {
            _selectedTrajectory = _trajectories.first;
          }
        case Failure(exception: final e):
          debugPrint('Fout bij laden trajecten in dashboard: $e');
      }
      if (_trajectories.isEmpty) {
        _trajectories = [gpxDefaultTrajectory];
        _selectedTrajectory = gpxDefaultTrajectory;
      }
      _isLoading = false;
    });

    if (_trajectories.isNotEmpty) {
      _sortTrajectoriesByLocation(_trajectories);
    }
  }

  Future<void> _sortTrajectoriesByLocation(List<Trajectory> list) async {
    try {
      Position? pos;
      final perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.whileInUse || perm == LocationPermission.always) {
        pos = await Geolocator.getLastKnownPosition();
        pos ??= await Geolocator.getCurrentPosition(
            locationSettings: const LocationSettings(
              accuracy: LocationAccuracy.low, 
              timeLimit: Duration(seconds: 3),
            ));
      } else if (perm == LocationPermission.denied) {
        return;
      }

      if (pos != null && mounted) {
        final userLatLng = LatLng(pos.latitude, pos.longitude);
        const distance = Distance();

        setState(() {
          _trajectories.sort((a, b) {
            final centerA = LatLng(
              (a.startNorthLat + a.startSouthLat) / 2,
              (a.startNorthLng + a.startSouthLng) / 2,
            );
            final centerB = LatLng(
              (b.startNorthLat + b.startSouthLat) / 2,
              (b.startNorthLng + b.startSouthLng) / 2,
            );
            final distA = distance.as(LengthUnit.Meter, userLatLng, centerA);
            final distB = distance.as(LengthUnit.Meter, userLatLng, centerB);
            return distA.compareTo(distB);
          });
          if (_trajectories.isNotEmpty) {
            _selectedTrajectory = _trajectories.first;
          }
        });
      }
    } catch (_) {
      // Negeer errors, we laten dan gewoon de default volgorde (id/naam) staan
    }
  }

  Future<void> _setRole(String role) async {
    widget.onHideNavBar?.call(true);
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
    ]);
    await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

    setState(() {
      _selectedRole = role;
    });
  }

  Future<void> _promptRowerDetails() async {
    int selectedSeat = 8;
    String selectedSide = 'port';

    final result = await showDialog<bool>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Jouw Bank in de Boot'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Op welke bank zit je?'),
                  DropdownButton<int>(
                    value: selectedSeat,
                    isExpanded: true,
                    items: List.generate(8, (i) => i + 1).map((e) => DropdownMenuItem(value: e, child: Text('Bank $e'))).toList(),
                    onChanged: (val) {
                      setDialogState(() => selectedSeat = val!);
                    }
                  ),
                  const SizedBox(height: 16),
                  const Text('Aan welke kant roei je?'),
                  DropdownButton<String>(
                    value: selectedSide,
                    isExpanded: true,
                    items: const [
                      DropdownMenuItem(value: 'port', child: Text('Bakboord (Rood)')),
                      DropdownMenuItem(value: 'starboard', child: Text('Stuurboord (Groen)')),
                    ],
                    onChanged: (val) {
                      setDialogState(() => selectedSide = val!);
                    }
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Annuleren'),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text('Starten'),
                ),
              ],
            );
          }
        );
      }
    );

    if (result == true) {
      _seatNumber = selectedSeat;
      _side = selectedSide;
      _setRole('roeier');
    }
  }

  Future<void> _clearRole() async {
    widget.onHideNavBar?.call(false);
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
    ]);
    await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    setState(() {
      _selectedRole = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_selectedRole == null || _selectedTrajectory == null) {
      return _buildRoleSelectionScreen();
    }

    return ChangeNotifierProvider(
      create: (context) => LiveRaceProvider(
        context.read<TelemetryRepository>(),
        context.read<LocationService>(),
        AnalyzeTelemetryUseCase(),
        context.read<DataRecordingService>(),
        _selectedTrajectory!,
        seatNumber: _seatNumber,
        side: _side,
      ),
      child: _selectedRole == 'stuur'
          ? LiveRaceScreen(onStop: _clearRole)
          : RowerLiveRaceScreen(onStop: _clearRole),
    );
  }

  Widget _buildRoleSelectionScreen() {
    final textTheme = Theme.of(context).textTheme;
    final locationService = context.watch<LocationService>();

    return Scaffold(
      backgroundColor: const Color(0xFFF9F9F9),
      appBar: AppBar(
        title: const Text('Kies je Rol'),
        centerTitle: true,
        actions: [
          Builder(
            builder: (context) => IconButton(
              icon: const Icon(Icons.menu),
              onPressed: () => Scaffold.of(context).openEndDrawer(),
            ),
          )
        ],
      ),
      endDrawer: const AppDrawer(),
      body: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (_isLoading)
                  const Center(child: CircularProgressIndicator())
                else ...[
                  Text(
                    'Kies een Traject',
                    style: textTheme.headlineMedium?.copyWith(
                      color: const Color(0xFF021C4B),
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  if (_trajectories.isEmpty)
                    const Text('Geen trajecten gevonden.', textAlign: TextAlign.center)
                  else
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFD9DADB)),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<Trajectory>(
                          isExpanded: true,
                          value: _selectedTrajectory,
                          items: _trajectories.map((traj) {
                            return DropdownMenuItem(
                              value: traj,
                              child: Text(traj.name),
                            );
                          }).toList(),
                          onChanged: (val) {
                            setState(() {
                              _selectedTrajectory = val;
                            });
                          },
                        ),
                      ),
                    ),
                  const SizedBox(height: 32),
                  Text(
                    'Wat is je rol in de boot vandaag?',
                    style: textTheme.titleLarge?.copyWith(
                      color: const Color(0xFF021C4B),
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  _buildRoleCard(
                    title: 'Stuur / Coach',
                    description: 'Gedetailleerd dashboard met GPS, tegenstanders en team synchronisatie.',
                    icon: Icons.person,
                    onTap: _selectedTrajectory == null ? () {} : () => _setRole('stuur'),
                  ),
                  const SizedBox(height: 16),
                  _buildRoleCard(
                    title: 'Roeier',
                    description: 'Landscape modus. Enorme getallen voor SPM en peddel-data.',
                    icon: Icons.directions_boat,
                    onTap: _selectedTrajectory == null ? () {} : () => _promptRowerDetails(),
                  ),
                  _buildSimulationToggle(locationService),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSimulationToggle(LocationService locationService) {
    final isSim = locationService.isSimulationMode;
    return Container(
      margin: const EdgeInsets.only(top: 24),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isSim ? const Color(0xFFFFF3E0) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isSim ? const Color(0xFFF2994A) : const Color(0xFFD9DADB),
          width: isSim ? 2 : 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isSim ? const Color(0xFFF2994A) : const Color(0xFFF5F5F5),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.gps_fixed,
              color: isSim ? Colors.white : const Color(0xFF5C5F60),
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'GPX Replay Simulatie',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                Text(
                  'Simuleer GPS op de IJssel in Deventer',
                  style: TextStyle(color: Color(0xFF717C96), fontSize: 12),
                ),
              ],
            ),
          ),
          Switch(
            value: isSim,
            activeThumbColor: const Color(0xFFF2994A),
            onChanged: (val) {
              if (val) {
                locationService.enableGpxSimulation(assetPath: 'assets/gpx/bridge_to_bridge.gpx');
              } else {
                locationService.disableGpxSimulation();
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildRoleCard({
    required String title,
    required String description,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Color(0xFFD9DADB)),
      ),
      color: Colors.white,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: const Color(0xFFEEEEEE),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: const Color(0xFF021C4B), size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF021C4B),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF717C96),
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios, size: 16, color: Color(0xFF717C96)),
            ],
          ),
        ),
      ),
    );
  }
}
