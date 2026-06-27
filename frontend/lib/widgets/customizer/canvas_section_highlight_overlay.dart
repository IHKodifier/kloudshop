import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import 'package:kloudshop/providers/theme_providers.dart';

class CanvasSectionHighlightOverlay extends ConsumerStatefulWidget {
  final Map<String, GlobalKey> sectionKeys;

  const CanvasSectionHighlightOverlay({
    super.key,
    required this.sectionKeys,
  });

  @override
  ConsumerState<CanvasSectionHighlightOverlay> createState() => _CanvasSectionHighlightOverlayState();
}

class _CanvasSectionHighlightOverlayState extends ConsumerState<CanvasSectionHighlightOverlay> {
  Rect? _targetRect;
  String? _lastId;

  void _updateBounds() {
    if (!mounted) return;
    
    final selectedId = ref.read(selectedSectionIdProvider);
    if (selectedId == null) {
      if (_targetRect != null) {
        setState(() {
          _targetRect = null;
          _lastId = null;
        });
      }
      return;
    }

    final key = widget.sectionKeys[selectedId];
    if (key == null || key.currentContext == null) {
      if (_targetRect != null) {
        setState(() {
          _targetRect = null;
          _lastId = null;
        });
      }
      return;
    }

    final RenderBox? renderBox = key.currentContext!.findRenderObject() as RenderBox?;
    if (renderBox == null || !renderBox.hasSize) return;

    final RenderBox? overlayBox = context.findRenderObject() as RenderBox?;
    if (overlayBox == null) return;

    try {
      final position = renderBox.localToGlobal(Offset.zero, ancestor: overlayBox);
      final size = renderBox.size;
      final rect = position & size;

      if (_targetRect != rect || _lastId != selectedId) {
        setState(() {
          _targetRect = rect;
          _lastId = selectedId;
        });
      }
    } catch (_) {
      // Catch exceptions during transition/disposal
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(selectedSectionIdProvider, (prev, next) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _updateBounds());
    });

    // Also update bounds periodically to adjust for layout mutations
    WidgetsBinding.instance.addPostFrameCallback((_) => _updateBounds());

    final rect = _targetRect;
    final selectedId = ref.watch(selectedSectionIdProvider);

    if (selectedId == null || rect == null) {
      return const SizedBox.shrink();
    }

    return IgnorePointer(
      child: Stack(
        children: [
          CustomPaint(
            size: Size.infinite,
            painter: DottedBorderPainter(
              rect: rect,
              color: const Color(0xFF3B82F6),
            ),
          ),
          Positioned(
            left: rect.left,
            top: rect.top - 20 < 0 ? rect.top : rect.top - 20,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
              decoration: const BoxDecoration(
                color: Color(0xFF3B82F6),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(4),
                  topRight: Radius.circular(4),
                ),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(LucideIcons.plus, size: 9, color: Colors.white),
                  SizedBox(width: 4),
                  Text(
                    'Active Section',
                    style: TextStyle(
                      fontSize: 9,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class DottedBorderPainter extends CustomPainter {
  final Rect rect;
  final Color color;

  DottedBorderPainter({required this.rect, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    const dashWidth = 6.0;
    const dashSpace = 4.0;

    _drawDashedLine(canvas, Offset(rect.left, rect.top), Offset(rect.right, rect.top), paint, dashWidth, dashSpace);
    _drawDashedLine(canvas, Offset(rect.right, rect.top), Offset(rect.right, rect.bottom), paint, dashWidth, dashSpace);
    _drawDashedLine(canvas, Offset(rect.right, rect.bottom), Offset(rect.left, rect.bottom), paint, dashWidth, dashSpace);
    _drawDashedLine(canvas, Offset(rect.left, rect.bottom), Offset(rect.left, rect.top), paint, dashWidth, dashSpace);
  }

  void _drawDashedLine(Canvas canvas, Offset start, Offset end, Paint paint, double dashWidth, double dashSpace) {
    final double dx = end.dx - start.dx;
    final double dy = end.dy - start.dy;
    final double distance = (end - start).distance;
    
    final int count = (distance / (dashWidth + dashSpace)).floor();
    for (int i = 0; i < count; i++) {
      final double startPercent = (i * (dashWidth + dashSpace)) / distance;
      final double endPercent = ((i * (dashWidth + dashSpace)) + dashWidth) / distance;
      
      canvas.drawLine(
        Offset(start.dx + dx * startPercent, start.dy + dy * startPercent),
        Offset(start.dx + dx * endPercent, start.dy + dy * endPercent),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant DottedBorderPainter oldDelegate) {
    return oldDelegate.rect != rect || oldDelegate.color != color;
  }
}
