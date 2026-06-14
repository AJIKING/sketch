import 'vector_object.dart';

/// ベクターオブジェクトの順序付き集合(ADR 0005, pure Dart)。
///
/// リストの末尾ほど前面(描画順)。確定後も各オブジェクトを無劣化で再編集できる。
/// 当たり判定は最前面優先。すべての操作は決定的で `dart:ui` 非依存。
class VectorLayer {
  VectorLayer({List<VectorObject>? objects}) : _objects = [...?objects];

  final List<VectorObject> _objects;

  List<VectorObject> get objects => List.unmodifiable(_objects);
  int get length => _objects.length;
  bool get isEmpty => _objects.isEmpty;
  bool get isNotEmpty => _objects.isNotEmpty;

  int _indexOf(String id) => _objects.indexWhere((o) => o.id == id);

  VectorObject? byId(String id) {
    final i = _indexOf(id);
    return i < 0 ? null : _objects[i];
  }

  /// 末尾(前面)へ追加する。
  void add(VectorObject object) => _objects.add(object);

  bool removeById(String id) {
    final i = _indexOf(id);
    if (i < 0) return false;
    _objects.removeAt(i);
    return true;
  }

  void clear() => _objects.clear();

  /// 中身を [objects] で丸ごと置き換える(undo/redo の復元用)。
  void replaceAll(Iterable<VectorObject> objects) {
    _objects
      ..clear()
      ..addAll(objects);
  }

  /// [p] に当たる最前面のオブジェクトを返す(無ければ null)。
  VectorObject? hitTest(VecPoint p, {double tolerance = 8}) {
    for (var i = _objects.length - 1; i >= 0; i--) {
      if (_objects[i].hitTest(p, tolerance: tolerance)) return _objects[i];
    }
    return null;
  }

  /// [id] のオブジェクトを [transform] で置き換える。見つかれば true。
  bool update(String id, VectorObject Function(VectorObject) transform) {
    final i = _indexOf(id);
    if (i < 0) return false;
    _objects[i] = transform(_objects[i]);
    return true;
  }

  bool moveBy(String id, double dx, double dy) =>
      update(id, (o) => o.translate(dx, dy));
  bool recolor(String id, String colorHex) =>
      update(id, (o) => o.withColor(colorHex));
  bool setWidth(String id, double width) =>
      update(id, (o) => o.withWidth(width));

  bool bringToFront(String id) {
    final i = _indexOf(id);
    if (i < 0) return false;
    _objects.add(_objects.removeAt(i));
    return true;
  }

  bool sendToBack(String id) {
    final i = _indexOf(id);
    if (i < 0) return false;
    _objects.insert(0, _objects.removeAt(i));
    return true;
  }

  /// 独立した複製(オブジェクトは不変なので浅いコピーで安全)。
  VectorLayer copy() => VectorLayer(objects: _objects);
}
