import 'dart:math' as math;

import 'package:flutter/foundation.dart';

import '../domain/canvas/shape_kind.dart';
import '../domain/vector/vector_layer.dart';
import '../domain/vector/vector_object.dart';

/// ベクターオーバーレイの状態(ADR 0005 Phase 2)。
///
/// ラスターレイヤー(ADR 0004)の上に重なる、再編集可能なベクターオブジェクト層
/// を管理する。描画モードの ON/OFF・選択・移動・削除・色変更と、ラスターとは
/// 独立した undo/redo を持つ。幾何は domain の [VectorLayer] / [VectorObject]。
class VectorController extends ChangeNotifier {
  VectorController({this.historyLimit = 50});

  /// undo 履歴の上限(超えた古い分から捨てる)。
  final int historyLimit;
  final VectorLayer _layer = VectorLayer();
  final List<List<VectorObject>> _undoStack = [];
  final List<List<VectorObject>> _redoStack = [];

  bool _enabled = false;
  String? _selectedId;
  bool _editArmed = false; // 移動/拡縮の開始済みだがまだスナップショット未取得
  bool _adjusting = false; // 長押し起動の「オブジェクト調整」モード
  int _seq = 0;

  VectorLayer get layer => _layer;
  bool get enabled => _enabled;
  int get count => _layer.length;
  String? get selectedId => _selectedId;
  VectorObject? get selected =>
      _selectedId == null ? null : _layer.byId(_selectedId!);
  bool get hasSelection => selected != null;

  /// 長押しで入る調整(移動/拡縮)モード中か。
  bool get adjusting => _adjusting;
  bool get canUndo => _undoStack.isNotEmpty;
  bool get canRedo => _redoStack.isNotEmpty;

  void setEnabled(bool value) {
    if (value == _enabled) return;
    _enabled = value;
    if (!value) {
      _selectedId = null;
      _editArmed = false;
      _adjusting = false;
    }
    notifyListeners();
  }

  /// [id] のオブジェクトを選択して調整モードへ入る(長押し起動)。
  void startAdjust(String id) {
    if (_layer.byId(id) == null) return;
    _selectedId = id;
    _adjusting = true;
    _editArmed = false;
    notifyListeners();
  }

  /// 調整モードを抜けて選択を解除する。
  void endAdjust() {
    if (!_adjusting && _selectedId == null) return;
    _adjusting = false;
    _selectedId = null;
    _editArmed = false;
    notifyListeners();
  }

  String _nextId() => 'v${_seq++}';

  // ---- history ----
  void _pushUndo() {
    _undoStack.add(_layer.objects.toList());
    if (_undoStack.length > historyLimit) _undoStack.removeAt(0);
    _redoStack.clear();
  }

  void _restore(List<VectorObject> snapshot) {
    _layer.replaceAll(snapshot);
    // 選択中オブジェクトが消えていたら選択解除。
    if (_selectedId != null && _layer.byId(_selectedId!) == null) {
      _selectedId = null;
    }
  }

  void undo() {
    if (_undoStack.isEmpty) return;
    _redoStack.add(_layer.objects.toList());
    _restore(_undoStack.removeLast());
    notifyListeners();
  }

  void redo() {
    if (_redoStack.isEmpty) return;
    _undoStack.add(_layer.objects.toList());
    _restore(_redoStack.removeLast());
    notifyListeners();
  }

  // ---- editing ----
  /// ストロークを追加して選択状態にする(undo 可能)。
  void addStroke(
    List<VecPoint> points, {
    required String colorHex,
    required double width,
  }) {
    if (points.isEmpty) return;
    _pushUndo();
    final object = VectorStroke(
      id: _nextId(),
      colorHex: colorHex,
      width: width,
      points: points,
    );
    _layer.add(object);
    _selectedId = object.id;
    notifyListeners();
  }

  /// 図形を追加して選択状態にする(undo 可能)。
  void addShape({
    required ShapeKind kind,
    required VecPoint start,
    required VecPoint end,
    required String colorHex,
    required double width,
    bool filled = false,
  }) {
    _pushUndo();
    final object = VectorShapeObject(
      id: _nextId(),
      colorHex: colorHex,
      width: width,
      kind: kind,
      start: start,
      end: end,
      filled: filled,
    );
    _layer.add(object);
    _selectedId = object.id;
    notifyListeners();
  }

