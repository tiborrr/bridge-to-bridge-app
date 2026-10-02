import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/trajectory.dart';
import '../repositories/trajectory_repository.dart';
import '../utils/result.dart';
import '../widgets/app_drawer.dart';
import 'package:go_router/go_router.dart';

class TrajectoriesScreen extends StatefulWidget {
  const TrajectoriesScreen({super.key});

  @override
  State<TrajectoriesScreen> createState() => _TrajectoriesScreenState();
}

class _TrajectoriesScreenState extends State<TrajectoriesScreen> {
  late final TrajectoryRepository _trajectoryRepository;
  List<Trajectory> _trajectories = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _trajectoryRepository = context.read<TrajectoryRepository>();
    _loadTrajectories();
  }

  Future<void> _loadTrajectories() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    
    final result = await _trajectoryRepository.getTrajectories();
    if (mounted) {
      setState(() {
        _isLoading = false;
        switch (result) {
          case Success(value: final data):
            _trajectories = data;
          case Failure(exception: final e):
            _error = e.toString();
        }
      });
    }
  }

  Future<void> _deleteTrajectory(Trajectory trajectory) async {
    final index = _trajectories.indexOf(trajectory);
    if (index == -1) return;

    // 1. Optimistic UI update
    setState(() {
      _trajectories.removeAt(index);
    });

    // 2. Perform API Call on the background
    final result = await _trajectoryRepository.deleteTrajectory(trajectory.id);
    
    if (mounted) {
      switch (result) {
        case Success():
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Traject verwijderd')),
          );
        case Failure(exception: final e):
          // 3. Revert on failure
          setState(() {
            _trajectories.insert(index, trajectory);
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Fout bij verwijderen, wijziging ongedaan gemaakt: $e')),
          );
      }
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
          child: Container(color: const Color(0xFFD9DADB), height: 1.0),
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
          ),
        ],
      ),
      endDrawer: const AppDrawer(),
      body: _isLoading 
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text('Fout bij ophalen trajecten: $_error'))
              : _trajectories.isEmpty
                  ? const Center(child: Text('Geen trajecten gevonden.'))
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 24.0),
                      itemCount: _trajectories.length + 1,
                      itemBuilder: (context, index) {
                        if (index == 0) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 24.0),
                            child: Text(
                              "Trajecten Beheren",
                              style: textTheme.headlineLarge?.copyWith(
                                color: const Color(0xFF1D3261),
                                fontSize: 24,
                              ),
                            ),
                          );
                        }
                        final trajectory = _trajectories[index - 1];
                        return _buildTrajectoryCard(trajectory, textTheme);
                      },
                    ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF1D3261),
        onPressed: () async {
          final result = await context.push('/trajectories/new');
          if (result == true) {
            _loadTrajectories();
          }
        },
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildTrajectoryCard(Trajectory trajectory, TextTheme textTheme) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 16.0),
      shape: RoundedRectangleBorder(
        side: const BorderSide(color: Color(0xFFD9DADB)),
        borderRadius: BorderRadius.circular(4),
      ),
      child: InkWell(
        onTap: () async {
          final result = await context.push('/trajectories/edit', extra: trajectory);
          if (result == true) {
            _loadTrajectories();
          }
        },
        borderRadius: BorderRadius.circular(4),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    trajectory.name,
                    style: textTheme.titleMedium?.copyWith(
                      color: const Color(0xFF1D3261),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                  onPressed: () async {
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: const Text('Verwijderen'),
                        content: Text('Weet je zeker dat je ${trajectory.name} wilt verwijderen?'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.of(ctx).pop(false),
                            child: const Text('Annuleren'),
                          ),
                          TextButton(
                            onPressed: () => Navigator.of(ctx).pop(true),
                            child: const Text('Verwijderen', style: TextStyle(color: Colors.red)),
                          ),
                        ],
                      ),
                    );
                    if (confirm == true) {
                      _deleteTrajectory(trajectory);
                    }
                  },
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Start: ${trajectory.startBridgeName}',
              style: textTheme.bodyMedium?.copyWith(color: const Color(0xFF717C96)),
            ),
            Text(
              'Finish: ${trajectory.finishBridgeName}',
              style: textTheme.bodyMedium?.copyWith(color: const Color(0xFF717C96)),
            ),
          ],
        ),
      ),
      ),
    );
  }
}
