import 'dart:async';

import 'package:flutter/foundation.dart';

import '../domain/brush/brush_preset.dart';
import '../domain/canvas/canvas_surface.dart';
import '../domain/canvas/history.dart';
import '../domain/canvas/layer_blend_mode.dart';
import '../domain/canvas/gradient_kind.dart';
import '../domain/canvas/layer_stack.dart';
import '../domain/canvas/selection_kind.dart';
import '../domain/canvas/shape_kind.dart';
import '../domain/color/ink_color.dart';
import '../domain/palette/palette_store.dart';

/// キャンバスのツール。
enum Tool {
  brush,
  smudge,
  erase,
  fill,
  eyedropper,
  gradient,
  shape,
  text,
  select,
}

/// undo/redo のスナップショット(対象レイヤー id + 不透明な画素トークン)。
typedef LayerSnapshot = ({String layerId, Object pixels});

/// キャンバス画面の状態(`docs/test-plan.md` Widget「ツールドック」ほか)。
///
/// ツール・ブラシ・サイズ・不透明度・現在色・最近色・レイヤー・履歴を保持する。
/// 実際のラスタライズは ui 層が `stroke_planner` と [CanvasSurface] を使って行う。
class CanvasController extends ChangeNotifier {
  CanvasController({
    required this.surface,
    this.paletteStore,
    int historyLimit = 16,
  }) : _history = History<LayerSnapshot>(limit: historyLimit);

  final CanvasSurface surface;

  /// ユーザー定義パレットの保存先(任意。null なら非永続)。
  final PaletteStore? paletteStore;
  final History<LayerSnapshot> _history;
  final LayerStack _layers = LayerStack.initial();
  final List<String> _customPalette = [];
  bool _disposed = false;

  Tool _tool = Tool.brush;
  BrushPreset _brush = inkBrush;
  double _size = 14;
  double _opacity = 1;
  double _stabilization = 0;
  Hsv _hsv = rgbToHsv(0xCF, 0x4A, 0x2C); // 既定は朱(#CF4A2C)
  final List<String> _recent = [];
  ShapeKind _shapeKind = ShapeKind.line;
  bool _shapeFilled = false;
  bool _shapeSnap = false;
  GradientKind _gradientKind = GradientKind.linear;
  SelectionKind _selectionKind = SelectionKind.rectangle;
  bool _gradientBrush = false;
  String _secondColorHex = '#2C4A63'; // 既定の 2 色目は藍

  Tool get tool => _tool;
  BrushPreset get brush => _brush;
  double get size => _size;
  double get opacity => _opacity;
  double get stabilization => _stabilization;
  Hsv get hsv => _hsv;
  List<String> get recent => List.unmodifiable(_recent);
  List<String> get palette => studioPalette;

  /// ユーザーが保存したカスタム色(新しい順)。
  List<String> get customPalette => List.unmodifiable(_customPalette);
  ShapeKind get shapeKind => _shapeKind;
  bool get shapeFilled => _shapeFilled;
  bool get shapeSnap => _shapeSnap;
  GradientKind get gradientKind => _gradientKind;
  SelectionKind get selectionKind => _selectionKind;

  /// 2 色グラデーションで描くか(始点色 → [secondColorHex] へ変化)。
  bool get gradientBrush => _gradientBrush;

  /// グラデブラシの 2 色目(終点色)の HEX。
  String get secondColorHex => _secondColorHex;
  LayerStack get layers => _layers;
  bool get canUndo => _history.canUndo;
  bool get canRedo => _history.canRedo;

  /// 現在色の HEX(アクセント色に使う)。
  String get colorHex {
    final (r, g, b) = hsvToRgb(_hsv.$1, _hsv.$2, _hsv.$3);
    return rgbToHex(r, g, b);
  }

  void selectTool(Tool tool) {
    if (_tool == tool) return;
    _tool = tool;
    notifyListeners();
  }

  /// ブラシを選び、ツールをブラシに戻す(プロトタイプ準拠)。
  void selectBrush(BrushPreset brush) {
    _brush = brush;
    _tool = Tool.brush;
    notifyListeners();
  }

  void setBrushFlow(double value) {
    _brush = _brush.copyWith(flow: value.clamp(0.02, 1.0));
    notifyListeners();
  }

  void setBrushScatter(double value) {
    _brush = _brush.copyWith(scatter: value.clamp(0.0, 2.0));
    notifyListeners();
  }

  void setBrushSpacing(double value) {
    _brush = _brush.copyWith(spacing: value.clamp(0.05, 2.0));
    notifyListeners();
  }

  void setSize(double value) {
    final clamped = value.clamp(1.0, 80.0);
    if (clamped == _size) return;
    _size = clamped;
    notifyListeners();
  }

  void setOpacity(double value) {
    final clamped = value.clamp(0.0, 1.0);
    if (clamped == _opacity) return;
    _opacity = clamped;
    notifyListeners();
  }

  void setStabilization(double value) {
    final clamped = value.clamp(0.0, 1.0);
    if (clamped == _stabilization) return;
    _stabilization = clamped;
    notifyListeners();
  }

  void setShapeKind(ShapeKind kind) {
    if (kind == _shapeKind) return;
    _shapeKind = kind;
    notifyListeners();
  }

