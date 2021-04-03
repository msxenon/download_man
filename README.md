# Big files downloader (in Pure dart)
![](files/screenshot.png)
## Tested on Android & iOS and should work on all platforms
a small downloader using Dio range download with DownloadMan Service which controlls the queue , pause all or pause a single file.

#Features

1.Resumaable downloads
2.fast download while it splits the file into small chunks and downloads them in parallel
3.easy to implement
4.parallel files download (Not yet implemented)
5.background worker(Not yet implemented)

#Workflow
1. download small chunk (1 byte) to check the file size
2. split files morethan 10 Mb to chunks (FileSize/10Mb) with max of 16 chunk
3. resumes the chunk if its already been (fully/partialy) downloaded before
4. emits progress updates (DownloadMan.streamController) =>  
(String downloadId, int prettyProgress,  int total,int count, int chunksCount,DownloadState downloadState)

enum DownloadState { unknown, queued, downloading, failed, completed, paused }


PS. if you download the file inside app sandbox then you don't need storage permission.
## Don't forget to give a star and follow))


