import 'package:flutter/material.dart';

import '../../ui/full_screen_image_viewer.dart';
import '../../ui/header_credit_badge.dart';
import 'models/product_image_models.dart';
import 'product_images_controller.dart';

class ProfessionalPhotoshootScreen extends StatefulWidget {
  const ProfessionalPhotoshootScreen({
    super.key,
    required this.controller,
  });

  final ProductImagesController controller;

  @override
  State<ProfessionalPhotoshootScreen> createState() =>
      _ProfessionalPhotoshootScreenState();
}

class _ProfessionalPhotoshootScreenState
    extends State<ProfessionalPhotoshootScreen>
    with SingleTickerProviderStateMixin {
  bool _triggered = false;
  late final AnimationController _pulseAnim;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_rebuild);
    _pulseAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
  }

  void _rebuild() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    widget.controller.removeListener(_rebuild);
    _pulseAnim.dispose();
    super.dispose();
  }

  void _generate() {
    setState(() => _triggered = true);
    widget.controller.generateCurrentStyle();
  }

  @override
  Widget build(BuildContext context) {
    final ctrl = widget.controller;
    final completed =
        ctrl.recentGenerations.where((g) => g.hasImage).toList();

    return Scaffold(
      appBar: _PhotoshootAppBar(controller: ctrl),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        children: [
          _PastGenerationsRow(generations: completed, controller: ctrl),
          const SizedBox(height: 24),
          _StylePicker(controller: ctrl),
          const SizedBox(height: 24),
          _buildGenerateArea(ctrl),
        ],
      ),
    );
  }

  Widget _buildGenerateArea(ProductImagesController ctrl) {
    // Generating — show original + pulsing overlay
    if (_triggered && ctrl.isGenerating) {
      return _GeneratingView(
        assetUrl: ctrl.selectedAsset != null
            ? ctrl.resolveImageUrl(ctrl.selectedAsset!.imageUrl)
            : null,
        headers: ctrl.imageHeaders,
        pulse: _pulseAnim,
      );
    }

    // Generation completed — show result + generate-again button
    if (_triggered && !ctrl.isGenerating && ctrl.currentGeneration?.hasImage == true) {
      return Column(
        children: [
          GestureDetector(
            onTap: () => openFullScreenImage(
              context,
              imageUrl: ctrl.resolveImageUrl(ctrl.currentGeneration!.imageUrl!),
              headers: ctrl.imageHeaders,
              heroTag: 'generated_${ctrl.currentGeneration!.id}',
            ),
            child: Hero(
              tag: 'generated_${ctrl.currentGeneration!.id}',
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: AspectRatio(
                  aspectRatio: 1,
                  child: Image.network(
                    ctrl.resolveImageUrl(ctrl.currentGeneration!.imageUrl!),
                    headers: ctrl.imageHeaders,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: ctrl.canGenerate ? _generate : null,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Generate again'),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF5C4635),
                side: const BorderSide(color: Color(0xFFD3B79D)),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(22),
                ),
              ),
            ),
          ),
        ],
      );
    }

    // Default — generate button (also shown after a failed generation)
    return _GenerateButton(
      enabled: ctrl.canGenerate,
      noPhoto: ctrl.selectedAsset == null,
      error: _triggered ? ctrl.errorMessage : null,
      onTap: _generate,
    );
  }
}

// ─── App bar ───────────────────────────────────────────────────────────────

class _PhotoshootAppBar extends StatelessWidget implements PreferredSizeWidget {
  const _PhotoshootAppBar({required this.controller});

  final ProductImagesController controller;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      surfaceTintColor: Colors.transparent,
      scrolledUnderElevation: 0,
      titleSpacing: 8,
      title: Text(
        'Professional Photoshoot',
        style: Theme.of(context).textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w700,
        ),
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 16),
          child: Center(
            child: HeaderCreditBadge(credits: controller.credits?.balance),
          ),
        ),
      ],
    );
  }
}

// ─── Past generations horizontal row ───────────────────────────────────────

class _PastGenerationsRow extends StatelessWidget {
  const _PastGenerationsRow({
    required this.generations,
    required this.controller,
  });

  final List<ProductImageGeneration> generations;
  final ProductImagesController controller;

