import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';

import '../../domain/canvas/layer_stack.dart';
import '../../domain/canvas/symmetry_mode.dart';
import '../../domain/color/ink_color.dart';
import '../../domain/vector/vector_layer.dart';
import '../../domain/vector/vector_object.dart';
import '../theme/atelier_theme.dart';
import 'blend_mode_map.dart';
import 'painted_stroke.dart';
import 'raster_layer_store.dart';
import 'shape_render.dart';
import 'stroke_render.dart';
import 'vector_render.dart';
import 'viewport_transform.dart';

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
    required this.viewport,
    required this.docSize,
    this.liveShape,
    this.selection,
    this.transformLayerId,
    this.layerTransform = const ViewportTransform(),
    this.vectorLayer,
    this.liveVector,
    this.selectedVectorId,
    this.symmetry = SymmetryMode.none,
    super.repaint,
  });

  final LayerStack layers;
  final RasterLayerStore store;
  final PaintedStroke? liveStroke;
  final String? liveLayerId;

  /// 描画中の図形プレビュー(無ければ null)。
  final LiveShape? liveShape;

  /// 選択範囲のパス(doc 空間、無ければ null)。アウトラインを表示する。
  final Path? selection;
  final ViewportTransform viewport;
  final Size docSize;

  /// 変形プレビュー中のレイヤー id(無ければ null)。
  final String? transformLayerId;

  /// [transformLayerId] のレイヤー画像に適用する変形(プレビュー)。
  final ViewportTransform layerTransform;

  /// ラスター層の上に重ねる確定ベクター層(ADR 0005, 無ければ null)。
  final VectorLayer? vectorLayer;

  /// 描画中のベクターオブジェクト(プレビュー、無ければ null)。
  final VectorObject? liveVector;

  /// 選択中ベクターオブジェクトの id(枠を描く、無ければ null)。
  final String? selectedVectorId;

  /// 対称(シンメトリー)描画モード。ライブ表示とガイド軸に使う。
  final SymmetryMode symmetry;

  @override
  void paint(Canvas canvas, Size size) {
    if (docSize.isEmpty) return;
    canvas.save();
    canvas.transform(viewport.toMatrix().storage);

    final rect = Offset.zero & docSize;
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

    _paintSymmetryGuides(canvas, rect);

    // ラスター層の上にベクターオーバーレイ(確定 + 描画中)を重ねる。
    final vec = vectorLayer;
    if (vec != null) renderVectorLayer(canvas, vec);
    final live = liveVector;
    if (live != null) renderVectorObject(canvas, live);
    _paintVectorSelection(canvas);

    final sel = selection;
    if (sel != null) {
      // 黒+白の二重線で、どの背景でも視認できる選択アウトライン。
      canvas.drawPath(
        sel,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.5
          ..color = const Color(0xCC000000),
      );
      canvas.drawPath(
        sel,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1
          ..color = const Color(0xFFFFFFFF),
      );
    }
    canvas.restore();
  }

  /// 対称軸のガイド(キャンバス中心の十字)。描画位置の目安。
  void _paintSymmetryGuides(Canvas canvas, Rect rect) {
    if (symmetry == SymmetryMode.none) return;
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = const Color(0x66CF4A2C);
    final showX =
        symmetry == SymmetryMode.vertical || symmetry == SymmetryMode.quad;
    final showY =
        symmetry == SymmetryMode.horizontal || symmetry == SymmetryMode.quad;
    if (showX) {
      canvas.drawLine(rect.topCenter, rect.bottomCenter, paint);
    }
    if (showY) {
      canvas.drawLine(rect.centerLeft, rect.centerRight, paint);
    }
  }

  /// 選択中ベクターオブジェクトの外接矩形を破線風の二重線で示す。
  void _paintVectorSelection(Canvas canvas) {
    final id = selectedVectorId;
    final vec = vectorLayer;
    if (id == null || vec == null) return;
    final object = vec.byId(id);
    if (object == null) return;
    final b = object.bounds;
    final rect = Rect.fromLTRB(b.left, b.top, b.right, b.bottom).inflate(6);
    canvas.drawRect(
      rect,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5
        ..color = const Color(0xCC000000),
    );
    canvas.drawRect(
      rect,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..color = const Color(0xFFFFFFFF),
    );
    // 四隅のハンドル(調整可能であることの目印)。
    final corners = [
      rect.topLeft,
      rect.topRight,
      rect.bottomLeft,
      rect.bottomRight,
    ];
    for (final c in corners) {
      canvas.drawCircle(c, 5, Paint()..color = const Color(0xFFFFFFFF));
      canvas.drawCircle(
        c,
        5,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5
          ..color = const Color(0xCC000000),
      );
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
    final mask = layer.hasMask ? store.imageOf(maskLayerId(layer.id)) : null;
    if (image != null) {
      // マスクがあれば、レイヤー画素をマスクのアルファで切り抜く(dstIn)。マスクは
      // 別レイヤーで saveLayer に包み、ライブプレビューには掛けない。
      if (mask != null) canvas.saveLayer(rect, Paint());
      final transformed = layer.id == transformLayerId;
      if (transformed) {
        canvas.save();
        canvas.transform(layerTransform.toMatrix().storage);
      }
      canvas.drawImageRect(
        image,
        Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble()),
        rect,
        Paint(),
      );
      if (transformed) canvas.restore();
      if (mask != null) {
        canvas.drawImageRect(
          mask,
          Rect.fromLTWH(0, 0, mask.width.toDouble(), mask.height.toDouble()),
          rect,
          Paint()..blendMode = BlendMode.dstIn,
        );
        canvas.restore();
      }
    }
    if (liveStroke != null && layer.id == liveLayerId) {
      renderStrokeMirrored(canvas, liveStroke!, symmetry, docSize);
    }
    final shape = liveShape;
    if (shape != null && layer.id == shape.layerId) {
      renderShape(
        canvas,
        kind: shape.kind,
        start: shape.start,
        end: shape.end,
        rgb: hexToRgb(shape.colorHex),
        size: shape.size,
        opacity: shape.opacity,
        filled: shape.filled,
      );
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
  Path? clip,
  SymmetryMode symmetry = SymmetryMode.none,
}) {
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);
  final bounds = Rect.fromLTWH(0, 0, width.toDouble(), height.toDouble());
  final doc = Size(width.toDouble(), height.toDouble());

  Rect srcOf(ui.Image img) =>
      Rect.fromLTWH(0, 0, img.width.toDouble(), img.height.toDouble());

  if (alphaLocked && existing != null) {
    canvas.drawImageRect(existing, srcOf(existing), bounds, Paint());
    canvas.save();
    if (clip != null) canvas.clipPath(clip); // 選択範囲に制限
    canvas.saveLayer(bounds, Paint());
    renderStrokeMirrored(canvas, stroke, symmetry, doc);
    // 既存の不透明部分でマスク(dstIn): ストロークを既存 alpha に閉じ込める。
    canvas.drawImageRect(
      existing,
      srcOf(existing),
      bounds,
      Paint()..blendMode = BlendMode.dstIn,
    );
    canvas.restore();
    canvas.restore();
  } else {
    if (existing != null) {
      canvas.drawImageRect(existing, srcOf(existing), bounds, Paint());
    }
    canvas.save();
    if (clip != null) canvas.clipPath(clip); // 選択範囲に制限
    renderStrokeMirrored(canvas, stroke, symmetry, doc);
    canvas.restore();
  }
  return recorder.endRecording().toImageSync(width, height);
}
