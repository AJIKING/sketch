import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import '../../application/canvas_controller.dart';
import '../../core/clock.dart';
import '../../domain/canvas/pixel_ops.dart';
import '../../domain/color/ink_color.dart';
import 'painted_stroke.dart';
import 'raster_layer_store.dart';
import 'raster_painter.dart';

/// 塗りつぶしの許容値(0..255、各成分の差)。将来は設定 UI から変える。
const int _fillTolerance = 24;

/// 描画面(ADR 0004 ラスター)。
///
/// ブラシ/スマッジ/消しゴムはベクターのライブ描画→離上で焼き込み。
/// 塗りつぶし/スポイト/グラデーションはピクセル操作(`pixel_ops`)で焼き込む。
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
  Offset? _startPos;
  int _seed = 0;
  Size _size = Size.zero;

  CanvasController get _c => widget.controller;

  double get _nowMs => widget.clock.now().millisecondsSinceEpoch.toDouble();

  bool get _strokeTool =>
      _c.tool == Tool.brush || _c.tool == Tool.smudge || _c.tool == Tool.erase;

  @override
  void dispose() {
    _tick.dispose();
    super.dispose();
  }

  void _warnHidden() => ScaffoldMessenger.maybeOf(
    context,
  )?.showSnackBar(const SnackBar(content: Text('非表示のレイヤーには描けません')));

  void _onDown(PointerDownEvent e) {
    if (!_strokeTool) {
      _startPos = e.localPosition;
      return;
    }
    if (!_c.layers.active.visible) {
      _warnHidden();
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

  void _onUp(Offset up) {
    if (_current != null) {
      _bake(_current!, _currentLayerId!);
      _current = null;
      _currentLayerId = null;
      _tick.value++;
      return;
    }
    final start = _startPos;
    _startPos = null;
    if (start == null) return;
    switch (_c.tool) {
      case Tool.fill:
        unawaited(_fillAt(start));
      case Tool.eyedropper:
        unawaited(_sampleAt(start));
      case Tool.gradient:
        _gradientFromTo(start, up);
      case Tool.brush:
      case Tool.smudge:
      case Tool.erase:
        break;
    }
  }

  void _bake(PaintedStroke stroke, String layerId) {
    if (_size.isEmpty) return;
    final existing = widget.surface.imageOf(layerId);
    final alphaLocked = _c.layers.layers
        .firstWhere((l) => l.id == layerId)
        .alphaLocked;
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

  (int, int, int) _currentRgb() => hexToRgb(_c.colorHex);

  int get _alpha => (_c.opacity * 255).round().clamp(0, 255);

  Future<ui.Image> _decode(Uint8List rgba, int w, int h) {
    final c = Completer<ui.Image>();
    ui.decodeImageFromPixels(rgba, w, h, ui.PixelFormat.rgba8888, c.complete);
    return c.future;
  }

  Future<void> _fillAt(Offset local) async {
    if (_size.isEmpty) return;
    final layer = _c.layers.active;
    if (!layer.visible) {
      _warnHidden();
      return;
    }
    final id = layer.id;
    final (r, g, b) = _currentRgb();
    final fill = (r, g, b, _alpha);
    final existing = widget.surface.imageOf(id);
    _c.beginStroke();

    if (existing == null) {
      final w = _size.width.round().clamp(1, 4096);
      final h = _size.height.round().clamp(1, 4096);
      final buf = Uint8List(w * h * 4);
      for (var p = 0; p < w * h; p++) {
        buf[p * 4] = r;
        buf[p * 4 + 1] = g;
        buf[p * 4 + 2] = b;
        buf[p * 4 + 3] = _alpha;
      }
      widget.surface.set(id, await _decode(buf, w, h));
      _tick.value++;
      return;
    }

    final bd = await existing.toByteData(format: ui.ImageByteFormat.rawRgba);
    if (bd == null) return;
    final src = bd.buffer.asUint8List();
    final ix = (local.dx / _size.width * existing.width).round();
    final iy = (local.dy / _size.height * existing.height).round();
    final out = floodFill(
      src,
      existing.width,
      existing.height,
      ix,
      iy,
      fill,
      tolerance: _fillTolerance,
    );
    widget.surface.set(id, await _decode(out, existing.width, existing.height));
    _tick.value++;
  }

  Future<void> _sampleAt(Offset local) async {
    final existing = widget.surface.imageOf(_c.layers.active.id);
    if (existing == null) {
      _c.setColorHex('#EFE7D6'); // 紙の色
      return;
    }
    final bd = await existing.toByteData(format: ui.ImageByteFormat.rawRgba);
    if (bd == null) return;
    final src = bd.buffer.asUint8List();
    final ix = (local.dx / _size.width * existing.width).round();
    final iy = (local.dy / _size.height * existing.height).round();
    final (r, g, b, a) = samplePixel(
      src,
      existing.width,
      existing.height,
      ix,
      iy,
    );
    _c.setColorHex(a == 0 ? '#EFE7D6' : rgbToHex(r, g, b));
  }

  void _gradientFromTo(Offset a, Offset b) {
    if (_size.isEmpty || a == b) return;
    final layer = _c.layers.active;
    if (!layer.visible) {
      _warnHidden();
      return;
    }
    final id = layer.id;
    final (r, g, bb) = _currentRgb();
    final w = _size.width.round().clamp(1, 4096);
    final h = _size.height.round().clamp(1, 4096);
    _c.beginStroke();
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    final existing = widget.surface.imageOf(id);
    if (existing != null) {
      canvas.drawImageRect(
        existing,
        Rect.fromLTWH(
          0,
          0,
          existing.width.toDouble(),
          existing.height.toDouble(),
        ),
        Rect.fromLTWH(0, 0, w.toDouble(), h.toDouble()),
        Paint(),
      );
    }
    final shader = ui.Gradient.linear(a, b, [
      Color.fromARGB(_alpha, r, g, bb),
      Color.fromARGB(0, r, g, bb),
    ]);
    canvas.drawRect(
      Rect.fromLTWH(0, 0, w.toDouble(), h.toDouble()),
      Paint()..shader = shader,
    );
    widget.surface.set(id, recorder.endRecording().toImageSync(w, h));
    _tick.value++;
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
            onPointerUp: (e) => _onUp(e.localPosition),
            onPointerCancel: (e) => _onUp(e.localPosition),
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
