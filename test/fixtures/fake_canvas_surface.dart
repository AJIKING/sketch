import 'package:sketch/src/domain/canvas/canvas_surface.dart';

/// `CanvasSurface` の fake。画素を不透明な [Object] として Map で持つ。
///
/// テストでは [draw] で「描いた」状態を作り、snapshot/restore/clear の挙動を
/// 検証する。
class FakeCanvasSurface implements CanvasSurface {
  final Map<String, Object> state = {};

  /// 描画をシミュレートする(テスト用ヘルパ)。
  void draw(String layerId, Object pixels) => state[layerId] = pixels;

  @override
  Object snapshot(String layerId) => state[layerId] ?? 'empty';

  @override
  void restore(String layerId, Object pixels) => state[layerId] = pixels;

  @override
  void clear(String layerId) => state[layerId] = 'cleared';
}
