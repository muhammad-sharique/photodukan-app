import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../features/product_images/product_images_controller.dart';
import '../features/product_images/models/product_image_models.dart';
import '../features/product_images/product_images_repository.dart';
import '../features/product_images/product_screen.dart';
import '../services/api_client.dart';
import '../services/auth_repository.dart';
import 'header_credit_badge.dart';

class SignedInShellPage extends StatefulWidget {
  const SignedInShellPage({
    super.key,
    required this.authRepository,
    required this.apiClient,
  });

  final AuthRepository authRepository;
  final ApiClient apiClient;

  @override
  State<SignedInShellPage> createState() => _SignedInShellPageState();
}

class _SignedInShellPageState extends State<SignedInShellPage> {
  late final ProductImagesController _controller = ProductImagesController(
    repository: ProductImagesRepository(
      apiClient: widget.apiClient,
      loadIdToken: widget.authRepository.getIdToken,
    ),
  );

  late Future<void> _prepareFuture = _prepare();
  int _selectedIndex = 0;

  Future<void> _prepare() async {
    await widget.authRepository.syncCurrentUser();
    await _controller.initialize();
  }

  Future<void> _addProduct() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => const _PhotoSourceSheet(),
    );

    if (source == null) {
      return;
    }

    final product = await _controller.pickAndUploadPhotoFrom(source);
    if (!mounted || product == null) {
      return;
    }

    await _openProductEditor(product.id);
  }

  Future<void> _openProductEditor(int productId) async {
    await _controller.openProduct(productId);
    if (!mounted) {
      return;
    }

    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => ProductScreen(
          controller: _controller,
        ),
      ),
    );

    if (!mounted) {
      return;
    }

    await _controller.refreshOverview();
  }

  void _showTopupComingSoon(int amount) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('UPI top-up for INR $amount will be wired in a later backend payment step.'),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<void>(
      future: _prepareFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const _ShellLoadingState();
        }

        if (snapshot.hasError) {
          return _ShellErrorState(
            message: snapshot.error.toString(),
            onRetry: () {
              setState(() {
                _prepareFuture = _prepare();
              });
            },
            onSignOut: widget.authRepository.signOut,
          );
        }

        return Scaffold(
          body: IndexedStack(
            index: _selectedIndex,
            children: [
              _ProductsTab(
                controller: _controller,
                currentUser: widget.authRepository.currentUser,
                onAddProduct: _addProduct,
                onOpenProduct: _openProductEditor,
              ),
              _AccountTab(
                controller: _controller,
                currentUser: widget.authRepository.currentUser,
                onSignOut: widget.authRepository.signOut,
                onTopupSelected: _showTopupComingSoon,
              ),
            ],
          ),
          bottomNavigationBar: NavigationBar(
            selectedIndex: _selectedIndex,
            onDestinationSelected: (index) {
              setState(() {
                _selectedIndex = index;
              });
            },
            destinations: const [
              NavigationDestination(
                icon: Icon(Icons.inventory_2_outlined),
                selectedIcon: Icon(Icons.inventory_2_rounded),
                label: 'Products',
              ),
              NavigationDestination(
                icon: Icon(Icons.person_outline_rounded),
                selectedIcon: Icon(Icons.person_rounded),
                label: 'Account',
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ProductsTab extends StatelessWidget {
  const _ProductsTab({
    required this.controller,
    required this.currentUser,
    required this.onAddProduct,
    required this.onOpenProduct,
  });

  final ProductImagesController controller;
  final User? currentUser;
  final Future<void> Function() onAddProduct;
  final Future<void> Function(int productId) onOpenProduct;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) {
        return Scaffold(
          appBar: _ShellAppBar(
            title: 'Products',
            subtitle: currentUser?.displayName ?? currentUser?.email ?? 'PhotoDukan',
            credits: controller.credits?.balance,
          ),
          floatingActionButton: SizedBox(
            width: MediaQuery.of(context).size.width - 40,
            child: FilledButton.icon(
              onPressed: controller.isBusy ? null : onAddProduct,
              icon: controller.isUploading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.add_a_photo_rounded),
              label: Text(controller.isUploading ? 'Creating product...' : 'Add product'),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF1F1A17),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 18),
              ),
            ),
          ),
          floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
          body: RefreshIndicator(
            onRefresh: controller.refreshOverview,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 88),
              children: [
                if (controller.errorMessage != null) ...[
                  const SizedBox(height: 16),
                  _InlineMessageCard(message: controller.errorMessage!),
                ],
                const SizedBox(height: 16),
                _ProductsSection(
                  controller: controller,
                  onOpenProduct: onOpenProduct,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _AccountTab extends StatelessWidget {
  const _AccountTab({
    required this.controller,
    required this.currentUser,
    required this.onSignOut,
    required this.onTopupSelected,
  });

  final ProductImagesController controller;
  final User? currentUser;
  final Future<void> Function() onSignOut;
  final void Function(int amount) onTopupSelected;

  @override
  Widget build(BuildContext context) {
    final quickTopups = controller.credits?.quickTopups ?? const [100, 250, 500, 1000];

    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) {
        return Scaffold(
          appBar: _ShellAppBar(
            title: 'Account',
            subtitle: currentUser?.displayName ?? currentUser?.email ?? 'PhotoDukan',
            credits: controller.credits?.balance,
          ),
          body: ListView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
            children: [
              Card(
                elevation: 0,
                color: Colors.white.withValues(alpha: 0.92),
                child: Column(
                  children: [
                    ListTile(
                      leading: const CircleAvatar(child: Icon(Icons.person_rounded)),
                      title: Text(currentUser?.displayName ?? 'PhotoDukan account'),
                      subtitle: Text(currentUser?.email ?? currentUser?.phoneNumber ?? 'Signed in'),
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(Icons.account_balance_wallet_outlined),
                      title: const Text('Credits balance'),
                      subtitle: Text('${controller.credits?.balance ?? 0} credits available'),
                      trailing: const Text('1 INR / credit'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Card(
                elevation: 0,
                color: Colors.white.withValues(alpha: 0.92),
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Quick UPI top-up',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Standard top-up layout for India. Payment wiring comes in the next backend step.',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: const Color(0xFF6A5545),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: quickTopups
                            .map(
                              (amount) => OutlinedButton(
                                onPressed: () => onTopupSelected(amount),
                                child: Text('INR $amount'),
                              ),
                            )
                            .toList(),
                      ),
                      const SizedBox(height: 16),
                      const ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: Icon(Icons.qr_code_scanner_rounded),
                        title: Text('Preferred UPI'),
                        subtitle: Text('photodukan@upi'),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              FilledButton.tonalIcon(
                onPressed: onSignOut,
                icon: const Icon(Icons.logout_rounded),
                label: const Text('Logout'),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ShellAppBar extends StatelessWidget implements PreferredSizeWidget {
  const _ShellAppBar({
    required this.title,
    required this.subtitle,
    required this.credits,
  });

  final String title;
  final String subtitle;
  final int? credits;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight + 8);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      surfaceTintColor: Colors.transparent,
      scrolledUnderElevation: 0,
      titleSpacing: 20,
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: const Color(0xFF6A5545),
            ),
          ),
        ],
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

class _ProductsSection extends StatelessWidget {
  const _ProductsSection({required this.controller, required this.onOpenProduct});

  final ProductImagesController controller;
  final Future<void> Function(int productId) onOpenProduct;

  @override
  Widget build(BuildContext context) {
    if (controller.isInitializing && controller.products.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 48),
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (controller.products.isEmpty) {
      return Card(
        elevation: 0,
        color: Colors.white.withValues(alpha: 0.92),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const Icon(Icons.inventory_2_outlined, size: 40, color: Color(0xFF6A5545)),
              const SizedBox(height: 12),
              Text(
                'No products yet',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              Text(
                'Add your first product photo to start generating marketplace-ready visuals.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: const Color(0xFF6A5545),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
        childAspectRatio: 1,
      ),
      itemCount: controller.products.length,
      itemBuilder: (context, index) {
        final product = controller.products[index];
        return _ProductGridTile(
          controller: controller,
          product: product,
          onTap: () => onOpenProduct(product.id),
        );
      },
    );
  }
}

class _ProductGridTile extends StatelessWidget {
  const _ProductGridTile({
    required this.controller,
    required this.product,
    required this.onTap,
  });

  final ProductImagesController controller;
  final ProductSummary product;
  final Future<void> Function() onTap;

  @override
  Widget build(BuildContext context) {
    final imageUrl = product.latestAsset?.imageUrl;

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Material(
        color: const Color(0xFFF5EBDD),
        child: InkWell(
          onTap: onTap,
          child: imageUrl != null
              ? Image.network(
                  controller.resolveImageUrl(imageUrl),
                  headers: controller.imageHeaders,
                  fit: BoxFit.cover,
                )
              : const Center(
                  child: Icon(Icons.image_outlined, color: Color(0xFF6A5545), size: 32),
                ),
        ),
      ),
    );
  }
}

class _InlineMessageCard extends StatelessWidget {
  const _InlineMessageCard({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: const Color(0xFFFFF2EE),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            const Icon(Icons.info_outline_rounded, color: Color(0xFFB94E2D)),
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
      ),
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
            ListTile(
              leading: const Icon(Icons.camera_alt_rounded),
              title: const Text('Take a photo'),
              subtitle: const Text('Capture a fresh product shot now.'),
              onTap: () => Navigator.of(context).pop(ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_rounded),
              title: const Text('Choose from gallery'),
              subtitle: const Text('Pick an existing image from your device.'),
              onTap: () => Navigator.of(context).pop(ImageSource.gallery),
            ),
          ],
        ),
      ),
    );
  }
}

class _ShellLoadingState extends StatelessWidget {
  const _ShellLoadingState();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}

class _ShellErrorState extends StatelessWidget {
  const _ShellErrorState({
    required this.message,
    required this.onRetry,
    required this.onSignOut,
  });

  final String message;
  final VoidCallback onRetry;
  final Future<void> Function() onSignOut;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Card(
            margin: const EdgeInsets.all(24),
            color: Colors.white.withValues(alpha: 0.94),
            child: Padding(
              padding: const EdgeInsets.all(28),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'We could not load your workspace.',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(message),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: FilledButton(
                          onPressed: onRetry,
                          child: const Text('Retry'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton(
                          onPressed: onSignOut,
                          child: const Text('Sign out'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
