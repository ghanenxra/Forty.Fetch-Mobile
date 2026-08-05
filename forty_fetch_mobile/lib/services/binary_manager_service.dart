import 'dart:io';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';

class BinaryManagerService {
  static const List<String> _binaries = ['yt-dlp', 'ffmpeg', 'ffprobe'];
  
  static const _channel = MethodChannel('com.fortyfetch.app/media_scanner');
  
  static String? _nativeLibDir;

  Future<void> initBinaries() async {
    try {
      if (Platform.isAndroid) {
        _nativeLibDir = await _channel.invokeMethod<String>('getNativeLibraryDir');
        print('Native library dir: $_nativeLibDir');
      } else {
        // Fallback for Windows desktop testing
        final appSupportDir = await getApplicationSupportDirectory();
        _nativeLibDir = appSupportDir.path;
      }
    } catch (e) {
      print('Error initializing binaries: $e');
    }
  }

  String getBinaryPath(String binaryName) {
    if (_nativeLibDir == null) {
      throw StateError('BinaryManagerService not initialized');
    }
    if (Platform.isAndroid) {
      return '$_nativeLibDir/lib$binaryName.so';
    } else if (Platform.isWindows) {
      return '$_nativeLibDir/$binaryName.exe';
    }
    return '$_nativeLibDir/$binaryName';
  }

}
