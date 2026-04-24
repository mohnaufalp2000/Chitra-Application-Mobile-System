import 'package:camos/core/services/model/tire_damage_ai.dart';
import 'package:flutter/material.dart';

class BoundingBoxPainter extends CustomPainter {
  final List<TireDamageResult> detections;
  final double imageWidth;
  final double imageHeight;

  BoundingBoxPainter({
    required this.detections,
    required this.imageWidth,
    required this.imageHeight,
  });

  static const List<Color> _colors = [
    Colors.red,
    Colors.green,
    Colors.blue,
    Colors.yellow,
    Colors.purple,
    Colors.cyan,
    Colors.orange,
    Colors.pink,
  ];

  Color _getColor(int index) {
    return _colors[index % _colors.length];
  }

  bool _overlaps(Rect a, Rect b) => a.overlaps(b);

  @override
  void paint(Canvas canvas, Size size) {
    final scaleX = size.width / imageWidth;
    final scaleY = size.height / imageHeight;

    // simpan semua label yang sudah dipakai
    final List<Rect> usedLabels = [];

    for (int i = 0; i < detections.length; i++) {
      final item = detections[i];
      final bbox = item.bbox;

      final color = _getColor(i);

      double x1 = bbox[0] * scaleX;
      double y1 = bbox[1] * scaleY;
      double x2 = bbox[2] * scaleX;
      double y2 = bbox[3] * scaleY;

      final rect = Rect.fromLTRB(x1, y1, x2, y2);

      // === Fill
      canvas.drawRect(
        rect,
        Paint()
          ..color = color.withOpacity(0.15)
          ..style = PaintingStyle.fill,
      );

      // === Border
      canvas.drawRect(
        rect,
        Paint()
          ..color = color
          ..strokeWidth = 3
          ..style = PaintingStyle.stroke,
      );

      // === Text
      final textSpan = TextSpan(
        text:
            "${item.label} ${(item.confidenceLevel * 100).toStringAsFixed(1)}%",
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      );

      final tp = TextPainter(
        text: textSpan,
        textDirection: TextDirection.ltr,
      );

      tp.layout();

      // === Kandidat posisi label
      final candidates = [
        Offset(x1, y1 - tp.height - 6), // atas kiri
        Offset(x1, y2 + 2), // bawah kiri
        Offset(x2 - tp.width, y1 - tp.height - 6), // atas kanan
        Offset(x2 - tp.width, y2 + 2), // bawah kanan
      ];

      Rect? chosenRect;

      for (var pos in candidates) {
        final rectCandidate = Rect.fromLTWH(
          pos.dx,
          pos.dy,
          tp.width + 6,
          tp.height + 4,
        );

        final isCollision = usedLabels.any((r) => _overlaps(r, rectCandidate));

        final isInside = rectCandidate.top >= 0 &&
            rectCandidate.left >= 0 &&
            rectCandidate.right <= size.width &&
            rectCandidate.bottom <= size.height;

        if (!isCollision && isInside) {
          chosenRect = rectCandidate;
          break;
        }
      }

      // fallback kalau semua tabrakan → geser turun
      chosenRect ??= Rect.fromLTWH(
        x1,
        (y1 + 5).clamp(0, size.height - tp.height - 4),
        tp.width + 6,
        tp.height + 4,
      );

      usedLabels.add(chosenRect);

      // === Background
      canvas.drawRect(
        chosenRect,
        Paint()..color = Colors.black.withOpacity(0.7),
      );

      // === Text draw
      tp.paint(
        canvas,
        Offset(chosenRect.left + 3, chosenRect.top + 2),
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
