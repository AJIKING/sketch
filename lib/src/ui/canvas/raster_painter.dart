import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';

import '../../domain/canvas/layer_stack.dart';
import '../theme/atelier_theme.dart';
import 'painted_stroke.dart';
import 'raster_layer_store.dart';
import 'stroke_render.dart';

/// レイヤー画像を紙の上に合成して描く(ADR 0004)。
///
/// 各レイヤーは saveLayer 内で不透明度を適用して描く。描画中の [liveStroke] は
/// 対象レイヤー([liveLayerId])の上にベクターで重ね、確定時に DrawSurface が
/// レイヤー画像へ焼き込む。ブレンド/クリッピング/アルファロックは Phase1 で追加。
class RasterPainter extends CustomPainter {
  RasterPainter({
    required this.layers,
    required this.store,
    required this.liveStroke,
    required this.liveLayerId,
    super.repaint,
  });

  final LayerStack layers;
  final RasterLayerStore store;
  final PaintedStroke? liveStroke;
  final String? liveLayerId;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    canvas.drawRect(rect, Paint()..color = AtelierTokens.paper);

    for (final layer in layers.layers) {
      if (!layer.visible) continue;
      final image = store.imageOf(layer.id);
      final hasLive = liveStroke != null && layer.id == liveLayerId;
      if (image == null && !hasLive) continue;

      canvas.saveLayer(
        rect,
        Paint()
          ..color = Color.fromARGB(
            (layer.opacity * 255).round(),
            255,
            255,
            255,
          ),
      );
      if (image != null) {
        canvas.drawImageRect(
          image,
          Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble()),
          rect,
          Paint(),
        );
      }
      if (hasLive) renderStroke(canvas, liveStroke!);
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant RasterPainter old) => true;
}

/// ストロークを既存レイヤー画像へ焼き込み、新しい画像を同期生成する(ADR 0004)。
ui.Image bakeStroke({
  required ui.Image? existing,
  required PaintedStroke stroke,
  required int width,
  required int height,
}) {
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);
  if (existing != null) {
    canvas.drawImageRect(
      existing,
      Rect.fromLTWH(
        0,
        0,
        existing.width.toDouble(),
        existing.height.toDouble(),
      ),
      Rect.fromLTWH(0, 0, width.toDouble(), height.toDouble()),
      Paint(),
    );
  }
  renderStroke(canvas, stroke);
  return recorder.endRecording().toImageSync(width, height);
}
