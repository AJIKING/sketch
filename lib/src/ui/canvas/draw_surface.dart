import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../../application/canvas_controller.dart';
import '../../core/clock.dart';
import '../../domain/canvas/pixel_ops.dart';
import '../../domain/color/ink_color.dart';
import 'painted_stroke.dart';
import 'raster_layer_store.dart';
import 'raster_painter.dart';
import 'stroke_stabilizer.dart';
import 'viewport_transform.dart';

/// 塗りつぶしの許容値(0..255、各成分の差)。将来は設定 UI から変える。
const int _fillTolerance = 24;

/// 描画面(ADR 0004 ラスター / Phase3 ビューポート)。
///
/// 1 本指: 描画(ストローク座標は canvas 空間で保持)。2 本指: ズーム/回転/移動
/// (ビューポート変換)。ストローク確定/塗りつぶし/グラデは canvas 空間で焼き込む。
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
  final ValueNotifier<int> _tick = ValueNotifier<int>(0);

  PaintedStroke? _current;
  String? _currentLayerId;
  Offset? _startPos; // 非ストロークツールの開始点(view 空間)
  int _seed = 0;
  Size _docSize = Size.zero;
  StrokeStabilizer _stabilizer = StrokeStabilizer(0);

  // ビューポート(ズーム/回転/移動)。
  ViewportTransform _viewport = const ViewportTransform();
  final Map<int, Offset> _pointers = {};
  ViewportTransform? _gestureStart;
  int? _idA, _idB;
  Offset _a0 = Offset.zero, _b0 = Offset.zero;

  CanvasController get _c => widget.controller;
  double get _nowMs => widget.clock.now().millisecondsSinceEpoch.toDouble();
  bool get _strokeTool =>
      _c.tool == Tool.brush || _c.tool == Tool.smudge || _c.tool == Tool.erase;

  /// テスト/外部から現在のビューポートを読む。
  ViewportTransform get viewport => _viewport;

  /// ビューを初期状態(等倍・無回転・原点)へ戻す。
  void resetView() {
    _viewport = const ViewportTransform();
    _tick.value++;
  }

  @override
  void dispose() {
    _tick.dispose();
    super.dispose();
  }

  void _warnHidden() => ScaffoldMessenger.maybeOf(
    context,
  )?.showSnackBar(const SnackBar(content: Text('非表示のレイヤーには描けません')));

  // ---- pointers ----
  void _onDown(PointerDownEvent e) {
    _pointers[e.pointer] = e.localPosition;
    if (_pointers.length >= 2) {
      // 2 本指: 変形へ。進行中ストロークは(未焼込なので)破棄し、
      // 非ストロークツールの開始点も捨てる(離上時の誤発火を防ぐ)。
      _current = null;
      _currentLayerId = null;
      _startPos = null;
      _startGesture();
      _tick.value++;
      return;
    }
    _startPos = e.localPosition;
    if (_strokeTool) {
      if (!_c.layers.active.visible) {
        _warnHidden();
        return;
      }
      _currentLayerId = _c.layers.active.id;
      final stroke = PaintedStroke(
        tool: _c.tool,
        brushKey: _c.brush.key,
        colorHex: _c.colorHex,
        size: _c.size,
        opacity: _c.opacity,
        seed: _seed++,
      );
      _stabilizer = StrokeStabilizer(_c.stabilization);
      stroke.addPoint(
        _stabilizer.add(_viewport.toCanvas(e.localPosition)),
        _nowMs,
      );
      _current = stroke;
      _tick.value++;
    }
  }

  void _onMove(PointerMoveEvent e) {
    if (_pointers.containsKey(e.pointer)) {
      _pointers[e.pointer] = e.localPosition;
    }
    if (_pointers.length >= 2) {
      _updateGesture();
      return;
    }
    final stroke = _current;
    if (stroke == null) return;
    stroke.addPoint(
      _stabilizer.add(_viewport.toCanvas(e.localPosition)),
      _nowMs,
    );
    _tick.value++;
  }

  void _onUp(PointerUpEvent e) {
    final wasTransform = _pointers.length >= 2;
    _pointers.remove(e.pointer);
    if (wasTransform) {
      if (_pointers.length >= 2) {
        _startGesture(); // 残りの指で継続
      } else {
        _gestureStart = null;
      }
      _tick.value++;
      return;
    }
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
    final cs = _viewport.toCanvas(start);
    final cu = _viewport.toCanvas(e.localPosition);
    switch (_c.tool) {
      case Tool.fill:
        unawaited(_fillAt(cs));
      case Tool.eyedropper:
        unawaited(_sampleAt(cs));
      case Tool.gradient:
        _gradientFromTo(cs, cu);
      case Tool.brush:
      case Tool.smudge:
      case Tool.erase:
        break;
    }
  }

  void _onCancel(PointerCancelEvent e) {
    _pointers.remove(e.pointer);
    _current = null;
    _currentLayerId = null;
    if (_pointers.length < 2) _gestureStart = null;
  }

  void _startGesture() {
    final ids = _pointers.keys.toList();
    _idA = ids[0];
    _idB = ids[1];
    _a0 = _pointers[_idA]!;
    _b0 = _pointers[_idB]!;
    _gestureStart = _viewport;
  }

  void _updateGesture() {
    final start = _gestureStart;
    final a = _pointers[_idA];
    final b = _pointers[_idB];
    if (start == null || a == null || b == null) return;
    _viewport = ViewportTransform.fromTwoFinger(
      start: start,
      a0: _a0,
      b0: _b0,
      a: a,
      b: b,
    );
    _tick.value++;
  }

  // ---- baking / pixel ops (canvas 空間) ----
  void _bake(PaintedStroke stroke, String layerId) {
    if (_docSize.isEmpty) return;
    final existing = widget.surface.imageOf(layerId);
    final alphaLocked = _c.layers.layers
        .firstWhere((l) => l.id == layerId)
        .alphaLocked;
    if (alphaLocked && existing == null) return;
    final w = _docSize.width.round().clamp(1, 4096);
    final h = _docSize.height.round().clamp(1, 4096);
    _c.beginStroke(); // 変更直前に pre-stroke を履歴へ
    widget.surface.set(
      layerId,
      bakeStroke(
        existing: existing,
        stroke: stroke,
        width: w,
        height: h,
        alphaLocked: alphaLocked,
      ),
    );
  }

  (int, int, int) _currentRgb() => hexToRgb(_c.colorHex);
  int get _alpha => (_c.opacity * 255).round().clamp(0, 255);

  /// canvas(doc)座標を画像のピクセル座標へ変換する。
  (int, int) _imageCoord(Offset canvasPos, ui.Image img) => (
    (canvasPos.dx / _docSize.width * img.width).round(),
    (canvasPos.dy / _docSize.height * img.height).round(),
  );

  Future<ui.Image> _decode(Uint8List rgba, int w, int h) {
    final c = Completer<ui.Image>();
    ui.decodeImageFromPixels(rgba, w, h, ui.PixelFormat.rgba8888, c.complete);
    return c.future;
  }

  Future<void> _fillAt(Offset canvasPos) async {
    if (_docSize.isEmpty) return;
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
      final w = _docSize.width.round().clamp(1, 4096);
      final h = _docSize.height.round().clamp(1, 4096);
      final buf = Uint8List(w * h * 4);
      for (var p = 0; p < w * h; p++) {
        buf[p * 4] = r;
        buf[p * 4 + 1] = g;
        buf[p * 4 + 2] = b;
        buf[p * 4 + 3] = _alpha;
      }
      final img = await _decode(buf, w, h);
      if (!mounted) return;
      widget.surface.set(id, img);
      _tick.value++;
      return;
    }

    final bd = await existing.toByteData(format: ui.ImageByteFormat.rawRgba);
    if (!mounted || bd == null) return;
    final src = bd.buffer.asUint8List();
    final (ix, iy) = _imageCoord(canvasPos, existing);
    final out = floodFill(
      src,
      existing.width,
      existing.height,
      ix,
      iy,
      fill,
      tolerance: _fillTolerance,
    );
    final img = await _decode(out, existing.width, existing.height);
    if (!mounted) return;
    widget.surface.set(id, img);
    _tick.value++;
  }

  Future<void> _sampleAt(Offset canvasPos) async {
    final existing = widget.surface.imageOf(_c.layers.active.id);
    if (existing == null) {
      _c.setColorHex('#EFE7D6'); // 紙の色
      return;
    }
    final bd = await existing.toByteData(format: ui.ImageByteFormat.rawRgba);
    if (!mounted || bd == null) return;
    final src = bd.buffer.asUint8List();
    final (ix, iy) = _imageCoord(canvasPos, existing);
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
    if (_docSize.isEmpty || a == b) return;
    final layer = _c.layers.active;
    if (!layer.visible) {
      _warnHidden();
      return;
    }
    final id = layer.id;
    final (r, g, bb) = _currentRgb();
    final w = _docSize.width.round().clamp(1, 4096);
    final h = _docSize.height.round().clamp(1, 4096);
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

  /// アクティブレイヤーにフィルタ([op] は RGBA バッファ変換)を適用する。
  /// 空レイヤーには何もしない。undo 可能。
  Future<void> applyFilter(
    Uint8List Function(Uint8List rgba, int width, int height) op,
  ) async {
    final id = _c.layers.active.id;
    final existing = widget.surface.imageOf(id);
    if (existing == null) return;
    final bd = await existing.toByteData(format: ui.ImageByteFormat.rawRgba);
    if (!mounted || bd == null) return;
    final out = op(bd.buffer.asUint8List(), existing.width, existing.height);
    final img = await _decode(out, existing.width, existing.height);
    if (!mounted) return;
    _c.beginStroke();
    widget.surface.set(id, img);
    _tick.value++;
  }

  /// ドキュメントを等倍で合成して PNG バイト列に書き出す。
  ///
  /// 画面のビューポート(ズーム/回転/移動)に依存せず、常にキャンバス全体を
  /// 出力する(保存・サムネ・共有が拡大表示の影響を受けない)。
  Future<Uint8List?> exportPng() async {
    if (_docSize.isEmpty) return null;
    final w = _docSize.width.round().clamp(1, 4096);
    final h = _docSize.height.round().clamp(1, 4096);
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    RasterPainter(
      layers: _c.layers,
      store: widget.surface,
      liveStroke: null,
      liveLayerId: null,
      viewport: const ViewportTransform(), // 等倍・無回転で全体を出力
      docSize: _docSize,
    ).paint(canvas, Size(w.toDouble(), h.toDouble()));
    final image = await recorder.endRecording().toImage(w, h);
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    return data?.buffer.asUint8List();
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: LayoutBuilder(
        builder: (context, constraints) {
          if (_docSize.isEmpty) _docSize = constraints.biggest;
          return Listener(
            behavior: HitTestBehavior.opaque,
            onPointerDown: _onDown,
            onPointerMove: _onMove,
            onPointerUp: _onUp,
            onPointerCancel: _onCancel,
            child: CustomPaint(
              isComplex: true,
              painter: RasterPainter(
                layers: _c.layers,
                store: widget.surface,
                liveStroke: _current,
                liveLayerId: _currentLayerId,
                viewport: _viewport,
                docSize: _docSize,
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
