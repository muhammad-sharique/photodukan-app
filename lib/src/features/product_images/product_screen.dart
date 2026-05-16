import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../ui/header_credit_badge.dart';
import '../../ui/full_screen_image_viewer.dart';
import 'product_images_controller.dart';
import 'professional_photoshoot_screen.dart';

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

class ProductScreen extends StatelessWidget {
  const ProductScreen({
    super.key,
    required this.controller,
  });

  final ProductImagesController controller;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) {
        return Scaffold(
          appBar: _ProductEditorAppBar(
            controller: controller,
          ),
          body: ListView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
            children: [
              if (controller.errorMessage != null) ...[
                const SizedBox(height: 8),
                _ErrorCard(message: controller.errorMessage!),
              ],
              const SizedBox(height: 12),
              _TitleField(controller: controller),
              const SizedBox(height: 12),
              _PhotoSection(controller: controller),
              if (controller.currentProduct?.description?.isNotEmpty == true) ...[
                const SizedBox(height: 8),
                _DescriptionToggle(
                  controller: controller,
                ),
              ],
              const SizedBox(height: 28),
              Text(
                'My Tools',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 12),
              _ToolCard(
                title: 'Professional Photoshoot',
                description:
                    'Create professional images for your product to use on e-commerce and marketing',
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => ProfessionalPhotoshootScreen(
                      controller: controller,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ProductEditorAppBar extends StatelessWidget implements PreferredSizeWidget {
  const _ProductEditorAppBar({
    required this.controller,
  });

  final ProductImagesController controller;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    final credits = controller.credits?.balance;
    final title = controller.currentProduct?.name?.trim().isNotEmpty == true
        ? controller.currentProduct!.name!
        : 'View Product';

    return AppBar(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      surfaceTintColor: Colors.transparent,
      scrolledUnderElevation: 0,
      titleSpacing: 8,
      title: Text(
        title,
        style: Theme.of(context).textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w700,
        ),
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 16),
          child: Center(
            child: HeaderCreditBadge(credits: credits),
          ),
        ),
      ],
    );
  }
}

class _TitleField extends StatefulWidget {
  const _TitleField({required this.controller});

  final ProductImagesController controller;

  @override
  State<_TitleField> createState() => _TitleFieldState();
}

class _TitleFieldState extends State<_TitleField> {
  late final TextEditingController _textController;
  late final FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _textController = TextEditingController(
      text: widget.controller.currentProduct?.name ?? '',
    );
    _focusNode = FocusNode();
    _focusNode.addListener(_onFocusChange);
  }

  @override
  void didUpdateWidget(_TitleField oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Sync if the product changed externally (but not while editing)
    if (!_focusNode.hasFocus) {
      final newName = widget.controller.currentProduct?.name ?? '';
      if (_textController.text != newName) {
        _textController.text = newName;
      }
    }
  }

  void _onFocusChange() {
    if (!_focusNode.hasFocus) {
      _submit();
    }
  }

  void _submit() {
    widget.controller.updateProductName(_textController.text);
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChange);
    _focusNode.dispose();
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _textController,
      focusNode: _focusNode,
      onEditingComplete: () {
        _submit();
        _focusNode.unfocus();
      },
      maxLines: 1,
      textInputAction: TextInputAction.done,
      style: Theme.of(context).textTheme.titleLarge?.copyWith(
        fontWeight: FontWeight.w700,
        color: const Color(0xFF1F1A17),
      ),
      decoration: InputDecoration(
        hintText: 'Add title',
        hintStyle: Theme.of(context).textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w700,
          color: const Color(0xFFBCAFA6),
        ),
        border: InputBorder.none,
        enabledBorder: InputBorder.none,
        focusedBorder: UnderlineInputBorder(
          borderSide: BorderSide(
            color: const Color(0xFF5C4635).withOpacity(0.4),
            width: 1.5,
          ),
        ),
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(vertical: 4),
      ),
    );
  }
}

