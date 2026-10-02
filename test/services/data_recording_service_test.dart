import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:bridge_to_bridge_app/services/data_recording_service.dart';

void main() {
  group('DataRecordingService', () {
    late Directory tempDir;
    late DataRecordingService service;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('data_recording_test');
      service = DataRecordingService(directoryProvider: () async => tempDir);
    });

    tearDown(() async {
      if (tempDir.existsSync()) {
        tempDir.deleteSync(recursive: true);
      }
    });

    test('starts and stops recording correctly and persists chunks to disk', () async {
      expect(service.isRecording, isFalse);

      service.startRecording('test_session_123');
      expect(service.isRecording, isTrue);
      expect(service.currentSessionId, equals('test_session_123'));

      // Add sample data points
      service.addDataPoint(
        timestamp: 1000,
        accelX: 0.1,
        accelY: 0.2,
        accelZ: 9.8,
        gyroX: 0.01,
        gyroY: 0.02,
        gyroZ: 0.03,
        latitude: 52.25,
        longitude: 6.16,
      );
      service.addDataPoint(
        timestamp: 1010,
        accelX: 0.15,
        accelY: 0.25,
        accelZ: 9.85,
        gyroX: 0.01,
        gyroY: 0.02,
        gyroZ: 0.03,
        latitude: 52.2501,
        longitude: 6.1601,
      );

      await service.stopRecording();
      expect(service.isRecording, isFalse);
      expect(service.currentSessionId, isNull);

      // Verify chunk file is created on disk
      final files = tempDir.listSync().whereType<File>().toList();
      expect(files.length, equals(1));
      expect(files.first.path, contains('race_test_session_123_chunk_0.pb'));

      // Verify sessions listing
      final sessions = await service.listRecordedSessions();
      expect(sessions, contains('test_session_123'));
    });
  });
}
