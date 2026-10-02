import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/rowing_models.dart';
import '../providers/live_race_provider.dart';
import '../services/location_service.dart';
import '../services/websocket_service.dart';
import '../utils/result.dart';

class LiveRaceScreen extends StatelessWidget {
  final VoidCallback onStop;

  const LiveRaceScreen({super.key, required this.onStop});

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
              final speedKmh = snapshot.hasData && snapshot.data is Success 
                  ? (snapshot.data as Success<LiveTelemetry, Exception>).value.speedKmh.toStringAsFixed(1) 
                  : '--';
                  
              final leadLag = snapshot.hasData && snapshot.data is Success 
                  ? (snapshot.data as Success<LiveTelemetry, Exception>).value.timeLeadSeconds 
                  : 0;

              final isRacing = provider.raceState == RaceState.racing;

              return SafeArea(
                child: Column(
                  children: [
                    // TOP BAR: Distance & State
                    Padding(
                      padding: const EdgeInsets.only(top: 16, left: 16, right: 16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            isRacing ? Icons.directions_run : Icons.pause_circle_outline,
                            color: isRacing ? const Color(0xFF27AE60) : const Color(0xFFF2994A),
                            size: 16,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            "${provider.targetLabel}: ${provider.distanceText}",
                            style: const TextStyle(color: Color(0xFF5C5F60), fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // ROW 1: SPEED & LEAD/LAG
                    Expanded(
                      flex: 3,
                      child: Row(
                        children: [
                          Expanded(
                            child: _buildCard(
                              margin: const EdgeInsets.only(left: 16, right: 8, bottom: 8),
                              title: 'SNELHEID',
                              value: speedKmh,
                              unit: 'km/u',
                              borderColor: const Color(0xFF5C5F60),
                              valueSize: 110,
                            ),
                          ),
                          Expanded(
                            child: _buildLeadLagCard(
                              margin: const EdgeInsets.only(left: 8, right: 16, bottom: 8),
                              leadLag: leadLag,
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    // ROW 2: SYNC & SPM
                    Expanded(
                      flex: 2,
                      child: Row(
                        children: [
                          Expanded(
                            child: _buildPrecisionCard(provider.currentTeamData?.seatPrecisions),
                          ),
                          Expanded(
                            child: _buildCard(
                              margin: const EdgeInsets.only(left: 8, right: 16, top: 8, bottom: 16),
                              title: 'SLAGTEMPO',
                              value: spm,
                              unit: 's/m',
                              borderColor: const Color(0xFF5C5F60),
                              valueSize: 80,
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    // BOTTOM PROGRESS BAR
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
                      child: SizedBox(
                        height: 32,
                        child: Stack(
                          alignment: Alignment.centerLeft,
                          children: [
                            Container(
                              height: 8,
                              decoration: BoxDecoration(
                                color: const Color(0xFF1A1C1C),
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                            FractionallySizedBox(
                              widthFactor: provider.progressPercent,
                              child: Container(
                                height: 8,
                                decoration: BoxDecoration(
                                  color: const Color(0xFF27AE60),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ),
                            ),
                            Positioned(
                              left: MediaQuery.of(context).size.width * provider.progressPercent.clamp(0.0, 0.8) - 16,
                              child: Container(
                                width: 32,
                                height: 32,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.black,
                                  border: Border.all(color: const Color(0xFF27AE60), width: 2),
                                ),
                                child: const Icon(Icons.sailing, color: Colors.white, size: 16),
                              ),
                            )
                          ],
                        ),
                      ),
                    ),

                    // BOTTOM: Buttons
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
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
                          const SizedBox(width: 16),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () {
                                showDialog(
                                  context: context,
                                  builder: (ctx) => AlertDialog(
                                    backgroundColor: const Color(0xFF1A1C1C),
                                    title: const Text('Sessie Stoppen', style: TextStyle(color: Colors.white)),
                                    content: const Text('Weet je zeker dat je deze sessie wilt afbreken?', style: TextStyle(color: Colors.white70)),
                                    actions: [
                                      TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Annuleren', style: TextStyle(color: Color(0xFF5C5F60)))),
                                      TextButton(
                                        onPressed: () {
                                          Navigator.pop(ctx);
                                          onStop();
                                        },
                                        child: const Text('Ja, stop', style: TextStyle(color: Color(0xFFD0021B))),
                                      ),
                                    ],
                                  ),
                                );
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFD0021B),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                padding: const EdgeInsets.symmetric(vertical: 20),
                              ),
                              child: const Text('STOP', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                            ),
                          ),
                        ],
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

  Widget _buildCard({
    required EdgeInsetsGeometry margin,
    required String title,
    required String value,
    required String unit,
    required Color borderColor,
    Color valueColor = Colors.white,
    required double valueSize,
  }) {
    return Container(
      margin: margin,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1C1C),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: borderColor, width: 2),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(title, style: const TextStyle(color: Color(0xFF5C5F60), fontSize: 18, fontWeight: FontWeight.bold)),
          const Spacer(),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  value,
                  style: TextStyle(color: valueColor, fontSize: valueSize, fontWeight: FontWeight.bold, height: 1.0),
                ),
                const SizedBox(width: 8),
                Text(unit, style: const TextStyle(color: Color(0xFF5C5F60), fontSize: 24, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          const Spacer(),
        ],
      ),
    );
  }

  Widget _buildLeadLagCard({
    required EdgeInsetsGeometry margin,
    required int leadLag,
  }) {
    final bool isAhead = leadLag <= 0;
    final String value = isAhead ? "-${leadLag.abs()}" : "+$leadLag";
    final Color color = isAhead ? const Color(0xFF27AE60) : const Color(0xFFD0021B);
    
    return Container(
      margin: margin,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1C1C),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: color, width: 4),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(isAhead ? 'VOORSPRONG' : 'ACHTERSTAND', style: const TextStyle(color: Color(0xFF5C5F60), fontSize: 18, fontWeight: FontWeight.bold)),
          const Spacer(),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  value,
                  style: TextStyle(color: color, fontSize: 110, fontWeight: FontWeight.bold, height: 1.0),
                ),
                const SizedBox(width: 8),
                const Text('sec', style: TextStyle(color: Color(0xFF5C5F60), fontSize: 24, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          const Spacer(),
        ],
      ),
    );
  }

  Widget _buildPrecisionCard(List<SeatPrecision>? precisions) {
    if (precisions == null || precisions.isEmpty) {
      return Container(
        margin: const EdgeInsets.only(left: 16, right: 8, top: 8, bottom: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1C1C),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: const Color(0xFF5C5F60), width: 2),
        ),
        child: const Center(child: Text('Wachten op team...', style: TextStyle(color: Color(0xFF5C5F60)))),
      );
    }
    
    // Sorteer op plek
    final sorted = List<SeatPrecision>.from(precisions)..sort((a, b) => a.seat.compareTo(b.seat));

    return Container(
      margin: const EdgeInsets.only(left: 16, right: 8, top: 8, bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1C1C),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFF5C5F60), width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('TIMING (T.O.V SLAG)', style: TextStyle(color: Color(0xFF5C5F60), fontSize: 14, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
          const SizedBox(height: 8),
          Expanded(
            child: ListView.builder(
              itemCount: sorted.length,
              itemBuilder: (context, index) {
                final p = sorted[index];
                final offsetSec = p.offsetMs / 1000.0;
                final color = (offsetSec.abs() < 0.2) ? const Color(0xFF27AE60) : const Color(0xFFF2994A);
                final text = (offsetSec.abs() < 0.05) ? "SYNC" : (offsetSec < 0 ? "${offsetSec.abs().toStringAsFixed(2)}s vroeg" : "${offsetSec.toStringAsFixed(2)}s laat");
                final sideColor = p.side == 'port' ? Colors.redAccent : Colors.greenAccent;
                
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      Container(
                        width: 12, height: 12,
                        decoration: BoxDecoration(color: sideColor, shape: BoxShape.circle),
                      ),
                      const SizedBox(width: 8),
                      Text("Bank ${p.seat}", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      const Spacer(),
                      Text(text, style: TextStyle(color: color, fontWeight: FontWeight.bold)),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
