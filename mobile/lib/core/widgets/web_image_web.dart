import 'package:flutter/material.dart';
import 'dart:ui_web' as ui_web;
import 'package:web/web.dart' as web;

class WebImage extends StatelessWidget {
  final String imageUrl;
  final double? width;
  final double? height;
  final BoxFit? fit;
  final Widget Function(BuildContext, Object, StackTrace?)? errorBuilder;

  const WebImage({
    super.key,
    required this.imageUrl,
    this.width,
    this.height,
    this.fit,
    this.errorBuilder,
  });

  @override
  Widget build(BuildContext context) {
    // Unique ID for the view factory
    // Use a sanitized version of the URL or a random ID to avoid collisions
    final String viewId = 'img-${imageUrl.hashCode}';

    // Register the view factory. Using putIfAbsent logic conceptually by re-registering
    // (platformViewRegistry handles overwrites or we can check, but for simplicity re-registering is ok in dev)
    // A better approach for prod is to check if registered, but the API doesn't expose checking easily.
    // We register it every build? No, that's bad.
    // However, for stateless widget, we can't maintain state easily.
    // Let's use a global registration cache or idempotent registration.

    ui_web.platformViewRegistry.registerViewFactory(viewId, (int viewId) {
      final img = web.document.createElement('img') as web.HTMLImageElement;
      img.src = imageUrl;
      img.style.width = '100%';
      img.style.height = '100%';
      // Convert BoxFit to CSS object-fit
      img.style.objectFit = _getBoxFit(fit);

      // We can add simple error handling
      img.onError.listen((event) {
        // console.log('Image failed to load: $imageUrl');
      });

      return img;
    });

    return SizedBox(
      width: width,
      height: height,
      child: HtmlElementView(viewType: viewId),
    );
  }

  String _getBoxFit(BoxFit? fit) {
    switch (fit) {
      case BoxFit.cover:
        return 'cover';
      case BoxFit.contain:
        return 'contain';
      case BoxFit.fill:
        return 'fill';
      case BoxFit.fitHeight:
        return 'contain';
      case BoxFit.fitWidth:
        return 'contain';
      case BoxFit.none:
        return 'none';
      case BoxFit.scaleDown:
        return 'scale-down';
      default:
        return 'cover';
    }
  }
}
