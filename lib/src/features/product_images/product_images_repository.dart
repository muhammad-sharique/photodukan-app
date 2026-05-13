import 'dart:typed_data';

import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:http_parser/http_parser.dart';
import 'package:mime/mime.dart';

import '../../services/api_client.dart';
import 'models/product_image_models.dart';

typedef IdTokenLoader = Future<String> Function({bool forceRefresh});

const Set<String> _supportedUploadMimeTypes = {
  'image/jpeg',
  'image/jpg',
  'image/png',
  'image/webp',
};

class ProductImagesRepository {
  ProductImagesRepository({
    required ApiClient apiClient,
    required IdTokenLoader loadIdToken,
  }) : _apiClient = apiClient,
       _loadIdToken = loadIdToken;

  final ApiClient _apiClient;
  final IdTokenLoader _loadIdToken;

  Future<List<ProductImageStyleOption>> fetchStyles() async {
    final response = await _apiClient.getJsonAuthorized(
      '/product-images/styles',
      idToken: await _loadIdToken(),
    );
    final data = response['data'] as Map<String, dynamic>;
    final descriptions = data['descriptions'] as Map<String, dynamic>? ?? const {};
    final styles = (data['styles'] as List<dynamic>? ?? const []);

    return styles.map((style) {
      final key = style.toString();
      return ProductImageStyleOption(
        key: key,
        description: descriptions[key]?.toString() ?? '',
      );
    }).toList();
  }

  Future<ProductImageAsset> uploadAsset(XFile file) async {
    final upload = await _prepareUpload(file);
    final response = await _apiClient.postMultipartAuthorized(
      '/product-images/assets',
      idToken: await _loadIdToken(),
      files: [
        ApiMultipartFile(
          fieldName: 'image',
          filename: upload.filename,
          bytes: upload.bytes,
          contentType: upload.contentType,
        ),
      ],
    );

    return ProductImageAsset.fromMap(response['data'] as Map<String, dynamic>);
  }

  Future<ProductImageGeneration> generateImage({
    required int assetId,
    required String style,
  }) async {
    final response = await _apiClient.postJsonAuthorized(
      '/product-images/generations',
      idToken: await _loadIdToken(),
      payload: {
        'assetId': assetId,
        'style': style,
      },
    );

    return ProductImageGeneration.fromMap(response['data'] as Map<String, dynamic>);
  }

  Future<List<ProductImageGeneration>> listRecentGenerations({int limit = 10}) async {
    final response = await _apiClient.getJsonAuthorized(
      '/product-images/generations',
      idToken: await _loadIdToken(),
      queryParameters: {
        'limit': '$limit',
      },
    );

    final items = response['data'] as List<dynamic>? ?? const [];
    return items
        .whereType<Map<String, dynamic>>()
        .map(ProductImageGeneration.fromMap)
        .toList();
  }

  Future<Map<String, String>> buildImageHeaders() async {
    final token = await _loadIdToken();
    return {
      'Authorization': 'Bearer $token',
    };
  }

  String resolveImageUrl(String relativePath) {
    return _apiClient.resolveUrl(relativePath);
  }

  Future<_PreparedUpload> _prepareUpload(XFile file) async {
    final bytes = await file.readAsBytes();
    final mimeType = _detectMimeType(file, bytes);

    if (mimeType != null && _supportedUploadMimeTypes.contains(mimeType)) {
      return _PreparedUpload(
        filename: file.name,
        bytes: bytes,
        contentType: MediaType.parse(mimeType),
      );
    }

    final convertedBytes = await FlutterImageCompress.compressWithFile(
      file.path,
      format: CompressFormat.jpeg,
      quality: 92,
      keepExif: true,
    );

    if (convertedBytes == null || convertedBytes.isEmpty) {
      throw const ProductImageUploadException(
        'This image format could not be converted for upload. Please try another photo.',
      );
    }

    return _PreparedUpload(
      filename: _replaceExtension(file.name, 'jpg'),
      bytes: convertedBytes,
      contentType: MediaType('image', 'jpeg'),
    );
  }

  String? _detectMimeType(XFile file, Uint8List bytes) {
    final headerBytes = bytes.length > 32 ? bytes.sublist(0, 32) : bytes;
    return lookupMimeType(file.path, headerBytes: headerBytes) ??
        lookupMimeType(file.name, headerBytes: headerBytes);
  }

  String _replaceExtension(String filename, String extension) {
    final separatorIndex = filename.lastIndexOf('.');
    final baseName = separatorIndex <= 0 ? filename : filename.substring(0, separatorIndex);
    final normalizedBaseName = baseName.isEmpty ? 'product-image' : baseName;
    return '$normalizedBaseName.$extension';
  }
}

class ProductImageUploadException implements Exception {
  const ProductImageUploadException(this.message);

  final String message;

  @override
  String toString() => message;
}

class _PreparedUpload {
  const _PreparedUpload({
    required this.filename,
    required this.bytes,
    required this.contentType,
  });

  final String filename;
  final Uint8List bytes;
  final MediaType contentType;
}