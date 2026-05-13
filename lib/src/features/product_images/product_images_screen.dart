import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import 'product_images_controller.dart';

Future<void> _pickProductPhoto(
  BuildContext context,
  ProductImagesController controller,
) async {
  final source = await showModalBottomSheet<ImageSource>(
    context: context,
    backgroundColor: Colors.transparent,
    builder: (context) => const _PhotoSourceSheet(),
  );

  if (source == null) {
    return;
  }

  await controller.pickAndUploadPhotoFrom(source);
}

class ProductImagesScreen extends StatelessWidget {
  const ProductImagesScreen({
    super.key,
    required this.controller,
    required this.currentUser,
    required this.onSignOut,
  });

  final ProductImagesController controller;
  final User? currentUser;
  final Future<void> Function() onSignOut;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) {
        final canGenerate = controller.canGenerate;
        final primaryLabel = controller.selectedAsset == null
            ? (controller.isUploading ? 'Uploading photo...' : 'Choose product photo')
            : (controller.isGenerating ? 'Generating image...' : 'Generate style');

        return DecoratedBox(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFFF8F1E8), Color(0xFFF1E0CA), Color(0xFFE8D2BA)],
            ),
          ),
          child: SafeArea(
            child: Column(
              children: [
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
                    children: [
                      _HeaderCard(
                        currentUser: currentUser,
                        onSignOut: onSignOut,
                      ),
                      const SizedBox(height: 16),
                      _HeroCard(controller: controller),
                      if (controller.errorMessage != null) ...[
                        const SizedBox(height: 16),
                        _ErrorCard(message: controller.errorMessage!),
                      ],
                      const SizedBox(height: 16),
                      _PhotoSection(controller: controller),
                      const SizedBox(height: 16),
                      _StyleSection(controller: controller),
                      const SizedBox(height: 16),
                      _ResultSection(controller: controller),
                      if (controller.recentGenerations.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        _RecentSection(controller: controller),
                      ],
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                  child: SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: controller.isBusy
                          ? null
                          : controller.selectedAsset == null
                            ? () => _pickProductPhoto(context, controller)
                              : (canGenerate ? controller.generateCurrentStyle : null),
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFF1F1A17),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(22),
                        ),
                      ),
                      icon: controller.isBusy
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Icon(
                              controller.selectedAsset == null
                                  ? Icons.photo_library_rounded
                                  : Icons.auto_awesome_rounded,
                            ),
                      label: Text(primaryLabel),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _HeaderCard extends StatelessWidget {
  const _HeaderCard({required this.currentUser, required this.onSignOut});

  final User? currentUser;
  final Future<void> Function() onSignOut;

  @override
  Widget build(BuildContext context) {
    final label = currentUser?.displayName ?? currentUser?.email ?? 'PhotoDukan';

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.88),
        borderRadius: BorderRadius.circular(28),
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: const Color(0xFFB85C38),
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Icon(Icons.auto_awesome, color: Colors.white),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Product Images',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  label,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: const Color(0xFF6A5545),
                  ),
                ),
              ],
            ),
          ),
          IconButton.filledTonal(
            onPressed: onSignOut,
            style: IconButton.styleFrom(
              backgroundColor: const Color(0xFFF1E0CA),
              foregroundColor: const Color(0xFF5C4635),
            ),
            icon: const Icon(Icons.logout_rounded),
          ),
        ],
      ),
    );
  }
}

class _HeroCard extends StatelessWidget {
  const _HeroCard({required this.controller});

  final ProductImagesController controller;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        gradient: const LinearGradient(
          colors: [Color(0xFF4B3328), Color(0xFF8D4E2D)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(999),
            ),
            child: const Text(
              'Upload once, try multiple looks',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Create polished product visuals without filling in product details.',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              height: 1.15,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Pick a product photo, choose a visual style, and generate a fresh AI image directly.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: const Color(0xFFF8EDE4),
              height: 1.45,
            ),
          ),
          if (controller.isUploading || controller.isGenerating) ...[
            const SizedBox(height: 16),
            const LinearProgressIndicator(
              minHeight: 6,
              backgroundColor: Color(0x66FFFFFF),
              color: Colors.white,
            ),
          ],
        ],
      ),
    );
  }
}

