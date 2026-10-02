import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';
import '../models/trajectory.dart';
import '../repositories/trajectory_repository.dart';
import '../providers/trajectory_wizard_state.dart';
import '../utils/result.dart';
import '../utils/trajectory_geometry_utils.dart';
import 'map_picker_screen.dart';

class TrajectoryFormScreen extends StatefulWidget {
  final Trajectory? trajectory;

  const TrajectoryFormScreen({super.key, this.trajectory});

  @override
  State<TrajectoryFormScreen> createState() => _TrajectoryFormScreenState();
}

class _TrajectoryFormScreenState extends State<TrajectoryFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final TrajectoryWizardState _wizardState = TrajectoryWizardState();

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.trajectory != null) {
      final t = widget.trajectory!;
      _wizardState.name = t.name;
      _wizardState.startBridgeName = t.startBridgeName;
      _wizardState.finishBridgeName = t.finishBridgeName;
      _wizardState.startP1 = LatLng(t.startNorthLat, t.startNorthLng);
      _wizardState.startP2 = LatLng(t.startSouthLat, t.startSouthLng);
      _wizardState.startBearing = t.startDirectionBearing;
      _wizardState.finishP1 = LatLng(t.finishNorthLat, t.finishNorthLng);
      _wizardState.finishP2 = LatLng(t.finishSouthLat, t.finishSouthLng);
      _wizardState.finishBearing = t.finishDirectionBearing;
      // Assume completed if editing existing
      _wizardState.setCompleteForEditing();
    }
  }

  @override
  void dispose() {
    _wizardState.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_wizardState.isComplete) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Teken eerst het traject op de kaart!')),
      );
      return;
    }

    _formKey.currentState!.save();

    setState(() {
      _isLoading = true;
    });

    final tr = _wizardState.result!;
      final sN = tr.startP1.latitude > tr.startP2.latitude ? tr.startP1 : tr.startP2;
      final sS = tr.startP1.latitude > tr.startP2.latitude ? tr.startP2 : tr.startP1;
      final fN = tr.finishP1.latitude > tr.finishP2.latitude ? tr.finishP1 : tr.finishP2;
      final fS = tr.finishP1.latitude > tr.finishP2.latitude ? tr.finishP2 : tr.finishP1;

      final newTrajectory = Trajectory(
        id: widget.trajectory?.id ?? '', // Preserve ID if editing
        name: _wizardState.name,
        startBridgeName: _wizardState.startBridgeName,
        startNorthLat: sN.latitude,
        startNorthLng: sN.longitude,
        startSouthLat: sS.latitude,
        startSouthLng: sS.longitude,
        startDirectionBearing: tr.startBearing,
        finishBridgeName: _wizardState.finishBridgeName,
        finishNorthLat: fN.latitude,
        finishNorthLng: fN.longitude,
        finishSouthLat: fS.latitude,
        finishSouthLng: fS.longitude,
        finishDirectionBearing: tr.finishBearing,
      );

    final trajectoryRepository = context.read<TrajectoryRepository>();
    final result = widget.trajectory == null 
      ? await trajectoryRepository.createTrajectory(newTrajectory)
      : await trajectoryRepository.updateTrajectory(newTrajectory);
    
    if (mounted) {
      setState(() {
        _isLoading = false;
      });
      
      switch (result) {
        case Success():
          context.pop(true);
        case Failure(exception: final e):
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Fout bij opslaan: $e')),
          );
      }
    }
  }

  Widget _buildTextField(String label, Function(String) onSaved, {String? initialValue}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextFormField(
        initialValue: initialValue,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'Dit veld is verplicht';
          }
          return null;
        },
        onSaved: (value) {
          if (value != null) onSaved(value);
        },
      ),
    );
  }

  Widget _buildMapPreview() {
    return ListenableBuilder(
      listenable: _wizardState,
      builder: (context, child) {
        if (!_wizardState.isComplete) {
          return Container(
            height: 200,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[400]!),
            ),
            child: const Center(
              child: Text(
                'Nog geen traject getekend',
                style: TextStyle(color: Colors.grey, fontSize: 16),
              ),
            ),
          );
        }

        final tr = _wizardState.result!;
        // Center map roughly between start and finish
        final centerLat = (tr.startP1.latitude + tr.finishP1.latitude) / 2;
        final centerLng = (tr.startP1.longitude + tr.finishP1.longitude) / 2;

        return Container(
          height: 250,
          width: double.infinity,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.blueAccent, width: 2),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: FlutterMap(
              options: MapOptions(
                initialCenter: LatLng(centerLat, centerLng),
                initialZoom: 13.0,
                interactionOptions: const InteractionOptions(
                  flags: InteractiveFlag.none, // Read only preview
                ),
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}',
                  userAgentPackageName: 'com.bridgetobridge.app',
                ),
                PolylineLayer(
                  polylines: [
                    Polyline(points: [tr.startP1, tr.startP2], strokeWidth: 4.0, color: Colors.blueAccent),
                    Polyline(
                      points: TrajectoryGeometryUtils.getArrowHead(tr.startP1, tr.startP2, tr.startBearing),
                      strokeWidth: 6.0,
                      color: const Color(0xFF27AE60),
                    ),
                    Polyline(points: [tr.finishP1, tr.finishP2], strokeWidth: 4.0, color: Colors.redAccent),
                    Polyline(
                      points: TrajectoryGeometryUtils.getArrowHead(tr.finishP1, tr.finishP2, tr.finishBearing),
                      strokeWidth: 6.0,
                      color: const Color(0xFF27AE60),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.trajectory == null ? 'Nieuw Traject' : 'Traject Bewerken'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(16.0),
                children: [
                  const Text('Algemeen', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  _buildTextField('Naam Traject', (v) => _wizardState.name = v, initialValue: widget.trajectory?.name),
                  _buildTextField('Start Brug Naam', (v) => _wizardState.startBridgeName = v, initialValue: widget.trajectory?.startBridgeName),
                  _buildTextField('Finish Brug Naam', (v) => _wizardState.finishBridgeName = v, initialValue: widget.trajectory?.finishBridgeName),
                  
                  const SizedBox(height: 24),
                  const Text('Traject Route', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  
                  _buildMapPreview(),
                  
                  const SizedBox(height: 16),
                  ListenableBuilder(
                    listenable: _wizardState,
                    builder: (context, child) {
                      return ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF27AE60),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        onPressed: () async {
                          if (_wizardState.isComplete) {
                            _wizardState.resetMap();
                          }
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => MapPickerScreen(wizardState: _wizardState),
                            ),
                          );
                        },
                        icon: const Icon(Icons.map, color: Colors.white),
                        label: Text(
                          !_wizardState.isComplete ? 'Teken Traject op Kaart' : 'Wijzig Traject op Kaart',
                          style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 32),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1D3261),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    onPressed: _submit,
                    child: const Text('Opslaan', style: TextStyle(color: Colors.white, fontSize: 16)),
                  ),
                  SizedBox(height: 40 + MediaQuery.of(context).padding.bottom),
                ],
              ),
            ),
    );
  }
}
