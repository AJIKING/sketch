import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../application/canvas_controller.dart' show Tool;
import '../../domain/brush/brush_preset.dart';
import '../canvas/painted_stroke.dart';
import '../canvas/stroke_render.dart';

/// ブラシの筆跡プレビュー(プロトタイプの drawBrushPreview 相当)。
///
/// 固定 seed・固定の波形ストロークで決定的に描くので golden 対象にできる
/// (`docs/test-plan.md` Golden)。
class BrushPreview extends StatelessWidget {
  const BrushPreview({
    super.key,
    required this.brushKey,
    this.brushSize = 4,
    this.colorHex = '#2A2620',
    this.width = 168,
    this.height = 52,
  });

  final String brushKey;
  final double brushSize;
  final String colorHex;
  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: height,
      child: CustomPaint(
        painter: _BrushPreviewPainter(
          brushKey: brushKey,
          brushSize: brushSize,
          colorHex: colorHex,
        ),
      ),
    );
  }
}

class _BrushPreviewPainter extends CustomPainter {
  _BrushPreviewPainter({
    required this.brushKey,
    required this.brushSize,
    required this.colorHex,
  });

  final String brushKey;
  final double brushSize;
  final String colorHex;

  @override
  void paint(Canvas canvas, Size size) {
    final stroke = PaintedStroke(
      tool: Tool.brush,
      brush: brushByKey(brushKey),
      colorHex: colorHex,
      size: brushSize,
      opacity: 1,
      seed: 7,
    );
    const steps = 40;
    for (var i = 0; i <= steps; i++) {
      final x = 10 + i * (size.width - 20) / steps;
      final y = size.height / 2 + math.sin(i / 4) * (size.height * 0.28);
      stroke.points.add(Offset(x, y));
    }
    renderStroke(canvas, stroke);
  }

  @override
  bool shouldRepaint(covariant _BrushPreviewPainter old) =>
      old.brushKey != brushKey ||
      old.brushSize != brushSize ||
      old.colorHex != colorHex;
}
