import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:fixnum/fixnum.dart';
import '../proto/telemetry.pb.dart';

class DataRecordingService {
  final Future<Directory> Function()? _directoryProvider;

  DataRecordingService({Future<Directory> Function()? directoryProvider})
      : _directoryProvider = directoryProvider;

  String? _currentSessionId;
  int _chunkIndex = 0;
  final List<SensorData> _buffer = [];
  Timer? _flushTimer;

  bool get isRecording => _currentSessionId != null;
  String? get currentSessionId => _currentSessionId;

  void startRecording(String sessionId) {
    if (isRecording) {
      stopRecording();
    }
    _currentSessionId = sessionId;
    _chunkIndex = 0;
    _buffer.clear();
    
    // Flush to disk every 30 seconds
    _flushTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      _flushBuffer();
    });
    
    debugPrint('DataRecordingService: Started recording session $sessionId');
  }

  Future<void> stopRecording() async {
    if (!isRecording) return;
    
    _flushTimer?.cancel();
    _flushTimer = null;
    await _flushBuffer(); // Final flush
    
    debugPrint('DataRecordingService: Stopped recording session $_currentSessionId');
    _currentSessionId = null;
  }

  void addDataPoint({
    required int timestamp,
    required double accelX,
    required double accelY,
    required double accelZ,
    required double gyroX,
    required double gyroY,
    required double gyroZ,
    required double latitude,
    required double longitude,
  }) {
    if (!isRecording) return;
    
    final point = SensorData(
      timestamp: Int64(timestamp),
      accelX: accelX,
      accelY: accelY,
      accelZ: accelZ,
      gyroX: gyroX,
      gyroY: gyroY,
      gyroZ: gyroZ,
      latitude: latitude,
      longitude: longitude,
    );
    
    _buffer.add(point);
    
    // Safety fallback: if buffer gets too large between timer ticks
    if (_buffer.length > 5000) {
      _flushBuffer();
    }
  }

  Future<void> _flushBuffer() async {
    if (_buffer.isEmpty || _currentSessionId == null) return;
    
    final chunk = RaceRecordingChunk(
      sessionId: _currentSessionId!,
      chunkIndex: _chunkIndex,
      dataPoints: _buffer,
    );
    
    // Copy buffer to write asynchronously and clear current buffer
    final List<SensorData> dataToWrite = List.from(_buffer);
    _buffer.clear();
    final currentIndex = _chunkIndex;
    _chunkIndex++;
    
    try {
      final directory = _directoryProvider != null
          ? await _directoryProvider()
          : await getApplicationDocumentsDirectory();
      final fileName = 'race_${_currentSessionId}_chunk_$currentIndex.pb';
      final file = File('${directory.path}/$fileName');
      
      // Serialize to protobuf binary
      final bytes = chunk.writeToBuffer();
      await file.writeAsBytes(bytes);
      
      debugPrint('DataRecordingService: Flushed chunk $currentIndex to disk (${dataToWrite.length} points)');
    } catch (e) {
      debugPrint('DataRecordingService: Error flushing chunk to disk: $e');
      // If saving fails, we lose this chunk to avoid running out of memory. 
    }
  }

  // Helper method to list all recorded sessions
  Future<List<String>> listRecordedSessions() async {
    try {
      final directory = _directoryProvider != null
          ? await _directoryProvider()
          : await getApplicationDocumentsDirectory();
      final files = directory.listSync().whereType<File>();
      final Set<String> sessionIds = {};
      
      for (final file in files) {
        final name = file.uri.pathSegments.last;
        if (name.startsWith('race_') && name.endsWith('.pb')) {
          // Format: race_{sessionId}_chunk_{index}.pb
          final parts = name.split('_chunk_');
          if (parts.isNotEmpty) {
            final sessionId = parts[0].substring(5); // Remove 'race_'
            sessionIds.add(sessionId);
          }
        }
      }
      return sessionIds.toList();
    } catch (e) {
      debugPrint('Error listing sessions: $e');
      return [];
    }
  }
}
