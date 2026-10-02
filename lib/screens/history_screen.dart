import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/rowing_models.dart';
import '../repositories/telemetry_repository.dart';
import '../utils/result.dart';
import '../widgets/app_drawer.dart';
import '../services/data_recording_service.dart';
import '../utils/csv_exporter.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  late final TelemetryRepository _telemetryRepository;
  Future<Result<List<HistorySession>, Exception>>? _historyFuture;

  @override
  void initState() {
    super.initState();
    _telemetryRepository = context.read<TelemetryRepository>();
    _historyFuture = _telemetryRepository.getHistory();
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
              icon: const Icon(Icons.file_download, color: Color(0xFF1D3261)),
              onPressed: () => _showExportDialog(context),
            ),
          ),
          Builder(
            builder: (context) => IconButton(
              icon: const Icon(Icons.menu, color: Color(0xFF1D3261)),
              onPressed: () => Scaffold.of(context).openEndDrawer(),
            ),
          )
        ],
      ),
      endDrawer: const AppDrawer(),
      body: FutureBuilder<Result<List<HistorySession>, Exception>>(
        future: _historyFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: \${snapshot.error}'));
          } else if (snapshot.hasData) {
            final result = snapshot.data!;
            return switch (result) {
              Success(value: final data) => ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 24.0),
                  itemCount: data.length + 1, // +1 for the header
                  itemBuilder: (context, index) {
                    if (index == 0) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 24.0),
                        child: Text(
                          "Vorige Runs",
                          style: textTheme.headlineLarge?.copyWith(
                            color: const Color(0xFF1D3261), // oxford-blue
                            fontSize: 24,
                          ),
                        ),
                      );
                    }
                    final session = data[index - 1];
                    return _buildHistoryCard(session, textTheme);
                  },
                ),
              Failure(exception: final e) => Center(child: Text('Fout bij ophalen historie: $e')),
            };
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildHistoryCard(HistorySession session, TextTheme textTheme) {
    // The history design in Stitch actually shows Boat name + type, and segment name.
    // Our HistorySession model currently has segmentName, date, timeStr, averageSpeedKmh, averageStrokeRate.
    // We'll adapt it to fit the Stitch design as close as possible.
    final bool isUser = true; // Assume all history here is for the user for now

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 16.0),
      shape: RoundedRectangleBorder(
        side: const BorderSide(color: Color(0xFFD9DADB)), // silver-mist
        borderRadius: BorderRadius.circular(4), // small radius in history design
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0), // p-gutter
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      const Icon(Icons.directions_boat, color: Color(0xFF717C96), size: 18),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          "Tyr (Stokvisvaarder)", // Hardcoded to match design since model lacks it
                          style: textTheme.labelMedium?.copyWith(
                            color: const Color(0xFF1A1C1C), // on-surface
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (isUser) ...[
                        const SizedBox(width: 4),
                        Text(
                          "(Jij)",
                          style: textTheme.labelMedium?.copyWith(
                            color: const Color(0xFF1D3261), // oxford-blue
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 8.0),
                        child: Text("|", style: TextStyle(color: Color(0xFFD9DADB))), // silver-mist
                      ),
                      Flexible(
                        child: Text(
                          session.segmentName, // "Wilh.brug - Spoorbrug"
                          style: textTheme.labelSmall?.copyWith(
                            color: const Color(0xFF717C96), // cadet-grey
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.expand_more, color: Color(0xFF717C96)), // cadet-grey
              ],
            ),
            const SizedBox(height: 16),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "TOTALE TIJD",
                        style: textTheme.labelSmall?.copyWith(
                          color: const Color(0xFF717C96), // cadet-grey
                          letterSpacing: 1.0,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        session.timeStr, // e.g., "04:35"
                        style: textTheme.displayLarge?.copyWith(
                          color: const Color(0xFF1D3261), // oxford-blue
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "GEMIDDELDE SNELHEID",
                        style: textTheme.labelSmall?.copyWith(
                          color: const Color(0xFF717C96), // cadet-grey
                          letterSpacing: 1.0,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Text(
                            session.averageSpeedKmh.toStringAsFixed(1),
                            style: textTheme.headlineMedium?.copyWith(
                              color: const Color(0xFF1D3261), // oxford-blue
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            "km/u",
                            style: textTheme.bodyMedium?.copyWith(
                              color: const Color(0xFF717C96), // cadet-grey
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8), // Padding bottom to align with the tall time text
                    ],
                  ),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }

  void _showExportDialog(BuildContext context) async {
    final service = context.read<DataRecordingService>();
    final sessions = await service.listRecordedSessions();

    if (!context.mounted) return;

    if (sessions.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Geen lokale sensordata gevonden om te exporteren.')),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Exporteer Sensordata'),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: sessions.length,
              itemBuilder: (context, index) {
                final sessionId = sessions[index];
                // session ID is typically 'session_1234567890'
                final timestampStr = sessionId.replaceFirst('session_', '');
                final date = DateTime.fromMillisecondsSinceEpoch(int.tryParse(timestampStr) ?? 0);
                return ListTile(
                  leading: const Icon(Icons.insert_chart_outlined),
                  title: Text('Sessie van ${date.day}-${date.month}-${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}'),
                  trailing: const Icon(Icons.share),
                  onTap: () {
                    Navigator.pop(context);
                    CsvExporter.exportSessionToCsv(sessionId);
                  },
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Annuleren'),
            ),
          ],
        );
      },
    );
  }
}
