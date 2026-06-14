import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

class NetworkCachedImage extends StatelessWidget {
  final String imageUrl;
  final BoxFit fit;
  final double? width;
  final double? height;

  const NetworkCachedImage({
    super.key,
    required this.imageUrl,
    this.fit = BoxFit.cover,
    this.width,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    if (imageUrl.startsWith('http://') || imageUrl.startsWith('https://')) {
      return CachedNetworkImage(
        imageUrl: imageUrl,
        fit: fit,
        width: width,
        height: height,
        placeholder: (context, url) => Container(
          color: Colors.black12,
          child: const Center(
            child: SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
        ),
        errorWidget: (context, url, error) => Container(
          color: Colors.black12,
          child: const Center(
            child: Icon(Icons.broken_image, color: Colors.grey),
          ),
        ),
      );
    } else {
      return Image.asset(
        imageUrl,
        fit: fit,
        width: width,
        height: height,
        errorBuilder: (context, error, stackTrace) => Container(
          color: Colors.black12,
          child: const Center(
            child: Icon(Icons.broken_image, color: Colors.grey),
          ),
        ),
      );
    }
  }
}
