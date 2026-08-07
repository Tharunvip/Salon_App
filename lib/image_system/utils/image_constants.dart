class ImageConstants {
  ImageConstants._();

  static const int maxWidth = 1920;
  static const int maxHeight = 1080;
  static const int thumbnailSize = 300;
  static const int quality = 85;
  static const int minFileSizeBytes = 300 * 1024;
  static const int maxFileSizeBytes = 800 * 1024;
  static const int maxGalleryCount = 30;
  static const int maxUploadConcurrency = 3;
  static const Duration uploadTimeout = Duration(seconds: 120);

  static const String storageRoot = 'salons';
  static const String coverFolder = 'cover';
  static const String galleryFolder = 'gallery';
  static const String servicesFolder = 'services';
  static const String thumbnailSuffix = '_thumb';
}
