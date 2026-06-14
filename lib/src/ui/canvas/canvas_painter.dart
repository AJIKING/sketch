import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';

import '../../application/canvas_controller.dart' show Tool;
import '../../domain/brush/brush_preset.dart';
import '../../domain/brush/stroke_planner.dart';
import '../../domain/canvas/layer_stack.dart';
import '../../domain/color/ink_color.dart';
import '../theme/atelier_theme.dart';
import 'painted_stroke.dart';
import 'vector_canvas_surface.dart';

/// レイヤーを紙の上に合成して描く CustomPainter。
///
/// 各レイヤーは saveLayer 内で描き、消しゴム(BlendMode.clear)をそのレイヤーに
/// 限定する。ストロークの幾何は domain の `stroke_planner` が決める(ADR 0003)。
class CanvasPainter extends CustomPainter {
  CanvasPainter({
    required this.layers,
    required this.surface,
    required this.background,
    super.repaint,
  });

  final LayerStack layers;
  final VectorCanvasSurface surface;

  /// 既存スケッチを開いたときの背景画像(編集中は読み取り専用)。
  final ui.Image? background;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = AtelierTokens.paper);

    if (background != null) {
      paintImage(
        canvas: canvas,
        rect: Offset.zero & size,
        image: background!,
        fit: BoxFit.cover,
        filterQuality: FilterQuality.medium,
      );
    }

    for (final layer in layers.layers) {
      if (!layer.visible) continue;
      final alpha = (layer.opacity * 255).round();
      canvas.saveLayer(
        Offset.zero & size,
        Paint()..color = Color.fromARGB(alpha, 255, 255, 255),
      );
      for (final stroke in surface.strokesOf(layer.id)) {
        _paintStroke(canvas, stroke);
      }
      canvas.restore();
    }
  }

  void _paintStroke(Canvas canvas, PaintedStroke stroke) {
    final pts = stroke.points;
    if (pts.isEmpty) return;

    if (stroke.tool == Tool.erase) {
      _paintErase(canvas, stroke);
      return;
    }

    final (r, g, b) = hexToRgb(stroke.colorHex);
    final brush = brushByKey(stroke.brushKey);
    final rng = math.Random(stroke.seed);

    // 単独点(タップ)はその場に 1 区間を描く。
    final segmentPts = pts.length == 1 ? [pts.first, pts.first] : pts;
    for (var i = 1; i < segmentPts.length; i++) {
      final plan = planStroke(
        from: _toPoint(segmentPts[i - 1]),
        to: _toPoint(segmentPts[i]),
        speed: 0,
        brush: brush,
        size: stroke.size,
        opacity: stroke.opacity,
        random: rng,
      );
      _paintPlan(canvas, plan, r, g, b, stroke.tool);
    }
  }

  void _paintPlan(
    Canvas canvas,
    StrokePlan plan,
    int r,
    int g,
    int b,
    Tool tool,
  ) {
    for (final seg in plan.segments) {
      final paint = Paint()
        ..color = Color.fromARGB((seg.alpha * 255).round(), r, g, b)
        ..strokeWidth = seg.width
        ..strokeCap = seg.round ? StrokeCap.round : StrokeCap.butt
        ..strokeJoin = StrokeJoin.round
        ..style = PaintingStyle.stroke;
      canvas.drawLine(_toOffset(seg.from), _toOffset(seg.to), paint);
      if (seg.round) {
        canvas.drawCircle(
          _toOffset(seg.to),
          seg.width / 2,
          Paint()..color = Color.fromARGB((seg.alpha * 255).round(), r, g, b),
        );
      }
    }
    for (final dab in plan.dabs) {
      final center = _toOffset(dab.center);
      final alpha = (dab.alpha * 255).round().clamp(0, 255);
      if (dab.soft) {
        final shader = ui.Gradient.radial(center, dab.radius, [
          Color.fromARGB(alpha, r, g, b),
          Color.fromARGB(0, r, g, b),
        ]);
        canvas.drawCircle(center, dab.radius, Paint()..shader = shader);
      } else {
        canvas.drawCircle(
          center,
          dab.radius,
          Paint()..color = Color.fromARGB(alpha, r, g, b),
        );
      }
    }
  }

  void _paintErase(Canvas canvas, PaintedStroke stroke) {
    final pts = stroke.points.length == 1
        ? [stroke.points.first, stroke.points.first]
        : stroke.points;
    final paint = Paint()
      ..blendMode = BlendMode.clear
      ..strokeWidth = stroke.size
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;
    final path = Path()..moveTo(pts.first.dx, pts.first.dy);
    for (var i = 1; i < pts.length; i++) {
      path.lineTo(pts[i].dx, pts[i].dy);
    }
    canvas.drawPath(path, paint);
  }

  math.Point<double> _toPoint(Offset o) => math.Point(o.dx, o.dy);
  Offset _toOffset(math.Point<double> p) => Offset(p.x, p.y);

  @override
  bool shouldRepaint(covariant CanvasPainter oldDelegate) =>
      oldDelegate.layers != layers ||
      oldDelegate.surface != surface ||
      oldDelegate.background != background;
}
