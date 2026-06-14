import 'dart:ui';

import '../../domain/canvas/shape_kind.dart';

/// 描画中の図形プレビュー(座標は canvas/doc 空間)。
class LiveShape {
  const LiveShape({
    required this.kind,
    required this.start,
    required this.end,
    required this.layerId,
    required this.colorHex,
    required this.size,
    required this.opacity,
    required this.filled,
  });

  final ShapeKind kind;
  final Offset start;
  final Offset end;
  final String layerId;
  final String colorHex;
  final double size;
  final double opacity;
  final bool filled;
}

/// 図形を Canvas へ描く(プレビュー/焼込で共通)。
void renderShape(
  Canvas canvas, {
  required ShapeKind kind,
  required Offset start,
  required Offset end,
  required (int, int, int) rgb,
  required double size,
  required double opacity,
  required bool filled,
}) {
  final (r, g, b) = rgb;
  final color = Color.fromARGB((opacity * 255).round().clamp(0, 255), r, g, b);
  switch (kind) {
    case ShapeKind.line:
      canvas.drawLine(
        start,
        end,
        Paint()
          ..color = color
          ..strokeWidth = size
          ..strokeCap = StrokeCap.round
          ..style = PaintingStyle.stroke,
      );
    case ShapeKind.rectangle:
      canvas.drawRect(Rect.fromPoints(start, end), _paint(color, size, filled));
    case ShapeKind.ellipse:
      canvas.drawOval(Rect.fromPoints(start, end), _paint(color, size, filled));
  }
}

Paint _paint(Color color, double size, bool filled) => filled
    ? (Paint()
        ..color = color
        ..style = PaintingStyle.fill)
    : (Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = size
        ..strokeJoin = StrokeJoin.round);
