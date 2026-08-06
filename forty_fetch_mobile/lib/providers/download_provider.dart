import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import '../services/download_engine_service.dart';
import '../utils/yt_dlp_output_parser.dart';
import '../main.dart';

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

  Future<void> _stopForegroundService() async {
    if (await FlutterForegroundTask.isRunningService) {
      await FlutterForegroundTask.stopService();
    }
  }

  Future<void> startDownload(String url, String quality, String outputPath) async {
    if (_isDownloading) return;

    _isDownloading = true;
    _statusMessage = 'Starting engine...';
    _percentage = 0.0;
    _speed = '';
    _eta = '';
    _errorMessage = '';
    notifyListeners();
    
    if (await FlutterForegroundTask.isIgnoringBatteryOptimizations == false) {
      // Optional: request ignore battery optimizations if needed, but not strictly required for just network
    }

    await FlutterForegroundTask.startService(
      notificationTitle: 'FortyFetch Downloading',
      notificationText: 'Starting engine...',
      callback: startCallback,
    );

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
            _stopForegroundService();
            notifyListeners();
          }
        },
      );
    } catch (e) {
      _isDownloading = false;
      _statusMessage = 'Download failed';
      _errorMessage = e.toString();
      _stopForegroundService();
      notifyListeners();
    }
  }

  void _processOutputLine(String line) {
    if (line.startsWith('ERROR:')) {
      _statusMessage = 'Download failed';
      _errorMessage = line.replaceFirst('ERROR:', '').trim();
      _isDownloading = false;
      _stopForegroundService();
    } else if (line.startsWith('FILE_SAVED:')) {
      final actualPath = line.replaceFirst('FILE_SAVED:', '').trim();
      _channel.invokeMethod('scanFile', {'path': actualPath});
      _statusMessage = 'Completed!';
      _isDownloading = false;
      _stopForegroundService();
    } else if (line.contains('[download] Destination:')) {
      _statusMessage = 'Preparing download...';
      FlutterForegroundTask.updateService(notificationTitle: 'FortyFetch', notificationText: _statusMessage);
    } else if (line.contains('[ffmpeg]') || line.contains('[ExtractAudio]')) {
      _statusMessage = 'Finalizing with FFmpeg...';
      FlutterForegroundTask.updateService(notificationTitle: 'FortyFetch', notificationText: _statusMessage);
    } else if (line.contains('[download] Fetching video manifest...')) {
      _statusMessage = 'Fetching video info...';
      FlutterForegroundTask.updateService(notificationTitle: 'FortyFetch', notificationText: _statusMessage);
    } else {
      final progress = YtDlpOutputParser.parseProgress(line);
      if (progress != null) {
        if (line.contains('Audio progress:')) {
          _statusMessage = 'Downloading Audio...';
        } else if (line.contains('Video progress:')) {
          _statusMessage = 'Downloading Video...';
        }
        _percentage = progress.percentage;
        _speed = progress.speed;
        _eta = progress.eta;
        FlutterForegroundTask.updateService(
          notificationTitle: 'FortyFetch: $_statusMessage',
          notificationText: '${_percentage.toStringAsFixed(1)}% | ETA: $_eta'
        );
      }
    }
    notifyListeners();
  }

  void cancelDownload() {
    _engineService.cancelDownload();
    _isDownloading = false;
    _statusMessage = 'Cancelled';
    _stopForegroundService();
    notifyListeners();
  }
}
