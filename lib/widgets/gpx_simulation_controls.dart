import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/location_service.dart';

class GpxSimulationControls extends StatefulWidget {
  final EdgeInsets margin;

  const GpxSimulationControls({
    super.key,
    this.margin = const EdgeInsets.all(12),
  });

  @override
  State<GpxSimulationControls> createState() => _GpxSimulationControlsState();
}

class _GpxSimulationControlsState extends State<GpxSimulationControls> {
  bool _isCollapsed = false;

  final List<double> _speeds = [1.0, 2.0, 5.0, 10.0];
  int _speedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final locationService = context.watch<LocationService>();
    final replayClient = locationService.replayClient;

    if (replayClient == null) return const SizedBox.shrink();

    return StreamBuilder<int>(
      stream: replayClient.progressStream,
      initialData: replayClient.currentIndex,
      builder: (context, snapshot) {
        final currentPoint = replayClient.currentIndex;
        final totalPoints = replayClient.totalPoints;
        final isPlaying = replayClient.isPlaying;

        return Card(
          margin: widget.margin,
          color: const Color(0xFF1E222A).withValues(alpha: 0.95),
          elevation: 8,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: Color(0xFFF2994A), width: 1.5),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header Bar
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF2994A).withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.gps_fixed, color: Color(0xFFF2994A), size: 16),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'GPX SIMULATIE',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '[$currentPoint/$totalPoints]',
                      style: const TextStyle(
                        color: Color(0xFF9E9E9E),
                        fontSize: 12,
                        fontFamily: 'monospace',
                      ),
                    ),
                    const Spacer(),
                    // Speed cycle button
                    InkWell(
                      onTap: () {
                        setState(() {
                          _speedIndex = (_speedIndex + 1) % _speeds.length;
                          replayClient.setSpeedMultiplier(_speeds[_speedIndex]);
                        });
                      },
                      borderRadius: BorderRadius.circular(6),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFF2C323D),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '${_speeds[_speedIndex].toStringAsFixed(0)}x',
                          style: const TextStyle(
                            color: Color(0xFFF2994A),
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    // Collapse/Expand button
                    IconButton(
                      icon: Icon(
                        _isCollapsed ? Icons.keyboard_arrow_down : Icons.keyboard_arrow_up,
                        color: Colors.white70,
                        size: 18,
                      ),
                      visualDensity: VisualDensity.compact,
                      onPressed: () => setState(() => _isCollapsed = !_isCollapsed),
                    ),
                    // Exit simulation
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white54, size: 16),
                      visualDensity: VisualDensity.compact,
                      onPressed: () => locationService.disableGpxSimulation(),
                    ),
                  ],
                ),

                if (!_isCollapsed) ...[
                  // Scrubbing Slider
                  SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      trackHeight: 2,
                      thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                      overlayShape: const RoundSliderOverlayShape(overlayRadius: 12),
                      activeTrackColor: const Color(0xFFF2994A),
                      inactiveTrackColor: Colors.white24,
                      thumbColor: const Color(0xFFF2994A),
                    ),
                    child: Slider(
                      value: currentPoint.clamp(0, totalPoints > 0 ? totalPoints - 1 : 0).toDouble(),
                      min: 0,
                      max: (totalPoints > 0 ? totalPoints - 1 : 1).toDouble(),
                      onChanged: (val) {
                        setState(() {
                          replayClient.seek(val.round());
                        });
                      },
                    ),
                  ),

                  // Playback Actions
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      // Reset to start
                      IconButton(
                        tooltip: 'Reset naar start',
                        icon: const Icon(Icons.replay, color: Colors.white70, size: 20),
                        onPressed: () {
                          setState(() {
                            replayClient.reset();
                          });
                        },
                      ),
                      // Step back
                      IconButton(
                        tooltip: 'Stap terug',
                        icon: const Icon(Icons.skip_previous, color: Colors.white70, size: 20),
                        onPressed: currentPoint > 0
                            ? () {
                                setState(() {
                                  replayClient.seek(currentPoint - 1);
                                });
                              }
                            : null,
                      ),
                      // Play / Pause
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          shape: const CircleBorder(),
                          padding: const EdgeInsets.all(10),
                          backgroundColor: const Color(0xFFF2994A),
                          foregroundColor: Colors.black,
                        ),
                        onPressed: () {
                          setState(() {
                            if (isPlaying) {
                              replayClient.pause();
                            } else {
                              replayClient.play();
                            }
                          });
                        },
                        child: Icon(
                          isPlaying ? Icons.pause : Icons.play_arrow,
                          size: 24,
                          color: Colors.black,
                        ),
                      ),
                      // Step forward
                      IconButton(
                        tooltip: 'Stap vooruit',
                        icon: const Icon(Icons.skip_next, color: Colors.white70, size: 20),
                        onPressed: () {
                          setState(() {
                            replayClient.step();
                          });
                        },
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}
