/// レイヤー画素の差し替え境界(`docs/architecture.md`)。
///
/// 画素そのもの(`dart:ui.Image`)は ui 層が持つため、ここでは不透明な
/// [Object] として扱う。UI が本番実装を、テストは fake を与える。
/// undo/redo のスナップショット取得・復元・レイヤー消去をこの境界に集約する。
abstract interface class CanvasSurface {
  /// レイヤー [layerId] の現在の画素スナップショット(不透明トークン)を返す。
  Object snapshot(String layerId);

  /// レイヤー [layerId] をスナップショット [pixels] へ復元する。
  void restore(String layerId, Object pixels);

  /// レイヤー [layerId] を消去する。
  void clear(String layerId);
}