  @override
  Widget build(BuildContext context) {
    if (generations.isEmpty) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 28),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.9),
          borderRadius: BorderRadius.circular(24),
        ),
        child: Text(
          'Select a style and hit Generate to get professional photoshoot images',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: const Color(0xFF6A5545),
            height: 1.5,
          ),
          textAlign: TextAlign.center,
        ),
      );
    }

    return SizedBox(
      height: 180,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        clipBehavior: Clip.none,
        itemCount: generations.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, i) {
          final gen = generations[i];
          return GestureDetector(
            onTap: () => openFullScreenImage(
              context,
              imageUrl: controller.resolveImageUrl(gen.imageUrl!),
              headers: controller.imageHeaders,
              heroTag: 'past_gen_${gen.id}',
            ),
            child: Hero(
              tag: 'past_gen_${gen.id}',
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: AspectRatio(
                  aspectRatio: 1,
                  child: Image.network(
                    controller.resolveImageUrl(gen.imageUrl!),
                    headers: controller.imageHeaders,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

// ─── Style picker ──────────────────────────────────────────────────────────

class _StylePicker extends StatelessWidget {
  const _StylePicker({required this.controller});

  final ProductImagesController controller;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Visual style',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 220,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            clipBehavior: Clip.none,
            itemCount: controller.styles.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (context, i) {
              final style = controller.styles[i];
              final selected = style.key == controller.selectedStyle;
              return GestureDetector(
                onTap: () => controller.selectStyle(style.key),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  width: 170,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: selected
                        ? const Color(0xFF5C3B2E)
                        : const Color(0xFFF7EFE6),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: selected
                          ? const Color(0xFF5C3B2E)
                          : const Color(0xFFD7C1AC),
                    ),
                    boxShadow: selected
                        ? [
                            BoxShadow(
                              color: const Color(0xFF5C3B2E)
                                  .withValues(alpha: 0.18),
                              blurRadius: 18,
                              offset: const Offset(0, 10),
                            ),
                          ]
                        : null,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _StylePreviewThumb(
                          styleKey: style.key, isSelected: selected),
                      const SizedBox(height: 10),
                      Text(
                        style.label,
                        style:
                            Theme.of(context).textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: selected
                                      ? Colors.white
                                      : const Color(0xFF3E2B22),
                                ),
                      ),
                      const SizedBox(height: 4),
                      Expanded(
                        child: Text(
                          style.description,
                          overflow: TextOverflow.fade,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: selected
                                    ? const Color(0xFFF9EADB)
                                    : const Color(0xFF6A5545),
                                height: 1.3,
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
      ],
    );
  }
}

class _StylePreviewThumb extends StatelessWidget {
  const _StylePreviewThumb(
      {required this.styleKey, required this.isSelected});

  final String styleKey;
  final bool isSelected;

  @override
  Widget build(BuildContext context) {
    final config = switch (styleKey) {
      'professional' => (
          top: const Color(0xFFEFE2D4),
          bottom: const Color(0xFFF9F5EF),
          accent: const Color(0xFFBCA18B)
        ),
      'lifestyle' => (
          top: const Color(0xFFD8C5B1),
          bottom: const Color(0xFFF2E2D2),
          accent: const Color(0xFF8D5E3C)
        ),
      'minimal' => (
          top: const Color(0xFFF4F1EC),
          bottom: const Color(0xFFE8DED0),
          accent: const Color(0xFFA18D7D)
        ),
      'studio' => (
          top: const Color(0xFFE7D4C1),
          bottom: const Color(0xFFF9F3EC),
          accent: const Color(0xFFB67A4F)
        ),
      'creative' => (
          top: const Color(0xFFD8C2BA),
          bottom: const Color(0xFFF0E6DB),
          accent: const Color(0xFF714A3A)
        ),
      'luxury' => (
          top: const Color(0xFFD3C2A8),
          bottom: const Color(0xFFF1E3CB),
          accent: const Color(0xFF8B623B)
        ),
      _ => (
          top: const Color(0xFFEFE2D4),
          bottom: const Color(0xFFF9F5EF),
          accent: const Color(0xFFBCA18B)
        ),
    };

    return Container(
      height: 76,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [config.top, config.bottom],
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            left: 12,
            right: 12,
            bottom: 8,
            child: Container(
              height: 8,
              decoration: BoxDecoration(
                color: config.accent.withValues(alpha: 0.22),
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          ),
          Align(
            child: Container(
              width: 36,
              height: 44,
              decoration: BoxDecoration(
                color: isSelected ? Colors.white : const Color(0xFFFFFBF7),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: config.accent.withValues(alpha: 0.4)),
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
                size: 18,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Generate button ────────────────────────────────────────────────────────

class _GenerateButton extends StatelessWidget {
  const _GenerateButton({
    required this.enabled,
    required this.noPhoto,
    required this.onTap,
    this.error,
  });

  final bool enabled;
  final bool noPhoto;
  final VoidCallback onTap;
  final String? error;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (noPhoto)
          Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: Text(
              'Go back and add a product photo first.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: const Color(0xFF6A5545),
              ),
              textAlign: TextAlign.center,
            ),
          ),
        if (error != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF2EE),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: const Color(0xFFE9B6A6)),
              ),
              child: Text(
                error!,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: const Color(0xFF7A3E2A),
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        FilledButton.icon(
          onPressed: enabled ? onTap : null,
          style: FilledButton.styleFrom(
            backgroundColor: const Color(0xFF1F1A17),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 18),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(22),
            ),
          ),
          icon: const Icon(Icons.auto_awesome_rounded),
          label: const Text('Generate'),
        ),
      ],
    );
  }
}

// ─── Generating view (original + pulsing overlay) ──────────────────────────

class _GeneratingView extends StatelessWidget {
  const _GeneratingView({
    required this.assetUrl,
    required this.headers,
    required this.pulse,
  });

  final String? assetUrl;
  final Map<String, String> headers;
  final Animation<double> pulse;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: AspectRatio(
        aspectRatio: 1,
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (assetUrl != null)
              Image.network(
                assetUrl!,
                headers: headers,
                fit: BoxFit.cover,
              )
            else
              Container(color: const Color(0xFFF5EBDD)),
            AnimatedBuilder(
              animation: pulse,
              builder: (_, __) => Container(
                color: Colors.black
                    .withValues(alpha: 0.28 + 0.18 * pulse.value),
              ),
            ),
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(
                    width: 48,
                    height: 48,
                    child: CircularProgressIndicator(
                      strokeWidth: 3,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Generating…',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'This may take a moment',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
