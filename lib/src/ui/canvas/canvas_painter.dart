import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';

import '../../domain/canvas/layer_stack.dart';
import '../theme/atelier_theme.dart';
import 'stroke_render.dart';
import 'vector_canvas_surface.dart';

/// レイヤーを紙の上に合成して描く CustomPainter。
///
/// 各レイヤーは saveLayer 内で描き、消しゴム(BlendMode.clear)をそのレイヤーに
/// 限定する。ストローク 1 本の描画は `stroke_render` に委ねる。
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
        renderStroke(canvas, stroke);
      }
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant CanvasPainter oldDelegate) =>
      oldDelegate.layers != layers ||
      oldDelegate.surface != surface ||
      oldDelegate.background != background;
}
