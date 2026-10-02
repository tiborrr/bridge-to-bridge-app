import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/live_race_provider.dart';

class PreRaceScreen extends StatelessWidget {
  final VoidCallback onRaceStart;
  final VoidCallback onCancel;

  const PreRaceScreen({super.key, required this.onRaceStart, required this.onCancel});

  @override
  Widget build(BuildContext context) {
    return Consumer<LiveRaceProvider>(
      builder: (context, provider, child) {
        final distanceToStart = provider.currentDistanceToTarget != null 
            ? provider.currentDistanceToTarget!.toStringAsFixed(0)
            : '--';
            
        final spm = provider.currentMetrics?.spm != null 
            ? provider.currentMetrics!.spm!.toStringAsFixed(0) 
            : '--';

        return Scaffold(
          backgroundColor: Colors.black,
          body: SafeArea(
            child: Column(
              children: [
                // TOP BAR: Status
                Padding(
                  padding: const EdgeInsets.only(top: 16, left: 16, right: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.location_on, color: Color(0xFFF2994A), size: 16),
                      const SizedBox(width: 8),
                      const Text(
                        "WACHTEN OP START...",
                        style: TextStyle(color: Color(0xFF5C5F60), fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                
                // MASSIVE DISTANCE CARD
                Expanded(
                  flex: 3,
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1A1C1C),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: const Color(0xFFF2994A), width: 4),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text('AFSTAND TOT START', style: TextStyle(color: Color(0xFF5C5F60), fontSize: 20, fontWeight: FontWeight.bold)),
                        const Spacer(),
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            distanceToStart,
                            style: const TextStyle(color: Color(0xFFF2994A), fontSize: 150, fontWeight: FontWeight.bold, height: 1.0),
                          ),
                        ),
                        const Text('METER', style: TextStyle(color: Color(0xFF5C5F60), fontSize: 24, fontWeight: FontWeight.bold)),
                        const Spacer(),
                      ],
                    ),
                  ),
                ),
                
                // ROW 2: WARMUP STATS
                Expanded(
                  flex: 2,
                  child: Row(
                    children: [
                      Expanded(
                        child: Container(
                          margin: const EdgeInsets.only(left: 16, right: 8, top: 8, bottom: 16),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1A1C1C),
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(color: const Color(0xFF5C5F60), width: 2),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Text('SLAGTEMPO', style: TextStyle(color: Color(0xFF5C5F60), fontSize: 18, fontWeight: FontWeight.bold)),
                              const Spacer(),
                              FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.baseline,
                                  textBaseline: TextBaseline.alphabetic,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      spm,
                                      style: const TextStyle(color: Colors.white, fontSize: 80, fontWeight: FontWeight.bold, height: 1.0),
                                    ),
                                    const SizedBox(width: 8),
                                    const Text('s/m', style: TextStyle(color: Color(0xFF5C5F60), fontSize: 24, fontWeight: FontWeight.bold)),
                                  ],
                                ),
                              ),
                              const Spacer(),
                            ],
                          ),
                        ),
                      ),
                      Expanded(
                        child: Container(
                          margin: const EdgeInsets.only(left: 8, right: 16, top: 8, bottom: 16),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1A1C1C),
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(color: const Color(0xFF5C5F60), width: 2),
                          ),
                          child: const Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.directions_boat, color: Color(0xFF5C5F60), size: 48),
                              SizedBox(height: 16),
                              FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text('NAVIGEER\nNAAR DE BRUG', textAlign: TextAlign.center, style: TextStyle(color: Color(0xFF5C5F60), fontSize: 16, fontWeight: FontWeight.bold)),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                
                // BOTTOM: Buttons
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: onCancel,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFD0021B),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            padding: const EdgeInsets.symmetric(vertical: 20),
                          ),
                          child: const Text('ANNULEER', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                             provider.calibrate();
                             ScaffoldMessenger.of(context).showSnackBar(
                               const SnackBar(content: Text('Peddel rotatie gecentreerd!'), duration: Duration(seconds: 2)),
                             );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF021C4B),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            padding: const EdgeInsets.symmetric(vertical: 20),
                          ),
                          child: const Text('KALIBREER', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
