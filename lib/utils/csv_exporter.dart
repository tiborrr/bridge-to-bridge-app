import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../proto/telemetry.pb.dart';

class CsvExporter {
  static Future<void> exportSessionToCsv(String sessionId) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final files = directory.listSync().whereType<File>().toList();
      
      // Find all chunk files for this session
      final chunkFiles = files.where((f) {
        final name = f.uri.pathSegments.last;
        return name.startsWith('race_${sessionId}_chunk_') && name.endsWith('.pb');
      }).toList();
      
      if (chunkFiles.isEmpty) {
        debugPrint('No data found for session $sessionId');
        return;
      }
      
      // Sort by chunk index to ensure chronological order
      chunkFiles.sort((a, b) {
        final aIndex = int.parse(a.uri.pathSegments.last.split('_chunk_')[1].split('.pb')[0]);
        final bIndex = int.parse(b.uri.pathSegments.last.split('_chunk_')[1].split('.pb')[0]);
        return aIndex.compareTo(bIndex);
      });
      
      final sb = StringBuffer();
      // Header row
      sb.writeln('timestamp,accel_x,accel_y,accel_z,gyro_x,gyro_y,gyro_z,latitude,longitude');
      
      for (final file in chunkFiles) {
        final bytes = await file.readAsBytes();
        final chunk = RaceRecordingChunk.fromBuffer(bytes);
        
        for (final point in chunk.dataPoints) {
          sb.writeln('${point.timestamp.toInt()},${point.accelX},${point.accelY},${point.accelZ},${point.gyroX},${point.gyroY},${point.gyroZ},${point.latitude},${point.longitude}');
        }
      }
      
      final csvData = sb.toString();
      
      // Write CSV to a temporary file
      final tempDir = await getTemporaryDirectory();
      final tempFile = File('${tempDir.path}/race_data_$sessionId.csv');
      await tempFile.writeAsString(csvData);
      
      // Share the file (ignore deprecation warning for now)
      // ignore: deprecated_member_use
      await Share.shareXFiles(
        [XFile(tempFile.path)],
        text: 'Sensordata voor race sessie $sessionId',
      );
      
    } catch (e) {
      debugPrint('Failed to export CSV: $e');
    }
  }
}
