import '../domain/image_metadata.dart';
import '../presentation/cubit/upload_state.dart';

abstract class ImageRepository {
  Future<ImageMetadata> uploadCoverImage({
    required String salonId,
    required String ownerId,
    required UploadTaskFile file,
  });

  Future<List<ImageMetadata>> uploadGalleryImages({
    required String salonId,
    required String ownerId,
    required List<UploadTaskFile> files,
  });

  Future<List<ImageMetadata>> uploadServiceImages({
    required String salonId,
    required String serviceId,
    required String ownerId,
    required List<UploadTaskFile> files,
  });

  Future<void> deleteImage({
    required String salonId,
    required String storagePath,
    String? serviceId,
  });

  Future<void> deleteGalleryImage({
    required String salonId,
    required int index,
  });

  Future<void> reorderGalleryImages({
    required String salonId,
    required int oldIndex,
    required int newIndex,
  });

  Future<void> setCoverImage({
    required String salonId,
    required String imageUrl,
  });

  Stream<double> getUploadProgress(String taskId);

  Future<void> retryUpload(String taskId);

  void cancelUpload(String taskId);
}
