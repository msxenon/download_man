//ignore_for_file:avoid_print, prefer_interpolation_to_compose_strings
import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:dio/dio.dart';
import 'package:flutter_downloadman/dto/download_dto.dart';
import 'package:flutter_downloadman/utils/converters.dart';
import 'package:logger/logger.dart';

typedef CustomProgressCallback = void Function(String downloadId, int count,
    int total, int progress, int chunksCount, DownloadState);

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
        final dir = Directory(
            '/data/user/0/com.msa.flutter_downloadman/app_flutter/testFile/');
        final files = dir.listSync();
        int totalSize = 0;
        for (final file in files) {
          final _f = File(file.path);
          final l = await _f.length();
          totalSize += l;
          _logger?.i('file: ${file.path}:${Converter.formatBytes(l)}  ');
        }
        _logger
            ?.i('final size :${Converter.formatBytes(totalSize)} file merged');
        //
        final File f = File(savePath + 'temp0');
        final IOSink ioSink = f.openWrite(mode: FileMode.writeOnlyAppend);
        totalSize = 0;
        totalSize += await f.length();
        for (int i = 1; i < chunk; ++i) {
          final File _f = File(savePath + 'temp$i');
          final _fl = await _f.length();
          totalSize += _fl;
          await ioSink.addStream(_f.openRead());
          _logger?.i(
              'index $i: ${_f.path} : ${Converter.formatBytes(_fl)} merged');
          await _f.delete();
        }
        await ioSink.close();
        await f.rename(savePath);
        _logger?.i('$chunk:${Converter.formatBytes(totalSize)} file merged');
      } catch (e, s) {
        _logger?.e('mergeTempFiles id=$downloadId', e, s);
      }
    }

    ///appends f2 to f1
    ///deletes f2
    ///rename f1 to targetfile name
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
        _logger?.e('mergeFiles id=$downloadId ', e, s);
      }
    }

    void createCallback(int received, rangeTotal, int no) async {
      try {
        if (received >= rangeTotal) {
          final path = savePath + 'temp$no';
          final oldPath = savePath + 'temp${no}_pre';
          final File oldFile = File(oldPath);
          if (oldFile.existsSync()) {
            await mergeFiles(path, oldPath, path);
          }
        }
        progress[no] = progressInit[no] + received;
        if (onReceiveProgress != null && total != 0) {
          final count = progress.values.reduce((a, b) => a + b);
          final int prettyProgress = (count / total * 100).floor();

          if (prettyProgress > 100) {
            _logger?.w(
                'more than 100 $downloadId ==== ${prettyProgress} = $count / $total ${progress}');
          }
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
        --end;
        final File targetFile = File(path);
        if (await targetFile.exists() && isMerge) {
          final targetSize = await targetFile.length();
          final startAndTargetSize = start + targetSize;
          _logger?.d(
              'chunk($no) resumed with size ${targetSize.toReadableValue()} + start ${start.toReadableValue()} ${startAndTargetSize.toReadableValue()} <= end ${end.toReadableValue()}');
          if (startAndTargetSize < end) {
            initLength = await targetFile.length();
            start += initLength;
            final preFile = File(path + '_pre');
            if (await preFile.exists()) {
              initLength += await preFile.length();
              start += await preFile.length();
              _logger?.d('chunk($no) merging pre to target file');
              await mergeFiles(targetFile.path, preFile.path, targetFile.path);
            } else {
              _logger?.d(
                  'chunk($no) target file renamed ${targetFile.path.lastIndexOf('/')} to ${preFile.path.lastIndexOf('/')}');
              await targetFile.rename(preFile.path);
            }
          } else {
            ///chunk already downloaded
            return Response(
              statusCode: 200,
              statusMessage: 'Download sucess.',
              data: 'Download sucess.',
            );
            // await targetFile.delete();
            // _logger?.d('chunk($no) target file deleted');
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
        deleteOnError: false,
        cancelToken: cancelToken,
      );
    }

    try {
      if (await File(savePath).exists()) {
        onReceiveProgress(
            downloadId, 1, 1, 100, _chunksCount, DownloadState.completed);
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
            final int reserved = total -
                int.parse(
                    response.headers.value(HttpHeaders.contentLengthHeader));
            _chunksCount = total > _singleChunkSize
                ? min(max((reserved / _singleChunkSize).floor(), 1),
                    maxChunksCount)
                : 1;
            final int chunkSize = reserved ~/ _chunksCount;
            final futures = <Future>[];
            _logger
                ?.d('totalSize id=$downloadId $reserved chunkSize $chunkSize '
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
                downloadId,
                DownloadDTO.unknown,
                DownloadDTO.unknown,
                100,
                _chunksCount,
                DownloadState.completed);
            _completer.complete(Response(
              statusCode: 200,
              statusMessage: 'Download sucess.',
              data: 'Download sucess.',
            ));
          } catch (e, s) {
            _logger?.e('mainRangeDownload id=$downloadId', e, s);
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
