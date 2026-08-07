import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import '../domain/image_metadata.dart';
import '../domain/image_repository.dart';
import '../presentation/cubit/upload_state.dart';
import 'compression_service.dart';
import 'storage_service.dart';
import '../utils/image_constants.dart';

class ImageRepositoryImpl implements ImageRepository {
  final FirebaseFirestore _db;
  final StorageService _storageService;
  final CompressionService _compressionService;
  final _uuid = const Uuid();
  final _progressControllers = <String, StreamController<double>>{};

  ImageRepositoryImpl({
    required this._db,
    required this._storageService,
    required this._compressionService,
  });

  @override
  Future<ImageMetadata> uploadCoverImage({
    required String salonId,
    required String ownerId,
    required UploadTaskFile file,
  }) async {
    final compressed = _compressionService.compress(bytes: file.originalBytes);
    final thumb = _compressionService.generateThumbnail(bytes: compressed.data);

    final thumbUrl = await _storageService.uploadThumbnail(
      salonId: salonId,
      category: ImageConstants.coverFolder,
      data: thumb.data,
    );

    final uploadInfo = _storageService.uploadImage(
      salonId: salonId,
      category: ImageConstants.coverFolder,
      data: compressed.data,
    );

    final aw = _storageService.getProgress(uploadInfo.taskId).listen((p) {
      final ctrl = _progressControllers[uploadInfo.taskId];
      if (ctrl != null && !ctrl.isClosed) ctrl.add(p);
    });

    final downloadUrl = await uploadInfo.completer.future;
    aw.cancel();

    final meta = ImageMetadata(
      id: _uuid.v4(),
      thumbnailUrl: thumbUrl,
      downloadUrl: downloadUrl,
      createdAt: DateTime.now(),
      uploadedBy: ownerId,
      storagePath: uploadInfo.storagePath,
    );

    await _db.collection('salons').doc(salonId).update({
      'coverImage': meta.toMap(),
      'shopPhotoUrl': downloadUrl,
    });

    return meta;
  }

  @override
  Future<List<ImageMetadata>> uploadGalleryImages({
    required String salonId,
    required String ownerId,
    required List<UploadTaskFile> files,
  }) async {
    final results = <ImageMetadata>[];
    final docRef = _db.collection('salons').doc(salonId);

    for (var i = 0; i < files.length; i++) {
      final f = files[i];
      final compressed = _compressionService.compress(bytes: f.originalBytes);
      final thumb = _compressionService.generateThumbnail(bytes: compressed.data);

      final thumbUrl = await _storageService.uploadThumbnail(
        salonId: salonId,
        category: ImageConstants.galleryFolder,
        data: thumb.data,
      );

      final uploadInfo = _storageService.uploadImage(
        salonId: salonId,
        category: ImageConstants.galleryFolder,
        data: compressed.data,
      );

      final downloadUrl = await uploadInfo.completer.future;

      final meta = ImageMetadata(
        id: _uuid.v4(),
        thumbnailUrl: thumbUrl,
        downloadUrl: downloadUrl,
        sortOrder: DateTime.now().millisecondsSinceEpoch,
        createdAt: DateTime.now(),
        uploadedBy: ownerId,
        storagePath: uploadInfo.storagePath,
      );
      results.add(meta);
    }

    final existingDoc = await docRef.get();
    final existingGallery = (existingDoc.data()?['gallery'] as List<dynamic>?)?.cast<Map<String, dynamic>>() ?? [];
    final allGallery = existingGallery + results.map((m) => m.toMap()).toList();
    await docRef.update({'gallery': allGallery});

    return results;
  }

