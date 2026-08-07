import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

class CacheService {
  CacheService._();

  static CachedNetworkImageProvider provider(String url, {int? maxWidth, int? maxHeight}) {
    return CachedNetworkImageProvider(url, maxWidth: maxWidth ?? 960, maxHeight: maxHeight ?? 540, cacheKey: url);
  }

  static Widget cachedImage(String url, {double? width, double? height, BoxFit fit = BoxFit.cover, double borderRadius = 0}) {
    if (url.isEmpty) return _placeholder(width, height);
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: CachedNetworkImage(
        imageUrl: url,
        width: width,
        height: height,
        fit: fit,
        placeholder: (_, _) => _placeholder(width, height),
        errorWidget: (_, _, _) => _placeholder(width, height),
        fadeInDuration: const Duration(milliseconds: 200),
        fadeOutDuration: const Duration(milliseconds: 100),
      ),
    );
  }

  static Widget _placeholder(double? w, double? h) {
    return Container(
      width: w,
      height: h,
      color: Colors.grey.shade200,
      child: const Center(child: Icon(Icons.image_outlined, color: Colors.grey, size: 32)),
    );
  }
}
