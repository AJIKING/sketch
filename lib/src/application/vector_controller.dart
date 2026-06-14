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
  bool _moveArmed = false; // 移動ドラッグ開始済みだがまだスナップショット未取得
  int _seq = 0;

  VectorLayer get layer => _layer;
  bool get enabled => _enabled;
  int get count => _layer.length;
  String? get selectedId => _selectedId;
  VectorObject? get selected =>
      _selectedId == null ? null : _layer.byId(_selectedId!);
  bool get hasSelection => selected != null;
  bool get canUndo => _undoStack.isNotEmpty;
  bool get canRedo => _redoStack.isNotEmpty;

  void setEnabled(bool value) {
    if (value == _enabled) return;
    _enabled = value;
    if (!value) {
      _selectedId = null;
      _moveArmed = false;
    }
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

  /// [p] にある最前面のオブジェクトを選択する。当たれば true。
  bool selectAt(VecPoint p, {double tolerance = 10}) {
    final hit = _layer.hitTest(p, tolerance: tolerance);
    _selectedId = hit?.id;
    _moveArmed = false;
    notifyListeners();
    return hit != null;
  }

  void clearSelection() {
    _moveArmed = false;
    if (_selectedId == null) return;
    _selectedId = null;
    notifyListeners();
  }

  /// 移動ドラッグの開始を予約する。実際に動いた最初の [moveSelectedBy] で初めて
  /// スナップショットを積むため、タップ選択(移動なし)では履歴を汚さない。
  void beginMove() {
    if (_selectedId == null) return;
    _moveArmed = true;
  }

  void moveSelectedBy(double dx, double dy) {
    final id = _selectedId;
    if (id == null) return;
    if (dx == 0 && dy == 0) return; // 動きが無ければ何もしない
    if (_moveArmed) {
      _pushUndo(); // ドラッグ全体を 1 操作にする(最初の移動でだけ積む)
      _moveArmed = false;
    }
    if (_layer.moveBy(id, dx, dy)) notifyListeners();
  }

  void deleteSelected() {
    final id = _selectedId;
    if (id == null) return;
    _pushUndo();
    _layer.removeById(id);
    _selectedId = null;
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