class _DescriptionToggle extends StatefulWidget {
  const _DescriptionToggle({required this.controller});

  final ProductImagesController controller;

  @override
  State<_DescriptionToggle> createState() => _DescriptionToggleState();
}

class _DescriptionToggleState extends State<_DescriptionToggle> {
  bool _expanded = false;
  late final TextEditingController _textController;
  late final FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _textController = TextEditingController(
      text: widget.controller.currentProduct?.description ?? '',
    );
    _focusNode = FocusNode();
    _focusNode.addListener(_onFocusChange);
  }

  @override
  void didUpdateWidget(_DescriptionToggle oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_focusNode.hasFocus) {
      final newDesc = widget.controller.currentProduct?.description ?? '';
      if (_textController.text != newDesc) {
        _textController.text = newDesc;
      }
    }
  }

  void _onFocusChange() {
    if (!_focusNode.hasFocus) {
      widget.controller.updateProductDescription(_textController.text);
    }
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChange);
    _focusNode.dispose();
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        GestureDetector(
          onTap: () => setState(() => _expanded = !_expanded),
          behavior: HitTestBehavior.opaque,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(
              children: [
                Text(
                  'Description',
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: const Color(0xFF6A5545),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 4),
                Icon(
                  _expanded
                      ? Icons.keyboard_arrow_up_rounded
                      : Icons.keyboard_arrow_down_rounded,
                  size: 18,
                  color: const Color(0xFF6A5545),
                ),
                if (_expanded) ...[
                  const SizedBox(width: 6),
                  Text(
                    'Tap to Edit',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: const Color(0xFFBCAFA6),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
        if (_expanded)
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 260),
            child: TextField(
              controller: _textController,
              focusNode: _focusNode,
              maxLines: null,
              minLines: 3,
              textInputAction: TextInputAction.newline,
              keyboardType: TextInputType.multiline,
              onTapOutside: (_) => _focusNode.unfocus(),
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: const Color(0xFF6A5545),
                height: 1.6,
              ),
              decoration: InputDecoration(
                hintText: 'Write a description...',
                hintStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: const Color(0xFFBCAFA6),
                  height: 1.6,
                ),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                isDense: true,
                contentPadding: const EdgeInsets.only(bottom: 8),
              ),
            ),
          ),
      ],
    );
  }
}

class _ToolCard extends StatelessWidget {
  const _ToolCard({
    required this.title,
    required this.description,
    required this.onTap,
  });

