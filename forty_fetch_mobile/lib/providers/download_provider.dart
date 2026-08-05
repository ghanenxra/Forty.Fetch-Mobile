import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import '../services/download_engine_service.dart';
import '../utils/yt_dlp_output_parser.dart';

class DownloadProvider extends ChangeNotifier {
  final DownloadEngineService _engineService = DownloadEngineService();
  static const MethodChannel _channel = MethodChannel('com.fortyfetch.app/media_scanner');

  bool _isDownloading = false;
  String _statusMessage = 'Ready to Fetch';
  double _percentage = 0.0;
  String _speed = '';
  String _eta = '';
  String _errorMessage = '';

  bool get isDownloading => _isDownloading;
  String get statusMessage => _statusMessage;
  double get percentage => _percentage;
  String get speed => _speed;
  String get eta => _eta;
  String get errorMessage => _errorMessage;

  Future<void> startDownload(String url, String quality, String outputPath) async {
    if (_isDownloading) return;

    _isDownloading = true;
    _statusMessage = 'Starting engine...';
    _percentage = 0.0;
    _speed = '';
    _eta = '';
    _errorMessage = '';
    notifyListeners();

    try {
      final stream = await _engineService.startDownload(
        url: url,
        quality: quality,
        outputPath: outputPath,
      );

      stream.listen(
        (line) {
          _processOutputLine(line);
        },
        onDone: () {
          if (_isDownloading) {
            // If it finishes without an explicit exit code via stream
            _isDownloading = false;
            if (_statusMessage != 'Completed!' && !_statusMessage.contains('failed')) {
               _statusMessage = 'Completed!';
            }
            notifyListeners();
          }
        },
      );
    } catch (e) {
      _isDownloading = false;
      _statusMessage = 'Download failed';
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  void _processOutputLine(String line) {
    if (line.startsWith('ERROR:')) {
      _statusMessage = 'Download failed';
      _errorMessage = line.replaceFirst('ERROR:', '').trim();
      _isDownloading = false;
    } else if (line.startsWith('EXIT_CODE:')) {
      final code = int.tryParse(line.replaceFirst('EXIT_CODE:', '').trim());
      if (code == 0) {
        _statusMessage = 'Completed!';
        // In a real scenario we'd parse the actual output path from yt-dlp 
        // to pass to the scanner. For now we notify the scanner generically.
        _channel.invokeMethod('scanFile', {'path': '/storage/emulated/0/Download/FortyFetch/'});
      } else {
        _statusMessage = 'Download failed';
        _errorMessage = 'Process exited with code $code';
      }
      _isDownloading = false;
    } else if (line.contains('[download] Destination:')) {
      _statusMessage = 'Preparing download...';
    } else if (line.contains('[ffmpeg]') || line.contains('[ExtractAudio]')) {
      _statusMessage = 'Finalizing with FFmpeg...';
    } else {
      final progress = YtDlpOutputParser.parseProgress(line);
      if (progress != null) {
        _statusMessage = 'Fetching data...';
        _percentage = progress.percentage;
        _speed = progress.speed;
        _eta = progress.eta;
      }
    }
    notifyListeners();
  }

  void cancelDownload() {
    _engineService.cancelDownload();
    _isDownloading = false;
    _statusMessage = 'Cancelled';
    notifyListeners();
  }
}
