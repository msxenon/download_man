import 'package:freezed_annotation/freezed_annotation.dart';

part 'download_dto.freezed.dart';

enum DownloadState { unknown, queued, downloading, failed, completed, paused }

@freezed
abstract class DownloadDTO with _$DownloadDTO {
  const DownloadDTO._();

  const factory DownloadDTO(
      {@required String downloadId,
      @required int prettyProgress,
      @required int total,
      @required int count,
      @required int chunksCount,
      @required DownloadState downloadState,
      Map<String, dynamic> customObject}) = _DownloadDTO;
}

extension DownloadStateExts on DownloadState {
  bool get isRunning =>
      this == DownloadState.downloading || this == DownloadState.queued;

  bool get isCompleted => this == DownloadState.completed;

  bool get isResumable =>
      this != DownloadState.queued &&
      this != DownloadState.downloading &&
      this != DownloadState.completed;
}
