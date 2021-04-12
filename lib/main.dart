import 'dart:collection';
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

  final LinkedHashMap<String, DownloadDTO> downloads =
      LinkedHashMap<String, DownloadDTO>();
  final downloadData = <String, Map<String, String>>{
    '1': {'https://speed.hetzner.de/100MB.bin': '/100.bin'},
    // '2': {
    //   'https://test-videos.co.uk/vids/bigbuckbunny/mp4/h264/1080/'
    //       'Big_Buck_Bunny_1080_10s_30MB.mp4': '/2.mp4'
    // },
    // '3': {
    //   'https://test-videos.co.uk/vids/bigbuckbunny/mp4/h264/1080/'
    //       'Big_Buck_Bunny_1080_10s_30MB.mp4': '/3.mp4'
    // },
    // '4': {
    //   'https://test-videos.co.uk/vids/bigbuckbunny/mp4/h264/1080/'
    //       'Big_Buck_Bunny_1080_10s_30MB.mp4': '/4.mp4'
    // }
  };
  final Map<String, int> downloadSize = {};
  final Map<String, String> paths = {};

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          if (downloads.isEmpty)
            Text(
              'No downloads yet',
              style: Theme.of(context).textTheme.headline4,
            ),
          ListView.builder(
            shrinkWrap: true,
            itemBuilder: (context, index) {
              final currentItem = downloads.values.elementAt(index);
              if (currentItem.total > 0) {
                downloadSize.putIfAbsent(
                    currentItem.downloadId, () => currentItem.total);
              }
              if (currentItem.downloadState.isCompleted) {
                _checkIfFileValid(currentItem);
              }
              return ListTile(
                key: Key(currentItem.downloadId),
                title: Text('#${currentItem.downloadId}     '
                    // ignore: lines_longer_than_80_chars
                    '${currentItem.prettyProgress >= 0 ? '...${currentItem.prettyProgress}%' : ''}'),
                subtitle: Text('${currentItem.downloadState}'
                    '${' | ${Converter.formatBytes(downloadSize[currentItem.downloadId])}'}'),
                trailing: IconButton(
                  icon: Icon(currentItem.downloadState.isRunning
                      ? Icons.pause
                      : currentItem.downloadState.isCompleted
                          ? Icons.download_done_outlined
                          : Icons.play_arrow_rounded),
                  onPressed: () {
                    if (currentItem.downloadState.isRunning) {
                      downloadMan.pause(currentItem.downloadId);
                    } else if (currentItem.downloadState.isResumable) {
                      _add(currentItem.downloadId);
                    }
                  },
                ),
              );
            },
            itemCount: downloads.length,
          ),
          const SizedBox(
            height: 20,
          ),
          OutlineButton(
              child: const Text('Start Downloading'),
              onPressed: downloads.isNotEmpty
                  ? null
                  : () {
                      // _add('1');
                      downloadData.forEach((key, value) {
                        _add(key);
                      });
                    }),
          OutlineButton(
              child: const Text('Pause All'),
              onPressed: downloads.isEmpty ? null : downloadMan.pauseAll),
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

      downloads.update(event.downloadId, (value) => event,
          ifAbsent: () => event);
      if (mounted) {
        setState(() {});
      }
    });
  }

  void _add(String key) async {
    final finalDir = await _createDir();
    final filePath = finalDir.absolute.path + downloadData[key].values.first;
    paths.putIfAbsent(key, () => filePath);
    downloadMan.addToDownload(key, downloadData[key].keys.first, filePath);
  }

  void _checkIfFileValid(DownloadDTO currentItem) async {
    final filePath = File(paths[currentItem.downloadId]);
    final fileSize = await filePath.length();
    final downloadCorrectSize = downloadSize[currentItem.downloadId];

    debugPrint(
        'SERVERSIZE ${Converter.formatBytes(downloadCorrectSize)}== $downloadCorrectSize, FileSize ${Converter.formatBytes(fileSize)}==$fileSize');
  }
}