  void setShapeFilled(bool filled) {
    if (filled == _shapeFilled) return;
    _shapeFilled = filled;
    notifyListeners();
  }

  void setShapeSnap(bool snap) {
    if (snap == _shapeSnap) return;
    _shapeSnap = snap;
    notifyListeners();
  }

  void setGradientKind(GradientKind kind) {
    if (kind == _gradientKind) return;
    _gradientKind = kind;
    notifyListeners();
  }

  void setSelectionKind(SelectionKind kind) {
    if (kind == _selectionKind) return;
    _selectionKind = kind;
    notifyListeners();
  }

  void setGradientBrush(bool enabled) {
    if (enabled == _gradientBrush) return;
    _gradientBrush = enabled;
    notifyListeners();
  }

  void setSecondColorHex(String hex) {
    if (hex == _secondColorHex) return;
    _secondColorHex = hex;
    notifyListeners();
  }

  void setHsv(double h, double s, double v) {
    _hsv = (h, s, v);
    notifyListeners();
  }

  void setColorHex(String hex) {
    final (r, g, b) = hexToRgb(hex);
    _hsv = rgbToHsv(r, g, b);
    notifyListeners();
  }

  /// パレット / 最近色から選ぶ。現在色を変えて最近色へ積む。
  void selectColor(String hex) {
    setColorHex(hex);
    addRecent();
  }

  /// 現在色を最近色へ積む(重複は先頭へ寄せ、最大 8 件)。
  void addRecent() {
    final hex = colorHex;
    _recent
      ..remove(hex)
      ..insert(0, hex);
    if (_recent.length > 8) _recent.removeRange(8, _recent.length);
    notifyListeners();
  }

  /// 保存済みカスタムパレットを読み込む(起動時に 1 回)。store が無ければ無処理。
  Future<void> loadCustomPalette() async {
    final store = paletteStore;
    if (store == null) return;
    final loaded = await store.load();
    if (_disposed) return; // 読み込み中に画面を離れていたら通知しない
    _customPalette
      ..clear()
      ..addAll(loaded);
    notifyListeners();
  }

  /// 現在色([hex] 省略時)をカスタムパレットへ保存する(重複は先頭へ寄せ、最大 24 件)。
  void addCustomColor([String? hex]) {
    final h = hex ?? colorHex;
    _customPalette
      ..remove(h)
      ..insert(0, h);
    if (_customPalette.length > 24) {
      _customPalette.removeRange(24, _customPalette.length);
    }
    _persistCustomPalette();
    notifyListeners();
  }

  /// カスタムパレットから色を削除する。
  void removeCustomColor(String hex) {
    if (_customPalette.remove(hex)) {
      _persistCustomPalette();
      notifyListeners();
    }
  }

  void _persistCustomPalette() {
    final store = paletteStore;
    // 保存はユーザー操作の度に発火する fire-and-forget。各回が全件スナップショット
    // なので last-write-wins で壊れない。書き込み失敗はアプリを止めず握り潰す。
    if (store != null) {
      unawaited(store.save(List.of(_customPalette)).catchError((Object _) {}));
    }
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  void addLayer() {
    _layers.add();
    notifyListeners();
  }

  bool removeLayer(int index) {
    final removed = _layers.remove(index);
    if (removed) notifyListeners();
    return removed;
  }

  void toggleLayerVisible(int index) {
    _layers.toggleVisible(index);
    notifyListeners();
  }

  void setActiveLayer(int index) {
    _layers.setActive(index);
    notifyListeners();
  }

  void setLayerOpacity(int index, double opacity) {
    _layers.setOpacity(index, opacity);
    notifyListeners();
  }

  void setLayerBlendMode(int index, LayerBlendMode mode) {
    _layers.setBlendMode(index, mode);
    notifyListeners();
  }

  void toggleLayerAlphaLock(int index) {
    _layers.toggleAlphaLock(index);
    notifyListeners();
  }

  void toggleLayerClip(int index) {
    _layers.toggleClip(index);
    notifyListeners();
  }

  LayerSnapshot _snapshot(String layerId) =>
      (layerId: layerId, pixels: surface.snapshot(layerId));

  /// 変更の直前に呼ぶ。対象レイヤー([layerId] 省略時はアクティブ)の画素を
  /// 履歴へ積む。非同期処理では開始時に捕捉した id を渡すこと(await 中に
  /// アクティブが変わっても正しいレイヤーを記録するため)。
  void beginStroke([String? layerId]) {
    _history.record(_snapshot(layerId ?? _layers.active.id));
    notifyListeners();
  }

  void undo() {
    final next = _history.nextUndo;
    if (next == null) return;
    final restored = _history.undo(_snapshot(next.layerId))!;
    surface.restore(restored.layerId, restored.pixels);
    notifyListeners();
  }

  void redo() {
    final next = _history.nextRedo;
    if (next == null) return;
    final restored = _history.redo(_snapshot(next.layerId))!;
    surface.restore(restored.layerId, restored.pixels);
    notifyListeners();
  }

  /// アクティブレイヤーを消去する(undo 可能)。
  void clearActiveLayer() {
    _history.record(_snapshot(_layers.active.id));
    surface.clear(_layers.active.id);
    notifyListeners();
  }
}