  final String title;
  final String description;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: Material(
        color: Colors.white.withValues(alpha: 0.9),
        child: InkWell(
          onTap: onTap,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Demo preview
              Container(
                height: 140,
                width: double.infinity,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFFEDE0CC), Color(0xFFD3B89C)],
                  ),
                ),
                child: Stack(
                  children: [
                    // Simulated product silhouette
                    Positioned(
                      right: 32,
                      top: 16,
                      child: Container(
                        width: 76,
                        height: 96,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.7),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Icon(
                          Icons.shopping_bag_rounded,
                          color: Color(0xFFBCA18B),
                          size: 38,
                        ),
                      ),
                    ),
                    // Shadow beneath product
                    Positioned(
                      right: 42,
                      bottom: 16,
                      child: Container(
                        width: 56,
                        height: 8,
                        decoration: BoxDecoration(
                          color: const Color(0xFFBCA18B).withValues(alpha: 0.28),
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                    ),
                    // AI badge
                    Positioned(
                      left: 16,
                      top: 16,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.88),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.auto_awesome_rounded,
                                size: 13, color: Color(0xFFB85C38)),
                            const SizedBox(width: 4),
                            Text(
                              'AI',
                              style: Theme.of(context)
                                  .textTheme
                                  .labelSmall
                                  ?.copyWith(
                                    fontWeight: FontWeight.w700,
                                    color: const Color(0xFFB85C38),
                                  ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // Text row
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            description,
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(
                                  color: const Color(0xFF6A5545),
                                  height: 1.4,
                                ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Icon(Icons.arrow_forward_rounded,
                        color: Color(0xFF6A5545)),
                  ],
                ),
              ),
            ],
          ),
        ),
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

    if (asset == null) {
      return OutlinedButton.icon(
        onPressed: controller.isBusy ? null : () => _pickProductPhoto(context, controller),
        style: OutlinedButton.styleFrom(
          foregroundColor: const Color(0xFF5C4635),
          minimumSize: const Size.fromHeight(64),
          padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 18),
          side: const BorderSide(color: Color(0xFFD3B79D)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
        ),
        icon: const Icon(Icons.add_photo_alternate_outlined),
        label: const Text('Choose photo'),
      );
    }

    return Stack(
      alignment: Alignment.bottomRight,
      children: [
        GestureDetector(
          onTap: () => openFullScreenImage(
            context,
            imageUrl: controller.resolveImageUrl(asset.imageUrl),
            headers: controller.imageHeaders,
            heroTag: 'product_asset_${asset.id}',
          ),
          child: Hero(
            tag: 'product_asset_${asset.id}',
            child: ClipRRect(
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
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(12),
          child: GestureDetector(
            onTap: controller.isBusy
                ? null
                : () => _pickProductPhoto(context, controller),
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.55),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.edit_rounded,
                      color: Colors.white, size: 13),
                  const SizedBox(width: 5),
                  Text(
                    'Change',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: Colors.white,
                        ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
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
              'Use your camera or choose an existing photo.',
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
      subtitle: 'Premium Background keeps the product intact and changes only the presentation.',
      child: SizedBox(
        height: 230,
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
                width: 206,
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
                    _StylePreview(styleKey: style.key, isSelected: isSelected),
                    const SizedBox(height: 12),
                    Text(
                      style.label,
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

class _StylePreview extends StatelessWidget {
  const _StylePreview({required this.styleKey, required this.isSelected});

  final String styleKey;
  final bool isSelected;

  @override
  Widget build(BuildContext context) {
    final config = switch (styleKey) {
      'professional' => (top: const Color(0xFFEFE2D4), bottom: const Color(0xFFF9F5EF), accent: const Color(0xFFBCA18B)),
      'lifestyle' => (top: const Color(0xFFD8C5B1), bottom: const Color(0xFFF2E2D2), accent: const Color(0xFF8D5E3C)),
      'minimal' => (top: const Color(0xFFF4F1EC), bottom: const Color(0xFFE8DED0), accent: const Color(0xFFA18D7D)),
      'studio' => (top: const Color(0xFFE7D4C1), bottom: const Color(0xFFF9F3EC), accent: const Color(0xFFB67A4F)),
      'creative' => (top: const Color(0xFFD8C2BA), bottom: const Color(0xFFF0E6DB), accent: const Color(0xFF714A3A)),
      'luxury' => (top: const Color(0xFFD3C2A8), bottom: const Color(0xFFF1E3CB), accent: const Color(0xFF8B623B)),
      _ => (top: const Color(0xFFEFE2D4), bottom: const Color(0xFFF9F5EF), accent: const Color(0xFFBCA18B)),
    };

    return Container(
      height: 88,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [config.top, config.bottom],
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            left: 16,
            right: 16,
            bottom: 12,
            child: Container(
              height: 12,
              decoration: BoxDecoration(
                color: config.accent.withValues(alpha: 0.22),
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          ),
          Align(
            child: Container(
              width: 44,
              height: 52,
              decoration: BoxDecoration(
                color: isSelected ? Colors.white : const Color(0xFFFFFBF7),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: config.accent.withValues(alpha: 0.4),
                ),
              ),
              child: Icon(
                styleKey == 'lifestyle'
                    ? Icons.chair_rounded
                    : styleKey == 'creative'
                        ? Icons.auto_awesome_rounded
                        : styleKey == 'luxury'
                            ? Icons.workspace_premium_rounded
                            : Icons.photo_camera_back_rounded,
                color: config.accent,
              ),
            ),
          ),
        ],
      ),
    );
  }
}