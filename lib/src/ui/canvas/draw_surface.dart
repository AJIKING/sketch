import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../../application/canvas_controller.dart';
import '../../application/vector_controller.dart';
import '../../core/clock.dart';
import '../../domain/canvas/gradient_direction.dart';
import '../../domain/canvas/layer_stack.dart';
import '../../domain/canvas/pixel_ops.dart';
import '../../domain/canvas/selection_kind.dart';
import '../../domain/color/ink_color.dart';
import '../../domain/timelapse/timelapse_frame.dart';
import '../../domain/vector/vector_object.dart';
import '../theme/atelier_theme.dart';
import 'blend_mode_map.dart';
import 'color_picker.dart';
import 'gradient_settings.dart';
import 'gradient_shader.dart';
import 'painted_stroke.dart';
import 'raster_layer_store.dart';
import 'raster_painter.dart';
import 'shape_render.dart';
import 'stroke_stabilizer.dart';
import 'text_fonts.dart';
import 'vector_render.dart';
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
    this.onToggleUi,
    this.vector,
    this.onCommitted,
    this.documentSize,
  });

  final CanvasController controller;
  final RasterLayerStore surface;

  /// 固定解像度ドキュメントの寸法(ADR 0006)。null なら画面サイズ追従(従来)。
  final Size? documentSize;

  /// ベクターオーバーレイ(ADR 0005 Phase 2)。null なら無効。
  final VectorController? vector;

  /// 速度(→ ink の筆幅)を実時間に縛られず測るための時間源(ADR 0003)。
  final Clock clock;

  /// 変形モードの ON/OFF(canvas_screen が確認/取消バーを出すために共有)。
  final ValueNotifier<bool> transforming;

  /// キャンバス長押しでツール UI の表示/非表示を切り替える(任意)。
  final VoidCallback? onToggleUi;

  /// 確定(焼き込み)ごとに呼ばれる(タイムラプスのフレーム取得などに使う)。
  final VoidCallback? onCommitted;

  @override
  State<DrawSurface> createState() => DrawSurfaceState();
}

class DrawSurfaceState extends State<DrawSurface> {
  PaintedStroke? _current;
  String? _currentLayerId;
  Offset? _startPos; // 非ストロークツールの開始点(view 空間)
  int _seed = 0;
  Size _docSize = Size.zero; // アートボード(固定解像度)の寸法
  Size _viewSize = Size.zero; // 直近の表示域。変化したら中央フィットし直す
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

  // 選択範囲(doc 空間の Path)。確定後は描画/焼込をこの範囲に制限する。
  Path? _selection;
  List<Offset>? _selDraft; // 作成中(canvas 空間の点列)

  /// 現在の選択範囲(テスト/外部参照用)。
  Path? get selection => _selection;
  bool get hasSelection => _selection != null;

  // 長押しスポイト(どのツールでも、その場で長押し→色吸い取り)。
  Timer? _longPressTimer;
  Offset? _longPressPos; // view 空間
  bool _longPressFired = false;
  static const int _longPressMs = 450;
  static const double _longPressSlop = 12;

  // ベクターモードの進行中操作(canvas/doc 空間)。
  List<Offset>? _vecStrokePts; // 描画中のストローク点列
  Offset? _vecShapeStart, _vecShapeEnd; // 描画中の図形
  bool _vecMoving = false; // 選択オブジェクトの移動中
  Offset? _vecLastPos; // 移動の前回位置

