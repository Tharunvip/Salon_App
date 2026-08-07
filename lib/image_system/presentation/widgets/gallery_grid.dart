import 'package:flutter/material.dart';
import '../../../theme/app_theme.dart';
import '../../domain/image_metadata.dart';
import 'cached_image_widget.dart';

class GalleryGrid extends StatelessWidget {
  final List<ImageMetadata> images;
  final int crossAxisCount;
  final double spacing;
  final double ratio;
  final bool showShimmer;
  final void Function(ImageMetadata)? onTap;
  final void Function(ImageMetadata)? onLongPress;
  final Widget Function(ImageMetadata)? overlayBuilder;

  const GalleryGrid({
    super.key,
    required this.images,
    this.crossAxisCount = 3,
    this.spacing = 4,
    this.ratio = 1,
    this.showShimmer = true,
    this.onTap,
    this.onLongPress,
    this.overlayBuilder,
  });

  @override
  Widget build(BuildContext context) {
    if (images.isEmpty) {
      return Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.photo_library_outlined, size: 48, color: DesignSystem.muted),
          const SizedBox(height: 8),
          Text('No images yet', style: TextStyle(color: DesignSystem.muted, fontWeight: FontWeight.w500)),
        ]),
      );
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: spacing,
        mainAxisSpacing: spacing,
        childAspectRatio: ratio,
      ),
      itemCount: images.length,
      itemBuilder: (context, index) {
        final img = images[index];
        final thumb = img.thumbnailUrl.isNotEmpty ? img.thumbnailUrl : img.downloadUrl;

        return GestureDetector(
          onTap: onTap != null ? () => onTap!(img) : null,
          onLongPress: onLongPress != null ? () => onLongPress!(img) : null,
          child: Stack(
            fit: StackFit.expand,
            children: [
              AppCachedImage(
                imageUrl: thumb,
                width: double.infinity,
                height: double.infinity,
                fit: BoxFit.cover,
                showShimmer: showShimmer,
              ),
              if (overlayBuilder != null) overlayBuilder!(img),
            ],
          ),
        );
      },
    );
  }
}
