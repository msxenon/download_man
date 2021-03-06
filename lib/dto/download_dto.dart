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
  static const unknown = -1;
}

extension DownloadStateExts on DownloadState {
  bool get isRunning =>
      this == DownloadState.downloading || this == DownloadState.queued;
  bool get isDownloading => this == DownloadState.downloading;
  bool get isQueued => this == DownloadState.queued;
  bool get isCompleted => this == DownloadState.completed;
  bool get isFailed => this == DownloadState.failed;

  bool get isResumable =>
      this != DownloadState.queued &&
      this != DownloadState.downloading &&
      this != DownloadState.completed;
}
