import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../theme/app_theme.dart';

class AppCachedImage extends StatelessWidget {
  final String imageUrl;
  final String? thumbnailUrl;
  final double? width;
  final double? height;
  final BoxFit fit;
  final double borderRadius;
  final Color? borderColor;
  final VoidCallback? onTap;
  final bool showShimmer;

  const AppCachedImage({
    super.key,
    required this.imageUrl,
    this.thumbnailUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.borderRadius = 0,
    this.borderColor,
    this.onTap,
    this.showShimmer = true,
  });

  @override
  Widget build(BuildContext context) {
    Widget image;
    if (imageUrl.isEmpty) {
      image = _placeholder;
    } else {
      image = CachedNetworkImage(
        imageUrl: imageUrl,
        width: width,
        height: height,
        fit: fit,
        placeholder: showShimmer ? (_, _) => _shimmerPlaceholder : (_, _) => _placeholder,
        errorWidget: (_, _, _) => _errorPlaceholder,
        fadeInDuration: const Duration(milliseconds: 200),
        fadeOutDuration: const Duration(milliseconds: 100),
        memCacheWidth: width != null ? (width! * 2).toInt() : null,
        memCacheHeight: height != null ? (height! * 2).toInt() : null,
      );
    }

    if (onTap != null || borderRadius > 0 || borderColor != null) {
      image = ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: image,
      );
      if (onTap != null) {
        image = GestureDetector(onTap: onTap, child: image);
      }
      if (borderColor != null) {
        image = Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(borderRadius),
            border: Border.all(color: borderColor!),
          ),
          child: image,
        );
      }
    }

    return image;
  }

  Widget get _placeholder => Container(
    width: width,
    height: height,
    color: Colors.grey.shade200,
    child: const Center(
      child: Icon(Icons.image_outlined, color: Colors.grey, size: 32),
    ),
  );

  Widget get _errorPlaceholder => Container(
    width: width,
    height: height,
    color: Colors.grey.shade200,
    child: const Center(
      child: Icon(Icons.broken_image_outlined, color: Colors.grey, size: 32),
    ),
  );

  Widget get _shimmerPlaceholder => Container(
    width: width,
    height: height,
    decoration: BoxDecoration(
      color: Colors.grey.shade200,
      borderRadius: BorderRadius.circular(borderRadius),
    ),
  );
}

class AppSkeletonImage extends StatefulWidget {
  final double? width;
  final double? height;
  final double borderRadius;
  final Color? baseColor;
  final Color? highlightColor;

  const AppSkeletonImage({
    super.key,
    this.width,
    this.height,
    this.borderRadius = DesignSystem.radiusLg,
    this.baseColor,
    this.highlightColor,
  });

  @override
  State<AppSkeletonImage> createState() => _AppSkeletonImageState();
}

class _AppSkeletonImageState extends State<AppSkeletonImage>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final base = widget.baseColor ?? (isDark ? Colors.grey.shade800 : Colors.grey.shade200);
    final highlight = widget.highlightColor ?? (isDark ? Colors.grey.shade700 : Colors.grey.shade100);

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(widget.borderRadius),
            gradient: LinearGradient(
              colors: [base, highlight, base],
              stops: const [0, 0.5, 1],
              begin: Alignment(-1, _controller.value * 2 - 1),
              end: Alignment(1, _controller.value * 2 - 1),
            ),
          ),
        );
      },
    );
  }
}
