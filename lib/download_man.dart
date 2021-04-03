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
    _streamListener.distinct((d1, d2) => d1 == d2).listen((rawData) async {
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
      total: -1,
      prettyProgress: -1,
      chunksCount: 0,
      count: 0,
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
            (downloadId, count, total, chinksCount, downloadState) {
      final int prettyProgress = (count / total * 100).floor();
      _streamListener.add(DownloadDTO(
          downloadId: downloadId,
          downloadState: downloadState,
          total: total,
          prettyProgress: prettyProgress,
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
    waitingList.keys.forEach((element) {
      _streamListener.add(DownloadDTO(
        downloadId: element,
        downloadState: DownloadState.paused,
        total: -1,
        prettyProgress: -1,
        chunksCount: 0,
        count: 0,
      ));
    });
    _cancelTokens.clear();
  }

  void pause(String downloadId) {
    if (waitingList.containsKey(downloadId)) {
      waitingList.remove(downloadId);
    } else if (_currentDownloadId == downloadId) {
      _currentOperation?.cancel();
    }
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
        _currentDownloadId = null;
        _currentOperation = null;
        _cancelTokens[downloadId].cancel();
        _cancelTokens.remove(downloadId);
        _logger?.d('download cancelled id = $downloadId');
        await Future.delayed(const Duration(milliseconds: 500));
        _streamListener.add(DownloadDTO(
          downloadId: downloadId,
          downloadState: DownloadState.paused,
          total: -1,
          prettyProgress: -1,
          chunksCount: 0,
          count: 0,
        ));
      });
      _currentOperation.value.then((value) {
        _logger?.d('download cancelled id = $downloadId  $value == '
            '${_currentOperation.isCompleted} '
            '${_currentOperation.isCanceled}');
      }, onError: (error, stack) {
        _logger?.e('download cancelled id = $downloadId', error, stack);
      });
    }
  }
}
