import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

enum TrajectoryWizardStep {
  selectStartPoint1,
  selectStartPoint2,
  confirmStartDirection,
  selectFinishPoint1,
  selectFinishPoint2,
  confirmFinishDirection,
  completed
}

class FullTrajectoryResult {
  final LatLng startP1;
  final LatLng startP2;
  final double startBearing;
  final LatLng finishP1;
  final LatLng finishP2;
  final double finishBearing;

  FullTrajectoryResult({
    required this.startP1,
    required this.startP2,
    required this.startBearing,
    required this.finishP1,
    required this.finishP2,
    required this.finishBearing,
  });
}

class TrajectoryWizardState extends ChangeNotifier {
  final Distance _distance = const Distance();

  // Form State
  String name = '';
  String startBridgeName = '';
  String finishBridgeName = '';

  // Map Picker State
  TrajectoryWizardStep currentStep = TrajectoryWizardStep.selectStartPoint1;
  LatLng? startP1;
  LatLng? startP2;
  double startBearing = 0.0;
  LatLng? finishP1;
  LatLng? finishP2;
  double finishBearing = 0.0;

  bool get isComplete => currentStep == TrajectoryWizardStep.completed;

  void undo() {
    switch (currentStep) {
      case TrajectoryWizardStep.confirmFinishDirection:
        currentStep = TrajectoryWizardStep.selectFinishPoint2;
        break;
      case TrajectoryWizardStep.selectFinishPoint2:
        finishP2 = null;
        currentStep = TrajectoryWizardStep.selectFinishPoint1;
        break;
      case TrajectoryWizardStep.selectFinishPoint1:
        finishP1 = null;
        currentStep = TrajectoryWizardStep.confirmStartDirection;
        break;
      case TrajectoryWizardStep.confirmStartDirection:
        currentStep = TrajectoryWizardStep.selectStartPoint2;
        break;
      case TrajectoryWizardStep.selectStartPoint2:
        startP2 = null;
        currentStep = TrajectoryWizardStep.selectStartPoint1;
        break;
      case TrajectoryWizardStep.selectStartPoint1:
        startP1 = null;
        break;
      case TrajectoryWizardStep.completed:
        currentStep = TrajectoryWizardStep.confirmFinishDirection;
        break;
    }
    notifyListeners();
  }

  void nextStep(LatLng currentCenter) {
    switch (currentStep) {
      case TrajectoryWizardStep.selectStartPoint1:
        startP1 = currentCenter;
        currentStep = TrajectoryWizardStep.selectStartPoint2;
        break;
      case TrajectoryWizardStep.selectStartPoint2:
        startP2 = currentCenter;
        double lineBearing = _distance.bearing(startP1!, startP2!);
        if (lineBearing.isNaN) lineBearing = 0.0;
        startBearing = (lineBearing + 90) % 360;
        currentStep = TrajectoryWizardStep.confirmStartDirection;
        break;
      case TrajectoryWizardStep.confirmStartDirection:
        currentStep = TrajectoryWizardStep.selectFinishPoint1;
        break;
      case TrajectoryWizardStep.selectFinishPoint1:
        finishP1 = currentCenter;
        currentStep = TrajectoryWizardStep.selectFinishPoint2;
        break;
      case TrajectoryWizardStep.selectFinishPoint2:
        finishP2 = currentCenter;
        double lineBearing = _distance.bearing(finishP1!, finishP2!);
        if (lineBearing.isNaN) lineBearing = 0.0;
        finishBearing = (lineBearing + 90) % 360;
        currentStep = TrajectoryWizardStep.confirmFinishDirection;
        break;
      case TrajectoryWizardStep.confirmFinishDirection:
        currentStep = TrajectoryWizardStep.completed;
        break;
      case TrajectoryWizardStep.completed:
        break;
    }
    notifyListeners();
  }

  void flipBearing() {
    if (currentStep == TrajectoryWizardStep.confirmStartDirection) {
      startBearing = (startBearing + 180) % 360;
    } else if (currentStep == TrajectoryWizardStep.confirmFinishDirection) {
      finishBearing = (finishBearing + 180) % 360;
    }
    notifyListeners();
  }
  
  void resetMap() {
    currentStep = TrajectoryWizardStep.selectStartPoint1;
    startP1 = null;
    startP2 = null;
    startBearing = 0.0;
    finishP1 = null;
    finishP2 = null;
    finishBearing = 0.0;
    notifyListeners();
  }
  
  void setCompleteForEditing() {
    currentStep = TrajectoryWizardStep.completed;
    notifyListeners();
  }
  
  void loadResult(FullTrajectoryResult result) {
      startP1 = result.startP1;
      startP2 = result.startP2;
      startBearing = result.startBearing;
      finishP1 = result.finishP1;
      finishP2 = result.finishP2;
      finishBearing = result.finishBearing;
      currentStep = TrajectoryWizardStep.completed;
      notifyListeners();
  }
  
  FullTrajectoryResult? get result {
      if (!isComplete) return null;
      return FullTrajectoryResult(
          startP1: startP1!,
          startP2: startP2!,
          startBearing: startBearing,
          finishP1: finishP1!,
          finishP2: finishP2!,
          finishBearing: finishBearing,
      );
  }
}
