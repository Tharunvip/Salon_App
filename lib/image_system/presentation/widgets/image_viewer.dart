import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../domain/image_metadata.dart';

class ImageViewer extends StatefulWidget {
  final List<ImageMetadata> images;
  final int initialIndex;

  const ImageViewer({
    super.key,
    required this.images,
    this.initialIndex = 0,
  });

  @override
  State<ImageViewer> createState() => _ImageViewerState();
}

class _ImageViewerState extends State<ImageViewer> with SingleTickerProviderStateMixin {
  late PageController _pageController;
  late int _currentIndex;
  late AnimationController _animController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: _currentIndex);
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _fadeAnimation = CurvedAnimation(parent: _animController, curve: Curves.easeIn);
    _animController.forward();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text('${_currentIndex + 1} / ${widget.images.length}'),
        elevation: 0,
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: PageView.builder(
            controller: _pageController,
            onPageChanged: (i) => setState(() => _currentIndex = i),
            itemCount: widget.images.length,
            itemBuilder: (context, index) {
              final img = widget.images[index];
              return InteractiveViewer(
                minScale: 0.5,
                maxScale: 5.0,
                child: Center(
                  child: CachedNetworkImage(
                    imageUrl: img.downloadUrl,
                    fit: BoxFit.contain,
                    placeholder: (_, _) => const Center(
                      child: CircularProgressIndicator(color: Colors.white),
                    ),
                    errorWidget: (_, _, _) => const Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.broken_image_outlined, color: Colors.white54, size: 48),
                          SizedBox(height: 8),
                          Text('Failed to load image', style: TextStyle(color: Colors.white54)),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
