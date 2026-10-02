import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:go_router/go_router.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';
import '../providers/trajectory_wizard_state.dart';
import '../services/location_service.dart';
import '../utils/trajectory_geometry_utils.dart';

class MapPickerScreen extends StatefulWidget {
  final TrajectoryWizardState wizardState;

  const MapPickerScreen({super.key, required this.wizardState});

  @override
  State<MapPickerScreen> createState() => _MapPickerScreenState();
}

class _MapPickerScreenState extends State<MapPickerScreen> {
  final MapController _mapController = MapController();
  late LatLng _defaultCenter;

  @override
  void initState() {
    super.initState();
    // Default fallback is Deventer, but override with current location if already known
    _defaultCenter = const LatLng(52.2536, 6.1558);
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Check if location service has a known location
      // We can't access context.read in initState directly, so do it in post frame or didChangeDependencies
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Attempt to set default center immediately from pre-fetched location before building map
    try {
      final locProvider = Provider.of<LocationService>(context, listen: false);
      if (locProvider.currentLocation != null) {
        _defaultCenter = LatLng(locProvider.currentLocation!.latitude, locProvider.currentLocation!.longitude);
      }
    } catch (_) {}
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _centerOnLocation();
    });
  }

  Future<void> _centerOnLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Locatievoorzieningen staan uit.')));
      return;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Locatie permissie is geweigerd.')));
        return;
      }
    }
    
    if (permission == LocationPermission.deniedForever) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Locatie permissie is permanent geweigerd.')));
      return;
    } 

    try {
      final position = await Geolocator.getCurrentPosition();
      _mapController.move(LatLng(position.latitude, position.longitude), 16.0);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Kon locatie niet bepalen.')));
      }
    }
  }

  String _getInstructionText(TrajectoryWizardStep step) {
    switch (step) {
      case TrajectoryWizardStep.selectStartPoint1: return 'Stap 1/6: Plaats het vizier op Start Pyloon 1';
      case TrajectoryWizardStep.selectStartPoint2: return 'Stap 2/6: Plaats het vizier op Start Pyloon 2';
      case TrajectoryWizardStep.confirmStartDirection: return 'Stap 3/6: Controleer de roeirichting (Start)';
      case TrajectoryWizardStep.selectFinishPoint1: return 'Stap 4/6: Plaats het vizier op Finish Pyloon 1';
      case TrajectoryWizardStep.selectFinishPoint2: return 'Stap 5/6: Plaats het vizier op Finish Pyloon 2';
      case TrajectoryWizardStep.confirmFinishDirection: return 'Stap 6/6: Controleer de roeirichting (Finish)';
      case TrajectoryWizardStep.completed: return 'Klaar!';
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.wizardState,
      builder: (context, child) {
        final state = widget.wizardState;
        bool isDirectionStep = state.currentStep == TrajectoryWizardStep.confirmStartDirection || state.currentStep == TrajectoryWizardStep.confirmFinishDirection;
        
        return Scaffold(
          appBar: AppBar(
            title: const Text('Map Wizard'),
            actions: [
              IconButton(
                icon: const Icon(Icons.undo),
                onPressed: (state.currentStep != TrajectoryWizardStep.selectStartPoint1 || state.startP1 != null) ? state.undo : null,
                tooltip: 'Stap terug',
              ),
            ],
          ),
          body: Stack(
            children: [
              FlutterMap(
                mapController: _mapController,
                options: MapOptions(
                  initialCenter: _defaultCenter,
                  initialZoom: 14.0,
                ),
                children: [
                  TileLayer(
                    urlTemplate: 'https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}',
                    userAgentPackageName: 'com.bridgetobridge.app',
                  ),
                  StreamBuilder<MapEvent>(
                    stream: _mapController.mapEventStream,
                    builder: (context, snapshot) {
                      List<Polyline> polylines = [];
                      List<Marker> markers = [];
                      
                      // START LINE
                      if (state.startP1 != null) {
                        markers.add(Marker(width: 40, height: 40, point: state.startP1!, child: const Icon(Icons.flag_circle, color: Colors.blueAccent, size: 36)));
                        LatLng endPoint = state.startP2 ?? (state.currentStep == TrajectoryWizardStep.selectStartPoint2 ? _mapController.camera.center : state.startP1!);
                        if (state.startP2 != null || state.currentStep == TrajectoryWizardStep.selectStartPoint2) {
                          polylines.add(Polyline(points: [state.startP1!, endPoint], strokeWidth: 4.0, color: Colors.blueAccent));
                        }
                        
                        bool hasPassedStartPoint2 = state.currentStep.index >= TrajectoryWizardStep.confirmStartDirection.index;
                        if (hasPassedStartPoint2 && state.startP2 != null) {
                           polylines.add(Polyline(
                             points: TrajectoryGeometryUtils.getArrowHead(state.startP1!, state.startP2!, state.startBearing),
                             strokeWidth: 8.0,
                             color: const Color(0xFF27AE60).withValues(alpha: 0.8), // Performance Green
                           ));
                        }
                      }
                      if (state.startP2 != null) {
                        markers.add(Marker(width: 40, height: 40, point: state.startP2!, child: const Icon(Icons.flag_circle, color: Colors.blueAccent, size: 36)));
                      }

                      // FINISH LINE
                      if (state.finishP1 != null) {
                        markers.add(Marker(width: 40, height: 40, point: state.finishP1!, child: const Icon(Icons.flag_circle, color: Colors.redAccent, size: 36)));
                        LatLng endPoint = state.finishP2 ?? (state.currentStep == TrajectoryWizardStep.selectFinishPoint2 ? _mapController.camera.center : state.finishP1!);
                        if (state.finishP2 != null || state.currentStep == TrajectoryWizardStep.selectFinishPoint2) {
                          polylines.add(Polyline(points: [state.finishP1!, endPoint], strokeWidth: 4.0, color: Colors.redAccent));
                        }
                        
                        bool hasPassedFinishPoint2 = state.currentStep.index >= TrajectoryWizardStep.confirmFinishDirection.index;
                        if (hasPassedFinishPoint2 && state.finishP2 != null) {
                           polylines.add(Polyline(
                             points: TrajectoryGeometryUtils.getArrowHead(state.finishP1!, state.finishP2!, state.finishBearing),
                             strokeWidth: 8.0,
                             color: const Color(0xFF27AE60).withValues(alpha: 0.8), // Performance Green
                           ));
                        }
                      }
                      if (state.finishP2 != null) {
                        markers.add(Marker(width: 40, height: 40, point: state.finishP2!, child: const Icon(Icons.flag_circle, color: Colors.redAccent, size: 36)));
                      }

                      return Stack(
                        children: [
                          PolylineLayer(polylines: polylines),
                          MarkerLayer(markers: markers),
                        ],
                      );
                    },
                  ),
                ],
              ),
              
              if (!isDirectionStep)
                 const Align(
                   alignment: Alignment.center,
                   child: Icon(Icons.add, color: Colors.amber, size: 48), // Geel/gouden vizier
                 ),
              
              Positioned(
                top: 16, left: 16, right: 16,
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1D3261),
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 2))],
                  ),
                  child: Text(
                    _getInstructionText(state.currentStep),
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
                
              Positioned(
                bottom: 140, // Increased to avoid overlap with centerFloat FAB
                right: 16,
                child: FloatingActionButton(
                  heroTag: 'locationBtn',
                  onPressed: _centerOnLocation,
                  backgroundColor: Colors.white,
                  foregroundColor: const Color(0xFF1D3261),
                  child: const Icon(Icons.my_location),
                ),
              ),
              
              if (isDirectionStep)
                Positioned(
                  bottom: 140, // Increased to avoid overlap with centerFloat FAB
                  left: 16,
                  child: FloatingActionButton.extended(
                    heroTag: 'flipBtn',
                    onPressed: state.flipBearing,
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                    icon: const Icon(Icons.flip_camera_android),
                    label: const Text('Draai Om'),
                  ),
                ),
            ],
          ),
          floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () {
              state.nextStep(_mapController.camera.center);
              if (state.isComplete) {
                context.pop();
              }
            },
            icon: Icon(isDirectionStep ? Icons.check : Icons.place),
            label: Text(
              isDirectionStep 
                ? 'Bevestig Richting' 
                : (state.currentStep == TrajectoryWizardStep.selectStartPoint1 || state.currentStep == TrajectoryWizardStep.selectFinishPoint1 ? 'Plaats Pyloon 1' : 'Plaats Pyloon 2')
            ),
            backgroundColor: isDirectionStep ? const Color(0xFF1D3261) : const Color(0xFF27AE60),
            foregroundColor: Colors.white,
          ),
        );
      }
    );
  }
}
