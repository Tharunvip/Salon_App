import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../domain/image_metadata.dart';

class CustomerGalleryScreen extends StatefulWidget {
  final String shopName;
  final String coverImageUrl;
  final List<ImageMetadata> gallery;

  const CustomerGalleryScreen({
    super.key,
    required this.shopName,
    required this.coverImageUrl,
    required this.gallery,
  });

  @override
  State<CustomerGalleryScreen> createState() => _CustomerGalleryScreenState();
}

class _CustomerGalleryScreenState extends State<CustomerGalleryScreen> {
  late PageController _pageController;
  int _currentPage = 0;

  List<ImageMetadata> get _allImages {
    final list = <ImageMetadata>[];
    if (widget.coverImageUrl.isNotEmpty) {
      list.add(ImageMetadata(
        id: 'cover',
        thumbnailUrl: widget.coverImageUrl,
        downloadUrl: widget.coverImageUrl,
        createdAt: DateTime.now(),
        uploadedBy: '',
      ));
    }
    final sorted = List<ImageMetadata>.from(widget.gallery);
    sorted.sort((a, b) {
      if (a.pinned && !b.pinned) return -1;
      if (!a.pinned && b.pinned) return 1;
      return 0;
    });
    list.addAll(sorted);
    return list;
  }

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final images = _allImages;
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        elevation: 0,
        title: Text(widget.shopName, style: const TextStyle(fontWeight: FontWeight.w700)),
        actions: [
          Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${_currentPage + 1}/${images.length}',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13),
              ),
            ),
          ),
          const SizedBox(width: 12),
        ],
      ),
      body: images.isEmpty
          ? const Center(child: Text('No images', style: TextStyle(color: Colors.white54)))
          : PageView.builder(
              controller: _pageController,
              onPageChanged: (i) => setState(() => _currentPage = i),
              itemCount: images.length,
              itemBuilder: (context, index) {
                final img = images[index];
                return InteractiveViewer(
                  minScale: 0.5,
                  maxScale: 5.0,
                  child: Center(
                    child: CachedNetworkImage(
                      imageUrl: img.downloadUrl,
                      fit: BoxFit.contain,
                      placeholder: (_, _) => const Center(
                        child: CircularProgressIndicator(color: Colors.white54),
                      ),
                      errorWidget: (_, _, _) => const Center(
                        child: Icon(Icons.broken_image_outlined, color: Colors.white38, size: 48),
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }
}
