// This is a generated file - do not edit.
//
// Generated from lib/proto/telemetry.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_relative_imports

import 'dart:core' as $core;

import 'package:fixnum/fixnum.dart' as $fixnum;
import 'package:protobuf/protobuf.dart' as $pb;

export 'package:protobuf/protobuf.dart' show GeneratedMessageGenericExtensions;

class SensorData extends $pb.GeneratedMessage {
  factory SensorData({
    $fixnum.Int64? timestamp,
    $core.double? accelX,
    $core.double? accelY,
    $core.double? accelZ,
    $core.double? gyroX,
    $core.double? gyroY,
    $core.double? gyroZ,
    $core.double? latitude,
    $core.double? longitude,
  }) {
    final result = create();
    if (timestamp != null) result.timestamp = timestamp;
    if (accelX != null) result.accelX = accelX;
    if (accelY != null) result.accelY = accelY;
    if (accelZ != null) result.accelZ = accelZ;
    if (gyroX != null) result.gyroX = gyroX;
    if (gyroY != null) result.gyroY = gyroY;
    if (gyroZ != null) result.gyroZ = gyroZ;
    if (latitude != null) result.latitude = latitude;
    if (longitude != null) result.longitude = longitude;
    return result;
  }

  SensorData._();

  factory SensorData.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory SensorData.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'SensorData',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'telemetry'),
      createEmptyInstance: create)
    ..aInt64(1, _omitFieldNames ? '' : 'timestamp')
    ..aD(2, _omitFieldNames ? '' : 'accelX', fieldType: $pb.PbFieldType.OF)
    ..aD(3, _omitFieldNames ? '' : 'accelY', fieldType: $pb.PbFieldType.OF)
    ..aD(4, _omitFieldNames ? '' : 'accelZ', fieldType: $pb.PbFieldType.OF)
    ..aD(5, _omitFieldNames ? '' : 'gyroX', fieldType: $pb.PbFieldType.OF)
    ..aD(6, _omitFieldNames ? '' : 'gyroY', fieldType: $pb.PbFieldType.OF)
    ..aD(7, _omitFieldNames ? '' : 'gyroZ', fieldType: $pb.PbFieldType.OF)
    ..aD(8, _omitFieldNames ? '' : 'latitude')
    ..aD(9, _omitFieldNames ? '' : 'longitude')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SensorData clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SensorData copyWith(void Function(SensorData) updates) =>
      super.copyWith((message) => updates(message as SensorData)) as SensorData;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static SensorData create() => SensorData._();
  @$core.override
  SensorData createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static SensorData getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<SensorData>(create);
  static SensorData? _defaultInstance;

  @$pb.TagNumber(1)
  $fixnum.Int64 get timestamp => $_getI64(0);
  @$pb.TagNumber(1)
  set timestamp($fixnum.Int64 value) => $_setInt64(0, value);
  @$pb.TagNumber(1)
  $core.bool hasTimestamp() => $_has(0);
  @$pb.TagNumber(1)
  void clearTimestamp() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.double get accelX => $_getN(1);
  @$pb.TagNumber(2)
  set accelX($core.double value) => $_setFloat(1, value);
  @$pb.TagNumber(2)
  $core.bool hasAccelX() => $_has(1);
  @$pb.TagNumber(2)
  void clearAccelX() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.double get accelY => $_getN(2);
  @$pb.TagNumber(3)
  set accelY($core.double value) => $_setFloat(2, value);
  @$pb.TagNumber(3)
  $core.bool hasAccelY() => $_has(2);
  @$pb.TagNumber(3)
  void clearAccelY() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.double get accelZ => $_getN(3);
  @$pb.TagNumber(4)
  set accelZ($core.double value) => $_setFloat(3, value);
  @$pb.TagNumber(4)
  $core.bool hasAccelZ() => $_has(3);
  @$pb.TagNumber(4)
  void clearAccelZ() => $_clearField(4);

  @$pb.TagNumber(5)
  $core.double get gyroX => $_getN(4);
  @$pb.TagNumber(5)
  set gyroX($core.double value) => $_setFloat(4, value);
  @$pb.TagNumber(5)
  $core.bool hasGyroX() => $_has(4);
  @$pb.TagNumber(5)
  void clearGyroX() => $_clearField(5);

  @$pb.TagNumber(6)
  $core.double get gyroY => $_getN(5);
  @$pb.TagNumber(6)
  set gyroY($core.double value) => $_setFloat(5, value);
  @$pb.TagNumber(6)
  $core.bool hasGyroY() => $_has(5);
  @$pb.TagNumber(6)
  void clearGyroY() => $_clearField(6);

  @$pb.TagNumber(7)
  $core.double get gyroZ => $_getN(6);
  @$pb.TagNumber(7)
  set gyroZ($core.double value) => $_setFloat(6, value);
  @$pb.TagNumber(7)
  $core.bool hasGyroZ() => $_has(6);
  @$pb.TagNumber(7)
  void clearGyroZ() => $_clearField(7);

  @$pb.TagNumber(8)
  $core.double get latitude => $_getN(7);
  @$pb.TagNumber(8)
  set latitude($core.double value) => $_setDouble(7, value);
  @$pb.TagNumber(8)
  $core.bool hasLatitude() => $_has(7);
  @$pb.TagNumber(8)
  void clearLatitude() => $_clearField(8);

  @$pb.TagNumber(9)
  $core.double get longitude => $_getN(8);
  @$pb.TagNumber(9)
  set longitude($core.double value) => $_setDouble(8, value);
  @$pb.TagNumber(9)
  $core.bool hasLongitude() => $_has(8);
  @$pb.TagNumber(9)
  void clearLongitude() => $_clearField(9);
}

