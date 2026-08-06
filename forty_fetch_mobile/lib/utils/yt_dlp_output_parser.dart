class DownloadProgress {
  final double percentage;
  final String totalSize;
  final String speed;
  final String eta;

  DownloadProgress({
    required this.percentage,
    required this.totalSize,
    required this.speed,
    required this.eta,
  });
}

class YtDlpOutputParser {
  static final RegExp _progressRegex = RegExp(
    r'\[download\]\s+(\d+(?:\.\d+)?)%\s+of\s+~?\s*(\S+)\s+at\s+(\S+)\s+ETA\s+(\S+)',
  );
  
  static final RegExp _nativeProgressRegex = RegExp(
    r'\[download\]\s+(?:Audio|Video)\s+progress:\s+(\d+)%',
  );

  static DownloadProgress? parseProgress(String line) {
    // Try original yt-dlp format first
    final match = _progressRegex.firstMatch(line);
    if (match != null) {
      return DownloadProgress(
        percentage: double.tryParse(match.group(1) ?? '0') ?? 0,
        totalSize: match.group(2) ?? '',
        speed: match.group(3) ?? '',
        eta: match.group(4) ?? '',
      );
    }
    
    // Fallback to new youtube_explode_dart format
    final nativeMatch = _nativeProgressRegex.firstMatch(line);
    if (nativeMatch != null) {
      // In youtube_explode, video and audio are downloaded sequentially. 
      // We can map 0-100% of Audio to 0-30%, and 0-100% of Video to 30-100%.
      // But for simplicity, we'll just display the raw percentage and update the status message.
      double rawPct = double.tryParse(nativeMatch.group(1) ?? '0') ?? 0;
      
      return DownloadProgress(
        percentage: rawPct,
        totalSize: 'N/A',
        speed: 'N/A',
        eta: 'N/A',
      );
    }
    
    return null;
  }
}
