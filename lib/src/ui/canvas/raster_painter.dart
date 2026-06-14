import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';

import '../../domain/canvas/layer_stack.dart';
import '../theme/atelier_theme.dart';
import 'blend_mode_map.dart';
import 'painted_stroke.dart';
import 'raster_layer_store.dart';
import 'stroke_render.dart';

/// レイヤー画像を紙の上に合成して描く(ADR 0004 / Phase1)。
///
/// レイヤーごとに saveLayer で「ブレンドモード + 不透明度」を適用してグループ化し、
/// 直上の `clipToLower` レイヤー群を BlendMode.srcATop で下のレイヤーにクリップする。
/// 描画中の [liveStroke] は対象レイヤー上にベクターで重ねる。
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

    final ls = layers.layers;
    var i = 0;
    while (i < ls.length) {
      final base = ls[i];
      var j = i + 1;
      final clipped = <LayerMeta>[];
      while (j < ls.length && ls[j].clipToLower) {
        clipped.add(ls[j]);
        j++;
      }
      if (base.visible) _paintGroup(canvas, rect, base, clipped);
      i = j;
    }
  }

  void _paintGroup(
    Canvas canvas,
    Rect rect,
    LayerMeta base,
    List<LayerMeta> clipped,
  ) {
    canvas.saveLayer(
      rect,
      Paint()
        ..blendMode = toUiBlendMode(base.blendMode)
        ..color = Color.fromARGB((base.opacity * 255).round(), 255, 255, 255),
    );
    _drawContent(canvas, rect, base);
    for (final child in clipped) {
      if (!child.visible) continue;
      // 下(グループの現在の内容)の不透明部分にのみ描く。
      canvas.saveLayer(
        rect,
        Paint()
          ..blendMode = BlendMode.srcATop
          ..color = Color.fromARGB(
            (child.opacity * 255).round(),
            255,
            255,
            255,
          ),
      );
      _drawContent(canvas, rect, child);
      canvas.restore();
    }
    canvas.restore();
  }

  void _drawContent(Canvas canvas, Rect rect, LayerMeta layer) {
    final image = store.imageOf(layer.id);
    if (image != null) {
      canvas.drawImageRect(
        image,
        Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble()),
        rect,
        Paint(),
      );
    }
    if (liveStroke != null && layer.id == liveLayerId) {
      renderStroke(canvas, liveStroke!);
    }
  }

  @override
  bool shouldRepaint(covariant RasterPainter old) => true;
}

/// ストロークを既存レイヤー画像へ焼き込み、新しい画像を同期生成する(ADR 0004)。
///
/// [alphaLocked] が true のとき、ストロークは既存の不透明部分にのみ反映する
/// (Phase1)。呼び出し側は「アルファロック かつ 既存が空」の場合は焼き込みを
/// 省く(塗る対象が無い)。
ui.Image bakeStroke({
  required ui.Image? existing,
  required PaintedStroke stroke,
  required int width,
  required int height,
  bool alphaLocked = false,
}) {
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);
  final bounds = Rect.fromLTWH(0, 0, width.toDouble(), height.toDouble());

  Rect srcOf(ui.Image img) =>
      Rect.fromLTWH(0, 0, img.width.toDouble(), img.height.toDouble());

  if (alphaLocked && existing != null) {
    canvas.drawImageRect(existing, srcOf(existing), bounds, Paint());
    canvas.saveLayer(bounds, Paint());
    renderStroke(canvas, stroke);
    // 既存の不透明部分でマスク(dstIn): ストロークを既存 alpha に閉じ込める。
    canvas.drawImageRect(
      existing,
      srcOf(existing),
      bounds,
      Paint()..blendMode = BlendMode.dstIn,
    );
    canvas.restore();
  } else {
    if (existing != null) {
      canvas.drawImageRect(existing, srcOf(existing), bounds, Paint());
    }
    renderStroke(canvas, stroke);
  }
  return recorder.endRecording().toImageSync(width, height);
}
