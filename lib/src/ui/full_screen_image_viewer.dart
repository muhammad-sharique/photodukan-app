import 'dart:io';

import 'package:flutter/material.dart';
import 'package:gal/gal.dart';
import 'package:http/http.dart' as http;
import 'package:share_plus/share_plus.dart';

/// Opens [FullScreenImageViewer] as a full-screen route.
Future<void> openFullScreenImage(
  BuildContext context, {
  required String imageUrl,
  Map<String, String>? headers,
  String? heroTag,
}) {
  return Navigator.of(context).push(
    PageRouteBuilder<void>(
      opaque: false,
      barrierColor: Colors.black,
      transitionsBuilder: (_, animation, __, child) => FadeTransition(
        opacity: animation,
        child: child,
      ),
      pageBuilder: (_, __, ___) => FullScreenImageViewer(
        imageUrl: imageUrl,
        headers: headers,
        heroTag: heroTag,
      ),
    ),
  );
}

class FullScreenImageViewer extends StatefulWidget {
  const FullScreenImageViewer({
    super.key,
    required this.imageUrl,
    this.headers,
    this.heroTag,
  });

  final String imageUrl;
  final Map<String, String>? headers;
  final String? heroTag;

  @override
  State<FullScreenImageViewer> createState() => _FullScreenImageViewerState();
}

