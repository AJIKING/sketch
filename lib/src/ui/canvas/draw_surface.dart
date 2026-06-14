import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import '../../application/canvas_controller.dart';
import '../../core/clock.dart';
import 'painted_stroke.dart';
import 'raster_layer_store.dart';
import 'raster_painter.dart';

/// 描画面(ADR 0004 ラスター)。
///
/// 描画中のストロークはベクターで上に重ね、ポインタ離上時にレイヤー画像へ
/// 同期で焼き込む(`toImageSync`)。[GlobalKey] 経由で [DrawSurfaceState.exportPng]
/// を呼ぶと現在の合成を PNG に書き出せる。
class DrawSurface extends StatefulWidget {
  const DrawSurface({
    super.key,
    required this.controller,
    required this.surface,
    required this.clock,
  });

  final CanvasController controller;
  final RasterLayerStore surface;

  /// 速度(→ ink の筆幅)を実時間に縛られず測るための時間源(ADR 0003)。
  final Clock clock;

  @override
  State<DrawSurface> createState() => DrawSurfaceState();
}

class DrawSurfaceState extends State<DrawSurface> {
  final GlobalKey _boundaryKey = GlobalKey();
  final ValueNotifier<int> _tick = ValueNotifier<int>(0);
  PaintedStroke? _current;
  String? _currentLayerId;
  int _seed = 0;
  Size _size = Size.zero;

  CanvasController get _c => widget.controller;

  double get _nowMs => widget.clock.now().millisecondsSinceEpoch.toDouble();

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
    _currentLayerId = _c.layers.active.id;
    final stroke = PaintedStroke(
      tool: _c.tool,
      brushKey: _c.brush.key,
      colorHex: _c.colorHex,
      size: _c.size,
      opacity: _c.opacity,
      seed: _seed++,
    );
    stroke.addPoint(e.localPosition, _nowMs);
    _current = stroke;
    _tick.value++;
  }

  void _onMove(PointerMoveEvent e) {
    final stroke = _current;
    if (stroke == null) return;
    stroke.addPoint(e.localPosition, _nowMs);
    _tick.value++;
  }

  void _onUp() {
    final stroke = _current;
    final id = _currentLayerId;
    if (stroke == null || id == null) return;
    _bake(stroke, id);
    _current = null;
    _currentLayerId = null;
    _tick.value++;
  }

  void _bake(PaintedStroke stroke, String layerId) {
    if (_size.isEmpty) return;
    final existing = widget.surface.imageOf(layerId);
    final alphaLocked = _c.layers.layers
        .firstWhere((l) => l.id == layerId)
        .alphaLocked;
    // アルファロックで既存が空なら塗る対象が無いので何もしない。
    if (alphaLocked && existing == null) return;
    final w = _size.width.round().clamp(1, 4096);
    final h = _size.height.round().clamp(1, 4096);
    final image = bakeStroke(
      existing: existing,
      stroke: stroke,
      width: w,
      height: h,
      alphaLocked: alphaLocked,
    );
    widget.surface.set(layerId, image);
  }

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
      child: LayoutBuilder(
        builder: (context, constraints) {
          _size = constraints.biggest;
          return Listener(
            behavior: HitTestBehavior.opaque,
            onPointerDown: _onDown,
            onPointerMove: _onMove,
            onPointerUp: (_) => _onUp(),
            onPointerCancel: (_) => _onUp(),
            child: CustomPaint(
              isComplex: true,
              painter: RasterPainter(
                layers: _c.layers,
                store: widget.surface,
                liveStroke: _current,
                liveLayerId: _currentLayerId,
                repaint: Listenable.merge([_c, _tick]),
              ),
              size: Size.infinite,
            ),
          );
        },
      ),
    );
  }
}
