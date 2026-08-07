import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../../data/compression_service.dart';
import '../../data/storage_service.dart';
import '../../utils/image_constants.dart';
import 'upload_state.dart';

class UploadCubit extends ValueNotifier<UploadState> {
  final StorageService _storageService;
  final CompressionService _compressionService;
  final String salonId;
  final String ownerId;
  final String? serviceId;
  final String category;

  final _uuid = const Uuid();
  final _progressSubs = <String, StreamSubscription>{};
  final _queue = <UploadTaskFile>[];
  int _activeCount = 0;

  UploadCubit({
    required this._storageService,
    required this._compressionService,
    required this.salonId,
    required this.ownerId,
    this.serviceId,
    this.category = ImageConstants.galleryFolder,
  }) : super(const UploadState());

  void addFiles(List<Uint8List> bytesList) {
    final files = bytesList.map((bytes) {
      final id = _uuid.v4();
      return UploadTaskFile(
        id: id,
        name: 'image_$id.jpg',
        originalBytes: bytes,
        fileSize: bytes.length,
        status: UploadStatus.picking,
      );
    }).toList();

    final updated = List<UploadTaskFile>.from(value.files)..addAll(files);
    _recalculate(updated);
    _processAll(updated);
  }

  void addFile(Uint8List bytes) => addFiles([bytes]);

  Future<void> _processAll(List<UploadTaskFile> files) async {
    _queue.clear();
    _queue.addAll(files.where((f) => f.status == UploadStatus.picking));

    final updated = List<UploadTaskFile>.from(files);
    for (final file in _queue) {
      final idx = updated.indexWhere((f) => f.id == file.id);
      if (idx == -1) continue;
      updated[idx] = _processFile(updated[idx]);
    }
    _recalculate(updated);
    _drainQueue();
  }

  UploadTaskFile _processFile(UploadTaskFile file) {
    try {
      file.status = UploadStatus.compressing;

      final compressed = _compressionService.compress(bytes: file.originalBytes);
      file.compressedBytes = compressed.data;

      final thumbnail = _compressionService.generateThumbnail(bytes: file.originalBytes);
      file.thumbnailBytes = thumbnail.data;

      file.status = UploadStatus.uploading;
    } catch (e) {
      file.status = UploadStatus.failed;
      file.error = 'Compression failed: $e';
    }
    return file;
  }

  Future<void> _drainQueue() async {
    while (_queue.isNotEmpty) {
      if (_activeCount >= ImageConstants.maxUploadConcurrency) {
        await Future.delayed(const Duration(milliseconds: 200));
        continue;
      }

      final file = _queue.removeAt(0);
      if (file.status != UploadStatus.uploading) continue;

      _activeCount++;
      _uploadFile(file).then((_) {
        _activeCount--;
        _drainQueue();
      });
    }
  }

  Future<void> _uploadFile(UploadTaskFile file, {int attempt = 1}) async {
    try {
      final thumbBytes = file.thumbnailBytes ?? file.compressedBytes ?? file.originalBytes;
      final origBytes = file.compressedBytes ?? file.originalBytes;

      final thumbInfo = await _storageService.uploadThumbnail(
        salonId: salonId,
        category: category,
        data: thumbBytes,
        serviceId: serviceId,
        originalFileName: file.name,
      );
      file.thumbnailUrl = thumbInfo;
      notifyListeners();

      final origInfo = _storageService.uploadImage(
        salonId: salonId,
        category: category,
        data: origBytes,
        serviceId: serviceId,
        fileName: file.name,
      );

      _progressSubs[origInfo.taskId] = _storageService
          .getProgress(origInfo.taskId)
          .listen((p) {
        file.progress = p;
        notifyListeners();
      });

      final url = await origInfo.completer.future;
      file.downloadUrl = url;
      file.status = UploadStatus.completed;
      file.progress = 1.0;
      _progressSubs[origInfo.taskId]?.cancel();
      _progressSubs.remove(origInfo.taskId);
    } catch (e) {
      if (attempt < 3) {
        final delay = Duration(seconds: 2 * attempt * attempt);
        file.error = 'Retrying in ${delay.inSeconds}s... (attempt $attempt)';
        notifyListeners();
        await Future.delayed(delay);
        return _uploadFile(file, attempt: attempt + 1);
      }
      file.status = UploadStatus.failed;
      file.error = 'Upload failed after $attempt attempts: $e';
    }

    final updated = List<UploadTaskFile>.from(value.files);
    final idx = updated.indexWhere((f) => f.id == file.id);
    if (idx != -1) updated[idx] = file;
    _recalculate(updated);
  }

  Future<void> retryFile(String fileId) async {
    final updated = List<UploadTaskFile>.from(value.files);
    final idx = updated.indexWhere((f) => f.id == fileId);
    if (idx == -1 || updated[idx].status != UploadStatus.failed) return;

    updated[idx] = updated[idx].copyWith(
      status: UploadStatus.uploading,
      progress: 0,
      error: null,
    );
    _recalculate(updated);

    final file = updated[idx];
    if (!_queue.contains(file)) {
      _queue.add(file);
      _activeCount--;
      _drainQueue();
    }
  }

  void cancelFile(String fileId) {
    final updated = List<UploadTaskFile>.from(value.files);
    updated.removeWhere((f) => f.id == fileId);
    _queue.removeWhere((f) => f.id == fileId);
    _recalculate(updated);
  }

  void cancelAll() {
    _storageService.cancelAll();
    _queue.clear();
    _recalculate([]);
  }

  void _recalculate(List<UploadTaskFile> files) {
    final total = files.length;
    final completed = files.where((f) => f.status == UploadStatus.completed).length;
    final failed = files.where((f) => f.status == UploadStatus.failed).length;
    final uploading = files.where((f) =>
        f.status == UploadStatus.uploading ||
        f.status == UploadStatus.compressing).length;
    final progress = total == 0
        ? 0.0
        : files.fold<double>(0, (sum, f) => sum + f.progress) / total;

    value = value.copyWith(
      files: files,
      totalFiles: total,
      completedFiles: completed,
      failedFiles: failed,
      overallProgress: progress,
      isUploading: uploading > 0,
    );
  }

  @override
  void dispose() {
    for (final sub in _progressSubs.values) {
      sub.cancel();
    }
    _progressSubs.clear();
    _storageService.cancelAll();
    super.dispose();
  }
}
