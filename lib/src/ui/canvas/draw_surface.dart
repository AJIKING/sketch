import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../../application/canvas_controller.dart';
import '../../core/clock.dart';
import '../../domain/canvas/gradient_kind.dart';
import '../../domain/canvas/pixel_ops.dart';
import '../../domain/color/ink_color.dart';
import 'painted_stroke.dart';
import 'raster_layer_store.dart';
import 'raster_painter.dart';
import 'shape_render.dart';
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
    required this.transforming,
  });

  final CanvasController controller;
  final RasterLayerStore surface;

  /// 速度(→ ink の筆幅)を実時間に縛られず測るための時間源(ADR 0003)。
  final Clock clock;

  /// 変形モードの ON/OFF(canvas_screen が確認/取消バーを出すために共有)。
  final ValueNotifier<bool> transforming;

  @override
  State<DrawSurface> createState() => DrawSurfaceState();
}

class DrawSurfaceState extends State<DrawSurface> {
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

  // レイヤー変形モード(移動/拡縮/回転 → 確定で焼き込み)。
  ViewportTransform _layerTransform = const ViewportTransform();
  String? _transformLayerId;
  Offset? _lastPanPos;

  // 図形ツール(ドラッグで bounding box → 離上で焼込)。canvas 空間。
  Offset? _shapeStart, _shapeEnd;
  String? _shapeLayerId;

  CanvasController get _c => widget.controller;
  double get _nowMs => widget.clock.now().millisecondsSinceEpoch.toDouble();
  bool get _strokeTool =>
      _c.tool == Tool.brush || _c.tool == Tool.smudge || _c.tool == Tool.erase;
  bool get _inTransform => widget.transforming.value;

  /// ジェスチャ点を扱う空間へ変換(変形中は doc 空間、通常は view 空間)。
  Offset _gPoint(Offset viewPos) =>
      _inTransform ? _viewport.toCanvas(viewPos) : viewPos;

  // ---- layer transform mode ----
  /// 変形モードに入る(アクティブレイヤー対象)。
  void enterTransform() {
    if (!_c.layers.active.visible) {
      _warnHidden();
      return;
    }
    _layerTransform = const ViewportTransform();
    _transformLayerId = _c.layers.active.id;
    _pointers.clear();
    _gestureStart = null;
    _current = null;
    _currentLayerId = null;
    _startPos = null;
    _lastPanPos = null;
    widget.transforming.value = true;
    setState(() {});
  }

