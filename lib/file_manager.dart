import 'dart:io';

import 'package:path_provider/path_provider.dart';

class FileManager {
  Future mergeTempFiles(int chunks, String path) async {
    try {
      final f = File('${path}temp0');
      final ioSink = f.openWrite(mode: FileMode.writeOnlyAppend);
      for (var i = 1; i < chunks; ++i) {
        final _f = File('$path${'temp$i'}');
        await ioSink.addStream(_f.openRead());
        await _f.delete();
      }
      await ioSink.close();
      await f.rename(path);
    } catch (e) {
      rethrow;
    }
  }

  ///[file1] the resumed chunk file
  ///[file2] the original chunk file
  ///[targetFile] name of the result file after merge
  /// this method help to merger two files then:
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
    } catch (e) {
      rethrow;
    }
  }

  Future<bool> checkIfExist(String savedPath) async {
    return File(savedPath).exists();
  }

  static Future<String> createDir(
      {String fileName = 'testFile', bool deleteContent = false}) async {
    final docDir = (await getApplicationDocumentsDirectory()).path;
    final finalDirPath = '$docDir/$fileName';
    final _directory = Directory(finalDirPath);
    var isDirExist = await _directory.exists();
    if (isDirExist && deleteContent) {
      await _directory.delete(recursive: true);
      isDirExist = false;
    }
    if (!isDirExist) {
      _directory.createSync();
    }
    return _directory.absolute.path;
  }

  Future<int> getFileSize(String fullFilePath) {
    return File(fullFilePath).length();
  }
}
