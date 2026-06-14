import 'dart:math' as math;
import 'dart:ui';

import '../../application/canvas_controller.dart' show Tool;
import '../../domain/brush/stroke_planner.dart';
import '../../domain/color/ink_color.dart';
import 'painted_stroke.dart';

/// 1 ストロークを Canvas へ描く(CanvasPainter / BrushPreview の共通実装)。
///
/// 幾何は domain の `stroke_planner` が決め(ADR 0003)、ここはその計画を
/// ピクセルへ落とすだけ。消しゴムは BlendMode.clear で描く。
void renderStroke(Canvas canvas, PaintedStroke stroke) {
  final pts = stroke.points;
  if (pts.isEmpty) return;

  if (stroke.tool == Tool.erase) {
    _renderErase(canvas, stroke);
    return;
  }

  final startRgb = hexToRgb(stroke.colorHex);
  // 2 色グラデブラシなら終点色まで線形補間。単色なら始点色のまま。
  final endRgb = stroke.secondColorHex == null
      ? startRgb
      : hexToRgb(stroke.secondColorHex!);
  final brush = stroke.brush;
  final rng = math.Random(stroke.seed);

  // 単独点(タップ)はその場に 1 区間を描く。
  final segmentPts = pts.length == 1 ? [pts.first, pts.first] : pts;
  final lastIndex = math.max(1, segmentPts.length - 1);
  for (var i = 1; i < segmentPts.length; i++) {
    final plan = planStroke(
      from: _toPoint(segmentPts[i - 1]),
      to: _toPoint(segmentPts[i]),
      speed: stroke.speedAt(i),
      brush: brush,
      size: stroke.size,
      opacity: stroke.opacity,
      random: rng,
    );
    final (r, g, b) = _lerpRgb(startRgb, endRgb, i / lastIndex);
    _renderPlan(canvas, plan, r, g, b);
  }
}

/// rgb を t(0..1)で線形補間する。
(int, int, int) _lerpRgb((int, int, int) a, (int, int, int) b, double t) {
  final tt = t.clamp(0.0, 1.0);
  int mix(int x, int y) => (x + (y - x) * tt).round();
  return (mix(a.$1, b.$1), mix(a.$2, b.$2), mix(a.$3, b.$3));
}

void _renderPlan(Canvas canvas, StrokePlan plan, int r, int g, int b) {
  for (final seg in plan.segments) {
    final color = Color.fromARGB(
      (seg.alpha * 255).round().clamp(0, 255),
      r,
      g,
      b,
    );
    canvas.drawLine(
      _toOffset(seg.from),
      _toOffset(seg.to),
      Paint()
        ..color = color
        ..strokeWidth = seg.width
        ..strokeCap = seg.round ? StrokeCap.round : StrokeCap.butt
        ..strokeJoin = StrokeJoin.round
        ..style = PaintingStyle.stroke,
    );
    if (seg.round) {
      canvas.drawCircle(
        _toOffset(seg.to),
        seg.width / 2,
        Paint()..color = color,
      );
    }
  }
  for (final dab in plan.dabs) {
    final center = _toOffset(dab.center);
    final alpha = (dab.alpha * 255).round().clamp(0, 255);
    if (dab.soft) {
      final shader = Gradient.radial(center, dab.radius, [
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

void _renderErase(Canvas canvas, PaintedStroke stroke) {
  final pts = stroke.points;
  final path = Path()..moveTo(pts.first.dx, pts.first.dy);
  for (var i = 1; i < pts.length; i++) {
    path.lineTo(pts[i].dx, pts[i].dy);
  }
  if (pts.length == 1) {
    path.lineTo(pts.first.dx, pts.first.dy);
  }
  canvas.drawPath(
    path,
    Paint()
      ..blendMode = BlendMode.clear
      ..strokeWidth = stroke.size
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke,
  );
}

math.Point<double> _toPoint(Offset o) => math.Point(o.dx, o.dy);
Offset _toOffset(math.Point<double> p) => Offset(p.x, p.y);