class _ErrorCard extends StatelessWidget {
  const _ErrorCard({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF2EE),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE9B6A6)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.error_outline_rounded, color: Color(0xFFB94E2D)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: const Color(0xFF7A3E2A),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PhotoSection extends StatelessWidget {
  const _PhotoSection({required this.controller});

  final ProductImagesController controller;

  @override
  Widget build(BuildContext context) {
    final asset = controller.selectedAsset;

    return _SectionCard(
      title: '1. Product photo',
      subtitle: asset == null
          ? 'Choose a clean product image from your gallery or camera.'
          : 'This source photo stays available while you try different styles.',
      action: asset == null
          ? null
          : TextButton(
            onPressed: controller.isBusy ? null : () => _showPhotoSourcePicker(context),
              child: const Text('Change photo'),
            ),
      child: asset == null
          ? OutlinedButton.icon(
            onPressed: controller.isBusy ? null : () => _showPhotoSourcePicker(context),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF5C4635),
                padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 18),
                side: const BorderSide(color: Color(0xFFD3B79D)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
              ),
              icon: const Icon(Icons.add_photo_alternate_outlined),
              label: const Text('Choose photo'),
            )
          : ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: AspectRatio(
                aspectRatio: 1,
                child: Image.network(
                  controller.resolveImageUrl(asset.imageUrl),
                  headers: controller.imageHeaders,
                  fit: BoxFit.cover,
                ),
              ),
            ),
    );
  }

  Future<void> _showPhotoSourcePicker(BuildContext context) {
    return _pickProductPhoto(context, controller);
  }
}

class _PhotoSourceSheet extends StatelessWidget {
  const _PhotoSourceSheet();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 10),
        decoration: BoxDecoration(
          color: const Color(0xFFFFFBF7),
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.12),
              blurRadius: 30,
              offset: const Offset(0, 16),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Add product photo',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
                color: const Color(0xFF3E2B22),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Use your camera or choose an existing photo. Unsupported formats will be converted automatically when possible.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: const Color(0xFF6A5545),
                height: 1.4,
              ),
            ),
            const SizedBox(height: 18),
            _PhotoSourceTile(
              icon: Icons.camera_alt_rounded,
              title: 'Take a photo',
              subtitle: 'Capture a fresh product shot now.',
              onTap: () => Navigator.of(context).pop(ImageSource.camera),
            ),
            const SizedBox(height: 10),
            _PhotoSourceTile(
              icon: Icons.photo_library_rounded,
              title: 'Choose from gallery',
              subtitle: 'Pick an existing product image from your device.',
              onTap: () => Navigator.of(context).pop(ImageSource.gallery),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

class _PhotoSourceTile extends StatelessWidget {
  const _PhotoSourceTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(22),
      child: Ink(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFF5EBDD),
          borderRadius: BorderRadius.circular(22),
        ),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: const Color(0xFFB85C38),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(icon, color: Colors.white),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF3E2B22),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: const Color(0xFF6A5545),
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: Color(0xFF6A5545)),
          ],
        ),
      ),
    );
  }
}

class _StyleSection extends StatelessWidget {
  const _StyleSection({required this.controller});

  final ProductImagesController controller;

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: '2. Visual style',
      subtitle: 'Each style keeps the product intact and changes only the presentation.',
      child: SizedBox(
        height: 146,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: controller.styles.length,
          separatorBuilder: (context, index) => const SizedBox(width: 12),
          itemBuilder: (context, index) {
            final style = controller.styles[index];
            final isSelected = style.key == controller.selectedStyle;

            return GestureDetector(
              onTap: () => controller.selectStyle(style.key),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                width: 190,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isSelected ? const Color(0xFF5C3B2E) : const Color(0xFFF7EFE6),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: isSelected ? const Color(0xFF5C3B2E) : const Color(0xFFD7C1AC),
                  ),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: const Color(0xFF5C3B2E).withValues(alpha: 0.18),
                            blurRadius: 18,
                            offset: const Offset(0, 10),
                          ),
                        ]
                      : null,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      style.key[0].toUpperCase() + style.key.substring(1),
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: isSelected ? Colors.white : const Color(0xFF3E2B22),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Expanded(
                      child: Text(
                        style.description,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: isSelected ? const Color(0xFFF9EADB) : const Color(0xFF6A5545),
                          height: 1.35,
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
    );
  }
}