  // 長押し起動のオブジェクト調整モード(1本指=移動 / 2本指=拡縮)。
  Offset? _adjLastPos; // 1 本指移動の前回位置(canvas 空間)
  double _adjPinchPrevDist = 0; // 直前の 2 指間距離(view 空間)
  bool _adjMoved = false; // ドラッグ/ピンチで動いたか(タップ判定用)

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onControllerChanged);
    widget.vector?.addListener(_onVectorChanged);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onControllerChanged);
    widget.vector?.removeListener(_onVectorChanged);
    _longPressTimer?.cancel();
    super.dispose();
  }

  /// ベクター状態の変化(選択・undo 等)で再描画する。ベクターモードが切れたら
  /// 進行中のベクター操作も破棄する(描きかけが次の操作へ漏れないように)。
  void _onVectorChanged() {
    if (!mounted) return;
    if (!_vectorMode) _vecCancelInProgress();
    setState(() {});
  }

  bool get _vectorMode => widget.vector?.enabled ?? false;

  bool get _vecInProgress =>
      _vecStrokePts != null || _vecShapeStart != null || _vecMoving;

  /// 外部からの状態変更(ツール変更・レイヤー操作・undo/redo 等)で、進行中の
  /// 操作を無効化する。これらの変更中はコントローラが通知するが、通常の描画
  /// 中(down/move)はコントローラを呼ばないため、ここで安全に破棄できる。
  /// 古いレイヤーへの誤焼込や履歴の食い違いを防ぐ。
  void _onControllerChanged() {
    if (_current == null &&
        _shapeStart == null &&
        _selDraft == null &&
        !_vecInProgress) {
      return;
    }
    _cancelAllInProgress();
    // ListenableBuilder(_c) が DrawSurface を再ビルドするので setState 不要。
  }

  /// 進行中のすべての操作(ストローク/図形/選択/ベクター/長押し)を破棄する。
  void _cancelAllInProgress() {
    _current = null;
    _currentLayerId = null;
    _startPos = null;
    _shapeStart = null;
    _shapeEnd = null;
    _shapeLayerId = null;
    _selDraft = null;
    _vecCancelInProgress();
    _cancelLongPress();
  }

  CanvasController get _c => widget.controller;
  double get _nowMs => widget.clock.now().millisecondsSinceEpoch.toDouble();

  /// ポインタの筆圧を 0..1 へ正規化。圧力非対応(指など)は 1.0。
  double _pressureOf(PointerEvent e) {
    final range = e.pressureMax - e.pressureMin;
    if (range <= 0) return 1.0;
    return ((e.pressure - e.pressureMin) / range).clamp(0.0, 1.0);
  }

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

  /// ビューを初期状態へ戻す。固定解像度は中央フィット、画面サイズは等倍全面。
  void resetView() {
    _viewport = ViewportTransform.fit(_docSize, _viewSize);
    setState(() {});
  }

  void _warnHidden() => ScaffoldMessenger.maybeOf(
    context,
  )?.showSnackBar(const SnackBar(content: Text('非表示のレイヤーには描けません')));

  // ---- long-press: ツール UI の表示/非表示トグル ----
  void _startLongPress(Offset viewPos) {
    _longPressPos = viewPos;
    _longPressFired = false;
    _longPressTimer?.cancel();
    _longPressTimer = Timer(
      const Duration(milliseconds: _longPressMs),
      _fireLongPress,
    );
  }

  void _cancelLongPress() {
    _longPressTimer?.cancel();
    _longPressTimer = null;
  }

  void _fireLongPress() {
    _longPressTimer = null;
    final pos = _longPressPos;
    if (pos == null) return;
    _longPressFired = true;
    _cancelAllInProgress();
    // オブジェクトの上で長押し → そのオブジェクトの調整(移動/拡縮)モードへ。
    final vec = widget.vector;
    if (vec != null) {
      final c = _viewport.toCanvas(pos);
      final hit = vec.layer.hitTest(VecPoint(c.dx, c.dy), tolerance: 10);
      if (hit != null) {
        vec.startAdjust(hit.id);
        // 押している指をそのまま調整ドラッグの起点にする(長押し→そのまま移動)。
        // この指の up は _adjUp で正しく後始末するため _longPressFired は下げる。
        _longPressFired = false;
        _gestureStart = null; // 単指長押しなので通常 null だが念のため
        _idA = null;
        _idB = null;
        _adjLastPos = c;
        _adjMoved = false;
        vec.beginEdit(); // 動いたら undo を積む
        setState(() {});
        return;
      }
    }
    // 何も無い所での長押しはツール UI の表示/非表示を切り替える。
    widget.onToggleUi?.call();
    setState(() {});
  }

  bool get _adjusting => widget.vector?.adjusting ?? false;

  // ---- object adjust mode (long-press 起動) ----
  void _adjDown(PointerDownEvent e) {
    final vec = widget.vector!;
    if (_pointers.length >= 2) {
      final ids = _pointers.keys.toList();
      _adjPinchPrevDist = (_pointers[ids[0]]! - _pointers[ids[1]]!).distance;
      _adjMoved = true; // ピンチはタップではない
    } else {
      _adjLastPos = _viewport.toCanvas(e.localPosition);
      _adjMoved = false;
    }
    vec.beginEdit(); // 実際に動いた時だけ undo を積む
  }

  void _adjMove(PointerMoveEvent e) {
    final vec = widget.vector!;
    if (_pointers.length >= 2) {
      final ids = _pointers.keys.toList();
      final d = (_pointers[ids[0]]! - _pointers[ids[1]]!).distance;
      final sel = vec.selected;
      if (_adjPinchPrevDist > 0 && d > 0 && sel != null) {
        final b = sel.bounds;
        final anchor = VecPoint((b.left + b.right) / 2, (b.top + b.bottom) / 2);
        vec.scaleSelectedBy(d / _adjPinchPrevDist, anchor);
        _adjPinchPrevDist = d;
      }
      _adjMoved = true;
      return;
    }
    final c = _viewport.toCanvas(e.localPosition);
    final last = _adjLastPos;
    if (last != null) {
      final dx = c.dx - last.dx, dy = c.dy - last.dy;
      if (dx != 0 || dy != 0) {
        vec.moveSelectedBy(dx, dy);
        _adjMoved = true;
      }
    }
    _adjLastPos = c;
  }

  void _adjUp(PointerUpEvent e) {
    final vec = widget.vector!;
    final wasPinch = _pointers.length >= 2;
    _pointers.remove(e.pointer);
    if (_pointers.length >= 2) {
      // 指の組が変わっても拡縮が飛ばないよう、残り 2 指で基準を取り直す。
      final ids = _pointers.keys.toList();
      _adjPinchPrevDist = (_pointers[ids[0]]! - _pointers[ids[1]]!).distance;
      return;
    }
    if (wasPinch) {
      // ピンチ終了。残り 1 本で移動へ戻れるよう基準をリセット。
      _adjLastPos = null;
      _adjPinchPrevDist = 0;
      return;
    }
    if (!_adjMoved) {
      // タップ: 別オブジェクトなら切替、空なら調整終了。
      final c = _viewport.toCanvas(e.localPosition);
      final hit = vec.layer.hitTest(VecPoint(c.dx, c.dy), tolerance: 10);
      if (hit != null) {
        vec.startAdjust(hit.id);
      } else {
        vec.endAdjust();
      }
    }
    _adjLastPos = null;
    _adjMoved = false;
  }

  // ---- pointers ----
  void _onDown(PointerDownEvent e) {
    _pointers[e.pointer] = e.localPosition;
    if (_adjusting) {
      _adjDown(e);
      setState(() {});
      return;
    }
    if (_pointers.length >= 2) {
      _cancelLongPress();
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
        _selDraft = null;
        _vecCancelInProgress();
        _startGesture();
      }
      setState(() {});
      return;
    }
    if (_inTransform) {
      _lastPanPos = e.localPosition; // 1 本指で移動
      return;
    }
    // 1 本指長押しでツール UI をトグル(全ツール/ベクター共通)。動いたら成立しない。
    _startLongPress(e.localPosition);
    if (_c.tool == Tool.text) {
      // テキストはタップ位置を記録し、離上で配置/編集(ベクター扱い)。
      _startPos = e.localPosition;
      setState(() {});
      return;
    }
    if (_vectorMode) {
      _vecDown(e.localPosition);
      setState(() {});
      return;
    }
    if (_c.tool == Tool.select) {
      final cs = _viewport.toCanvas(e.localPosition);
      // 自動選択はドラフトを作らず、その場で連結領域を選ぶ。
      if (_c.selectionKind == SelectionKind.magicWand) {
        unawaited(_magicWandAt(cs));
        return;
      }
      _selDraft = [cs];
      setState(() {});
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
        // 2 色グラデブラシ時のみ終点色を持たせる(消しゴムには無効)。
        secondColorHex: _c.gradientBrush && _c.tool == Tool.brush
            ? _c.secondColorHex
            : null,
      );
      _stabilizer = StrokeStabilizer(_c.stabilization);
      stroke.addPoint(
        _stabilizer.add(_viewport.toCanvas(e.localPosition)),
        _nowMs,
        pressure: _pressureOf(e),
      );
      _current = stroke;
      setState(() {});
    }
  }

  void _onMove(PointerMoveEvent e) {
    if (_adjusting) {
      if (_pointers.containsKey(e.pointer)) {
        _pointers[e.pointer] = e.localPosition;
      }
      _adjMove(e);
      setState(() {});
      return;
    }
    if (_pointers.containsKey(e.pointer)) {
      _pointers[e.pointer] = e.localPosition;
    }
    final lp = _longPressPos;
    if (_longPressTimer != null &&
        lp != null &&
        (e.localPosition - lp).distance > _longPressSlop) {
      _cancelLongPress(); // 動いたら長押し成立しない
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
    if (_vectorMode && _vecInProgress) {
      _vecMove(e.localPosition);
      setState(() {});
      return;
    }
    if (_selDraft != null) {
      final p = _viewport.toCanvas(e.localPosition);
      if (_c.selectionKind == SelectionKind.rectangle) {
        _selDraft = [_selDraft!.first, p];
      } else {
        _selDraft!.add(p);
      }
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
      pressure: _pressureOf(e),
    );
    setState(() {});
  }

  void _onUp(PointerUpEvent e) {
    if (_adjusting && !_longPressFired) {
      _adjUp(e);
      setState(() {});
      return;
    }
    final id = e.pointer;
    final gesturing = _gestureStart != null;
    _pointers.remove(id);
    _cancelLongPress();
    if (_longPressFired) {
      // 長押しトグルで処理済み。通常のツール動作はしない。
      _longPressFired = false;
      return;
    }
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
    if (_vectorMode && _vecInProgress) {
      _vecUp(e.localPosition);
      setState(() {});
      return;
    }
    if (_current != null) {
      _bake(_current!, _currentLayerId!);
      _current = null;
      _currentLayerId = null;
      setState(() {});
      return;
    }
    if (_selDraft != null) {
      _commitSelection();
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
        unawaited(_handleTextTap(cs));
      case Tool.brush:
      case Tool.smudge:
      case Tool.erase:
      case Tool.shape:
      case Tool.select:
        break;
    }
  }

  void _onCancel(PointerCancelEvent e) {
    if (_adjusting) {
      _pointers.remove(e.pointer);
      _adjLastPos = null;
      _adjPinchPrevDist = 0;
      _adjMoved = false;
      setState(() {});
      return;
    }
    final id = e.pointer;
    final gesturing = _gestureStart != null;
    _pointers.remove(id);
    _cancelLongPress();
    _longPressFired = false;
    _current = null; // 進行中ストロークを破棄
    _currentLayerId = null;
    _lastPanPos = null;
    _shapeStart = null;
    _shapeEnd = null;
    _shapeLayerId = null;
    _selDraft = null;
    _vecCancelInProgress();
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
    final target = _targetFor(layerId);
    final maskMode = target != layerId;
    final existing = widget.surface.imageOf(target);
    // マスクはアルファロック対象外(本体のみ尊重)。
    final alphaLocked = !maskMode && layer.alphaLocked;
    if (alphaLocked && existing == null) return;
    final w = _docSize.width.round().clamp(1, 4096);
    final h = _docSize.height.round().clamp(1, 4096);
    _c.beginStroke(target); // 変更直前に pre-stroke を履歴へ
    widget.surface.set(
      target,
      bakeStroke(
        existing: existing,
        stroke: stroke,
        width: w,
        height: h,
        alphaLocked: alphaLocked,
        clip: _selection,
        symmetry: _c.symmetry,
      ),
    );
    widget.onCommitted?.call();
  }

  Offset _snapEnd(Offset start, Offset end) =>
      snapShapeEnd(_c.shapeKind, start, end, snap: _c.shapeSnap);

  // ---- selection ----
  Path? _draftToPath(List<Offset> draft) {
    if (_c.selectionKind == SelectionKind.rectangle) {
      if (draft.length < 2) return null;
      return Path()..addRect(Rect.fromPoints(draft.first, draft.last));
    }
    if (draft.isEmpty) return null;
    final path = Path()..moveTo(draft.first.dx, draft.first.dy);
    for (final p in draft.skip(1)) {
      path.lineTo(p.dx, p.dy);
    }
    return path;
  }

  /// 表示用の選択パス(作成中は draft、無ければ確定済み)。
  Path? _displaySelection() {
    final draft = _selDraft;
    if (draft != null) {
      final path = _draftToPath(draft);
      // なげなわは確定形(閉パス)と一致させてプレビューする。
      if (path != null && _c.selectionKind == SelectionKind.lasso) {
        path.close();
      }
      return path;
    }
    return _selection;
  }

  void _commitSelection() {
    final draft = _selDraft;
    _selDraft = null;
    if (draft == null) {
      setState(() {});
      return;
    }
    if (_c.selectionKind == SelectionKind.rectangle) {
      if (draft.length >= 2) {
        final r = Rect.fromPoints(draft.first, draft.last);
        // タップ程度の極小は「選択解除」とみなす。
        _selection = (r.width.abs() > 3 && r.height.abs() > 3)
            ? (Path()..addRect(r))
            : null;
      }
    } else {
      _selection = draft.length >= 3 ? (_draftToPath(draft)!..close()) : null;
    }
    setState(() {});
  }

  /// 選択を解除する。
  void deselect() {
    _selection = null;
    _selDraft = null;
    setState(() {});
  }

  /// アートボード全体を選択する。docSize 未確定なら何もしない。
  void selectAll() {
    if (_docSize.isEmpty) return;
    _selDraft = null;
    setState(() {
      _selection = Path()..addRect(Offset.zero & _docSize);
    });
  }

  /// 現在の選択範囲を反転する(アートボード全体との差分)。未選択なら全選択。
  void invertSelection() {
    if (_docSize.isEmpty) return;
    final full = Path()..addRect(Offset.zero & _docSize);
    _selDraft = null;
    setState(() {
      _selection = _selection == null
          ? full
          : Path.combine(PathOperation.difference, full, _selection!);
    });
  }

  /// 選択範囲(未選択ならレイヤー全体)を現在色で塗りつぶす(undo 可能)。
  void fillSelection() {
    final id = _c.layers.active.id;
    if (_docSize.isEmpty || _c.layers.byId(id) == null) return;
    final (r, g, b) = _currentRgb();
    _bakeOnLayer(id, (canvas, w, h) {
      canvas.drawRect(
        Rect.fromLTWH(0, 0, w.toDouble(), h.toDouble()),
        Paint()..color = Color.fromARGB(_alpha, r, g, b),
      );
    });
    setState(() {});
  }

  /// 選択範囲内をアクティブレイヤーから消す(undo 可能)。
  /// 既存画像の上に [draw] を描いてレイヤー [id] へ焼き込む共通処理(undo 可能)。
  /// [clipToSelection] が true で選択範囲があれば、新規描画をその範囲へ制限する
  /// (既存画素は範囲外も保持)。レイヤーが消えている / docSize 未確定なら何もしない。
  /// [ownerId] のレイヤーへの描画が、マスク編集中はそのマスク画素へ向く。
  /// アクティブレイヤー以外を指定したときは常に本体へ向ける。
  String _targetFor(String ownerId) =>
      ownerId == _c.layers.active.id ? _c.drawTargetId : ownerId;

  void _bakeOnLayer(
    String id,
    void Function(Canvas canvas, int width, int height) draw, {
    bool clipToSelection = true,
  }) {
    if (_docSize.isEmpty || _c.layers.byId(id) == null) return;
    final target = _targetFor(id);
    final w = _docSize.width.round().clamp(1, 4096);
    final h = _docSize.height.round().clamp(1, 4096);
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    final existing = widget.surface.imageOf(target);
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
    canvas.save();
    if (clipToSelection && _selection != null) canvas.clipPath(_selection!);
    draw(canvas, w, h);
    canvas.restore();
    _c.beginStroke(target);
    widget.surface.set(target, recorder.endRecording().toImageSync(w, h));
    widget.onCommitted?.call();
  }

  /// アクティブレイヤーを直下のレイヤーへ結合する(undo 可能)。最下層なら false。
  ///
  /// 見た目を保つため、上下それぞれの**マスクを適用した**結果を、上のブレンド+
  /// 不透明度で下へ焼き込んでから上を取り除く。下のマスクは焼き込み済みになるため
  /// 解除する(下自身のブレンド/不透明度はメタとして残す)。結合で不要になった
  /// 上レイヤー・下マスクの画素は解放する。
  bool mergeActiveDown() {
    if (_docSize.isEmpty) return false;
    final i = _c.layers.activeIndex;
    if (i <= 0) return false; // 直下が無い(最下層)
    final above = _c.layers.layers[i];
    final below = _c.layers.layers[i - 1];
    final w = _docSize.width.round().clamp(1, 4096);
    final h = _docSize.height.round().clamp(1, 4096);
    final rect = Rect.fromLTWH(0, 0, w.toDouble(), h.toDouble());

    _c.beginStructural(); // 結合前の構成 + 全画素を履歴へ積む(undo 用)

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    _paintMaskedLayer(canvas, below, rect); // 下: マスク適用済みを下地に
    if (above.visible) {
      // 上: マスク適用後にブレンド+不透明度で重ねる。
      canvas.saveLayer(
        rect,
        Paint()
          ..blendMode = toUiBlendMode(above.blendMode)
          ..color = Color.fromARGB(
            (above.opacity * 255).round(),
            255,
            255,
            255,
          ),
      );
      _paintMaskedLayer(canvas, above, rect);
      canvas.restore();
    }
    widget.surface.set(below.id, recorder.endRecording().toImageSync(w, h));

    final belowHadMask = below.hasMask;
    _c.mergeDown(i); // 上レイヤーのメタを取り除き、アクティブを下へ
    // 結合で不要になった画素のライブ参照を外す(履歴 snapshot が保持するので
    // dispose はしない=undo で復元できる)。
    widget.surface.set(maskLayerId(above.id), null); // 上のマスク
    if (belowHadMask) {
      widget.surface.set(maskLayerId(below.id), null); // 焼き込み済みの下マスク
      _c.setLayerMask(_c.layers.activeIndex, false);
    }
    setState(() {});
    return true;
  }

  /// レイヤーの本体画像を、マスクがあれば dstIn で切り抜いて [canvas] に描く。
  /// 表示(`RasterPainter._drawContent`)と同じ合成で、見た目を保って焼き込む。
  void _paintMaskedLayer(Canvas canvas, LayerMeta layer, Rect rect) {
    final img = widget.surface.imageOf(layer.id);
    if (img == null) return;
    final mask = layer.hasMask
        ? widget.surface.imageOf(maskLayerId(layer.id))
        : null;
    if (mask != null) canvas.saveLayer(rect, Paint());
    canvas.drawImageRect(img, _imageRect(img), rect, Paint());
    if (mask != null) {
      canvas.drawImageRect(
        mask,
        _imageRect(mask),
        rect,
        Paint()..blendMode = BlendMode.dstIn,
      );
      canvas.restore();
    }
  }

  Rect _imageRect(ui.Image img) =>
      Rect.fromLTWH(0, 0, img.width.toDouble(), img.height.toDouble());

  /// アクティブレイヤーにマスクを追加する(全面不透明=初期状態は見た目そのまま)。
  /// 追加後はそのままマスク編集モードに入る。undo 可能。
  void addMaskToActive() {
    if (_docSize.isEmpty) return;
    final i = _c.layers.activeIndex;
    final layer = _c.layers.active;
    if (layer.hasMask) return; // 既にある
    final w = _docSize.width.round().clamp(1, 4096);
    final h = _docSize.height.round().clamp(1, 4096);

    _c.beginStructural(); // マスク有無 + 画素をまとめて履歴へ

    // 全面白(不透明)= どこも隠さない初期マスク。消すほど隠れる。
    final recorder = ui.PictureRecorder();
    Canvas(recorder).drawRect(
      Rect.fromLTWH(0, 0, w.toDouble(), h.toDouble()),
      Paint()..color = const Color(0xFFFFFFFF),
    );
    widget.surface.set(
      maskLayerId(layer.id),
      recorder.endRecording().toImageSync(w, h),
    );
    _c.setLayerMask(i, true);
    _c.setMaskEditing(true);
    setState(() {});
  }

  /// アクティブレイヤーのマスクを解除する(画素は破棄、レイヤー本体はそのまま)。
  /// undo 可能。
  void removeMaskFromActive() {
    final i = _c.layers.activeIndex;
    final layer = _c.layers.active;
    if (!layer.hasMask) return;
    _c.beginStructural();
    widget.surface.set(maskLayerId(layer.id), null);
    _c.setLayerMask(i, false);
    setState(() {});
  }

  void clearInsideSelection() {
    final id = _c.layers.active.id;
    // 焼き込み先(マスク編集中はマスク)に画素が無ければ消す対象が無い。
    if (_selection == null || widget.surface.imageOf(_targetFor(id)) == null) {
      return;
    }
    _bakeOnLayer(id, (canvas, w, h) {
      canvas.drawRect(
        Rect.fromLTWH(0, 0, w.toDouble(), h.toDouble()),
        Paint()..blendMode = BlendMode.clear,
      );
    });
    setState(() {});
  }

  void _bakeShape() {
    final id = _shapeLayerId;
    final a = _shapeStart;
    final rawEnd = _shapeEnd;
    final b = (a != null && rawEnd != null) ? _snapEnd(a, rawEnd) : rawEnd;
    if (id != null && a != null && b != null) {
      _bakeOnLayer(
        id,
        (canvas, w, h) => renderShape(
          canvas,
          kind: _c.shapeKind,
          start: a,
          end: b,
          rgb: _currentRgb(),
          size: _c.size,
          opacity: _c.opacity,
          filled: _c.shapeFilled,
        ),
      );
    }
    _shapeStart = null;
    _shapeEnd = null;
    _shapeLayerId = null;
    setState(() {});
  }

  /// テキストツール: タップ位置に文字を配置する。入力ダイアログ→焼込(undo 可)。
  /// テキストツールのタップ。既存テキストに当たれば編集、無ければ新規作成。
  /// 内容を空にして確定すると(編集時は)削除する。テキストは焼き込まず
  /// ベクターオーバーレイの再編集可能オブジェクトとして保持する(ADR 0005)。
  Future<void> _handleTextTap(Offset canvasPos) async {
    final vec = widget.vector;
    if (vec == null || _docSize.isEmpty) return;
    final hit = vec.layer.hitTest(
      VecPoint(canvasPos.dx, canvasPos.dy),
      tolerance: 6,
    );
    final existing = hit is VectorText ? hit : null;
    final result = await _promptText(existing);
    if (!mounted || result == null) return;
    final trimmed = result.text.trim();
    if (trimmed.isEmpty) {
      if (existing != null) vec.deleteById(existing.id);
      return;
    }
    // 実フォントのロードを待ってから box を測る。未ロードのフォールバック寸法で
    // 確定すると、後で実フォントが届いたとき当たり判定/選択枠が字形とずれるため。
    if (result.fontFamily.isNotEmpty) {
      await ensureFontLoaded(result.fontFamily);
      if (!mounted) return;
    }
    final painter = buildVectorTextPainter(
      text: trimmed,
      colorHex: result.colorHex,
      fontSize: result.fontSize,
      bold: result.bold,
      underline: result.underline,
      strikethrough: result.strikethrough,
      fontFamily: result.fontFamily,
      gradient: result.gradient,
      secondColorHex: result.secondColorHex,
      gradientDirection: result.gradientDirection,
    );
    if (existing != null) {
      vec.updateText(
        existing.id,
        text: trimmed,
        fontSize: result.fontSize,
        colorHex: result.colorHex,
        boxWidth: painter.width,
        boxHeight: painter.height,
        bold: result.bold,
        underline: result.underline,
        strikethrough: result.strikethrough,
        fontFamily: result.fontFamily,
        gradient: result.gradient,
        secondColorHex: result.secondColorHex,
        gradientDirection: result.gradientDirection,
      );
    } else {
      vec.addText(
        position: VecPoint(canvasPos.dx, canvasPos.dy),
        text: trimmed,
        fontSize: result.fontSize,
        colorHex: result.colorHex,
        boxWidth: painter.width,
        boxHeight: painter.height,
        bold: result.bold,
        underline: result.underline,
        strikethrough: result.strikethrough,
        fontFamily: result.fontFamily,
        gradient: result.gradient,
        secondColorHex: result.secondColorHex,
        gradientDirection: result.gradientDirection,
      );
    }
    setState(() {});
  }

  /// テキスト設定は他ツールと同じく下から出るボトムシートで編集する。
  Future<TextEditResult?> _promptText(VectorText? existing) {
    return showModalBottomSheet<TextEditResult>(
      context: context,
      backgroundColor: AtelierTokens.surface,
      showDragHandle: true,
      isScrollControlled: true,
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * 0.92,
      ),
      builder: (_) => _TextSheet(
        initialText: existing?.text ?? '',
        initialSize: (existing?.fontSize ?? _c.size * 2.2).clamp(12.0, 240.0),
        initialColorHex: existing?.colorHex ?? _c.colorHex,
        initialBold: existing?.bold ?? false,
        initialUnderline: existing?.underline ?? false,
        initialStrikethrough: existing?.strikethrough ?? false,
        initialFontFamily: existing?.fontFamily ?? '',
        initialGradient: existing?.gradient ?? false,
        initialSecondColorHex: existing?.secondColorHex ?? _c.secondColorHex,
        initialDirection: existing?.gradientDirection ?? _c.gradientDirection,
        palette: _c.palette,
        isEditing: existing != null,
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

  /// テスト用: 自動選択を doc 座標で直接実行し、完了を待てるようにする
  /// (ポインタ経由の `unawaited` を固定 sleep で待たずに同期するため)。
  @visibleForTesting
  Future<void> magicWandAt(Offset canvasPos) => _magicWandAt(canvasPos);

  /// 自動選択(マジックワンド)。タップ点の色に連結する領域を選択パスにする。
  /// 領域はピクセル精度の走査線ラン(矩形集合)として `_selection` に載せるため、
  /// 既存の clipPath ベースの消去 / 塗り / 反転がそのまま使える。
  Future<void> _magicWandAt(Offset canvasPos) async {
    if (_docSize.isEmpty) return;
    final existing = widget.surface.imageOf(_c.layers.active.id);
    if (existing == null) {
      deselect(); // 空レイヤーは選択できるものが無い
      return;
    }
    final bd = await existing.toByteData(format: ui.ImageByteFormat.rawRgba);
    if (!mounted || bd == null) return;
    final src = bd.buffer.asUint8List();
    final (ix, iy) = _imageCoord(canvasPos, existing);
    final spans = selectRegion(
      src,
      existing.width,
      existing.height,
      ix,
      iy,
      tolerance: _fillTolerance,
    );
    if (!mounted) return;
    if (spans.isEmpty) {
      deselect();
      return;
    }
    // image 座標 → doc 座標へスケールして矩形を積む。
    final sx = _docSize.width / existing.width;
    final sy = _docSize.height / existing.height;
    final path = Path();
    for (final (y, x0, x1) in spans) {
      path.addRect(Rect.fromLTWH(x0 * sx, y * sy, (x1 - x0) * sx, sy));
    }
    _selDraft = null;
    setState(() => _selection = path);
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
    // 始点=現在色、終点=2 色目(どちらもカラーコードで指定可)。終点を透明に
    // したい場合は 2 色目の不透明度を下げる、ではなく『透明グラデ』トグルで切替。
    final colors = _c.gradientToTransparent
        ? [Color.fromARGB(_alpha, r, g, bb), Color.fromARGB(0, r, g, bb)]
        : [
            Color.fromARGB(_alpha, r, g, bb),
            () {
              final (r2, g2, b2) = hexToRgb(_c.secondColorHex);
              return Color.fromARGB(_alpha, r2, g2, b2);
            }(),
          ];
    // ドラッグした矩形を対象に、選んだ方向(横/縦/斜め/放射)でシェーダを作る。
    final shader = gradientShader(
      _c.gradientDirection,
      Rect.fromPoints(a, b),
      colors,
    );
    _bakeOnLayer(id, (canvas, w, h) {
      canvas.drawRect(
        Rect.fromLTWH(0, 0, w.toDouble(), h.toDouble()),
        Paint()..shader = shader,
      );
    });
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
      vectorLayer: widget.vector?.layer, // ベクター層も焼き込む
      // 対称ガイドは出力に含めない(symmetry 既定 none のまま)。
    ).paint(canvas, Size(w.toDouble(), h.toDouble()));
    final image = await recorder.endRecording().toImage(w, h);
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    return data?.buffer.asUint8List();
  }

  /// タイムラプス用に、現在のドキュメントを最大辺 [maxDim] へ縮小して RGBA で取得。
  Future<TimelapseFrame?> captureFrame(int maxDim) async {
    if (_docSize.isEmpty) return null;
    final longest = _docSize.width > _docSize.height
        ? _docSize.width
        : _docSize.height;
    final scale = (maxDim / longest).clamp(0.05, 1.0);
    final w = (_docSize.width * scale).round().clamp(1, maxDim);
    final h = (_docSize.height * scale).round().clamp(1, maxDim);
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    canvas.scale(w / _docSize.width, h / _docSize.height);
    RasterPainter(
      layers: _c.layers,
      store: widget.surface,
      liveStroke: null,
      liveLayerId: null,
      viewport: const ViewportTransform(),
      docSize: _docSize,
      vectorLayer: widget.vector?.layer,
    ).paint(canvas, _docSize);
    final image = await recorder.endRecording().toImage(w, h);
    final data = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
    if (data == null) return null;
    return TimelapseFrame(rgba: data.buffer.asUint8List(), width: w, height: h);
  }

  /// 写真(エンコード済みバイト列)を新規レイヤーへ中央フィットで取り込む(undo 可)。
  /// デコードに失敗したら何もしない。
  Future<void> importImage(Uint8List bytes) async {
    if (_docSize.isEmpty) return;
    final ui.Image image;
    try {
      final codec = await ui.instantiateImageCodec(bytes);
      image = (await codec.getNextFrame()).image;
    } catch (_) {
      return; // 壊れた/未対応画像
    }
    if (!mounted) return;
    placeImageLayer(image);
  }

  /// デコード済み画像を新規レイヤーへ中央フィットで焼き込む(undo 可)。
  /// テスト/外部からも使えるよう、デコードと分離している。
  void placeImageLayer(ui.Image image) {
    if (_docSize.isEmpty) return;
    _c.addLayer(); // 既存の絵を壊さないよう新規レイヤーへ
    final id = _c.layers.active.id;
    final w = _docSize.width.round().clamp(1, 4096);
    final h = _docSize.height.round().clamp(1, 4096);
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    final src = Rect.fromLTWH(
      0,
      0,
      image.width.toDouble(),
      image.height.toDouble(),
    );
    final dst = _fitCentered(
      Size(image.width.toDouble(), image.height.toDouble()),
      Size(w.toDouble(), h.toDouble()),
    );
    canvas.drawImageRect(image, src, dst, Paint());
    _c.beginStroke(id); // 取り込み前(空)を履歴へ → undo で戻せる
    widget.surface.set(id, recorder.endRecording().toImageSync(w, h));
    widget.onCommitted?.call();
    setState(() {});
  }

  /// [src] を [dst] にアスペクト比保持で内接させ、中央寄せした矩形。
  Rect _fitCentered(Size src, Size dst) {
    if (src.isEmpty || dst.isEmpty) return Offset.zero & dst;
    final sx = dst.width / src.width, sy = dst.height / src.height;
    final scale = sx < sy ? sx : sy;
    final w = src.width * scale, h = src.height * scale;
    return Rect.fromLTWH((dst.width - w) / 2, (dst.height - h) / 2, w, h);
  }

  // ---- vector mode pointer handlers (canvas/doc 空間) ----
  VecPoint _vp(Offset c) => VecPoint(c.dx, c.dy);

  void _vecCancelInProgress() {
    _vecStrokePts = null;
    _vecShapeStart = null;
    _vecShapeEnd = null;
    _vecMoving = false;
    _vecLastPos = null;
  }

  void _vecDown(Offset viewPos) {
    final c = _viewport.toCanvas(viewPos);
    final vec = widget.vector!;
    switch (_c.tool) {
      case Tool.select:
        if (vec.selectAt(_vp(c))) {
          vec.beginMove();
          _vecMoving = true;
          _vecLastPos = c;
        }
      case Tool.shape:
        _vecShapeStart = c;
        _vecShapeEnd = c;
      default:
        _vecStrokePts = [c]; // brush ほかはストローク
    }
  }

  void _vecMove(Offset viewPos) {
    final c = _viewport.toCanvas(viewPos);
    if (_vecMoving) {
      final last = _vecLastPos;
      if (last != null) {
        widget.vector!.moveSelectedBy(c.dx - last.dx, c.dy - last.dy);
      }
      _vecLastPos = c;
      return;
    }
    if (_vecShapeStart != null) {
      _vecShapeEnd = c;
      return;
    }
    if (_vecStrokePts != null) _vecStrokePts!.add(c);
  }

  void _vecUp(Offset viewPos) {
    final vec = widget.vector!;
    if (_vecMoving) {
      _vecMoving = false;
      _vecLastPos = null;
      return;
    }
    final shapeStart = _vecShapeStart;
    if (shapeStart != null) {
      final end = _snapEnd(shapeStart, _vecShapeEnd ?? shapeStart);
      _vecShapeStart = null;
      _vecShapeEnd = null;
      if ((end - shapeStart).distance > 2) {
        vec.addShape(
          kind: _c.shapeKind,
          start: _vp(shapeStart),
          end: _vp(end),
          colorHex: _c.colorHex,
          width: _c.size,
          filled: _c.shapeFilled,
        );
      }
      return;
    }
    final pts = _vecStrokePts;
    _vecStrokePts = null;
    if (pts != null) {
      vec.addStroke(
        [for (final p in pts) _vp(p)],
        colorHex: _c.colorHex,
        width: _c.size,
      );
    }
  }

  /// 描画中ベクターのプレビュー(無ければ null)。
  VectorObject? _buildLiveVector() {
    if (!_vectorMode) return null;
    final pts = _vecStrokePts;
    if (pts != null && pts.isNotEmpty) {
      return VectorStroke(
        id: '__live__',
        colorHex: _c.colorHex,
        width: _c.size,
        points: [for (final p in pts) _vp(p)],
      );
    }
    final a = _vecShapeStart;
    if (a != null) {
      final b = _snapEnd(a, _vecShapeEnd ?? a);
      return VectorShapeObject(
        id: '__live__',
        colorHex: _c.colorHex,
        width: _c.size,
        kind: _c.shapeKind,
        start: _vp(a),
        end: _vp(b),
        filled: _c.shapeFilled,
      );
    }
    return null;
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
          final view = constraints.biggest;
          final fixed = widget.documentSize;
          if (_docSize.isEmpty) {
            // 固定解像度ならその寸法、画面サイズなら表示域。表示は中央フィット
            // (画面サイズは doc==view なので等倍=全面)。
            _docSize = fixed ?? view;
            _viewSize = view;
            _viewport = ViewportTransform.fit(_docSize, view);
          } else if (view != _viewSize) {
            final old = _viewSize;
            _viewSize = view;
            // 再フィット/作り直しは「向きが変わった」ときだけ。同じ向きの微小な
            // インセット変化(キーボード/システムバー等)ではズーム/位置を保つ。
            final orientationChanged =
                (old.width >= old.height) != (view.width >= view.height);
            if (orientationChanged) {
              if (fixed != null) {
                // 固定解像度: 新しい向きへ中央フィットし直す。
                _viewport = ViewportTransform.fit(_docSize, view);
              } else {
                // 画面サイズ: 新しい向きいっぱいに作り直す。
                _docSize = view;
                _viewport = const ViewportTransform();
              }
              _cancelAllInProgress();
            }
          }
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
                selection: _displaySelection(),
                transformLayerId: _transformLayerId,
                layerTransform: _layerTransform,
                vectorLayer: widget.vector?.layer,
                liveVector: _buildLiveVector(),
                selectedVectorId: widget.vector?.selectedId,
                symmetry: _c.symmetry,
              ),
              size: Size.infinite,
            ),
          );
        },
      ),
    );
  }
}

