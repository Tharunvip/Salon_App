import 'dart:typed_data';

enum UploadStatus { idle, picking, compressing, uploading, completed, failed }

class UploadTaskFile {
  final String id;
  final String name;
  final Uint8List originalBytes;
  Uint8List? compressedBytes;
  Uint8List? thumbnailBytes;
  final int fileSize;
  String? thumbnailUrl;
  String? downloadUrl;
  UploadStatus status;
  double progress;
  String? error;

  UploadTaskFile({
    required this.id,
    required this.name,
    required this.originalBytes,
    this.compressedBytes,
    this.thumbnailBytes,
    required this.fileSize,
    this.thumbnailUrl,
    this.downloadUrl,
    this.status = UploadStatus.picking,
    this.progress = 0,
    this.error,
  });

  UploadTaskFile copyWith({
    String? id,
    String? name,
    Uint8List? originalBytes,
    Uint8List? compressedBytes,
    Uint8List? thumbnailBytes,
    int? fileSize,
    String? thumbnailUrl,
    String? downloadUrl,
    UploadStatus? status,
    double? progress,
    String? error,
  }) {
    final f = this;
    return UploadTaskFile(
      id: id ?? f.id,
      name: name ?? f.name,
      originalBytes: originalBytes ?? f.originalBytes,
      compressedBytes: compressedBytes ?? f.compressedBytes,
      thumbnailBytes: thumbnailBytes ?? f.thumbnailBytes,
      fileSize: fileSize ?? f.fileSize,
      thumbnailUrl: thumbnailUrl ?? f.thumbnailUrl,
      downloadUrl: downloadUrl ?? f.downloadUrl,
      status: status ?? f.status,
      progress: progress ?? f.progress,
      error: error ?? f.error,
    );
  }
}

class UploadState {
  final List<UploadTaskFile> files;
  final int totalFiles;
  final int completedFiles;
  final int failedFiles;
  final double overallProgress;
  final bool isUploading;
  final bool isPaused;
  final String? error;

  const UploadState({
    this.files = const [],
    this.totalFiles = 0,
    this.completedFiles = 0,
    this.failedFiles = 0,
    this.overallProgress = 0,
    this.isUploading = false,
    this.isPaused = false,
    this.error,
  });

  UploadState copyWith({
    List<UploadTaskFile>? files,
    int? totalFiles,
    int? completedFiles,
    int? failedFiles,
    double? overallProgress,
    bool? isUploading,
    bool? isPaused,
    String? error,
  }) => UploadState(
    files: files ?? this.files,
    totalFiles: totalFiles ?? this.totalFiles,
    completedFiles: completedFiles ?? this.completedFiles,
    failedFiles: failedFiles ?? this.failedFiles,
    overallProgress: overallProgress ?? this.overallProgress,
    isUploading: isUploading ?? this.isUploading,
    isPaused: isPaused ?? this.isPaused,
    error: error ?? this.error,
  );
}