  /// テキストを追加して選択状態にする(undo 可能)。box は UI が測って渡す。
  void addText({
    required VecPoint position,
    required String text,
    required double fontSize,
    required String colorHex,
    required double boxWidth,
    required double boxHeight,
    bool bold = false,
    bool underline = false,
    bool strikethrough = false,
  }) {
    _pushUndo();
    final object = VectorText(
      id: _nextId(),
      colorHex: colorHex,
      position: position,
      text: text,
      fontSize: fontSize,
      boxWidth: boxWidth,
      boxHeight: boxHeight,
      bold: bold,
      underline: underline,
      strikethrough: strikethrough,
    );
    _layer.add(object);
    _selectedId = object.id;
    notifyListeners();
  }

  /// 既存テキストの内容/装飾/色を更新する(位置は据え置き)。対象が
  /// テキストでなければ false。
  bool updateText(
    String id, {
    required String text,
    required double fontSize,
    required String colorHex,
    required double boxWidth,
    required double boxHeight,
    bool bold = false,
    bool underline = false,
    bool strikethrough = false,
  }) {
    final current = _layer.byId(id);
    if (current is! VectorText) return false;
    final updated = current.copyWith(
      text: text,
      fontSize: fontSize,
      colorHex: colorHex,
      boxWidth: boxWidth,
      boxHeight: boxHeight,
      bold: bold,
      underline: underline,
      strikethrough: strikethrough,
    );
    // 変化が無ければ履歴を汚さない(再編集して未変更で確定したケース)。
    if (current.text == updated.text &&
        current.fontSize == updated.fontSize &&
        current.colorHex == updated.colorHex &&
        current.bold == updated.bold &&
        current.underline == updated.underline &&
        current.strikethrough == updated.strikethrough) {
      return true;
    }
    _pushUndo();
    _layer.update(id, (_) => updated);
    notifyListeners();
    return true;
  }

  /// id を指定して削除する(undo 可能)。
  bool deleteById(String id) {
    if (_layer.byId(id) == null) return false;
    _pushUndo();
    _layer.removeById(id);
    if (_selectedId == id) _selectedId = null;
    notifyListeners();
    return true;
  }

  /// [p] にある最前面のオブジェクトを選択する。当たれば true。
  bool selectAt(VecPoint p, {double tolerance = 10}) {
    final hit = _layer.hitTest(p, tolerance: tolerance);
    _selectedId = hit?.id;
    _editArmed = false;
    notifyListeners();
    return hit != null;
  }

  void clearSelection() {
    _editArmed = false;
    if (_selectedId == null) return;
    _selectedId = null;
    notifyListeners();
  }

  /// 移動/拡縮ドラッグの開始を予約する。実際に動いた最初の [moveSelectedBy] /
  /// [scaleSelectedBy] で初めてスナップショットを積むため、タップ選択(無操作)
  /// では履歴を汚さない。
  void beginEdit() {
    if (_selectedId == null) return;
    _editArmed = true;
  }

  /// 後方互換の別名。
  void beginMove() => beginEdit();

  void moveSelectedBy(double dx, double dy) {
    final id = _selectedId;
    if (id == null) return;
    if (dx == 0 && dy == 0) return; // 動きが無ければ何もしない
    if (_editArmed) {
      _pushUndo(); // ドラッグ全体を 1 操作にする(最初の編集でだけ積む)
      _editArmed = false;
    }
    if (_layer.moveBy(id, dx, dy)) notifyListeners();
  }

  /// 選択オブジェクトを [anchor] を中心に [factor] 倍する(ピンチ拡縮)。
  /// 縮みすぎ(外接矩形の短辺が ~6px 未満)になる縮小は無視する。
  void scaleSelectedBy(double factor, VecPoint anchor) {
    final id = _selectedId;
    if (id == null || factor == 1.0) return;
    final current = _layer.byId(id);
    if (current == null) return;
    final b = current.bounds;
    final minSide = math.min(b.right - b.left, b.bottom - b.top);
    if (factor < 1 && minSide * factor < 6) return;
    if (_editArmed) {
      _pushUndo();
      _editArmed = false;
    }
    _layer.update(id, (o) => o.scaled(factor, anchor));
    notifyListeners();
  }

  void deleteSelected() {
    final id = _selectedId;
    if (id == null) return;
    _pushUndo();
    _layer.removeById(id);
    _selectedId = null;
    _adjusting = false;
    notifyListeners();
  }

  void recolorSelected(String colorHex) {
    final id = _selectedId;
    if (id == null) return;
    _pushUndo();
    _layer.recolor(id, colorHex);
    notifyListeners();
  }

  /// 全消去(undo 可能)。
  void clearAll() {
    if (_layer.isEmpty) return;
    _pushUndo();
    _layer.clear();
    _selectedId = null;
    notifyListeners();
  }
}
