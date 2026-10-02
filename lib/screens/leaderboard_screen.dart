import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart';
import '../models/rowing_models.dart';
import '../models/trajectory.dart';
import '../repositories/telemetry_repository.dart';
import '../services/api_service.dart';
import '../utils/result.dart';
import '../widgets/app_drawer.dart';
import '../widgets/trajectory_map_preview.dart';
import '../services/location_service.dart';

class LeaderboardScreen extends StatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen> {
  late final TelemetryRepository _telemetryRepository;
  late final ApiService _apiService;
  
  bool _isLoading = true;
  String? _error;
  
  List<Trajectory> _trajectories = [];
  Trajectory? _selectedTrajectory;
  List<LeaderboardEntry> _leaderboard = [];

  @override
  void initState() {
    super.initState();
    _telemetryRepository = context.read<TelemetryRepository>();
    _apiService = context.read<ApiService>();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final trajResult = await _apiService.fetchTrajectories();
      if (trajResult is Failure<List<Trajectory>, Exception>) {
        setState(() {
          _error = 'Fout bij ophalen trajecten: \${trajResult.exception}';
          _isLoading = false;
        });
        return;
      }

      _trajectories = (trajResult as Success<List<Trajectory>, Exception>).value;
      if (_trajectories.isEmpty) {
        setState(() {
          _error = 'Geen trajecten gevonden.';
          _isLoading = false;
        });
        return;
      }

      // Try to find closest trajectory
      Trajectory closest = _trajectories.first;
      
      if (!mounted) return;
      
      try {
        final locService = context.read<LocationService>();
        double? lat;
        double? lng;
        
        if (locService.currentLocation != null) {
          lat = locService.currentLocation!.latitude;
          lng = locService.currentLocation!.longitude;
        } else {
          final permission = await Geolocator.checkPermission();
          if (permission == LocationPermission.always || permission == LocationPermission.whileInUse) {
            final position = await Geolocator.getLastKnownPosition();
            if (position != null) {
              lat = position.latitude;
              lng = position.longitude;
            } else {
              final pos = await Geolocator.getCurrentPosition(
                locationSettings: const LocationSettings(
                  accuracy: LocationAccuracy.low,
                  timeLimit: Duration(seconds: 3),
                ),
              );
              lat = pos.latitude;
              lng = pos.longitude;
            }
          }
        }
        
        if (lat != null && lng != null) {
          double minDistance = double.infinity;
          for (final traj in _trajectories) {
            final dist = Geolocator.distanceBetween(
              lat, lng,
              traj.startNorthLat, traj.startNorthLng
            );
            if (dist < minDistance) {
              minDistance = dist;
              closest = traj;
            }
          }
        }
      } catch (_) {
        // Fallback to first if location fails
      }

      _selectedTrajectory = closest;
      await _fetchLeaderboardForSelected();
      
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _fetchLeaderboardForSelected() async {
    if (_selectedTrajectory == null) return;
    
    setState(() => _isLoading = true);
    final result = await _telemetryRepository.getLeaderboard(trajectoryId: _selectedTrajectory!.id);
    
    if (mounted) {
      setState(() {
        if (result is Success<List<LeaderboardEntry>, Exception>) {
          _leaderboard = result.value;
          _error = null;
        } else {
          _error = 'Fout bij ophalen ranglijst: \${(result as Failure).exception}';
        }
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        backgroundColor: colorScheme.surface,
        scrolledUnderElevation: 0,
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1.0),
          child: Container(color: const Color(0xFFD9DADB), height: 1.0), // silver-mist border
        ),
        title: Row(
          children: [
            const Icon(Icons.directions_boat, color: Color(0xFF1D3261)),
            const SizedBox(width: 12),
            Text(
              'BRUG TOT BRUG',
              style: textTheme.headlineMedium?.copyWith(
                color: const Color(0xFF1D3261),
                fontWeight: FontWeight.w600,
                letterSpacing: 1.5,
              ),
            ),
          ],
        ),
        actions: [
          Builder(
            builder: (context) => IconButton(
              icon: const Icon(Icons.menu, color: Color(0xFF1D3261)),
              onPressed: () => Scaffold.of(context).openEndDrawer(),
            ),
          )
        ],
      ),
      endDrawer: const AppDrawer(),
      body: _buildBody(theme, textTheme),
    );
  }
  
