import 'dart:async';
import 'dart:typed_data';
import 'package:firebase_storage/firebase_storage.dart';
import '../utils/image_constants.dart';
import '../utils/file_utils.dart';

class UploadTaskInfo {
  final String taskId;
  final String storagePath;
  final String fileName;
  final UploadTask task;
  final Completer<String> completer;

  const UploadTaskInfo({
    required this.taskId,
    required this.storagePath,
    required this.fileName,
    required this.task,
    required this.completer,
  });
}

class StorageService {
  final FirebaseStorage _storage;
  final Map<String, UploadTaskInfo> _activeTasks = {};
  final _progressControllers = <String, StreamController<double>>{};
  int _taskCounter = 0;

  StorageService({FirebaseStorage? storage})
      : _storage = storage ?? FirebaseStorage.instance;

  UploadTaskInfo uploadImage({
    required String salonId,
    required String category,
    required Uint8List data,
    String? serviceId,
    String? fileName,
  }) {
    final ext = 'jpg';
    final name = fileName ?? FileUtils.uniqueFilename(ext);
    _taskCounter++;

    String fullPath;
    if (serviceId != null) {
      fullPath = '${ImageConstants.storageRoot}/$salonId/${ImageConstants.servicesFolder}/$serviceId/$name';
    } else if (category == ImageConstants.coverFolder) {
      fullPath = '${ImageConstants.storageRoot}/$salonId/${ImageConstants.coverFolder}/$name';
    } else {
      fullPath = '${ImageConstants.storageRoot}/$salonId/${ImageConstants.galleryFolder}/$name';
    }

    final ref = _storage.ref().child(fullPath);
    final metadata = SettableMetadata(
      contentType: FileUtils.contentType(ext),
      cacheControl: 'public,max-age=31536000',
    );

    final task = ref.putData(data, metadata);
    final taskId = 'upload_$_taskCounter';
    final completer = Completer<String>();

    final info = UploadTaskInfo(
      taskId: taskId,
      storagePath: fullPath,
      fileName: name,
      task: task,
      completer: completer,
    );
    _activeTasks[taskId] = info;

    final ctrl = StreamController<double>.broadcast();
    _progressControllers[taskId] = ctrl;

    task.snapshotEvents.listen(
      (snap) {
        if (snap.state == TaskState.running && snap.totalBytes > 0) {
          final progress = snap.bytesTransferred / snap.totalBytes;
          if (!ctrl.isClosed) ctrl.add(progress);
        }
      },
      onError: (e) {
        if (!completer.isCompleted) completer.completeError(e);
        if (!ctrl.isClosed) ctrl.addError(e);
        _cleanup(taskId);
      },
      onDone: () async {
        try {
          final url = await ref.getDownloadURL();
          if (!completer.isCompleted) completer.complete(url);
          if (!ctrl.isClosed) ctrl.add(1.0);
        } catch (e) {
          if (!completer.isCompleted) completer.completeError(e);
          if (!ctrl.isClosed) ctrl.addError(e);
        }
        _cleanup(taskId);
      },
      cancelOnError: false,
    );

    Future.delayed(ImageConstants.uploadTimeout, () {
      if (!completer.isCompleted) {
        task.cancel();
        completer.completeError(TimeoutException(
          'Upload timed out after ${ImageConstants.uploadTimeout.inSeconds}s',
          ImageConstants.uploadTimeout,
        ));
        _cleanup(taskId);
      }
    });

    return info;
  }

  Future<String> uploadThumbnail({
    required String salonId,
    required String category,
    required Uint8List data,
    String? serviceId,
    String? originalFileName,
  }) async {
    final ext = 'jpg';
    final baseName = originalFileName ?? FileUtils.uniqueFilename(ext);
    final thumbName = baseName.replaceAll('.$ext', '${ImageConstants.thumbnailSuffix}.$ext');

    String fullPath;
    if (serviceId != null) {
      fullPath = '${ImageConstants.storageRoot}/$salonId/${ImageConstants.servicesFolder}/$serviceId/$thumbName';
    } else if (category == ImageConstants.coverFolder) {
      fullPath = '${ImageConstants.storageRoot}/$salonId/${ImageConstants.coverFolder}/$thumbName';
    } else {
      fullPath = '${ImageConstants.storageRoot}/$salonId/${ImageConstants.galleryFolder}/$thumbName';
    }

    final ref = _storage.ref().child(fullPath);
    final metadata = SettableMetadata(
      contentType: FileUtils.contentType(ext),
      cacheControl: 'public,max-age=31536000',
    );

    await ref.putData(data, metadata).timeout(ImageConstants.uploadTimeout);
    return ref.getDownloadURL();
  }

  Future<void> deleteFile(String storagePath) async {
    try {
      await _storage.ref().child(storagePath).delete();
    } catch (_) {}
  }

  Future<void> deleteFolder(String path) async {
    try {
      await _storage.ref().child(path).delete();
    } catch (_) {}
  }

  Stream<double> getProgress(String taskId) {
    final ctrl = _progressControllers[taskId];
    if (ctrl == null) return const Stream.empty();
    return ctrl.stream;
  }

  UploadTaskInfo? getTask(String taskId) => _activeTasks[taskId];

  void cancelUpload(String taskId) {
    final info = _activeTasks[taskId];
    info?.task.cancel();
    _cleanup(taskId);
  }

  void cancelAll() {
    for (final id in _activeTasks.keys.toList()) {
      cancelUpload(id);
    }
  }

  void _cleanup(String taskId) {
    _activeTasks.remove(taskId);
    final ctrl = _progressControllers.remove(taskId);
    if (ctrl != null && !ctrl.isClosed) ctrl.close();
  }

  void dispose() {
    cancelAll();
    for (final ctrl in _progressControllers.values) {
      if (!ctrl.isClosed) ctrl.close();
    }
    _progressControllers.clear();
  }
}
