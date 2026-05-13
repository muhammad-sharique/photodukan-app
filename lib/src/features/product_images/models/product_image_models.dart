class ProductImageStyleOption {
  const ProductImageStyleOption({
    required this.key,
    required this.description,
  });

  final String key;
  final String description;
}

class ProductImageAsset {
  const ProductImageAsset({
    required this.id,
    required this.imageUrl,
    required this.originalName,
    required this.mimeType,
    required this.byteSize,
    required this.createdAt,
  });

  factory ProductImageAsset.fromMap(Map<String, dynamic> json) {
    return ProductImageAsset(
      id: (json['id'] as num).toInt(),
      imageUrl: json['imageUrl']?.toString() ?? '',
      originalName: json['originalName']?.toString() ?? 'Product photo',
      mimeType: json['mimeType']?.toString() ?? 'image/jpeg',
      byteSize: (json['byteSize'] as num?)?.toInt() ?? 0,
      createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? ''),
    );
  }

  final int id;
  final String imageUrl;
  final String originalName;
  final String mimeType;
  final int byteSize;
  final DateTime? createdAt;
}

class ProductImageGeneration {
  const ProductImageGeneration({
    required this.id,
    required this.assetId,
    required this.style,
    required this.status,
    required this.imageUrl,
    required this.errorMessage,
    required this.createdAt,
    required this.completedAt,
    required this.asset,
  });

  factory ProductImageGeneration.fromMap(Map<String, dynamic> json) {
    return ProductImageGeneration(
      id: (json['id'] as num).toInt(),
      assetId: (json['assetId'] as num).toInt(),
      style: json['style']?.toString() ?? 'professional',
      status: json['status']?.toString() ?? 'pending',
      imageUrl: json['imageUrl']?.toString(),
      errorMessage: json['errorMessage']?.toString(),
      createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? ''),
      completedAt: DateTime.tryParse(json['completedAt']?.toString() ?? ''),
      asset: json['asset'] is Map<String, dynamic>
          ? ProductImageAsset.fromMap(json['asset'] as Map<String, dynamic>)
          : null,
    );
  }

  final int id;
  final int assetId;
  final String style;
  final String status;
  final String? imageUrl;
  final String? errorMessage;
  final DateTime? createdAt;
  final DateTime? completedAt;
  final ProductImageAsset? asset;

  bool get hasImage => status == 'completed' && imageUrl != null && imageUrl!.isNotEmpty;
}