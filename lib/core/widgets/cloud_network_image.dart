import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Displays a network image from Firebase Storage.
/// On Flutter Web (CanvasKit), uses a native HTML `<img>` element via
/// [HtmlElementView.fromTagName] so images load even when bucket CORS is not
/// configured for `localhost`.
class CloudNetworkImage extends StatelessWidget {
  final String url;
  final double? width;
  final double? height;
  final BoxFit fit;
  final Widget Function(BuildContext, Object, StackTrace?)? errorBuilder;

  const CloudNetworkImage({
    super.key,
    required this.url,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.errorBuilder,
  });

  @override
  Widget build(BuildContext context) {
    if (kIsWeb) {
      return SizedBox(
        width: width,
        height: height,
        child: HtmlElementView.fromTagName(
          tagName: 'img',
          onElementCreated: (Object element) {
            final dynamic img = element;
            img.src = url;
            img.style.width = '100%';
            img.style.height = '100%';
            img.style.objectFit = fit == BoxFit.contain ? 'contain' : 'cover';
            img.style.display = 'block';
          },
        ),
      );
    }

    return Image.network(
      url,
      width: width,
      height: height,
      fit: fit,
      gaplessPlayback: true,
      errorBuilder: errorBuilder,
    );
  }
}
