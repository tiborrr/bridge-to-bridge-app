# Bridge to Bridge App

A Flutter application for tracking and analyzing rowing times and telemetry for sloep (gig) rowing along the river IJssel in Deventer (Wilhelminabrug to Spoorfietsbrug).

---

## Features

- **Real-Time Race Tracking**: Automatic geofenced detection of race start and finish line crossings.
- **Role-Based Views**:
  - **Stuur / Coach**: Full dashboard with GPS, timing, distance to start/finish, pace, and live team synchronization.
  - **Roeier**: High-contrast, large-metric landscape view focused on stroke rate (SPM) and paddle metrics.
- **Bi-directional Telemetry**: Live sensor telemetry (accelerometer, gyroscope, orientation) processed via `AnalyzeTelemetryUseCase` with periodic batch persistence.
- **GPX Simulation & Replay**:
  - Replay real-life GPS tracks (`assets/gpx/bridge_to_bridge.gpx`) without physical water testing.
  - Interactive UI simulation controls (Play/Pause, Step, Scrub, 1x–10x playback speed).
  - Test harness (`GpxReplayLocationClient`) for deterministic unit and integration tests.

---

## Getting Started

### Prerequisites

- Flutter SDK `^3.7.0` (or compatible `^3.11.3` Dart SDK)
- Android Studio / Xcode for device emulation

### Installation

```bash
git clone https://github.com/tiborrr/bridge-to-bridge-app.git
cd bridge-to-bridge-app

# Install dependencies
flutter pub get
```

### Environment Configuration

Create or verify `.env` in the root directory:
```env
BACKEND_BASE_URL=https://api.yourdomain.com
WEBSOCKET_URL=wss://api.yourdomain.com/ws
```

---

## Testing & Quality

All tests can be executed without real hardware or platform channels thanks to decoupled interfaces (`LocationClient`, sensor streams injection):

```bash
# Run static analysis
flutter analyze

# Run all unit, widget, and service tests
flutter test
```

### Test Structure

- `test/utils/geofence_calculator_test.dart`: Geofence line-crossing geometry and bearing calculations.
- `test/usecases/analyze_telemetry_usecase_test.dart`: Stroke rate (SPM), catch angles, and pitch/roll calibration using real recorded IMU CSV data.
- `test/utils/gpx_replay_test.dart`: GPX XML parsing, geodesic mathematics, and simulated race lifecycle (`waiting` -> `racing` -> `finished`).
- `test/widgets/gpx_simulation_controls_test.dart`: UI playback, stepping, and scrubbing controls.
- `test/services/`: Services tests for `LocationService`, `ApiService`, and `DataRecordingService`.
- `test/providers/`: Provider tests for `LiveRaceProvider`.

---

## Architecture Overview

```mermaid
graph TD
    UI[DashboardContainer / LiveRaceScreen / RowerLiveRaceScreen] --> LiveRaceProvider
    LiveRaceProvider --> LocationService
    LiveRaceProvider --> AnalyzeTelemetryUseCase
    LiveRaceProvider --> DataRecordingService
    LiveRaceProvider --> TelemetryRepository

    LocationService --> LocationClient
    LocationClient -.-> GeolocatorLocationClient[GeolocatorLocationClient (Native GPS)]
    LocationClient -.-> GpxReplayLocationClient[GpxReplayLocationClient (GPX Simulator)]
```
