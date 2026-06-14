import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import '../../application/canvas_controller.dart';
import 'canvas_painter.dart';
import 'painted_stroke.dart';
import 'vector_canvas_surface.dart';

/// 描画面。ポインタ入力をストロークへ変換し、合成結果を描く。
///
/// [GlobalKey] 経由で [DrawSurfaceState.exportPng] を呼ぶと現在の合成を PNG に
/// 書き出せる(保存・ギャラリー反映に使う)。
class DrawSurface extends StatefulWidget {
  const DrawSurface({
    super.key,
    required this.controller,
    required this.surface,
    this.background,
  });

  final CanvasController controller;
  final VectorCanvasSurface surface;
  final ui.Image? background;

  @override
  State<DrawSurface> createState() => DrawSurfaceState();
}

class DrawSurfaceState extends State<DrawSurface> {
  final GlobalKey _boundaryKey = GlobalKey();
  final ValueNotifier<int> _tick = ValueNotifier<int>(0);
  PaintedStroke? _current;
  int _seed = 0;

  CanvasController get _c => widget.controller;

  @override
  void dispose() {
    _tick.dispose();
    super.dispose();
  }

  void _onDown(PointerDownEvent e) {
    if (!_c.layers.active.visible) {
      ScaffoldMessenger.maybeOf(
        context,
      )?.showSnackBar(const SnackBar(content: Text('非表示のレイヤーには描けません')));
      return;
    }
    _c.beginStroke();
    final stroke = PaintedStroke(
      tool: _c.tool,
      brushKey: _c.brush.key,
      colorHex: _c.colorHex,
      size: _c.size,
      opacity: _c.opacity,
      seed: _seed++,
    );
    widget.surface.add(_c.layers.active.id, stroke);
    stroke.points.add(e.localPosition);
    _current = stroke;
    _tick.value++;
  }

  void _onMove(PointerMoveEvent e) {
    final stroke = _current;
    if (stroke == null) return;
    stroke.points.add(e.localPosition);
    _tick.value++;
  }

  void _onUp() => _current = null;

  /// 現在の合成を PNG バイト列に書き出す。
  Future<Uint8List?> exportPng({double pixelRatio = 3}) async {
    final boundary =
        _boundaryKey.currentContext?.findRenderObject()
            as RenderRepaintBoundary?;
    if (boundary == null) return null;
    final image = await boundary.toImage(pixelRatio: pixelRatio);
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    return data?.buffer.asUint8List();
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      key: _boundaryKey,
      child: Listener(
        behavior: HitTestBehavior.opaque,
        onPointerDown: _onDown,
        onPointerMove: _onMove,
        onPointerUp: (_) => _onUp(),
        onPointerCancel: (_) => _onUp(),
        child: CustomPaint(
          isComplex: true,
          painter: CanvasPainter(
            layers: _c.layers,
            surface: widget.surface,
            background: widget.background,
            repaint: Listenable.merge([_c, _tick]),
          ),
          size: Size.infinite,
        ),
      ),
    );
  }
}
