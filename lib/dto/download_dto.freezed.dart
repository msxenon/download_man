// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies

part of 'download_dto.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

/// @nodoc
class _$DownloadDTOTearOff {
  const _$DownloadDTOTearOff();

// ignore: unused_element
  _DownloadDTO call(
      {@required String downloadId,
      @required int prettyProgress,
      @required int total,
      @required int count,
      @required int chunksCount,
      @required DownloadState downloadState,
      Map<String, dynamic> customObject}) {
    return _DownloadDTO(
      downloadId: downloadId,
      prettyProgress: prettyProgress,
      total: total,
      count: count,
      chunksCount: chunksCount,
      downloadState: downloadState,
      customObject: customObject,
    );
  }
}

/// @nodoc
// ignore: unused_element
const $DownloadDTO = _$DownloadDTOTearOff();

/// @nodoc
mixin _$DownloadDTO {
  String get downloadId;
  int get prettyProgress;
  int get total;
  int get count;
  int get chunksCount;
  DownloadState get downloadState;
  Map<String, dynamic> get customObject;

  @JsonKey(ignore: true)
  $DownloadDTOCopyWith<DownloadDTO> get copyWith;
}

/// @nodoc
abstract class $DownloadDTOCopyWith<$Res> {
  factory $DownloadDTOCopyWith(
          DownloadDTO value, $Res Function(DownloadDTO) then) =
      _$DownloadDTOCopyWithImpl<$Res>;
  $Res call(
      {String downloadId,
      int prettyProgress,
      int total,
      int count,
      int chunksCount,
      DownloadState downloadState,
      Map<String, dynamic> customObject});
}

/// @nodoc
class _$DownloadDTOCopyWithImpl<$Res> implements $DownloadDTOCopyWith<$Res> {
  _$DownloadDTOCopyWithImpl(this._value, this._then);

  final DownloadDTO _value;
  // ignore: unused_field
  final $Res Function(DownloadDTO) _then;

  @override
  $Res call({
    Object downloadId = freezed,
    Object prettyProgress = freezed,
    Object total = freezed,
    Object count = freezed,
    Object chunksCount = freezed,
    Object downloadState = freezed,
    Object customObject = freezed,
  }) {
    return _then(_value.copyWith(
      downloadId:
          downloadId == freezed ? _value.downloadId : downloadId as String,
      prettyProgress: prettyProgress == freezed
          ? _value.prettyProgress
          : prettyProgress as int,
      total: total == freezed ? _value.total : total as int,
      count: count == freezed ? _value.count : count as int,
      chunksCount:
          chunksCount == freezed ? _value.chunksCount : chunksCount as int,
      downloadState: downloadState == freezed
          ? _value.downloadState
          : downloadState as DownloadState,
      customObject: customObject == freezed
          ? _value.customObject
          : customObject as Map<String, dynamic>,
    ));
  }
}

/// @nodoc
abstract class _$DownloadDTOCopyWith<$Res>
    implements $DownloadDTOCopyWith<$Res> {
  factory _$DownloadDTOCopyWith(
          _DownloadDTO value, $Res Function(_DownloadDTO) then) =
      __$DownloadDTOCopyWithImpl<$Res>;
  @override
  $Res call(
      {String downloadId,
      int prettyProgress,
      int total,
      int count,
      int chunksCount,
      DownloadState downloadState,
      Map<String, dynamic> customObject});
}

/// @nodoc
class __$DownloadDTOCopyWithImpl<$Res> extends _$DownloadDTOCopyWithImpl<$Res>
    implements _$DownloadDTOCopyWith<$Res> {
  __$DownloadDTOCopyWithImpl(
      _DownloadDTO _value, $Res Function(_DownloadDTO) _then)
      : super(_value, (v) => _then(v as _DownloadDTO));

  @override
  _DownloadDTO get _value => super._value as _DownloadDTO;

  @override
  $Res call({
    Object downloadId = freezed,
    Object prettyProgress = freezed,
    Object total = freezed,
    Object count = freezed,
    Object chunksCount = freezed,
    Object downloadState = freezed,
    Object customObject = freezed,
  }) {
    return _then(_DownloadDTO(
      downloadId:
          downloadId == freezed ? _value.downloadId : downloadId as String,
      prettyProgress: prettyProgress == freezed
          ? _value.prettyProgress
          : prettyProgress as int,
      total: total == freezed ? _value.total : total as int,
      count: count == freezed ? _value.count : count as int,
      chunksCount:
          chunksCount == freezed ? _value.chunksCount : chunksCount as int,
      downloadState: downloadState == freezed
          ? _value.downloadState
          : downloadState as DownloadState,
      customObject: customObject == freezed
          ? _value.customObject
          : customObject as Map<String, dynamic>,
    ));
  }
}

