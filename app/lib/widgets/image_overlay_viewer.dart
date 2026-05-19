import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../core/theme.dart';

class ImageOverlayViewer extends StatelessWidget {
  const ImageOverlayViewer({
    super.key,
    this.imageUrl,
    this.bboxes = const [],
  });

  final String? imageUrl;

  /// Each bbox: [x_min, y_min, x_max, y_max] in pixel coords of original image
  final List<List<double>> bboxes;

  @override
  Widget build(BuildContext context) {
    if (imageUrl == null) {
      return _Placeholder();
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        return CachedNetworkImage(
          imageUrl: imageUrl!,
          fit: BoxFit.contain,
          placeholder: (_, __) =>
              const Center(child: CircularProgressIndicator()),
          errorWidget: (_, __, ___) => _Placeholder(),
          imageBuilder: (context, provider) => _ImageWithOverlay(
            imageProvider: provider,
            bboxes: bboxes,
          ),
        );
      },
    );
  }
}

class _Placeholder extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      color: Theme.of(context).colorScheme.surface,
      child: const Center(
        child: Icon(Icons.image_not_supported_outlined, size: 64),
      ),
    );
  }
}

class _ImageWithOverlay extends StatelessWidget {
  const _ImageWithOverlay({
    required this.imageProvider,
    required this.bboxes,
  });

  final ImageProvider imageProvider;
  final List<List<double>> bboxes;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        Image(image: imageProvider, fit: BoxFit.contain),
        if (bboxes.isNotEmpty)
          CustomPaint(painter: _BboxPainter(bboxes: bboxes)),
      ],
    );
  }
}

class _BboxPainter extends CustomPainter {
  const _BboxPainter({required this.bboxes});
  final List<List<double>> bboxes;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = kDefectColor
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke;

    for (final bbox in bboxes) {
      if (bbox.length < 4) continue;
      // Assume bbox coords are normalized 0–1 relative to image dimensions
      final rect = Rect.fromLTRB(
        bbox[0] * size.width,
        bbox[1] * size.height,
        bbox[2] * size.width,
        bbox[3] * size.height,
      );
      canvas.drawRect(rect, paint);
    }
  }

  @override
  bool shouldRepaint(_BboxPainter old) => old.bboxes != bboxes;
}
