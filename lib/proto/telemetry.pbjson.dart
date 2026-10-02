// This is a generated file - do not edit.
//
// Generated from lib/proto/telemetry.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_relative_imports
// ignore_for_file: unused_import

import 'dart:convert' as $convert;
import 'dart:core' as $core;
import 'dart:typed_data' as $typed_data;

@$core.Deprecated('Use sensorDataDescriptor instead')
const SensorData$json = {
  '1': 'SensorData',
  '2': [
    {'1': 'timestamp', '3': 1, '4': 1, '5': 3, '10': 'timestamp'},
    {'1': 'accel_x', '3': 2, '4': 1, '5': 2, '10': 'accelX'},
    {'1': 'accel_y', '3': 3, '4': 1, '5': 2, '10': 'accelY'},
    {'1': 'accel_z', '3': 4, '4': 1, '5': 2, '10': 'accelZ'},
    {'1': 'gyro_x', '3': 5, '4': 1, '5': 2, '10': 'gyroX'},
    {'1': 'gyro_y', '3': 6, '4': 1, '5': 2, '10': 'gyroY'},
    {'1': 'gyro_z', '3': 7, '4': 1, '5': 2, '10': 'gyroZ'},
    {'1': 'latitude', '3': 8, '4': 1, '5': 1, '10': 'latitude'},
    {'1': 'longitude', '3': 9, '4': 1, '5': 1, '10': 'longitude'},
  ],
};

/// Descriptor for `SensorData`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List sensorDataDescriptor = $convert.base64Decode(
    'CgpTZW5zb3JEYXRhEhwKCXRpbWVzdGFtcBgBIAEoA1IJdGltZXN0YW1wEhcKB2FjY2VsX3gYAi'
    'ABKAJSBmFjY2VsWBIXCgdhY2NlbF95GAMgASgCUgZhY2NlbFkSFwoHYWNjZWxfehgEIAEoAlIG'
    'YWNjZWxaEhUKBmd5cm9feBgFIAEoAlIFZ3lyb1gSFQoGZ3lyb195GAYgASgCUgVneXJvWRIVCg'
    'ZneXJvX3oYByABKAJSBWd5cm9aEhoKCGxhdGl0dWRlGAggASgBUghsYXRpdHVkZRIcCglsb25n'
    'aXR1ZGUYCSABKAFSCWxvbmdpdHVkZQ==');

@$core.Deprecated('Use raceRecordingChunkDescriptor instead')
const RaceRecordingChunk$json = {
  '1': 'RaceRecordingChunk',
  '2': [
    {'1': 'session_id', '3': 1, '4': 1, '5': 9, '10': 'sessionId'},
    {'1': 'chunk_index', '3': 2, '4': 1, '5': 5, '10': 'chunkIndex'},
    {
      '1': 'data_points',
      '3': 3,
      '4': 3,
      '5': 11,
      '6': '.telemetry.SensorData',
      '10': 'dataPoints'
    },
  ],
};

/// Descriptor for `RaceRecordingChunk`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List raceRecordingChunkDescriptor = $convert.base64Decode(
    'ChJSYWNlUmVjb3JkaW5nQ2h1bmsSHQoKc2Vzc2lvbl9pZBgBIAEoCVIJc2Vzc2lvbklkEh8KC2'
    'NodW5rX2luZGV4GAIgASgFUgpjaHVua0luZGV4EjYKC2RhdGFfcG9pbnRzGAMgAygLMhUudGVs'
    'ZW1ldHJ5LlNlbnNvckRhdGFSCmRhdGFQb2ludHM=');
