import 'dart:async';

import 'package:async/async.dart';
import 'package:dio/dio.dart' as _dio;
import 'package:flutter_downloadman/download_range.dart';
import 'package:get/get.dart';
import 'package:logger/logger.dart';
import 'package:rxdart/rxdart.dart';

import 'dto/download_dto.dart';

class DownloadMan extends GetxService {
  DownloadMan({this.dio, this.isLogEnabled = true}) {
    if (isLogEnabled) {
      _logger = Logger();
    }
    _streamListener
        .throttleTime(const Duration(milliseconds: 500),
            leading: false, trailing: true)
        .listen((rawData) async {
      streamController.add(rawData);
    });
  }
  final _dio.Dio dio;
  final bool isLogEnabled;
  final _streamListener = BehaviorSubject<DownloadDTO>();
  final streamController = StreamController<DownloadDTO>();
  final Map<String, Future Function()> waitingList = {};
  final Map<String, _dio.CancelToken> _cancelTokens = {};
  CancelableOperation _currentOperation;
  String _currentDownloadId;

  Logger _logger;
  void addToDownload(String downloadId, String url, String savePath) async {
    _streamListener.add(DownloadDTO(
      downloadId: downloadId,
      downloadState: DownloadState.queued,
      total: DownloadDTO.unknown,
      prettyProgress: DownloadDTO.unknown,
      chunksCount: DownloadDTO.unknown,
      count: DownloadDTO.unknown,
    ));
    waitingList.putIfAbsent(
        downloadId, () => () => downloadFuture(downloadId, url, savePath));
    _checkQueue();
    return;
  }

  Future<_dio.Response<dynamic>> downloadFuture(
      String downloadId, String url, String savePath) {
    final _cancelToken =
        _cancelTokens.putIfAbsent(downloadId, () => _dio.CancelToken());
    return RangeDownload(downloadId).downloadWithChunks(url, savePath,
        cancelToken: _cancelToken, dio: dio, onReceiveProgress:
            (downloadId, count, total, progress, chinksCount, downloadState) {
      _streamListener.add(DownloadDTO(
          downloadId: downloadId,
          downloadState: downloadState,
          total: total,
          prettyProgress: progress,
          chunksCount: chinksCount,
          count: count));
    });
  }

  @override
  void onClose() {
    _closeStream();
    streamController.close();
    super.onClose();
  }

  void _closeStream() async {
    await _streamListener?.drain();
    await _streamListener?.close();
  }

  void pauseAll() {
    _currentOperation?.cancel();
    // ignore: avoid_function_literals_in_foreach_calls
    waitingList.keys.forEach((element) {
      _streamListener.add(DownloadDTO(
        downloadId: element,
        downloadState: DownloadState.paused,
        total: DownloadDTO.unknown,
        prettyProgress: DownloadDTO.unknown,
        chunksCount: DownloadDTO.unknown,
        count: DownloadDTO.unknown,
      ));
    });
    _cancelTokens.clear();
  }

  bool pause(String downloadId) {
    bool result = false;
    if (waitingList.containsKey(downloadId)) {
      waitingList.remove(downloadId);
      result = true;
    } else if (_currentDownloadId == downloadId) {
      _currentOperation?.cancel();
      result = true;
    }
    return result;
  }

  void _checkQueue() {
    if (_currentOperation == null && waitingList.isNotEmpty) {
      final downloadId = waitingList.keys.first;
      final value = waitingList[downloadId];
      _logger?.d('download started id = $downloadId');
      waitingList.remove(downloadId);
      _currentDownloadId = downloadId;
      _currentOperation =
          CancelableOperation.fromFuture(value.call(), onCancel: () async {
        _logger?.e('download cancelled #1 id = $downloadId');

        await _refresh(downloadId);
        _streamListener.add(DownloadDTO(
          downloadId: downloadId,
          downloadState: DownloadState.paused,
          total: DownloadDTO.unknown,
          prettyProgress: DownloadDTO.unknown,
          chunksCount: DownloadDTO.unknown,
          count: DownloadDTO.unknown,
        ));
        _checkQueue();
      });
      _currentOperation.value.then((value) async {
        _logger?.d('download value id = $downloadId  $value == '
            'isCompleted ${_currentOperation.isCompleted} '
            'isCancelled ${_currentOperation.isCanceled}');
        if (_currentOperation.isCompleted) {
          await _refresh(downloadId);
          _checkQueue();
        }
      }, onError: (error, stack) async {
        _logger?.e('download cancelled id = $downloadId', error, stack);
        await _refresh(downloadId);

        _streamListener.add(DownloadDTO(
          downloadId: downloadId,
          downloadState: DownloadState.failed,
          total: DownloadDTO.unknown,
          prettyProgress: DownloadDTO.unknown,
          chunksCount: DownloadDTO.unknown,
          count: DownloadDTO.unknown,
        ));
      });
    }
  }

  Future<void> _refresh(String downloadId) async {
    _currentDownloadId = null;
    _currentOperation = null;
    final cancel = _cancelTokens[downloadId];
    if (cancel?.isCancelled == false) {
      _logger?.d('download cancelled id = $downloadId');
      cancel.cancel();
    }
    if (cancel != null) {
      _cancelTokens.remove(downloadId);
    }
    await Future.delayed(const Duration(milliseconds: 500));
    return;
  }
}