class RaceRecordingChunk extends $pb.GeneratedMessage {
  factory RaceRecordingChunk({
    $core.String? sessionId,
    $core.int? chunkIndex,
    $core.Iterable<SensorData>? dataPoints,
  }) {
    final result = create();
    if (sessionId != null) result.sessionId = sessionId;
    if (chunkIndex != null) result.chunkIndex = chunkIndex;
    if (dataPoints != null) result.dataPoints.addAll(dataPoints);
    return result;
  }

  RaceRecordingChunk._();

  factory RaceRecordingChunk.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory RaceRecordingChunk.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'RaceRecordingChunk',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'telemetry'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'sessionId')
    ..aI(2, _omitFieldNames ? '' : 'chunkIndex')
    ..pPM<SensorData>(3, _omitFieldNames ? '' : 'dataPoints',
        subBuilder: SensorData.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  RaceRecordingChunk clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  RaceRecordingChunk copyWith(void Function(RaceRecordingChunk) updates) =>
      super.copyWith((message) => updates(message as RaceRecordingChunk))
          as RaceRecordingChunk;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static RaceRecordingChunk create() => RaceRecordingChunk._();
  @$core.override
  RaceRecordingChunk createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static RaceRecordingChunk getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<RaceRecordingChunk>(create);
  static RaceRecordingChunk? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get sessionId => $_getSZ(0);
  @$pb.TagNumber(1)
  set sessionId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasSessionId() => $_has(0);
  @$pb.TagNumber(1)
  void clearSessionId() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.int get chunkIndex => $_getIZ(1);
  @$pb.TagNumber(2)
  set chunkIndex($core.int value) => $_setSignedInt32(1, value);
  @$pb.TagNumber(2)
  $core.bool hasChunkIndex() => $_has(1);
  @$pb.TagNumber(2)
  void clearChunkIndex() => $_clearField(2);

  @$pb.TagNumber(3)
  $pb.PbList<SensorData> get dataPoints => $_getList(2);
}

const $core.bool _omitFieldNames =
    $core.bool.fromEnvironment('protobuf.omit_field_names');
const $core.bool _omitMessageNames =
    $core.bool.fromEnvironment('protobuf.omit_message_names');
