import 'dart:math';
import 'dart:ui';

import '../../domain/canvas/shape_kind.dart';

/// スナップ後の終点を返す。[snap] が false ならそのまま。
/// 直線は 45° 刻み、四角→正方形 / 楕円→正円に整える。
Offset snapShapeEnd(
  ShapeKind kind,
  Offset start,
  Offset end, {
  required bool snap,
}) {
  if (!snap) return end;
  final d = end - start;
  if (kind == ShapeKind.line) {
    final len = d.distance;
    const step = pi / 4;
    final angle = (atan2(d.dy, d.dx) / step).round() * step;
    return start + Offset(cos(angle) * len, sin(angle) * len);
  }
  final s = max(d.dx.abs(), d.dy.abs());
  return start + Offset(d.dx < 0 ? -s : s, d.dy < 0 ? -s : s);
}

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
    case ShapeKind.triangle:
      canvas.drawPath(
        _trianglePath(Rect.fromPoints(start, end)),
        _paint(color, size, filled),
      );
    case ShapeKind.ellipse:
      canvas.drawOval(Rect.fromPoints(start, end), _paint(color, size, filled));
  }
}

/// 外接矩形に内接する二等辺三角形(頂点は上辺中央、底辺は下辺両端)。
Path _trianglePath(Rect r) => Path()
  ..moveTo(r.center.dx, r.top)
  ..lineTo(r.right, r.bottom)
  ..lineTo(r.left, r.bottom)
  ..close();

Paint _paint(Color color, double size, bool filled) => filled
    ? (Paint()
        ..color = color
        ..style = PaintingStyle.fill)
    : (Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = size
        ..strokeJoin = StrokeJoin.round);
