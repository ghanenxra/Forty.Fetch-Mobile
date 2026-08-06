import 'dart:async';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';
import 'binary_manager_service.dart';

class DownloadEngineService {
  Process? _activeProcess;
  final _binaryManager = BinaryManagerService();
  bool _isCancelled = false;

  Future<Stream<String>> startDownload({
    required String url,
    required String quality,
    required String outputPath,
  }) async {
    final StreamController<String> controller = StreamController<String>();
    _isCancelled = false;

    // Start download process async
    _performDownload(url, quality, outputPath, controller);

    return controller.stream;
  }

  Future<void> _performDownload(
      String url, String quality, String outputPath, StreamController<String> controller) async {
    
    // Fix for youtube_explode_dart crashing on Shorts/Live URLs with query parameters (e.g. ?feature=share)
    if (url.contains('/shorts/') || url.contains('/live/')) {
      url = url.split('?').first;
    }

    final yt = YoutubeExplode();
    File? tempVideoFile;
    File? tempAudioFile;

    try {
      final ffmpegPath = _binaryManager.getBinaryPath('ffmpeg');
      if (!await File(ffmpegPath).exists()) {
        throw Exception('FFmpeg binary not found. Please restart or update the app.');
      }

      controller.add('[download] Fetching video manifest...');
      var manifest = await yt.videos.streamsClient.getManifest(url);

      if (_isCancelled) return;

      var audioStreamInfo = manifest.audioOnly.withHighestBitrate();
      
      var videoStreamInfo = manifest.videoOnly.firstWhere(
        (e) => e.qualityLabel.startsWith(RegExp(r'(\d+)p').firstMatch(quality)?.group(1) ?? '1080'),
        orElse: () => manifest.videoOnly.withHighestBitrate(),
      );

      final tempDir = await getTemporaryDirectory();
      final videoId = VideoId(url).value;
      
      // We need the video title to construct the file name!
      var video = await yt.videos.get(videoId);
      String safeTitle = video.title.replaceAll(RegExp(r'[\\/:*?"<>|]'), '_');
      String actualOutputPath = '$outputPath/$safeTitle.${quality == 'MP3 (Audio)' ? 'mp3' : 'mp4'}';

      controller.add('[download] Downloading audio stream...');
      var audioStream = yt.videos.streamsClient.get(audioStreamInfo);
      tempAudioFile = File('${tempDir.path}/$videoId.m4a');
      var audioFileStream = tempAudioFile.openWrite();
      
      int audioDownloaded = 0;
      int lastAudioPct = -1;
      await for (var data in audioStream) {
        if (_isCancelled) {
          await audioFileStream.close();
          return;
        }
        audioFileStream.add(data);
        audioDownloaded += data.length;
        int pct = ((audioDownloaded / audioStreamInfo.size.totalBytes) * 100).toInt();
        if (pct != lastAudioPct) {
          controller.add('[download] Audio progress: $pct%');
          lastAudioPct = pct;
        }
      }
      await audioFileStream.close();

      if (quality != 'MP3 (Audio)' && quality != 'MP3') {
        controller.add('[download] Downloading video stream...');
        var videoStream = yt.videos.streamsClient.get(videoStreamInfo);
        tempVideoFile = File('${tempDir.path}/$videoId.mp4');
        var videoFileStream = tempVideoFile.openWrite();

        int videoDownloaded = 0;
        int lastVideoPct = -1;
        await for (var data in videoStream) {
          if (_isCancelled) {
            await videoFileStream.close();
            return;
          }
          videoFileStream.add(data);
          videoDownloaded += data.length;
          int pct = ((videoDownloaded / videoStreamInfo.size.totalBytes) * 100).toInt();
          if (pct != lastVideoPct) {
            controller.add('[download] Video progress: $pct%');
            lastVideoPct = pct;
          }
        }
        await videoFileStream.close();

        controller.add('[ffmpeg] Merging audio and video tracks...');
        
        // Use FFmpeg to merge
        _activeProcess = await Process.start(ffmpegPath, [
          '-y',
          '-i', tempVideoFile.path,
          '-i', tempAudioFile.path,
          '-c:v', 'copy',
          '-c:a', 'copy',
          actualOutputPath
        ]);

      } else {
        // Just extract MP3 from audio
        controller.add('[ffmpeg] Extracting MP3...');
        _activeProcess = await Process.start(ffmpegPath, [
          '-y',
          '-i', tempAudioFile.path,
          '-vn',
          '-ar', '44100',
          '-ac', '2',
          '-b:a', '192k',
          actualOutputPath
        ]);
      }

      _activeProcess?.stdout.listen((event) {});
      _activeProcess?.stderr.listen((event) {
        String log = String.fromCharCodes(event).trim();
        if (log.isNotEmpty) {
           print('FFMPEG: $log'); // Let's log it to console just in case
           // If we pipe this to controller, it might mess up our progress parsing, 
           // but we should capture the last error line if it fails.
        }
      });

      final exitCode = await _activeProcess?.exitCode;
      
      if (exitCode == 0) {
        controller.add('[download] 100% of video merged successfully');
        controller.add('FILE_SAVED: $actualOutputPath');
      } else {
        controller.add('ERROR: FFmpeg merge failed with code $exitCode');
      }

    } catch (e) {
      controller.add('ERROR: $e');
    } finally {
      yt.close();
      if (tempVideoFile != null && await tempVideoFile.exists()) {
        await tempVideoFile.delete();
      }
      if (tempAudioFile != null && await tempAudioFile.exists()) {
        await tempAudioFile.delete();
      }
      controller.close();
    }
  }
  
  void cancelDownload() {
    _isCancelled = true;
    if (_activeProcess != null) {
      _activeProcess!.kill();
      _activeProcess = null;
    }
  }
}
