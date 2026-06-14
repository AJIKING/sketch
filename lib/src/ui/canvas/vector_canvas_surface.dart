import '../../domain/canvas/canvas_surface.dart';
import 'painted_stroke.dart';

/// `CanvasSurface` のベクター実装。レイヤー id ごとにストローク列を保持する。
///
/// undo/redo のスナップショットはストローク列の浅いコピー(完成済みストロークは
/// 不変として共有してよい)。`canvas_controller` がこの境界越しに履歴を扱う。
class VectorCanvasSurface implements CanvasSurface {
  final Map<String, List<PaintedStroke>> _layers = {};

  List<PaintedStroke> strokesOf(String layerId) =>
      _layers.putIfAbsent(layerId, () => <PaintedStroke>[]);

  void add(String layerId, PaintedStroke stroke) =>
      strokesOf(layerId).add(stroke);

  @override
  Object snapshot(String layerId) => List<PaintedStroke>.of(strokesOf(layerId));

  @override
  void restore(String layerId, Object pixels) {
    _layers[layerId] = List<PaintedStroke>.of(pixels as List<PaintedStroke>);
  }

  @override
  void clear(String layerId) {
    _layers[layerId] = <PaintedStroke>[];
  }
}
