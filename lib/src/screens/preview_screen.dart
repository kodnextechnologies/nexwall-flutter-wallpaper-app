import 'package:async_wallpaper/async_wallpaper.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../models.dart';

/// Full-screen preview with a "Set as wallpaper" action (Android only).
class PreviewScreen extends StatefulWidget {
  const PreviewScreen({super.key, required this.wallpaper});

  final Wallpaper wallpaper;

  @override
  State<PreviewScreen> createState() => _PreviewScreenState();
}

class _PreviewScreenState extends State<PreviewScreen> {
  bool _busy = false;

  bool get _canSet =>
      !kIsWeb &&
      defaultTargetPlatform == TargetPlatform.android &&
      widget.wallpaper.isImage;

  Future<void> _setWallpaper(WallpaperTarget target) async {
    setState(() => _busy = true);
    String message;
    try {
      final result = await AsyncWallpaper.applyWallpaper(
        StaticWallpaperRequest(
          source: WallpaperSource.url(widget.wallpaper.imageUrl),
          target: target,
          scaleMode: WallpaperScaleMode.centerCrop,
          strategy: WallpaperApplyStrategy.direct,
        ),
      );
      message = switch (result.status) {
        WallpaperOperationStatus.applied => 'Wallpaper set',
        WallpaperOperationStatus.cancelled => 'Cancelled',
        WallpaperOperationStatus.unsupported => 'Not supported on this device',
        _ => result.errorMessage ?? 'Could not set wallpaper',
      };
    } catch (e) {
      message = 'Could not set wallpaper: $e';
    }
    if (!mounted) return;
    setState(() => _busy = false);
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _chooseTarget() async {
    final target = await showModalBottomSheet<WallpaperTarget>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.home_outlined),
              title: const Text('Home screen'),
              onTap: () => Navigator.pop(context, WallpaperTarget.home),
            ),
            ListTile(
              leading: const Icon(Icons.lock_outline),
              title: const Text('Lock screen'),
              onTap: () => Navigator.pop(context, WallpaperTarget.lock),
            ),
            ListTile(
              leading: const Icon(Icons.smartphone),
              title: const Text('Both'),
              onTap: () => Navigator.pop(context, WallpaperTarget.both),
            ),
          ],
        ),
      ),
    );
    if (target != null) await _setWallpaper(target);
  }

  @override
  Widget build(BuildContext context) {
    final w = widget.wallpaper;
    return Scaffold(
      backgroundColor: Colors.black,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        title: Text(w.resolution ?? ''),
      ),
      body: Hero(
        tag: 'wallpaper-${w.id}',
        child: InteractiveViewer(
          child: SizedBox.expand(
            child: CachedNetworkImage(
              imageUrl: w.imageUrl,
              fit: BoxFit.cover,
              // Show the cached thumbnail while the full image downloads.
              placeholder: (_, _) => CachedNetworkImage(
                imageUrl: w.thumbnailUrl,
                fit: BoxFit.cover,
              ),
              errorWidget: (_, _, _) => const Center(
                child: Icon(Icons.broken_image_outlined, color: Colors.white),
              ),
            ),
          ),
        ),
      ),
      floatingActionButton: _canSet
          ? FloatingActionButton.extended(
              onPressed: _busy ? null : _chooseTarget,
              icon: _busy
                  ? const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.wallpaper),
              label: const Text('Set as wallpaper'),
            )
          : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}
