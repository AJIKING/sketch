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

  /// 履歴から落としたスナップショット [pixels] を解放する(参照が無くなれば破棄)。
  ///
  /// undo 履歴が保持していたスナップショットが上限超過・redo クリア等で不要に
  /// なったときに呼ぶ。スナップショットの画素はライブ画像や他スナップショットと
  /// **共有されうる**ため、実装は参照計数で「最後の 1 個」になったときのみ破棄する。
  void disposeSnapshot(Object pixels);
}
