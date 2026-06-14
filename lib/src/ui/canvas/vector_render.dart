import 'dart:ui';

import '../../domain/color/ink_color.dart';
import '../../domain/vector/vector_layer.dart';
import '../../domain/vector/vector_object.dart';
import 'shape_render.dart';

/// ベクターレイヤー(ADR 0005)を `Canvas` へ描く(ui 層)。
///
/// 幾何・編集は domain(`VectorObject` / `VectorLayer`)が持ち、ここは色とパスへ
/// 落とすだけ。図形は `renderShape` を再利用する。ラスター合成へ渡すときは、
/// 呼び出し側が `PictureRecorder` 経由で `ui.Image` 化する。
void renderVectorLayer(Canvas canvas, VectorLayer layer) {
  for (final object in layer.objects) {
    renderVectorObject(canvas, object);
  }
}

void renderVectorObject(Canvas canvas, VectorObject object) {
  final (r, g, b) = hexToRgb(object.colorHex);
  switch (object) {
    case VectorStroke stroke:
      final color = Color.fromARGB(255, r, g, b);
      final first = stroke.points.first;
      if (stroke.points.length == 1) {
        canvas.drawCircle(
          Offset(first.x, first.y),
          stroke.width / 2,
          Paint()..color = color,
        );
        return;
      }
      final path = Path()..moveTo(first.x, first.y);
      for (final p in stroke.points.skip(1)) {
        path.lineTo(p.x, p.y);
      }
      canvas.drawPath(
        path,
        Paint()
          ..color = color
          ..strokeWidth = stroke.width
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round,
      );
    case VectorShapeObject shape:
      renderShape(
        canvas,
        kind: shape.kind,
        start: Offset(shape.start.x, shape.start.y),
        end: Offset(shape.end.x, shape.end.y),
        rgb: (r, g, b),
        size: shape.width,
        opacity: 1,
        filled: shape.filled,
      );
  }
}
