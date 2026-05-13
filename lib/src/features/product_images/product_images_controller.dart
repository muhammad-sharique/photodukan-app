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
  String? _errorMessage;
  ProductImageAsset? _selectedAsset;
  ProductImageGeneration? _currentGeneration;
  List<ProductImageGeneration> _recentGenerations = const [];
  List<ProductImageStyleOption> _styles = const [];
  String? _selectedStyle;
  Map<String, String> _imageHeaders = const {};
  bool _didInitialize = false;

  bool get isInitializing => _isInitializing;
  bool get isUploading => _isUploading;
  bool get isGenerating => _isGenerating;
  bool get isBusy => _isInitializing || _isUploading || _isGenerating;
  String? get errorMessage => _errorMessage;
  ProductImageAsset? get selectedAsset => _selectedAsset;
  ProductImageGeneration? get currentGeneration => _currentGeneration;
  List<ProductImageGeneration> get recentGenerations => _recentGenerations;
  List<ProductImageStyleOption> get styles => _styles;
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
      _recentGenerations = await _repository.listRecentGenerations(limit: 8);
      _imageHeaders = await _repository.buildImageHeaders();
      if (_currentGeneration == null && _recentGenerations.isNotEmpty) {
        _currentGeneration = _recentGenerations.first;
      }
    } catch (error) {
      _log('initialize failed error=$error');
      _errorMessage = _describeError(error);
    } finally {
      _isInitializing = false;
      notifyListeners();
    }
  }

  Future<void> pickAndUploadPhoto() async {
    await pickAndUploadPhotoFrom(ImageSource.gallery);
  }

  Future<void> pickAndUploadPhotoFrom(ImageSource source) async {
    _errorMessage = null;
    notifyListeners();

    final file = await _picker.pickImage(
      source: source,
      imageQuality: 92,
      maxWidth: 2400,
    );

    if (file == null) {
      return;
    }

    _isUploading = true;
    notifyListeners();

    try {
      _selectedAsset = await _repository.uploadAsset(file);
      _currentGeneration = null;
      _imageHeaders = await _repository.buildImageHeaders();
      _recentGenerations = await _repository.listRecentGenerations(limit: 8);
    } catch (error) {
      _log('pickAndUploadPhotoFrom failed error=$error');
      _errorMessage = _describeError(error);
    } finally {
      _isUploading = false;
      notifyListeners();
    }
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
        style: _selectedStyle!,
      );
      _imageHeaders = await _repository.buildImageHeaders();
      _recentGenerations = await _repository.listRecentGenerations(limit: 8);
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