/// テキスト編集の結果。
typedef TextEditResult = ({
  String text,
  double fontSize,
  bool bold,
  bool underline,
  bool strikethrough,
  String colorHex,
  String fontFamily,
  bool gradient,
  String secondColorHex,
  GradientDirection gradientDirection,
});

/// テキスト設定のボトムシート(文字 + サイズ + 装飾 + フォント + グラデ + 色)。
///
/// 他ツール(ブラシ等)と同じく下から出るシートに統一。既存テキストの再編集にも
/// 使う(各値をプリフィル)。グラデ設定は共通の [GradientSettings] を使う。
class _TextSheet extends StatefulWidget {
  const _TextSheet({
    required this.initialText,
    required this.initialSize,
    required this.initialColorHex,
    required this.initialBold,
    required this.initialUnderline,
    required this.initialStrikethrough,
    required this.initialFontFamily,
    required this.initialGradient,
    required this.initialSecondColorHex,
    required this.initialDirection,
    required this.palette,
    required this.isEditing,
  });

  final String initialText;
  final double initialSize;
  final String initialColorHex;
  final bool initialBold;
  final bool initialUnderline;
  final bool initialStrikethrough;
  final String initialFontFamily;
  final bool initialGradient;
  final String initialSecondColorHex;
  final GradientDirection initialDirection;
  final List<String> palette;
  final bool isEditing;

