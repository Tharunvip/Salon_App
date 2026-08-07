import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../design_system.dart';
import '../../../firebase_service.dart';
import '../../../models.dart';
import '../../../widgets/premium_button.dart';
import '../../domain/image_metadata.dart';
import '../widgets/image_viewer.dart';

class OwnerGalleryScreen extends StatefulWidget {
  final Shop shop;
  final String ownerId;

  const OwnerGalleryScreen({
    super.key,
    required this.shop,
    required this.ownerId,
  });

  @override
  State<OwnerGalleryScreen> createState() => _OwnerGalleryScreenState();
}

class _OwnerGalleryScreenState extends State<OwnerGalleryScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final svc = FirebaseService();
  final _picker = ImagePicker();
  bool _loading = false;
  bool _uploadingCover = false;
  late String _coverUrl;
  late List<ImageMetadata> _galleryItems;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _coverUrl = widget.shop.shopPhotoUrl;
    _galleryItems = _parseGallery();
  }

  List<ImageMetadata> _parseGallery() {
    final raw = widget.shop.gallery;
    final items = raw.map((e) {
      if (e is Map<String, dynamic>) return ImageMetadata.fromMap(e);
      if (e is String) {
        return ImageMetadata(
          id: e,
          thumbnailUrl: e,
          downloadUrl: e,
          createdAt: DateTime.now(),
          uploadedBy: widget.ownerId,
        );
      }
      return null;
    }).whereType<ImageMetadata>().toList();
    items.sort((a, b) {
      if (a.pinned && !b.pinned) return -1;
      if (!a.pinned && b.pinned) return 1;
      return 0;
    });
    return items;
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final d = DS.isDark(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gallery Management', style: TextStyle(fontWeight: FontWeight.w800)),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Column(children: [
        Container(
          color: DS.surfaceC(context),
          child: TabBar(
            controller: _tabController,
            indicatorColor: DS.primary,
            labelColor: DS.primary,
            unselectedLabelColor: d ? DS.darkMuted : DS.muted,
            tabs: const [
              Tab(icon: Icon(Icons.photo_camera), text: 'Cover'),
              Tab(icon: Icon(Icons.photo_library), text: 'Gallery'),
            ],
          ),
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildCoverTab(d),
              _buildGalleryTab(d),
            ],
          ),
        ),
      ]),
    );
  }

  Widget _buildCoverTab(bool isDark) {
    final coverUrl = _coverUrl;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(children: [
        Container(
          height: 220,
          width: double.infinity,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(DS.rXl),
            boxShadow: [DS.shadowMd],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(DS.rXl),
            child: coverUrl.isNotEmpty
                ? CachedNetworkImage(
                    imageUrl: coverUrl,
                    width: double.infinity,
                    height: 220,
                    fit: BoxFit.cover,
                    placeholder: (_, _) => _skeleton(220),
                    errorWidget: (_, _, _) => _placeholder(220),
                  )
                : _placeholder(220),
          ),
        ),
        const SizedBox(height: 20),
        _uploadingCover
            ? const Padding(padding: EdgeInsets.all(12), child: CircularProgressIndicator())
            : PButton(
                text: coverUrl.isEmpty ? 'Upload Cover Photo' : 'Change Cover Photo',
                icon: Icons.add_photo_alternate,
                isOutlined: true,
                onPressed: _pickCoverImage,
              ),
      ]),
    );
  }

  Widget _buildGalleryTab(bool isDark) {
    final gallery = _galleryItems;
    return Column(children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: Row(children: [
            Expanded(
              child: Text(
                gallery.isEmpty
                    ? '0 photos'
                    : '${gallery.length} photo${gallery.length != 1 ? 's' : ''}${gallery.any((e) => e.pinned) ? ' (${gallery.where((e) => e.pinned).length} pinned)' : ''}',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: DS.inkC(context)),
              ),
            ),
          if (!_loading)
            SizedBox(
              width: 148,
              height: 36,
              child: PButton(
                text: 'Add Photos',
                icon: Icons.add_a_photo,
                isOutlined: true,
                expanded: true,
                horizontalPadding: 12,
                onPressed: _pickGalleryImages,
              ),
            ),
        ]),
      ),
      const SizedBox(height: 12),
      Expanded(
        child: gallery.isEmpty
            ? Center(
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.photo_library_outlined, size: 64, color: isDark ? DS.darkMuted : DS.muted),
                  const SizedBox(height: 12),
                  Text('No gallery photos yet', style: TextStyle(color: isDark ? DS.darkMuted : DS.muted, fontWeight: FontWeight.w500)),
                  const SizedBox(height: 4),
                  Text('Tap "Add Photos" to upload', style: TextStyle(color: isDark ? DS.darkMuted : DS.muted, fontSize: 13)),
                ]),
              )
            : GridView.builder(
                padding: const EdgeInsets.all(16),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                ),
                itemCount: gallery.length,
                itemBuilder: (context, index) {
                  final img = gallery[index];
                  final thumb = img.thumbnailUrl.isNotEmpty ? img.thumbnailUrl : img.downloadUrl;
                  return GestureDetector(
                    onTap: () => _openViewer(index),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(DS.rMd),
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          CachedNetworkImage(
                            imageUrl: thumb,
                            fit: BoxFit.cover,
                            placeholder: (_, _) => Container(color: Colors.grey.shade200),
                            errorWidget: (_, _, _) => Container(
                              color: Colors.grey.shade200,
                              child: const Icon(Icons.broken_image, color: Colors.grey),
                            ),
                          ),
                          if (img.pinned)
                            Positioned(top: 6, left: 6,
                              child: Container(
                                padding: const EdgeInsets.all(3),
                                decoration: const BoxDecoration(color: DS.primary, shape: BoxShape.circle),
                                child: const Icon(Icons.push_pin, color: Colors.white, size: 11),
                              ),
                            ),
                          Positioned(top: 0, right: 0,
                            child: GestureDetector(
                              behavior: HitTestBehavior.opaque,
                              onTap: () => _deleteImage(index),
                              child: Container(
                                padding: const EdgeInsets.all(10),
                                decoration: const BoxDecoration(color: Colors.black45, borderRadius: BorderRadius.only(bottomLeft: Radius.circular(12))),
                                child: const Icon(Icons.delete_outline, color: Colors.white, size: 16),
                              ),
                            ),
                          ),
                          Positioned(bottom: 0, left: 0,
                            child: GestureDetector(
                              behavior: HitTestBehavior.opaque,
                              onTap: () => _togglePin(index),
                              child: Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: img.pinned ? DS.primary.withValues(alpha: 0.9) : Colors.black45,
                                  borderRadius: const BorderRadius.only(topRight: Radius.circular(12)),
                                ),
                                child: Icon(
                                  img.pinned ? Icons.push_pin : Icons.push_pin_outlined,
                                  color: Colors.white,
                                  size: 16,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
      ),
      if (_loading)
        const Padding(
          padding: EdgeInsets.all(16),
          child: LinearProgressIndicator(),
        ),
    ]);
  }

  Future<void> _pickCoverImage() async {
    setState(() => _uploadingCover = true);
    try {
      final picked = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 60, maxWidth: 1920);
      if (picked == null) return;
      final bytes = await picked.readAsBytes();
      final url = await svc.uploadImageBytes(bytes: bytes, folder: 'salon_covers');
      await svc.db.collection('shops').doc(widget.ownerId).update({
        'shopPhotoUrl': url,
      });
      if (mounted) {
        setState(() => _coverUrl = url);
        _showSnack('Cover photo updated');
      }
    } catch (e) {
      if (mounted) _showSnack('Failed to upload cover: $e');
    } finally {
      if (mounted) setState(() => _uploadingCover = false);
    }
  }

  Future<void> _pickGalleryImages() async {
    setState(() => _loading = true);
    try {
      final picked = await _picker.pickMultiImage(imageQuality: 60, maxWidth: 1920);
      if (picked.isEmpty) return;

      final uploaded = <ImageMetadata>[];
      for (final p in picked) {
        final bytes = await p.readAsBytes();
        final url = await svc.uploadImageBytes(bytes: bytes, folder: 'salon_gallery');
        uploaded.add(ImageMetadata(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          downloadUrl: url,
          thumbnailUrl: url,
          createdAt: DateTime.now(),
          uploadedBy: widget.ownerId,
        ));
      }

      final doc = await svc.db.collection('shops').doc(widget.ownerId).get();
      final existing = List<Map<String, dynamic>>.from(
        (doc.data()?['gallery'] as List<dynamic>?)?.cast<Map<String, dynamic>>() ?? [],
      );
      existing.addAll(uploaded.map((e) => e.toMap()));
      await svc.db.collection('shops').doc(widget.ownerId).update({'gallery': existing});

      if (mounted) {
        setState(() => _galleryItems = [..._galleryItems, ...uploaded]);
        _showSnack('${uploaded.length} photo${uploaded.length != 1 ? 's' : ''} uploaded');
      }
    } catch (e) {
      if (mounted) _showSnack('Upload failed: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _deleteImage(int index) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Photo'),
        content: const Text('Are you sure you want to delete this photo?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete', style: TextStyle(color: DS.error)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    if (index < 0 || index >= _galleryItems.length) return;

    _galleryItems.removeAt(index);
    final raw = _galleryItems.map((e) => e.toMap()).toList();
    await svc.db.collection('shops').doc(widget.ownerId).update({'gallery': raw});
    if (mounted) {
      setState(() {});
      _showSnack('Photo deleted');
    }
  }

  Future<void> _togglePin(int index) async {
    if (index < 0 || index >= _galleryItems.length) return;
    final item = _galleryItems[index];
    final newPinned = !item.pinned;
    _galleryItems[index] = item.copyWith(pinned: newPinned);
    _galleryItems.sort((a, b) {
      if (a.pinned && !b.pinned) return -1;
      if (!a.pinned && b.pinned) return 1;
      return 0;
    });
    final raw = _galleryItems.map((e) => e.toMap()).toList();
    await svc.db.collection('shops').doc(widget.ownerId).update({'gallery': raw});
    if (mounted) {
      setState(() {});
      _showSnack(newPinned ? 'Image pinned' : 'Image unpinned');
    }
  }

  void _openViewer(int index) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ImageViewer(images: _galleryItems, initialIndex: index),
      ),
    );
  }

  void _showSnack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), behavior: SnackBarBehavior.floating),
    );
  }

  Widget _skeleton(double h) => Container(
    height: h,
    color: Colors.grey.shade300,
    child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
  );

  Widget _placeholder(double h) => Container(
    height: h,
    color: Colors.grey.shade200,
    child: const Center(
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Icon(Icons.image_outlined, size: 48, color: Colors.grey),
        SizedBox(height: 8),
        Text('No cover image', style: TextStyle(color: Colors.grey)),
      ]),
    ),
  );
}
