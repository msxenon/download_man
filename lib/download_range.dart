//ignore_for_file:avoid_print, prefer_interpolation_to_compose_strings

import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:dio/dio.dart';
import 'package:flutter_downloadman/utils/converters.dart';
import 'package:logger/logger.dart';

import 'dto/download_dto.dart';
import 'file_manager.dart';

typedef CustomProgressCallback = void Function(String downloadId, int count,
    int total, int progress, int chunksCount, DownloadState);
typedef ConnectionChecker = Future<bool> Function();

class RangeDownload {
  RangeDownload(this.downloadId,
      {bool enableLogs = true,
      this.connectionChecker,
      this.deleteOnError = true}) {
    if (enableLogs) {
      _logger = Logger();
    }
  }

  ///[fileManager] control all writing and merge files operations
  //TODO Test the merger again, i think maybe we will face other issues with
  //many play/pause and connection interrupt
  FileManager fileManager = FileManager();
  final ConnectionChecker connectionChecker;
  Logger _logger;
  final String downloadId;
  final _completer = Completer<Response>();
  final bool deleteOnError;
  Future<Response> downloadWithChunks(url, savePath,
      {bool isRangeDownload = true,
      CustomProgressCallback onReceiveProgress,
      Dio dio,
      CancelToken cancelToken,
      int maxChunksCount = 16}) async {
    _logger?.d('RangeDownload Started id=$downloadId ');
    const _singleChunkSize = 2097152;
    int total = 0;
    if (dio == null) {
      dio = Dio();
      dio.options.connectTimeout = 60 * 1000;
    }
    final progress = <int, int>{};
    final progressInit = <int, int>{};
    int _chunksCount = 1;

    void createCallback(int received, rangeTotal, int no) async {
      try {
        if (no >= 0 && received >= rangeTotal) {
          final path = savePath + 'temp$no';
          final oldPath = savePath + 'temp${no}_pre';
          final File oldFile = File(oldPath);
          if (oldFile.existsSync()) {
            await fileManager.mergeFiles(oldPath, path, path);
          }
        }
        progress[no] = progressInit[no] + received;

        if (onReceiveProgress != null && total != 0) {
          final count = progress.values.reduce((a, b) => a + b);
          final int prettyProgress = (count / total * 100).floor();
          onReceiveProgress(downloadId, count, total, prettyProgress,
              _chunksCount, DownloadState.downloading);
        }
      } catch (e, s) {
        _logger?.e('createCallback id=$downloadId ', e, s);
      }
    }

    Future<Response> downloadChunk(String url, int start, int end, int no,
        {isMerge = true}) async {
      final path = savePath + 'temp$no';

      if (isMerge) {
        int initLength = 0;
        // this is because the second start exactly after the end
        // of the first, so one byte is always duplicated
        --end;

        final File targetFile = File(path);
        if (await targetFile.exists() && isMerge) {
          final targetSize = await targetFile.length();
          final startAndTargetSize = start + targetSize;
          _logger?.d(
              'chunk($no) resumed with size ${targetSize.toReadableValue()} '
              '+ start ${start.toReadableValue()} '
              '${startAndTargetSize.toReadableValue()} '
              '<= end ${end.toReadableValue()}');
          if (startAndTargetSize < end) {
            initLength = await targetFile.length();
            start += initLength;
            final preFile = File(path + '_pre');
            if (await preFile.exists()) {
              initLength += await preFile.length();
              start += await preFile.length();
              _logger?.d('chunk($no) merging pre to target file');
              await fileManager.mergeFiles(
                  preFile.path, targetFile.path, preFile.path);
            } else {
              _logger?.d('chunk($no) target file renamed '
                  '${targetFile.path.lastIndexOf('/')} to ${preFile.path}');
              await targetFile.rename(preFile.path);
            }
          } else {
            ///chunk already downloaded
            progress[no] = (initLength);
            progressInit[no] = (initLength);
            return Response(
              statusCode: 200,
              statusMessage: 'Download sucess.',
              data: 'Download sucess.',
            );
          }
        }
        _logger?.d('RangeDownload good job end:$start $initLength $end '
            ' id=$downloadId');
        progress[no] = (initLength);
        progressInit[no] = (initLength);
      }
      return dio.download(
        url,
        isMerge ? path : savePath + '__',
        onReceiveProgress: (int count, int total) =>
            isMerge ? createCallback(count, total, no) : {},
        options: Options(
          headers: {'range': 'bytes=$start-$end'},
        ),
        deleteOnError: deleteOnError,
        cancelToken: cancelToken,
      );
    }

    try {
      final file = File(savePath);
      if (await file.exists()) {
        final fileSize = await file.length();
        onReceiveProgress(downloadId, fileSize, fileSize, 100, _chunksCount,
            DownloadState.completed);
        _completer.complete(Response(
          statusCode: 200,
          statusMessage: 'Download sucess.',
          data: 'Download sucess.',
        ));
        return _completer.future;
      }
      if (!await connectionChecker()) {
        //TODO after update please change it to cancel not CANCEL
        throw DioError(type: DioErrorType.CANCEL, error: 'No Connection');
      }
      if (isRangeDownload) {
        final response = await downloadChunk(url, 0, 1, -1, isMerge: false);
        try {
          await File(savePath + '__').delete();
        } catch (e, s) {
          _logger?.i('Not important!!!! id=$downloadId', e, s);
        }
        if (response.statusCode == 206) {
          try {
            _logger
                ?.i('RangeDownload This http protocol support range download '
                    'id=$downloadId');
            total = int.parse(response.headers
                .value(HttpHeaders.contentRangeHeader)
                .split('/')
                .last);

            _chunksCount =
                min(maxChunksCount, max((total / _singleChunkSize).floor(), 1));
            final int chunkSize = total ~/ _chunksCount;
            final futures = <Future>[];
            _logger?.d('totalSize id=$downloadId $total chunkSize $chunkSize '
                '$_chunksCount');

            for (var chunkNo = 0; chunkNo < _chunksCount; chunkNo++) {
              final int start = chunkSize * chunkNo;
              final int end = chunkSize + start;
              _logger?.d('start id=$downloadId $start end $end $chunkNo');
              futures.add(downloadChunk(url, start, end, chunkNo));
            }
            await Future.wait(futures);
            await fileManager.mergeTempFiles(_chunksCount, savePath);
            final fileSize = await fileManager.getFileSize(savePath);
            onReceiveProgress(downloadId, fileSize, fileSize, 100, _chunksCount,
                DownloadState.completed);
            _completer.complete(Response(
              statusCode: 200,
              statusMessage: 'Download sucess.',
              data: 'Download sucess.',
            ));
          } catch (e, s) {
            if (e is DioError && e.type == DioErrorType.CANCEL) {
              ///dont log anything .. user just paused the download process
            } else {
              _logger?.e('mainRangeDownload id=$downloadId', e, s);
            }
            _completer.completeError(e, s);
          }
        } else if (response.statusCode == 200) {
          _logger?.i('RangeDownload The protocol does not support resumable '
              'downloads, and regular downloads will be used. id=$downloadId');
          _completer.complete(dio.download(
            url,
            savePath,
            onReceiveProgress: (count, total) => onReceiveProgress(
                downloadId,
                count,
                total,
                DownloadDTO.unknown,
                _chunksCount,
                DownloadState.downloading),
            cancelToken: cancelToken,
          ));
        } else {
          _logger?.i('RangeDownload The request encountered '
              'a problem, please handle it yourself id=$downloadId');
          return response;
        }
      } else {
        _completer.complete(dio.download(
          url,
          savePath,
          onReceiveProgress: (count, total) => onReceiveProgress(
              downloadId,
              count,
              total,
              DownloadDTO.unknown,
              _chunksCount,
              DownloadState.downloading),
          cancelToken: cancelToken,
        ));
      }
    } catch (e, stack) {
      _logger?.e('', e, stack);
      _completer.completeError(e, stack);
    }

    return _completer.future;
  }
}

extension IntExts on int {
  String toReadableValue() {
    return Converter.formatBytes(this);
  }
}
