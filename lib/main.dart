import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_downloadman/download_man.dart';
import 'package:flutter_downloadman/dto/download_dto.dart';
import 'package:flutter_downloadman/utils/converters.dart';
import 'package:get/get.dart';
import 'package:path_provider/path_provider.dart';

void main() async {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter DownloadMan',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: MyHomePage(title: 'Download-Man demo'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key);
  final String title;
  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final downloadMan = Get.put(DownloadMan());
  @override
  void initState() {
    super.initState();
    _createListDownloads();
  }

  ///this package downloads single file per time
  final downloadData = <String, Map<String, String>>{
    '2': {
      'https://alcorn.com/wp-content/downloads/test-files/AlcornSpinningProductsHD.mpg':
          '/AlcornSpinningProductsHD.mpg'
    },
  };
  DownloadDTO _downloadDTO;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          if (_downloadDTO == null)
            Center(
              child: Text(
                'No downloads yet',
                style: Theme.of(context).textTheme.headline4,
              ),
            ),
          if (_downloadDTO != null)
            ListView.builder(
              shrinkWrap: true,
              itemBuilder: (context, index) {
                return ListTile(
                  key: Key(_downloadDTO.downloadId),
                  title: Text('#${_downloadDTO.downloadId}     '
                      // ignore: lines_longer_than_80_chars
                      '${_downloadDTO.prettyProgress >= 0 ? '...${_downloadDTO.prettyProgress}%' : ''}'),
                  subtitle: Text('${_downloadDTO.downloadState}'
                      '${' || '
                          ' ${Converter.formatBytes(_downloadDTO.count)}/'
                          '${Converter.formatBytes(_downloadDTO.total)}'}'),
                  trailing: IconButton(
                    icon: Icon(_downloadDTO.downloadState.isDownloading
                        ? Icons.pause
                        : _downloadDTO.downloadState.isCompleted
                            ? Icons.download_done_outlined
                            : Icons.play_arrow_rounded),
                    onPressed: () {
                      if (_downloadDTO.downloadState.isRunning) {
                        downloadMan.pause(_downloadDTO.downloadId);
                      } else if (_downloadDTO.downloadState.isResumable) {
                        _add(_downloadDTO.downloadId);
                      }
                    },
                  ),
                );
              },
              itemCount: 1,
            ),
          const SizedBox(
            height: 20,
          ),
          OutlineButton(
              child: const Text('Start Downloading'),
              onPressed: _downloadDTO != null
                  ? null
                  : () {
                      _add(downloadData.keys.first);
                    }),
          OutlineButton(
              child: const Text('Pause'),
              onPressed: downloadData == null ? null : downloadMan.pauseAll),
        ],
      ),
    );
  }

  Future<Directory> _createDir() async {
    final docDir = (await getApplicationDocumentsDirectory()).path;
    final finalDirPath = '$docDir/testFile';
    final _directory = Directory(finalDirPath);
    if (!_directory.existsSync()) {
      _directory.createSync();
    }
    return _directory;
  }

  void _createListDownloads() async {
    downloadMan.streamController.stream.listen((event) {
      debugPrint('_createListDownloads $event');

      _setDownloadEvent(event);
      if (mounted) {
        setState(() {});
      }
    });
  }

  void _add(String key) async {
    final finalDir = await _createDir();
    final filePath = finalDir.absolute.path + downloadData[key].values.first;
    downloadMan.addToDownload(key, downloadData[key].keys.first, filePath);
  }

  ///lets pretend we are persisting DownloadDTO to a local database
  void _setDownloadEvent(DownloadDTO event) {
    _downloadDTO ??= event;
    _downloadDTO = _downloadDTO.copyWith(downloadState: event.downloadState);
    if (isValidValue(event.prettyProgress)) {
      _downloadDTO =
          _downloadDTO.copyWith(prettyProgress: event.prettyProgress);
    }
    if (isValidValue(event.total)) {
      _downloadDTO = _downloadDTO.copyWith(total: event.total);
    }
    if (isValidValue(event.count)) {
      _downloadDTO = _downloadDTO.copyWith(count: event.count);
    }
    if (isValidValue(event.chunksCount)) {
      _downloadDTO = _downloadDTO.copyWith(chunksCount: event.chunksCount);
    }
    if (isValidValue(event.prettyProgress)) {
      _downloadDTO =
          _downloadDTO.copyWith(prettyProgress: event.prettyProgress);
    }
  }

  bool isValidValue(int value) {
    return value != DownloadDTO.unknown;
  }
}