  @override
  Future<List<ImageMetadata>> uploadServiceImages({
    required String salonId,
    required String serviceId,
    required String ownerId,
    required List<UploadTaskFile> files,
  }) async {
    final results = <ImageMetadata>[];
    final docRef = _db.collection('salons').doc(salonId);

    for (var i = 0; i < files.length; i++) {
      final f = files[i];
      final compressed = _compressionService.compress(bytes: f.originalBytes);
      final thumb = _compressionService.generateThumbnail(bytes: compressed.data);

      final thumbUrl = await _storageService.uploadThumbnail(
        salonId: salonId,
        category: ImageConstants.servicesFolder,
        data: thumb.data,
        serviceId: serviceId,
      );

      final uploadInfo = _storageService.uploadImage(
        salonId: salonId,
        category: ImageConstants.servicesFolder,
        data: compressed.data,
        serviceId: serviceId,
      );

      final downloadUrl = await uploadInfo.completer.future;

      final meta = ImageMetadata(
        id: _uuid.v4(),
        thumbnailUrl: thumbUrl,
        downloadUrl: downloadUrl,
        sortOrder: i,
        createdAt: DateTime.now(),
        uploadedBy: ownerId,
        storagePath: uploadInfo.storagePath,
      );
      results.add(meta);
    }

    final existingDoc = await docRef.get();
    final servicesList = (existingDoc.data()?['services'] as List<dynamic>?)?.cast<Map<String, dynamic>>() ?? [];
    var updated = false;

    for (var j = 0; j < servicesList.length; j++) {
      if (servicesList[j]['id'] == serviceId) {
        final existingImages = (servicesList[j]['serviceImages'] as List<dynamic>?)?.cast<Map<String, dynamic>>() ?? [];
        servicesList[j]['serviceImages'] = existingImages + results.map((m) => m.toMap()).toList();
        servicesList[j]['photoUrl'] = results.first.downloadUrl;
        updated = true;
        break;
      }
    }

    if (!updated) {
      final hasService = servicesList.any((s) => (s['id'] as String?) == serviceId);
      if (!hasService) {
        servicesList.add({
          'id': serviceId,
          'serviceImages': results.map((m) => m.toMap()).toList(),
          'photoUrl': results.first.downloadUrl,
        });
      }
    }

    await docRef.update({'services': servicesList});

    return results;
  }

  @override
  Future<void> deleteImage({
    required String salonId,
    required String storagePath,
    String? serviceId,
  }) async {
    await _storageService.deleteFile(storagePath);
  }

  @override
  Future<void> deleteGalleryImage({
    required String salonId,
    required int index,
  }) async {
    final docRef = _db.collection('salons').doc(salonId);
    final doc = await docRef.get();
    final gallery = List<Map<String, dynamic>>.from(
      (doc.data()?['gallery'] as List<dynamic>?)?.cast<Map<String, dynamic>>() ?? [],
    );

    if (index < 0 || index >= gallery.length) return;

    final item = ImageMetadata.fromMap(gallery[index]);
    if (item.storagePath.isNotEmpty) {
      await _storageService.deleteFile(item.storagePath);
    }

    gallery.removeAt(index);
    await docRef.update({'gallery': gallery});
  }

  @override
  Future<void> reorderGalleryImages({
    required String salonId,
    required int oldIndex,
    required int newIndex,
  }) async {
    final docRef = _db.collection('salons').doc(salonId);
    final doc = await docRef.get();
    final gallery = List<Map<String, dynamic>>.from(
      (doc.data()?['gallery'] as List<dynamic>?)?.cast<Map<String, dynamic>>() ?? [],
    );

    if (oldIndex < 0 || oldIndex >= gallery.length) return;
    if (newIndex < 0 || newIndex >= gallery.length) return;

    final item = gallery.removeAt(oldIndex);
    gallery.insert(newIndex, item);
    await docRef.update({'gallery': gallery});
  }

  @override
  Future<void> setCoverImage({
    required String salonId,
    required String imageUrl,
  }) async {
    await _db.collection('salons').doc(salonId).update({
      'shopPhotoUrl': imageUrl,
    });
  }

  @override
  Stream<double> getUploadProgress(String taskId) {
    final ctrl = _progressControllers[taskId];
    if (ctrl != null) return ctrl.stream;

    final newCtrl = StreamController<double>.broadcast();
    _progressControllers[taskId] = newCtrl;
    return newCtrl.stream;
  }

  @override
  Future<void> retryUpload(String taskId) async {
    final task = _storageService.getTask(taskId);
    if (task == null) return;
    task.completer.future;
  }

  @override
  void cancelUpload(String taskId) {
    _storageService.cancelUpload(taskId);
  }

  void dispose() {
    for (final ctrl in _progressControllers.values) {
      if (!ctrl.isClosed) ctrl.close();
    }
    _progressControllers.clear();
    _storageService.dispose();
  }
}