  Widget _buildBody(ThemeData theme, TextTheme textTheme) {
    if (_isLoading && _trajectories.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    
    if (_error != null && _trajectories.isEmpty) {
      return Center(child: Text(_error!));
    }

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (_selectedTrajectory != null)
                  TrajectoryMapPreview(
                    trajectory: _selectedTrajectory!,
                    height: 180,
                  ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFD9DADB)),
                    color: Colors.white,
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<Trajectory>(
                      value: _selectedTrajectory,
                      isExpanded: true,
                      icon: const Icon(Icons.arrow_drop_down, color: Color(0xFF1D3261)),
                      items: _trajectories.map((traj) {
                        return DropdownMenuItem(
                          value: traj,
                          child: Text(
                            traj.name,
                            style: textTheme.bodyLarge?.copyWith(
                              color: const Color(0xFF1A1C1C),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        );
                      }).toList(),
                      onChanged: (Trajectory? newValue) {
                        if (newValue != null && newValue.id != _selectedTrajectory?.id) {
                          setState(() {
                            _selectedTrajectory = newValue;
                          });
                          _fetchLeaderboardForSelected();
                        }
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
              decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(color: Color(0xFFD9DADB))), // silver-mist
              ),
              child: Row(
                children: [
                  SizedBox(
                    width: 48,
                    child: Text("POS", textAlign: TextAlign.center, style: textTheme.labelSmall?.copyWith(color: const Color(0xFF717C96), letterSpacing: 1.2)),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text("ROEIER / TEAM", style: textTheme.labelSmall?.copyWith(color: const Color(0xFF717C96), letterSpacing: 1.2)),
                  ),
                  Text("TIJD", style: textTheme.labelSmall?.copyWith(color: const Color(0xFF717C96), letterSpacing: 1.2)),
                ],
              ),
            ),
          ),
        ),
        if (_isLoading)
          const SliverFillRemaining(
            child: Center(child: CircularProgressIndicator()),
          )
        else if (_leaderboard.isEmpty)
          SliverFillRemaining(
            child: Center(
              child: Text(
                "Nog geen resultaten voor dit traject.",
                style: textTheme.bodyLarge?.copyWith(color: const Color(0xFF717C96)),
              ),
            ),
          )
        else
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  return _buildLeaderboardRow(_leaderboard[index], textTheme);
                },
                childCount: _leaderboard.length,
              ),
            ),
          ),
        const SliverPadding(padding: EdgeInsets.only(bottom: 24.0)),
      ],
    );
  }

  Widget _buildLeaderboardRow(LeaderboardEntry entry, TextTheme textTheme) {
    final bool isTop = entry.position == 1;
    final bool isUser = entry.team.name.contains("(Jij)");
    
    final backgroundColor = isUser ? const Color(0xFFF3F3F4) : Colors.white;

    return Container(
      decoration: BoxDecoration(
        color: backgroundColor,
        border: const Border(bottom: BorderSide(color: Color(0xFFD9DADB))), // silver-mist
      ),
      child: Stack(
        children: [
          if (isUser)
            Positioned(
              left: 0,
              top: 0,
              bottom: 0,
              width: 4,
              child: Container(color: const Color(0xFF27AE60)), // performance-green
            ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
            child: Row(
              children: [
                SizedBox(
                  width: 48,
                  child: Center(
                    child: isTop
                        ? const Icon(Icons.emoji_events, color: Color(0xFFC9915D), size: 28)
                        : Text(
                            entry.position.toString(),
                            style: isUser 
                                ? textTheme.headlineMedium?.copyWith(color: const Color(0xFF717C96)) 
                                : textTheme.bodyLarge?.copyWith(color: const Color(0xFF717C96)),
                          ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        entry.team.name,
                        style: textTheme.headlineMedium?.copyWith(
                          color: const Color(0xFF1A1C1C),
                        ),
                      ),
                      Text(
                        entry.team.boatType,
                        style: textTheme.bodyMedium?.copyWith(
                          color: const Color(0xFF717C96),
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  entry.timeStr,
                  style: textTheme.headlineMedium?.copyWith(
                    color: isTop || isUser ? const Color(0xFF1D3261) : const Color(0xFF44464F),
                  ),
                )
              ],
            ),
          ),
        ],
      ),
    );
  }
}
