//ignore_for_file:avoid_print, prefer_interpolation_to_compose_strings
import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:dio/dio.dart';
import 'package:flutter_downloadman/dto/download_dto.dart';
import 'package:logger/logger.dart';

typedef CustomProgressCallback = void Function(
    String downloadId, int count, int total, int chunksCount, DownloadState);

class RangeDownload {
  RangeDownload(this.downloadId, {bool enableLogs = true}) {
    if (enableLogs) {
      _logger = Logger();
    }
  }

  Logger _logger;
  final String downloadId;
  final _completer = Completer<Response>();
  Future<Response> downloadWithChunks(url, savePath,
      {bool isRangeDownload = true,
      CustomProgressCallback onReceiveProgress,
      Dio dio,
      CancelToken cancelToken,
      int maxChunksCount = 16}) async {
    // const firstChunkSize = 102;
    _logger?.d('RangeDownload Started id=$downloadId ');
    const _singleChunkSize = 10485760;
    int total = 0;
    if (dio == null) {
      dio = Dio();
      dio.options.connectTimeout = 60 * 1000;
    }
    final progress = <int, int>{};
    final progressInit = <int, int>{};
    int _chunksCount = 1;
    Future mergeTempFiles(chunk) async {
      try {
        final File f = File(savePath + 'temp0');
        final IOSink ioSink = f.openWrite(mode: FileMode.writeOnlyAppend);
        for (int i = 1; i < chunk; ++i) {
          final File _f = File(savePath + 'temp$i');
          await ioSink.addStream(_f.openRead());
          await _f.delete();
        }
        await ioSink.close();
        await f.rename(savePath);
      } catch (e, s) {
        _logger?.e(' id=$downloadId', e, s);
      }
    }

    Future mergeFiles(file1, file2, targetFile) async {
      try {
        final File f1 = File(file1);
        final File f2 = File(file2);
        final IOSink ioSink = f1.openWrite(mode: FileMode.writeOnlyAppend);
        await ioSink.addStream(f2.openRead());
        await f2.delete();
        await ioSink.close();
        await f1.rename(targetFile);
      } catch (e, s) {
        _logger?.e('id=$downloadId ', e, s);
      }
    }

    void createCallback(int received, rangeTotal, int no) async {
      try {
        if (received >= rangeTotal) {
          final path = savePath + 'temp$no';
          final oldPath = savePath + 'temp${no}_pre';
          final File oldFile = File(oldPath);
          if (oldFile.existsSync()) {
            await mergeFiles(oldPath, path, path);
          }
        }
        progress[no] = progressInit[no] + received;
        if (onReceiveProgress != null && total != 0) {
          onReceiveProgress(downloadId, progress.values.reduce((a, b) => a + b),
              total, _chunksCount, DownloadState.downloading);
        }
      } catch (e, s) {
        _logger?.e('id=$downloadId ', e, s);
      }
    }

    Future<Response> downloadChunk(String url, int start, int end, int no,
        {isMerge = true}) async {
      final path = savePath + 'temp$no';

      if (isMerge) {
        int initLength = 0;
        --end;
        final File targetFile = File(path);
        bool isExist = false;
        if (await targetFile.exists() && isMerge) {
          _logger?.d('RangeDownload good job start:$start'
              ' length:${File(path).lengthSync()} id=$downloadId');
          if (start + await targetFile.length() < end) {
            initLength = await targetFile.length();
            start += initLength;
            final preFile = File(path + '_pre');
            if (await preFile.exists()) {
              initLength += await preFile.length();
              start += await preFile.length();
              await mergeFiles(preFile.path, targetFile.path, preFile.path);
              isExist = true;
            } else {
              await targetFile.rename(preFile.path);
            }
          } else {
            await targetFile.delete();
          }
        }
        _logger?.d(
            'RangeDownload good job end:$start $initLength $end === $isExist'
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
        deleteOnError: false,
        cancelToken: cancelToken,
      );
    }

    if (await File(savePath).exists()) {
      onReceiveProgress(
          downloadId, 1, 1, _chunksCount, DownloadState.completed);
      _completer.complete(Response(
        statusCode: 200,
        statusMessage: 'Download sucess.',
        data: 'Download sucess.',
      ));
      return _completer.future;
    }
    if (isRangeDownload) {
      final response = await downloadChunk(url, 0, 1, 0, isMerge: false);
      try {
        await File(savePath + '__').delete();
      } catch (e, s) {
        _logger?.e('Not important!!!! id=$downloadId', e, s);
      }
      if (response.statusCode == 206) {
        try {
          _logger?.i('RangeDownload This http protocol support range download '
              'id=$downloadId');
          total = int.parse(response.headers
              .value(HttpHeaders.contentRangeHeader)
              .split('/')
              .last);
          final int reserved = total -
              int.parse(
                  response.headers.value(HttpHeaders.contentLengthHeader));
          _chunksCount = total > _singleChunkSize
              ? min(
                  max((reserved / _singleChunkSize).floor(), 1), maxChunksCount)
              : 1;
          final int chunkSize = reserved ~/ _chunksCount;
          final futures = <Future>[];
          _logger?.d('totalSize id=$downloadId $reserved chunkSize $chunkSize '
              '$_chunksCount');

          for (var chunkNo = 0; chunkNo < _chunksCount; chunkNo++) {
            final int start = chunkSize * chunkNo;
            final int end = chunkSize + start;
            _logger?.d('start id=$downloadId $start end $end $chunkNo');
            futures.add(downloadChunk(url, start, end, chunkNo));
          }
          await Future.wait(futures);
          await mergeTempFiles(_chunksCount);
          onReceiveProgress(
              downloadId, 1, 1, _chunksCount, DownloadState.completed);
        } catch (e, s) {
          _logger?.e(' id=$downloadId', e, s);
          _completer.completeError(e, s);
        }

        _completer.complete(Response(
          statusCode: 200,
          statusMessage: 'Download sucess.',
          data: 'Download sucess.',
        ));
      } else if (response.statusCode == 200) {
        _logger?.i('RangeDownload The protocol does not support resumable '
            'downloads, and regular downloads will be used. id=$downloadId');
        _completer.complete(dio.download(
          url,
          savePath,
          onReceiveProgress: (count, total) => onReceiveProgress(
              downloadId, count, total, _chunksCount, DownloadState.unknown),
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
            downloadId, count, total, _chunksCount, DownloadState.unknown),
        cancelToken: cancelToken,
      ));
    }

    return _completer.future;
  }
}
