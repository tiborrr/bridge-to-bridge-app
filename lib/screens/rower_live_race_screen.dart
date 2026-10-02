import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/live_race_provider.dart';
import '../models/rowing_models.dart';
import '../utils/result.dart';

class RowerLiveRaceScreen extends StatelessWidget {
  final VoidCallback onStop;

  const RowerLiveRaceScreen({super.key, required this.onStop});

  @override
  Widget build(BuildContext context) {
    return Consumer<LiveRaceProvider>(
      builder: (context, provider, child) {
        return Scaffold(
          backgroundColor: Colors.black,
          body: FutureBuilder<Result<LiveTelemetry, Exception>>(
            future: provider.liveTelemetryFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator(color: Color(0xFF27AE60)));
              }
              
              String? spmOverride;
              if (snapshot.hasData) {
                final result = snapshot.data!;
                if (result case Success(value: final data)) {
                  spmOverride = data.strokeRate.toString();
                }
              }

              final spm = provider.currentMetrics?.spm?.toStringAsFixed(0) ?? spmOverride ?? '--';
              final pitch = provider.currentMetrics?.pitch?.toStringAsFixed(1) ?? '--';
              final roll = provider.currentMetrics?.roll?.toStringAsFixed(1) ?? '--';
              
              return SafeArea(
                child: Column(
                  children: [
                    // Distance Indicator
                    Padding(
                      padding: const EdgeInsets.only(top: 16, left: 16, right: 16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.location_on, color: Color(0xFF5C5F60), size: 16),
                          const SizedBox(width: 8),
                          Text(
                            "${provider.targetLabel}: ${provider.distanceText}",
                            style: const TextStyle(color: Color(0xFF5C5F60), fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                    // TOP HALF: Massive SPM
                    Expanded(
                      flex: 3,
                      child: Container(
                        margin: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1A1C1C),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(color: const Color(0xFF27AE60), width: 4),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text(
                              'SPM',
                              style: TextStyle(color: Color(0xFF5C5F60), fontSize: 32, fontWeight: FontWeight.bold),
                            ),
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                spm,
                                style: const TextStyle(
                                  color: Color(0xFF27AE60),
                                  fontSize: 200,
                                  fontWeight: FontWeight.bold,
                                  height: 1.0,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    
                    // BOTTOM HALF: Pitch/Roll and Controls
                    Expanded(
                      flex: 2,
                      child: Padding(
                        padding: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
                        child: Column(
                          children: [
                            Expanded(
                              child: Row(
                                children: [
                                  Expanded(child: _buildSmallMetricCard('PITCH', pitch, '°')),
                                  const SizedBox(width: 16),
                                  Expanded(child: _buildSmallMetricCard('ROLL', roll, '°')),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),
                            Expanded(
                              child: Row(
                                children: [
                                  // Calibrate Button
                                  Expanded(
                                    child: ElevatedButton(
                                      onPressed: () {
                                        provider.calibrate();
                                      },
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: const Color(0xFF021C4B),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                      ),
                                      child: const Icon(Icons.center_focus_strong, color: Colors.white, size: 48),
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  // Exit Button
                                  Expanded(
                                    child: ElevatedButton(
                                      onPressed: onStop,
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: const Color(0xFFD0021B),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                      ),
                                      child: const Icon(Icons.exit_to_app, color: Colors.white, size: 48),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildSmallMetricCard(String title, String value, String unit) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1A1C1C),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF5C5F60), width: 2),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            title,
            style: const TextStyle(color: Color(0xFF5C5F60), fontSize: 20, fontWeight: FontWeight.bold),
          ),
          Flexible(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    value,
                    style: const TextStyle(color: Colors.white, fontSize: 60, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    unit,
                    style: const TextStyle(color: Color(0xFF5C5F60), fontSize: 24),
                  ),
                ],
              ),
            ),
          )
        ],
      ),
    );
  }
}
