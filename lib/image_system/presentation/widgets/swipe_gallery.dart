import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../theme/app_theme.dart';
import '../../domain/image_metadata.dart';
import 'image_viewer.dart';

class SwipeGallery extends StatefulWidget {
  final List<ImageMetadata> images;
  final double height;
  final bool showIndicators;
  final bool enableFullScreen;

  const SwipeGallery({
    super.key,
    required this.images,
    this.height = 240,
    this.showIndicators = true,
    this.enableFullScreen = true,
  });

  @override
  State<SwipeGallery> createState() => SwipeGalleryState();
}

class SwipeGalleryState extends State<SwipeGallery> {
  final _pageController = PageController();
  int _currentPage = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  List<ImageMetadata> get _images => widget.images;

  @override
  Widget build(BuildContext context) {
    if (_images.isEmpty) return const SizedBox.shrink();

    return Column(children: [
      SizedBox(
        height: widget.height,
        child: Stack(children: [
          PageView.builder(
            controller: _pageController,
            onPageChanged: (i) => setState(() => _currentPage = i),
            itemCount: _images.length,
            itemBuilder: (context, index) {
              final img = _images[index];
              return GestureDetector(
                onTap: widget.enableFullScreen
                    ? () => _openViewer(context, index)
                    : null,
                child: CachedNetworkImage(
                  imageUrl: img.thumbnailUrl.isNotEmpty ? img.thumbnailUrl : img.downloadUrl,
                  width: double.infinity,
                  height: widget.height,
                  fit: BoxFit.cover,
                  placeholder: (_, _) => _skeleton,
                  errorWidget: (_, _, _) => _placeholder,
                ),
              );
            },
          ),
          if (_images.length > 1)
            Positioned(
              left: 0, right: 0, bottom: 12,
              child: _buildIndicators(),
            ),
          if (_images.length > 1) ...[
            Positioned(left: 8, top: 0, bottom: 0,
              child: Center(
                child: IconButton(
                  icon: const Icon(Icons.chevron_left, color: Colors.white, size: 28),
                  onPressed: _currentPage > 0
                      ? () => _pageController.previousPage(duration: const Duration(milliseconds: 300), curve: Curves.easeOut)
                      : null,
                ),
              ),
            ),
            Positioned(right: 8, top: 0, bottom: 0,
              child: Center(
                child: IconButton(
                  icon: const Icon(Icons.chevron_right, color: Colors.white, size: 28),
                  onPressed: _currentPage < _images.length - 1
                      ? () => _pageController.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeOut)
                      : null,
                ),
              ),
            ),
          ],
        ]),
      ),
    ]);
  }

  Widget _buildIndicators() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(_images.length, (i) {
        final isActive = i == _currentPage;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.symmetric(horizontal: 3),
          width: isActive ? 20 : 8,
          height: 8,
          decoration: BoxDecoration(
            color: isActive ? DesignSystem.primary : Colors.white.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(4),
          ),
        );
      }),
    );
  }

  Widget get _skeleton => Container(
    height: widget.height,
    color: Colors.grey.shade300,
  );

  Widget get _placeholder => Container(
    height: widget.height,
    color: Colors.grey.shade200,
    child: const Center(child: Icon(Icons.image_outlined, color: Colors.grey, size: 40)),
  );

  void _openViewer(BuildContext context, int index) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ImageViewer(
          images: _images,
          initialIndex: index,
        ),
      ),
    );
  }
}
