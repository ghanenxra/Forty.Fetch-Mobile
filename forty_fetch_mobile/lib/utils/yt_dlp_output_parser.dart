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

  static DownloadProgress? parseProgress(String line) {
    final match = _progressRegex.firstMatch(line);
    if (match != null) {
      return DownloadProgress(
        percentage: double.tryParse(match.group(1) ?? '0') ?? 0,
        totalSize: match.group(2) ?? '',
        speed: match.group(3) ?? '',
        eta: match.group(4) ?? '',
      );
    }
    return null;
  }
}