/// @nodoc
class _$_DownloadDTO extends _DownloadDTO {
  const _$_DownloadDTO(
      {@required this.downloadId,
      @required this.prettyProgress,
      @required this.total,
      @required this.count,
      @required this.chunksCount,
      @required this.downloadState,
      this.customObject})
      : assert(downloadId != null),
        assert(prettyProgress != null),
        assert(total != null),
        assert(count != null),
        assert(chunksCount != null),
        assert(downloadState != null),
        super._();

  @override
  final String downloadId;
  @override
  final int prettyProgress;
  @override
  final int total;
  @override
  final int count;
  @override
  final int chunksCount;
  @override
  final DownloadState downloadState;
  @override
  final Map<String, dynamic> customObject;

  @override
  String toString() {
    return 'DownloadDTO(downloadId: $downloadId, prettyProgress: $prettyProgress, total: $total, count: $count, chunksCount: $chunksCount, downloadState: $downloadState, customObject: $customObject)';
  }

  @override
  bool operator ==(dynamic other) {
    return identical(this, other) ||
        (other is _DownloadDTO &&
            (identical(other.downloadId, downloadId) ||
                const DeepCollectionEquality()
                    .equals(other.downloadId, downloadId)) &&
            (identical(other.prettyProgress, prettyProgress) ||
                const DeepCollectionEquality()
                    .equals(other.prettyProgress, prettyProgress)) &&
            (identical(other.total, total) ||
                const DeepCollectionEquality().equals(other.total, total)) &&
            (identical(other.count, count) ||
                const DeepCollectionEquality().equals(other.count, count)) &&
            (identical(other.chunksCount, chunksCount) ||
                const DeepCollectionEquality()
                    .equals(other.chunksCount, chunksCount)) &&
            (identical(other.downloadState, downloadState) ||
                const DeepCollectionEquality()
                    .equals(other.downloadState, downloadState)) &&
            (identical(other.customObject, customObject) ||
                const DeepCollectionEquality()
                    .equals(other.customObject, customObject)));
  }

  @override
  int get hashCode =>
      runtimeType.hashCode ^
      const DeepCollectionEquality().hash(downloadId) ^
      const DeepCollectionEquality().hash(prettyProgress) ^
      const DeepCollectionEquality().hash(total) ^
      const DeepCollectionEquality().hash(count) ^
      const DeepCollectionEquality().hash(chunksCount) ^
      const DeepCollectionEquality().hash(downloadState) ^
      const DeepCollectionEquality().hash(customObject);

  @JsonKey(ignore: true)
  @override
  _$DownloadDTOCopyWith<_DownloadDTO> get copyWith =>
      __$DownloadDTOCopyWithImpl<_DownloadDTO>(this, _$identity);
}

abstract class _DownloadDTO extends DownloadDTO {
  const _DownloadDTO._() : super._();
  const factory _DownloadDTO(
      {@required String downloadId,
      @required int prettyProgress,
      @required int total,
      @required int count,
      @required int chunksCount,
      @required DownloadState downloadState,
      Map<String, dynamic> customObject}) = _$_DownloadDTO;

  @override
  String get downloadId;
  @override
  int get prettyProgress;
  @override
  int get total;
  @override
  int get count;
  @override
  int get chunksCount;
  @override
  DownloadState get downloadState;
  @override
  Map<String, dynamic> get customObject;
  @override
  @JsonKey(ignore: true)
  _$DownloadDTOCopyWith<_DownloadDTO> get copyWith;
}
