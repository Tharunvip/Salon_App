class ImageMetadata {
  final String id;
  final String thumbnailUrl;
  final String downloadUrl;
  final int sortOrder;
  final DateTime createdAt;
  final String uploadedBy;
  final String storagePath;
  final bool pinned;

  const ImageMetadata({
    required this.id,
    required this.thumbnailUrl,
    required this.downloadUrl,
    this.sortOrder = 0,
    required this.createdAt,
    required this.uploadedBy,
    this.storagePath = '',
    this.pinned = false,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'thumbnailUrl': thumbnailUrl,
    'downloadUrl': downloadUrl,
    'sortOrder': sortOrder,
    'createdAt': createdAt.toIso8601String(),
    'uploadedBy': uploadedBy,
    'storagePath': storagePath,
    'pinned': pinned,
  };

  factory ImageMetadata.fromMap(Map<String, dynamic> data) => ImageMetadata(
    id: (data['id'] as String?) ?? '',
    thumbnailUrl: (data['thumbnailUrl'] as String?) ?? '',
    downloadUrl: (data['downloadUrl'] as String?) ?? '',
    sortOrder: (data['sortOrder'] as num?)?.toInt() ?? 0,
    createdAt: data['createdAt'] != null
        ? DateTime.tryParse(data['createdAt'] as String) ?? DateTime.now()
        : DateTime.now(),
    uploadedBy: (data['uploadedBy'] as String?) ?? '',
    storagePath: (data['storagePath'] as String?) ?? '',
    pinned: (data['pinned'] as bool?) ?? false,
  );

  ImageMetadata copyWith({
    String? id,
    String? thumbnailUrl,
    String? downloadUrl,
    int? sortOrder,
    DateTime? createdAt,
    String? uploadedBy,
    String? storagePath,
    bool? pinned,
  }) => ImageMetadata(
    id: id ?? this.id,
    thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
    downloadUrl: downloadUrl ?? this.downloadUrl,
    sortOrder: sortOrder ?? this.sortOrder,
    createdAt: createdAt ?? this.createdAt,
    uploadedBy: uploadedBy ?? this.uploadedBy,
    storagePath: storagePath ?? this.storagePath,
    pinned: pinned ?? this.pinned,
  );
}
