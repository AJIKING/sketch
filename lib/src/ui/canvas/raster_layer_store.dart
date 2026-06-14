import 'dart:ui' as ui;

import '../../domain/canvas/canvas_surface.dart';

/// undo/redo 用のレイヤー画像スナップショット(null = 透明)。
class RasterSnapshot {
  const RasterSnapshot(this.image);
  final ui.Image? image;
}

/// `CanvasSurface` のラスター実装(ADR 0004)。レイヤー id ごとに合成済み
/// ピクセル(`ui.Image`)を保持する。`ui.Image` は不変なので、スナップショットは
/// 参照を持つだけで安価。
class RasterLayerStore implements CanvasSurface {
  final Map<String, ui.Image?> _images = {};

  ui.Image? imageOf(String layerId) => _images[layerId];

  void set(String layerId, ui.Image? image) => _images[layerId] = image;

  @override
  Object snapshot(String layerId) => RasterSnapshot(_images[layerId]);

  @override
  void restore(String layerId, Object pixels) =>
      _images[layerId] = (pixels as RasterSnapshot).image;

  @override
  void clear(String layerId) => _images[layerId] = null;
}