  /// 変形を確定してレイヤー画像へ焼き込む(undo 可能)。
  void confirmTransform() {
    final id = _transformLayerId;
    final existing = id == null ? null : widget.surface.imageOf(id);
    // 対象レイヤーが(変形中の削除などで)消えていたら焼き込まない。
    if (id != null &&
        existing != null &&
        _c.layers.byId(id) != null &&
        !_docSize.isEmpty) {
      final w = _docSize.width.round().clamp(1, 4096);
      final h = _docSize.height.round().clamp(1, 4096);
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);
      canvas.transform(_layerTransform.toMatrix().storage);
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
      _c.beginStroke(id);
      widget.surface.set(id, recorder.endRecording().toImageSync(w, h));
    }
    _exitTransform();
  }

  /// 変形を破棄してモードを抜ける。
  void cancelTransform() => _exitTransform();

  void _exitTransform() {
    widget.transforming.value = false;
    _layerTransform = const ViewportTransform();
    _transformLayerId = null;
    _lastPanPos = null;
    _pointers.clear();
    _gestureStart = null;
    setState(() {});
  }

  /// テスト/外部から現在のビューポートを読む。
  ViewportTransform get viewport => _viewport;

  /// ビューを初期状態(等倍・無回転・原点)へ戻す。
  void resetView() {
    _viewport = const ViewportTransform();
    setState(() {});
  }

  void _warnHidden() => ScaffoldMessenger.maybeOf(
    context,
  )?.showSnackBar(const SnackBar(content: Text('非表示のレイヤーには描けません')));

  // ---- pointers ----
  void _onDown(PointerDownEvent e) {
    _pointers[e.pointer] = e.localPosition;
    if (_pointers.length >= 2) {
      // 2 本指で変形を開始。既に変形中(3 本目以降)はアンカーを変えない。
      if (_gestureStart == null) {
        // 進行中ストローク/図形は(未焼込なので)破棄し、非ストロークツールの
        // 開始点も捨てる(離上時の誤発火を防ぐ)。
        _current = null;
        _currentLayerId = null;
        _startPos = null;
        _shapeStart = null;
        _shapeEnd = null;
        _shapeLayerId = null;
        _startGesture();
      }
      setState(() {});
      return;
    }
    if (_inTransform) {
      _lastPanPos = e.localPosition; // 1 本指で移動
      return;
    }
    if (_c.tool == Tool.shape) {
      if (!_c.layers.active.visible) {
        _warnHidden();
        return;
      }
      final p = _viewport.toCanvas(e.localPosition);
      _shapeLayerId = _c.layers.active.id;
      _shapeStart = p;
      _shapeEnd = p;
      setState(() {});
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
        brush: _c.brush,
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
      setState(() {});
    }
  }

  void _onMove(PointerMoveEvent e) {
    if (_pointers.containsKey(e.pointer)) {
      _pointers[e.pointer] = e.localPosition;
    }
    if (_gestureStart != null) {
      _updateGesture();
      return;
    }
    if (_inTransform) {
      final last = _lastPanPos;
      if (last == null) {
        // ジェスチャ後などで基準が無い → ここで再アンカー(差分 0)。
        _lastPanPos = e.localPosition;
        return;
      }
      final delta =
          _viewport.toCanvas(e.localPosition) - _viewport.toCanvas(last);
      _layerTransform = _layerTransform.copyWith(
        offset: _layerTransform.offset + delta,
      );
      _lastPanPos = e.localPosition;
      setState(() {});
      return;
    }
    if (_shapeStart != null) {
      _shapeEnd = _viewport.toCanvas(e.localPosition);
      setState(() {});
      return;
    }
    final stroke = _current;
    if (stroke == null) return;
    stroke.addPoint(
      _stabilizer.add(_viewport.toCanvas(e.localPosition)),
      _nowMs,
    );
    setState(() {});
  }

  void _onUp(PointerUpEvent e) {
    final id = e.pointer;
    final gesturing = _gestureStart != null;
    _pointers.remove(id);
    if (gesturing) {
      // アンカーの指が離れたら、残りで再アンカー(2 本未満なら終了)。
      // アンカー以外(3 本目)が離れても継続。
      if (id == _idA || id == _idB) {
        if (_pointers.length >= 2) {
          _startGesture();
        } else {
          _gestureStart = null;
          _idA = null;
          _idB = null;
          // 1 本指移動へ戻る際、残る指で再アンカーさせる(ジャンプ防止)。
          _lastPanPos = null;
        }
      }
      setState(() {});
      return;
    }
    if (_inTransform) {
      _lastPanPos = null;
      return;
    }
    if (_current != null) {
      _bake(_current!, _currentLayerId!);
      _current = null;
      _currentLayerId = null;
      setState(() {});
      return;
    }
    if (_shapeStart != null) {
      _bakeShape();
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
      case Tool.text:
        unawaited(_placeTextAt(cs));
      case Tool.brush:
      case Tool.smudge:
      case Tool.erase:
      case Tool.shape:
        break;
    }
  }

  void _onCancel(PointerCancelEvent e) {
    final id = e.pointer;
    final gesturing = _gestureStart != null;
    _pointers.remove(id);
    _current = null; // 進行中ストロークを破棄
    _currentLayerId = null;
    _lastPanPos = null;
    _shapeStart = null;
    _shapeEnd = null;
    _shapeLayerId = null;
    if (gesturing && (id == _idA || id == _idB)) {
      if (_pointers.length >= 2) {
        _startGesture();
      } else {
        _gestureStart = null;
        _idA = null;
        _idB = null;
      }
    }
    setState(() {}); // キャンセルしたストローク/状態を画面へ反映
  }

  void _startGesture() {
    final ids = _pointers.keys.toList();
    _idA = ids[0];
    _idB = ids[1];
    _a0 = _gPoint(_pointers[_idA]!);
    _b0 = _gPoint(_pointers[_idB]!);
    _gestureStart = _inTransform ? _layerTransform : _viewport;
  }

  void _updateGesture() {
    final start = _gestureStart;
    final a = _pointers[_idA];
    final b = _pointers[_idB];
    if (start == null || a == null || b == null) return;
    final next = ViewportTransform.fromTwoFinger(
      start: start,
      a0: _a0,
      b0: _b0,
      a: _gPoint(a),
      b: _gPoint(b),
    );
    if (_inTransform) {
      _layerTransform = next;
    } else {
      _viewport = next;
    }
    setState(() {});
  }

  // ---- baking / pixel ops (canvas 空間) ----
  void _bake(PaintedStroke stroke, String layerId) {
    if (_docSize.isEmpty) return;
    final layer = _c.layers.byId(layerId);
    if (layer == null) return; // 焼込前にレイヤーが消えた
    final existing = widget.surface.imageOf(layerId);
    final alphaLocked = layer.alphaLocked;
    if (alphaLocked && existing == null) return;
    final w = _docSize.width.round().clamp(1, 4096);
    final h = _docSize.height.round().clamp(1, 4096);
    _c.beginStroke(layerId); // 変更直前に pre-stroke を履歴へ
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

  Offset _snapEnd(Offset start, Offset end) =>
      snapShapeEnd(_c.shapeKind, start, end, snap: _c.shapeSnap);

  void _bakeShape() {
    final id = _shapeLayerId;
    final a = _shapeStart;
    final rawEnd = _shapeEnd;
    final b = (a != null && rawEnd != null) ? _snapEnd(a, rawEnd) : rawEnd;
    if (id != null &&
        a != null &&
        b != null &&
        !_docSize.isEmpty &&
        _c.layers.byId(id) != null) {
      final w = _docSize.width.round().clamp(1, 4096);
      final h = _docSize.height.round().clamp(1, 4096);
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
      renderShape(
        canvas,
        kind: _c.shapeKind,
        start: a,
        end: b,
        rgb: _currentRgb(),
        size: _c.size,
        opacity: _c.opacity,
        filled: _c.shapeFilled,
      );
      _c.beginStroke(id);
      widget.surface.set(id, recorder.endRecording().toImageSync(w, h));
    }
    _shapeStart = null;
    _shapeEnd = null;
    _shapeLayerId = null;
    setState(() {});
  }

  /// テキストツール: タップ位置に文字を配置する。入力ダイアログ→焼込(undo 可)。
  Future<void> _placeTextAt(Offset canvasPos) async {
    if (!_c.layers.active.visible) {
      _warnHidden();
      return;
    }
    final result = await _promptText();
    if (!mounted ||
        result == null ||
        result.text.trim().isEmpty ||
        _docSize.isEmpty) {
      return;
    }
    final id = _c.layers.active.id;
    final w = _docSize.width.round().clamp(1, 4096);
    final h = _docSize.height.round().clamp(1, 4096);
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
    final (r, g, b) = _currentRgb();
    final painter = TextPainter(
      text: TextSpan(
        text: result.text,
        style: TextStyle(
          color: Color.fromARGB(_alpha, r, g, b),
          fontSize: result.fontSize,
          fontWeight: result.bold ? FontWeight.w800 : FontWeight.w600,
          height: 1.2,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: w.toDouble());
    painter.paint(canvas, canvasPos);
    _c.beginStroke(id);
    widget.surface.set(id, recorder.endRecording().toImageSync(w, h));
    setState(() {});
  }

  Future<({String text, double fontSize, bool bold})?> _promptText() {
    final controller = TextEditingController();
    var fontSize = (_c.size * 2.2).clamp(12.0, 240.0);
    var bold = false;
    return showDialog<({String text, double fontSize, bool bold})>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => AlertDialog(
          title: const Text('テキスト'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: controller,
                autofocus: true,
                maxLines: null,
                decoration: const InputDecoration(hintText: '文字を入力'),
              ),
              Row(
                children: [
                  const Text('サイズ'),
                  Expanded(
                    child: Slider(
                      value: fontSize,
                      min: 12,
                      max: 240,
                      label: fontSize.round().toString(),
                      onChanged: (v) => setLocal(() => fontSize = v),
                    ),
                  ),
                ],
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('太字'),
                value: bold,
                onChanged: (v) => setLocal(() => bold = v),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('キャンセル'),
            ),
            TextButton(
              onPressed: () => Navigator.of(
                ctx,
              ).pop((text: controller.text, fontSize: fontSize, bold: bold)),
              child: const Text('追加'),
            ),
          ],
        ),
      ),
    );
  }

  (int, int, int) _currentRgb() => hexToRgb(_c.colorHex);
  int get _alpha => (_c.opacity * 255).round().clamp(0, 255);

  /// canvas(doc)座標を画像のピクセル座標へ変換する(範囲内にクランプ)。
  (int, int) _imageCoord(Offset canvasPos, ui.Image img) => (
    (canvasPos.dx / _docSize.width * img.width).floor().clamp(0, img.width - 1),
    (canvasPos.dy / _docSize.height * img.height).floor().clamp(
      0,
      img.height - 1,
    ),
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
      _c.beginStroke(id);
      widget.surface.set(id, img);
      setState(() {});
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
    _c.beginStroke(id);
    widget.surface.set(id, img);
    setState(() {});
  }

  Future<void> _sampleAt(Offset canvasPos) async {
    if (_docSize.isEmpty) return;
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
    _c.beginStroke(id);
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
    final colors = [
      Color.fromARGB(_alpha, r, g, bb),
      Color.fromARGB(0, r, g, bb),
    ];
    final shader = _c.gradientKind == GradientKind.radial
        ? ui.Gradient.radial(a, (b - a).distance, colors)
        : ui.Gradient.linear(a, b, colors);
    canvas.drawRect(
      Rect.fromLTWH(0, 0, w.toDouble(), h.toDouble()),
      Paint()..shader = shader,
    );
    widget.surface.set(id, recorder.endRecording().toImageSync(w, h));
    setState(() {});
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
    _c.beginStroke(id);
    widget.surface.set(id, img);
    setState(() {});
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

  LiveShape? _buildLiveShape() {
    final a = _shapeStart;
    final b = _shapeEnd;
    final id = _shapeLayerId;
    if (a == null || b == null || id == null) return null;
    return LiveShape(
      kind: _c.shapeKind,
      start: a,
      end: _snapEnd(a, b),
      layerId: id,
      colorHex: _c.colorHex,
      size: _c.size,
      opacity: _c.opacity,
      filled: _c.shapeFilled,
    );
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
                liveShape: _buildLiveShape(),
                transformLayerId: _transformLayerId,
                layerTransform: _layerTransform,
              ),
              size: Size.infinite,
            ),
          );
        },
      ),
    );
  }
}
