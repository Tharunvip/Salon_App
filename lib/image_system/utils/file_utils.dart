import 'dart:math';

class FileUtils {
  FileUtils._();

  static String uniqueFilename(String extension) {
    final now = DateTime.now().millisecondsSinceEpoch;
    final random = Random().nextInt(99999);
    return '${now}_$random.$extension';
  }

  static String contentType(String extension) {
    switch (extension.toLowerCase()) {
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'webp':
        return 'image/webp';
      default:
        return 'image/jpeg';
    }
  }

  static String formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  static String formatTimeRemaining(int seconds) {
    if (seconds < 60) return '${seconds}s';
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '${m}m ${s}s';
  }
}