class _FullScreenImageViewerState extends State<FullScreenImageViewer>
    with SingleTickerProviderStateMixin {
  bool _uiVisible = true;
  bool _isWorking = false;
  String? _statusMessage;
  bool _isError = false;

  // Swipe-to-dismiss
  double _dragOffset = 0;
  late final AnimationController _snapBack;
  late Animation<double> _snapBackAnim;
  late final TransformationController _transformCtrl;

  bool get _isZoomed => _transformCtrl.value.getMaxScaleOnAxis() > 1.05;

  @override
  void initState() {
    super.initState();
    _transformCtrl = TransformationController();
    _snapBack = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 220),
    );
  }

  @override
  void dispose() {
    _transformCtrl.dispose();
    _snapBack.dispose();
    super.dispose();
  }

  void _toggleUi() => setState(() => _uiVisible = !_uiVisible);

  void _onVerticalDragUpdate(DragUpdateDetails d) {
    if (_isZoomed) return;
    final newOffset = _dragOffset + d.delta.dy;
    if (newOffset >= 0) setState(() => _dragOffset = newOffset);
  }

  void _onVerticalDragEnd(DragEndDetails d) {
    if (_isZoomed) return;
    final velocity = d.velocity.pixelsPerSecond.dy;
    if (_dragOffset > 110 || velocity > 700) {
      Navigator.of(context).pop();
    } else {
      _snapBackAnim = Tween<double>(begin: _dragOffset, end: 0).animate(
        CurvedAnimation(parent: _snapBack, curve: Curves.easeOutCubic),
      )..addListener(() => setState(() => _dragOffset = _snapBackAnim.value));
      _snapBack.forward(from: 0);
    }
  }

  Future<File> _fetchToTempFile() async {
    final response = await http.get(
      Uri.parse(widget.imageUrl),
      headers: widget.headers,
    );
    if (response.statusCode != 200) {
      throw Exception('Server returned ${response.statusCode}');
    }
    final dir = Directory.systemTemp;
    final file = File(
        '${dir.path}/photodukan_${DateTime.now().millisecondsSinceEpoch}.jpg');
    await file.writeAsBytes(response.bodyBytes);
    return file;
  }

  Future<void> _runAction(String label, Future<void> Function(File) action) async {
    if (_isWorking) return;
    setState(() {
      _isWorking = true;
      _isError = false;
      _statusMessage = label;
    });
    try {
      final file = await _fetchToTempFile();
      await action(file);
      if (mounted) {
        setState(() {
          _isError = false;
          _statusMessage = label == 'Saving to gallery…' ? 'Saved to gallery!' : null;
        });
        if (_statusMessage != null) {
          await Future<void>.delayed(const Duration(seconds: 2));
          if (mounted) setState(() => _statusMessage = null);
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isError = true;
          _statusMessage = 'Error: $e';
        });
        await Future<void>.delayed(const Duration(seconds: 3));
        if (mounted) setState(() => _statusMessage = null);
      }
    } finally {
      if (mounted) setState(() => _isWorking = false);
    }
  }

  Future<void> _share() => _runAction('Preparing…', (file) async {
        final box = context.findRenderObject() as RenderBox?;
        await Share.shareXFiles(
          [XFile(file.path, mimeType: 'image/jpeg')],
          subject: 'PhotoDukan image',
          sharePositionOrigin:
              box != null ? box.localToGlobal(Offset.zero) & box.size : null,
        );
      });

  Future<void> _download() => _runAction('Saving to gallery…', (file) async {
        await Gal.putImage(file.path, album: 'PhotoDukan');
      });

  @override
  Widget build(BuildContext context) {
    final backgroundOpacity = (1.0 - (_dragOffset / 350).clamp(0.0, 0.7));

    Widget image = InteractiveViewer(
      transformationController: _transformCtrl,
      minScale: 0.5,
      maxScale: 6,
      child: Image.network(
        widget.imageUrl,
        headers: widget.headers,
        fit: BoxFit.contain,
        loadingBuilder: (_, child, progress) {
          if (progress == null) return child;
          return Center(
            child: CircularProgressIndicator(
              value: progress.expectedTotalBytes != null
                  ? progress.cumulativeBytesLoaded /
                      progress.expectedTotalBytes!
                  : null,
              color: Colors.white,
            ),
          );
        },
        errorBuilder: (_, __, ___) => const Center(
          child: Icon(Icons.broken_image_rounded,
              color: Colors.white54, size: 64),
        ),
      ),
    );

    if (widget.heroTag != null) {
      image = Hero(tag: widget.heroTag!, child: image);
    }

    return Scaffold(
      backgroundColor: Colors.black.withValues(alpha: backgroundOpacity),
      body: GestureDetector(
        onTap: _toggleUi,
        onVerticalDragUpdate: _onVerticalDragUpdate,
        onVerticalDragEnd: _onVerticalDragEnd,
        child: Transform.translate(
          offset: Offset(0, _dragOffset),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // ─── Main image ─────────────────────────────────────────
              image,

              // ─── Top bar ────────────────────────────────────────────
              AnimatedOpacity(
                opacity: _uiVisible ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 200),
                child: IgnorePointer(
                  ignoring: !_uiVisible,
                  child: SafeArea(
                    child: Align(
                      alignment: Alignment.topRight,
                      child: Padding(
                        padding: const EdgeInsets.all(8),
                        child: Material(
                          color: Colors.black54,
                          borderRadius: BorderRadius.circular(24),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(24),
                            onTap: () => Navigator.of(context).pop(),
                            child: const Padding(
                              padding: EdgeInsets.all(10),
                              child: Icon(Icons.close_rounded,
                                  color: Colors.white, size: 22),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              // ─── Bottom action bar ───────────────────────────────────
              AnimatedOpacity(
                opacity: _uiVisible ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 200),
                child: IgnorePointer(
                  ignoring: !_uiVisible,
                  child: Align(
                    alignment: Alignment.bottomCenter,
                    child: SafeArea(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (_statusMessage != null)
                              Container(
                                margin: const EdgeInsets.only(bottom: 10),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 8),
                                decoration: BoxDecoration(
                                  color: Colors.black87,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    if (!_isError)
                                      const SizedBox(
                                        width: 14,
                                        height: 14,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.white,
                                        ),
                                      )
                                    else
                                      const Icon(Icons.error_outline_rounded,
                                          color: Colors.redAccent, size: 16),
                                    const SizedBox(width: 8),
                                    Flexible(
                                      child: Text(
                                        _statusMessage!,
                                        style: const TextStyle(
                                            color: Colors.white, fontSize: 13),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 8),
                              decoration: BoxDecoration(
                                color: Colors.black54,
                                borderRadius: BorderRadius.circular(32),
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceEvenly,
                                children: [
                                  _ActionButton(
                                    icon: Icons.download_rounded,
                                    label: 'Save',
                                    onTap: _download,
                                    loading: _isWorking,
                                  ),
                                  _ActionButton(
                                    icon: Icons.share_rounded,
                                    label: 'Share',
                                    onTap: _share,
                                    loading: _isWorking,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
    required this.loading,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: loading ? null : onTap,
          child: Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, color: Colors.white, size: 24),
                const SizedBox(height: 4),
                Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
