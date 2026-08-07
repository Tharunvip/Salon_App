import 'dart:io';
import 'dart:typed_data';
import 'dart:math';
import 'package:image/image.dart' as img;
import '../utils/image_constants.dart';

class CompressionResult {
  final Uint8List data;
  final int width;
  final int height;
  final int sizeBytes;

  const CompressionResult({
    required this.data,
    required this.width,
    required this.height,
    required this.sizeBytes,
  });
}

class CompressionService {
  CompressionResult compress({
    required Uint8List bytes,
    int maxWidth = ImageConstants.maxWidth,
    int maxHeight = ImageConstants.maxHeight,
    int quality = ImageConstants.quality,
  }) {
    final image = img.decodeImage(bytes);
    if (image == null) throw Exception('Failed to decode image');

    final srcW = image.width;
    final srcH = image.height;

    double scale = 1;
    if (srcW > maxWidth || srcH > maxHeight) {
      final scaleW = maxWidth / srcW;
      final scaleH = maxHeight / srcH;
      scale = min(scaleW, scaleH);
    }

    final newW = (srcW * scale).round();
    final newH = (srcH * scale).round();

    final resized = img.copyResize(image, width: newW, height: newH);
    final data = img.encodeJpg(resized, quality: quality);

    return CompressionResult(
      data: data,
      width: newW,
      height: newH,
      sizeBytes: data.length,
    );
  }

  CompressionResult generateThumbnail({
    required Uint8List bytes,
    int size = ImageConstants.thumbnailSize,
    int quality = 70,
  }) {
    final image = img.decodeImage(bytes);
    if (image == null) throw Exception('Failed to decode thumbnail');

    final srcW = image.width;
    final srcH = image.height;
    final scale = size / max(srcW, srcH);
    final newW = (srcW * scale).round().clamp(1, size);
    final newH = (srcH * scale).round().clamp(1, size);

    final thumb = img.copyResize(image, width: newW, height: newH);
    final data = img.encodeJpg(thumb, quality: quality);

    return CompressionResult(
      data: data,
      width: newW,
      height: newH,
      sizeBytes: data.length,
    );
  }

  Future<CompressionResult> compressFile(File file) async {
    final bytes = await file.readAsBytes();
    return compress(bytes: bytes);
  }
}
