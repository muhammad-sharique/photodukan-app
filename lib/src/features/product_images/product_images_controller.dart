import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';

import '../../services/api_client.dart';
import 'models/product_image_models.dart';
import 'product_images_repository.dart';

class ProductImagesController extends ChangeNotifier {
  ProductImagesController({
    required ProductImagesRepository repository,
    ImagePicker? picker,
  }) : _repository = repository,
       _picker = picker ?? ImagePicker();

  final ProductImagesRepository _repository;
  final ImagePicker _picker;

  bool _isInitializing = false;
  bool _isUploading = false;
  bool _isGenerating = false;
  bool _isLoadingProduct = false;
  String? _errorMessage;
  ProductImageAsset? _selectedAsset;
  ProductImageGeneration? _currentGeneration;
  List<ProductImageGeneration> _recentGenerations = const [];
  List<ProductImageStyleOption> _styles = const [];
  List<ProductSummary> _products = const [];
  CreditSummary? _credits;
  ProductDetail? _currentProduct;
  String? _selectedStyle;
  Map<String, String> _imageHeaders = const {};
  bool _didInitialize = false;

  bool get isInitializing => _isInitializing;
  bool get isUploading => _isUploading;
  bool get isGenerating => _isGenerating;
  bool get isLoadingProduct => _isLoadingProduct;
  bool get isBusy => _isInitializing || _isUploading || _isGenerating || _isLoadingProduct;
  String? get errorMessage => _errorMessage;
  ProductImageAsset? get selectedAsset => _selectedAsset;
  ProductImageGeneration? get currentGeneration => _currentGeneration;
  List<ProductImageGeneration> get recentGenerations => _recentGenerations;
  List<ProductImageStyleOption> get styles => _styles;
  List<ProductSummary> get products => _products;
  CreditSummary? get credits => _credits;
  ProductDetail? get currentProduct => _currentProduct;
  String? get selectedStyle => _selectedStyle;
  Map<String, String> get imageHeaders => _imageHeaders;

  bool get canGenerate =>
      !_isGenerating && !_isUploading && _selectedAsset != null && _selectedStyle != null;

  void _log(String message) {
    developer.log(message, name: 'PhotoDukan.ProductImagesController');
  }

  Future<void> initialize() async {
    if (_didInitialize) {
      return;
    }

    _didInitialize = true;
    _isInitializing = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _styles = await _repository.fetchStyles();
      _selectedStyle = _styles.isNotEmpty ? _styles.first.key : null;
      _imageHeaders = await _repository.buildImageHeaders();
      await refreshOverview();
    } catch (error) {
      _log('initialize failed error=$error');
      _errorMessage = _describeError(error);
    } finally {
      _isInitializing = false;
      notifyListeners();
    }
  }

  Future<void> refreshOverview() async {
    try {
      _credits = await _repository.fetchCredits();
      _products = await _repository.listProducts();
      if (_currentProduct != null) {
        final detail = await _repository.getProduct(_currentProduct!.id);
        _applyProduct(detail);
      } else {
        _recentGenerations = await _repository.listRecentGenerations(limit: 8);
        if (_currentGeneration == null && _recentGenerations.isNotEmpty) {
          _currentGeneration = _recentGenerations.first;
        }
      }
      _errorMessage = null;
    } catch (error) {
      _log('refreshOverview failed error=$error');
      _errorMessage = _describeError(error);
    }
  }

  Future<void> pickAndUploadPhoto() async {
    await pickAndUploadPhotoFrom(ImageSource.gallery);
  }

  Future<ProductDetail?> pickAndUploadPhotoFrom(ImageSource source) async {
    _errorMessage = null;
    notifyListeners();

    final file = await _picker.pickImage(
      source: source,
      imageQuality: 92,
      maxWidth: 2400,
    );

    if (file == null) {
      return null;
    }

    _isUploading = true;
    notifyListeners();

    try {
      final product = await _repository.createProductFromUpload(file);
      _applyProduct(product);
      await refreshOverview();
      return product;
    } catch (error) {
      _log('pickAndUploadPhotoFrom failed error=$error');
      _errorMessage = _describeError(error);
    } finally {
      _isUploading = false;
      notifyListeners();
    }

    return null;
  }

  Future<void> openProduct(int productId) async {
    _isLoadingProduct = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final product = await _repository.getProduct(productId);
      _applyProduct(product);
    } catch (error) {
      _log('openProduct failed error=$error');
      _errorMessage = _describeError(error);
    } finally {
      _isLoadingProduct = false;
      notifyListeners();
    }
  }

  Future<void> updateProductName(String name) async {
    if (_currentProduct == null) return;
    final trimmed = name.trim();
    try {
      final product = await _repository.updateProductName(
        _currentProduct!.id,
        trimmed.isEmpty ? null : trimmed,
      );
      _applyProduct(product);
      _products = await _repository.listProducts();
      notifyListeners();
    } catch (error) {
      _log('updateProductName failed error=$error');
    }
  }

  Future<void> updateProductDescription(String description) async {
    if (_currentProduct == null) return;
    final trimmed = description.trim();
    try {
      final product = await _repository.updateProductDescription(
        _currentProduct!.id,
        trimmed.isEmpty ? null : trimmed,
      );
      _applyProduct(product);
      notifyListeners();
    } catch (error) {
      _log('updateProductDescription failed error=$error');
    }
  }

  void clearCurrentProduct() {
    _currentProduct = null;
    _selectedAsset = null;
    _currentGeneration = null;
    _recentGenerations = const [];
    notifyListeners();
  }

  void selectStyle(String style) {
    _selectedStyle = style;
    notifyListeners();
  }

  Future<void> generateCurrentStyle() async {
    if (!canGenerate) {
      return;
    }

    _isGenerating = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _currentGeneration = await _repository.generateImage(
        assetId: _selectedAsset!.id,
        productId: _currentProduct?.id,
        style: _selectedStyle!,
      );
      _imageHeaders = await _repository.buildImageHeaders();
      if (_currentProduct != null) {
        final product = await _repository.getProduct(_currentProduct!.id);
        _applyProduct(product);
      } else {
        _recentGenerations = await _repository.listRecentGenerations(limit: 8);
      }
      _credits = await _repository.fetchCredits();
      _products = await _repository.listProducts();
    } catch (error) {
      _log('generateCurrentStyle failed error=$error');
      _errorMessage = _describeError(error);
    } finally {
      _isGenerating = false;
      notifyListeners();
    }
  }

  String resolveImageUrl(String relativePath) {
    return _repository.resolveImageUrl(relativePath);
  }

  void _applyProduct(ProductDetail product) {
    _currentProduct = product;
    _selectedAsset = product.assets.isNotEmpty
        ? product.assets.first
        : product.latestAsset;
    _recentGenerations = product.generations.take(8).toList();
    _currentGeneration = _recentGenerations.isNotEmpty
        ? _recentGenerations.first
        : product.latestGeneration;
  }

  String _describeError(Object error) {
    if (error is ApiException) {
      return error.userMessage;
    }

    if (error is ProductImageUploadException) {
      return error.message;
    }

    return error.toString();
  }
}