class _ResultSection extends StatelessWidget {
  const _ResultSection({required this.controller});

  final ProductImagesController controller;

  @override
  Widget build(BuildContext context) {
    final generation = controller.currentGeneration;

    return _SectionCard(
      title: '3. Generated result',
      subtitle: generation?.hasImage == true
          ? 'Compare your uploaded photo with the latest generated output.'
          : 'Your latest render will appear here after generation completes.',
      child: Column(
        children: [
          if (controller.selectedAsset != null)
            _ImagePanel(
              label: 'Original',
              imageUrl: controller.resolveImageUrl(controller.selectedAsset!.imageUrl),
              headers: controller.imageHeaders,
            ),
          const SizedBox(height: 12),
          generation?.hasImage == true
              ? _ImagePanel(
                  label: 'Generated',
                  imageUrl: controller.resolveImageUrl(generation!.imageUrl!),
                  headers: controller.imageHeaders,
                  accent: const Color(0xFFB85C38),
                )
              : Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF7EFE6),
                    borderRadius: BorderRadius.circular(22),
                  ),
                  child: Text(
                    controller.selectedAsset == null
                        ? 'Upload a product photo to unlock the first render.'
                        : 'Pick a style and generate to see the AI result.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: const Color(0xFF6A5545),
                    ),
                  ),
                ),
        ],
      ),
    );
  }
}

class _RecentSection extends StatelessWidget {
  const _RecentSection({required this.controller});

  final ProductImagesController controller;

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: 'Recent renders',
      subtitle: 'Your latest completed images stay available while you work.',
      child: SizedBox(
        height: 180,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: controller.recentGenerations.length,
          separatorBuilder: (context, index) => const SizedBox(width: 12),
          itemBuilder: (context, index) {
            final generation = controller.recentGenerations[index];
            final imageUrl = generation.imageUrl;

            return Container(
              width: 148,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.92),
                borderRadius: BorderRadius.circular(22),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: imageUrl == null
                          ? Container(
                              color: const Color(0xFFF0E0CF),
                              alignment: Alignment.center,
                              child: const Icon(Icons.image_not_supported_outlined),
                            )
                          : Image.network(
                              controller.resolveImageUrl(imageUrl),
                              headers: controller.imageHeaders,
                              width: double.infinity,
                              fit: BoxFit.cover,
                            ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    generation.style[0].toUpperCase() + generation.style.substring(1),
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    generation.status,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: const Color(0xFF6A5545),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.title,
    required this.subtitle,
    required this.child,
    this.action,
  });

  final String title;
  final String subtitle;
  final Widget child;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final actionWidgets = action == null ? const <Widget>[] : <Widget>[action!];

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(28),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: const Color(0xFF6A5545),
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              ...actionWidgets,
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}

class _ImagePanel extends StatelessWidget {
  const _ImagePanel({
    required this.label,
    required this.imageUrl,
    required this.headers,
    this.accent = const Color(0xFF5C4635),
  });

  final String label;
  final String imageUrl;
  final Map<String, String> headers;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF8F1E8),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 0),
            child: Text(
              label,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: accent,
              ),
            ),
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: const BorderRadius.vertical(bottom: Radius.circular(22)),
            child: AspectRatio(
              aspectRatio: 1.1,
              child: Image.network(
                imageUrl,
                headers: headers,
                fit: BoxFit.cover,
              ),
            ),
          ),
        ],
      ),
    );
  }
}