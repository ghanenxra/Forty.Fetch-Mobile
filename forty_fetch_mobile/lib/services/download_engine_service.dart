import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'binary_manager_service.dart';

class DownloadEngineService {
  Process? _activeProcess;
  final _binaryManager = BinaryManagerService();

  Future<Stream<String>> startDownload({
    required String url,
    required String quality,
    required String outputPath,
  }) async {
    final ytdlpPath = _binaryManager.getBinaryPath('ytdlp');
    final ffmpegPath = _binaryManager.getBinaryPath('ffmpeg');
    
    // Validate binaries exist
    if (!await File(ytdlpPath).exists() || !await File(ffmpegPath).exists()) {
      throw Exception('Engine binaries not found at $ytdlpPath. Please restart or update the app.');
    }

    // Fix for shorts/live URLs with query parameters
    if (url.contains('/shorts/') || url.contains('/live/')) {
      url = url.split('?').first;
    }

    List<String> args = [
      '--ffmpeg-location', ffmpegPath,
      '-o', '$outputPath/%(title)s.%(ext)s',
      '--no-playlist',
      '--newline',
    ];

    if (quality == 'MP3 (Audio)' || quality == 'MP3') {
      args.addAll([
        '-f', 'bestaudio/best',
        '--extract-audio',
        '--audio-format', 'mp3',
        '--audio-quality', '0',
      ]);
    } else {
      // Parse height from quality string (e.g. "1080p 60fps" -> "1080")
      final heightMatch = RegExp(r'(\d+)p').firstMatch(quality);
      final height = heightMatch != null ? heightMatch.group(1) : '1080';
      
      args.addAll([
        '-f', 'bestvideo[height<=$height][fps<=60]+bestaudio/best',
        '--merge-output-format', 'mp4',
      ]);
    }

    args.add(url);

    final StreamController<String> controller = StreamController<String>();

    try {
      _activeProcess = await Process.start(ytdlpPath, args);

      // Pipe stdout
      _activeProcess!.stdout
          .transform(utf8.decoder)
          .transform(const LineSplitter())
          .listen((line) {
        controller.add(line);
      });

      // Pipe stderr
      _activeProcess!.stderr
          .transform(utf8.decoder)
          .transform(const LineSplitter())
          .listen((line) {
        controller.add('ERROR: $line');
      });

      // Handle exit
      _activeProcess!.exitCode.then((code) {
        if (code == 0) {
            controller.add('[download] 100% of video merged successfully');
            controller.add('FILE_SAVED: $outputPath');
        } else {
            controller.add('ERROR: yt-dlp exited with code $code');
        }
        controller.close();
        _activeProcess = null;
      });
    } catch (e) {
      controller.add('ERROR: Failed to start process: $e');
      controller.close();
    }

    return controller.stream;
  }
  
  void cancelDownload() {
    if (_activeProcess != null) {
      _activeProcess!.kill();
      _activeProcess = null;
    }
  }
}