  @override
  State<_TextSheet> createState() => _TextSheetState();
}

class _TextSheetState extends State<_TextSheet> {
  late final TextEditingController _controller = TextEditingController(
    text: widget.initialText,
  );
  late double _fontSize = widget.initialSize;
  late bool _bold = widget.initialBold;
  late bool _underline = widget.initialUnderline;
  late bool _strikethrough = widget.initialStrikethrough;
  late String _fontFamily = widget.initialFontFamily;
  late bool _gradient = widget.initialGradient;
  late GradientDirection _direction = widget.initialDirection;
  late Hsv _hsv = _toHsv(widget.initialColorHex);
  late Hsv _hsv2 = _toHsv(widget.initialSecondColorHex);

  String get _secondColorHex {
    final (r, g, b) = hsvToRgb(_hsv2.$1, _hsv2.$2, _hsv2.$3);
    return rgbToHex(r, g, b);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Hsv _toHsv(String hex) {
    final (r, g, b) = hexToRgb(hex);
    return rgbToHsv(r, g, b);
  }

  String get _colorHex {
    final (r, g, b) = hsvToRgb(_hsv.$1, _hsv.$2, _hsv.$3);
    return rgbToHex(r, g, b);
  }

  Color _color(String hex) {
    final (r, g, b) = hexToRgb(hex);
    return Color.fromARGB(255, r, g, b);
  }

  void _submit() => Navigator.of(context).pop((
    text: _controller.text,
    fontSize: _fontSize,
    bold: _bold,
    underline: _underline,
    strikethrough: _strikethrough,
    colorHex: _colorHex,
    fontFamily: _fontFamily,
    gradient: _gradient,
    secondColorHex: _secondColorHex,
    gradientDirection: _direction,
  ));

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(
        20,
        0,
        20,
        24 + MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            widget.isEditing ? 'テキストを編集' : 'テキスト',
            style: const TextStyle(color: AtelierTokens.ink, fontSize: 18),
          ),
          // autofocus しない: 開いた直後はキーボードを出さず設定を見渡せるように
          // する。文字を打つときはテキスト欄をタップする。
          TextField(
            controller: _controller,
            maxLines: null,
            decoration: const InputDecoration(hintText: '文字を入力(タップで開始)'),
          ),
          // テキスト欄以外に触れたらキーボード(フォーカス)を解除する。Listener は
          // ジェスチャを奪わない受動監視なので、各設定の操作はそのまま効く。
          Listener(
            behavior: HitTestBehavior.translucent,
            onPointerDown: (_) => FocusScope.of(context).unfocus(),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    const Text('サイズ'),
                    Expanded(
                      child: Slider(
                        value: _fontSize,
                        min: 12,
                        max: 240,
                        label: _fontSize.round().toString(),
                        onChanged: (v) => setState(() => _fontSize = v),
                      ),
                    ),
                  ],
                ),
                Wrap(
                  spacing: 8,
                  children: [
                    FilterChip(
                      label: const Text('太字'),
                      selected: _bold,
                      onSelected: (v) => setState(() => _bold = v),
                    ),
                    FilterChip(
                      label: const Text('下線'),
                      selected: _underline,
                      onSelected: (v) => setState(() => _underline = v),
                    ),
                    FilterChip(
                      label: const Text('取り消し線'),
                      selected: _strikethrough,
                      onSelected: (v) => setState(() => _strikethrough = v),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Text('フォント'),
                    const SizedBox(width: 8),
                    Expanded(
                      child: DropdownButton<String>(
                        key: const Key('text-font-dropdown'),
                        isExpanded: true,
                        value: _fontFamily,
                        items: [
                          for (final f in textFonts)
                            DropdownMenuItem(
                              value: f.family,
                              child: Text(f.label),
                            ),
                        ],
                        onChanged: (v) => setState(() => _fontFamily = v ?? ''),
                      ),
                    ),
                  ],
                ),
                // グラデ設定はブラシ/グラデツールと共通 UI(方向=横/縦/斜め/放射)。
                GradientSettings(
                  enabled: _gradient,
                  onEnabledChanged: (v) => setState(() => _gradient = v),
                  firstColorHex: _colorHex,
                  secondColorHex: _secondColorHex,
                  onSecondColorHex: (hex) =>
                      setState(() => _hsv2 = _toHsv(hex)),
                  swatches: widget.palette,
                  direction: _direction,
                  onDirectionChanged: (d) => setState(() => _direction = d),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Text('色'),
                    const SizedBox(width: 8),
                    Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: _color(_colorHex),
                        shape: BoxShape.circle,
                        border: Border.all(color: AtelierTokens.hair),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _colorHex,
                      style: const TextStyle(color: AtelierTokens.inkDim),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                HsvField(
                  h: _hsv.$1,
                  s: _hsv.$2,
                  v: _hsv.$3,
                  onChanged: (h, s, v) => setState(() => _hsv = (h, s, v)),
                ),
                const SizedBox(height: 8),
                HexColorField(
                  hex: _colorHex,
                  onSubmitted: (hex) => setState(() => _hsv = _toHsv(hex)),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final hex in widget.palette)
                      GestureDetector(
                        onTap: () => setState(() => _hsv = _toHsv(hex)),
                        child: Container(
                          width: 26,
                          height: 26,
                          decoration: BoxDecoration(
                            color: _color(hex),
                            shape: BoxShape.circle,
                            border: Border.all(color: AtelierTokens.hair),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('キャンセル'),
                    ),
                    const SizedBox(width: 8),
                    FilledButton(
                      onPressed: _submit,
                      child: Text(widget.isEditing ? '更新' : '追加'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
