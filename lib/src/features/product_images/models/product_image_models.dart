class ProductImageStyleOption {
  const ProductImageStyleOption({
    required this.key,
    required this.description,
  });

  final String key;
  final String description;

  String get label => key[0].toUpperCase() + key.substring(1);
}

class ProductImageAsset {
  const ProductImageAsset({
    required this.id,
    required this.productId,
    required this.imageUrl,
    required this.originalName,
    required this.mimeType,
    required this.byteSize,
    required this.description,
    required this.createdAt,
  });

  factory ProductImageAsset.fromMap(Map<String, dynamic> json) {
    return ProductImageAsset(
      id: (json['id'] as num).toInt(),
      productId: (json['productId'] as num?)?.toInt(),
      imageUrl: json['imageUrl']?.toString() ?? '',
      originalName: json['originalName']?.toString() ?? 'Product photo',
      mimeType: json['mimeType']?.toString() ?? 'image/jpeg',
      byteSize: (json['byteSize'] as num?)?.toInt() ?? 0,
      description: json['description']?.toString(),
      createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? ''),
    );
  }

  final int id;
  final int? productId;
  final String imageUrl;
  final String originalName;
  final String mimeType;
  final int byteSize;
  final String? description;
  final DateTime? createdAt;
}

class ProductImageGeneration {
  const ProductImageGeneration({
    required this.id,
    required this.productId,
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
      productId: (json['productId'] as num?)?.toInt(),
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
  final int? productId;
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

class ProductSummary {
  const ProductSummary({
    required this.id,
    required this.uid,
    required this.name,
    required this.description,
    required this.coverImageUrl,
    required this.assetCount,
    required this.generationCount,
    required this.latestAsset,
    required this.latestGeneration,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ProductSummary.fromMap(Map<String, dynamic> json) {
    return ProductSummary(
      id: (json['id'] as num).toInt(),
      uid: json['uid']?.toString(),
      name: json['name']?.toString(),
      description: json['description']?.toString(),
      coverImageUrl: json['coverImageUrl']?.toString(),
      assetCount: (json['assetCount'] as num?)?.toInt() ?? 0,
      generationCount: (json['generationCount'] as num?)?.toInt() ?? 0,
      latestAsset: json['coverAsset'] is Map<String, dynamic>
          ? ProductImageAsset.fromMap(json['coverAsset'] as Map<String, dynamic>)
          : null,
      latestGeneration: json['latestGeneration'] is Map<String, dynamic>
          ? ProductImageGeneration.fromMap(json['latestGeneration'] as Map<String, dynamic>)
          : null,
      createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? ''),
      updatedAt: DateTime.tryParse(json['updatedAt']?.toString() ?? ''),
    );
  }

  final int id;
  final String? uid;
  final String? name;
  final String? description;
  final String? coverImageUrl;
  final int assetCount;
  final int generationCount;
  final ProductImageAsset? latestAsset;
  final ProductImageGeneration? latestGeneration;
  final DateTime? createdAt;
  final DateTime? updatedAt;
}

class ProductDetail extends ProductSummary {
  const ProductDetail({
    required super.id,
    required super.uid,
    required super.name,
    required super.description,
    required super.coverImageUrl,
    required super.assetCount,
    required super.generationCount,
    required super.latestAsset,
    required super.latestGeneration,
    required super.createdAt,
    required super.updatedAt,
    required this.assets,
    required this.generations,
  });

  factory ProductDetail.fromMap(Map<String, dynamic> json) {
    final summary = ProductSummary.fromMap(json);
    final assetItems = json['assets'] as List<dynamic>? ?? const [];
    final generationItems = json['generations'] as List<dynamic>? ?? const [];

    return ProductDetail(
      id: summary.id,
      uid: summary.uid,
      name: summary.name,
      description: summary.description,
      coverImageUrl: summary.coverImageUrl,
      assetCount: summary.assetCount,
      generationCount: summary.generationCount,
      latestAsset: summary.latestAsset,
      latestGeneration: summary.latestGeneration,
      createdAt: summary.createdAt,
      updatedAt: summary.updatedAt,
      assets: assetItems
          .whereType<Map<String, dynamic>>()
          .map(ProductImageAsset.fromMap)
          .toList(),
      generations: generationItems
          .whereType<Map<String, dynamic>>()
          .map(ProductImageGeneration.fromMap)
          .toList(),
    );
  }

  final List<ProductImageAsset> assets;
  final List<ProductImageGeneration> generations;
}

class CreditSummary {
  const CreditSummary({
    required this.balance,
    required this.quickTopups,
    required this.updatedAt,
  });

  factory CreditSummary.fromMap(Map<String, dynamic> json) {
    final quickTopupItems = json['quickTopups'] as List<dynamic>? ?? const [];

    return CreditSummary(
      balance: (json['balance'] as num?)?.toInt() ?? 0,
      quickTopups: quickTopupItems.whereType<num>().map((value) => value.toInt()).toList(),
      updatedAt: DateTime.tryParse(json['updatedAt']?.toString() ?? ''),
    );
  }

  final int balance;
  final List<int> quickTopups;
  final DateTime? updatedAt;
}