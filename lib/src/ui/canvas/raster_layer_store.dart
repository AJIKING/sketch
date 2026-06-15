import 'dart:ui' as ui;

import '../../domain/canvas/canvas_surface.dart';

/// undo/redo 用のレイヤー画像スナップショット(null = 透明)。
class RasterSnapshot {
  const RasterSnapshot(this.image);
  final ui.Image? image;
}

/// `CanvasSurface` のラスター実装(ADR 0004)。レイヤー id ごとに合成済み
/// ピクセル(`ui.Image`)を保持する。
///
/// `ui.Image` はネイティブメモリを持つため、ライブのレイヤー画像と undo 履歴の
/// スナップショットが**同一オブジェクトを共有**しうる前提で**参照計数**し、最後の
/// 参照が外れたときだけ `dispose` する(ADR 0003 の「履歴画像の解放」)。参照元は
/// (1) 各レイヤー id のライブスロット、(2) 各 [RasterSnapshot]。
class RasterLayerStore implements CanvasSurface {
  final Map<String, ui.Image?> _images = {};

  /// 画像ごとの参照数(ライブスロット + 生存スナップショット)。
  final Map<ui.Image, int> _refs = {};

  ui.Image? imageOf(String layerId) => _images[layerId];

  /// レイヤー [layerId] のライブ画像を [image] へ差し替える(参照計数を更新)。
  void set(String layerId, ui.Image? image) => _setLive(layerId, image);

  void _setLive(String layerId, ui.Image? image) {
    final old = _images[layerId];
    if (identical(old, image)) return;
    _retain(image); // 先に retain してから release(同一でも安全side)
    _images[layerId] = image;
    _release(old);
  }

  void _retain(ui.Image? image) {
    if (image == null) return;
    _refs[image] = (_refs[image] ?? 0) + 1;
  }

  void _release(ui.Image? image) {
    if (image == null) return;
    final count = _refs[image];
    if (count == null) return; // 追跡外(通常起きない)
    if (count <= 1) {
      _refs.remove(image);
      image.dispose();
    } else {
      _refs[image] = count - 1;
    }
  }

  @override
  Object snapshot(String layerId) {
    final image = _images[layerId];
    _retain(image); // スナップショットが 1 参照を持つ
    return RasterSnapshot(image);
  }

  @override
  void restore(String layerId, Object pixels) =>
      _setLive(layerId, (pixels as RasterSnapshot).image);

  @override
  void clear(String layerId) => _setLive(layerId, null);

  @override
  void disposeSnapshot(Object pixels) =>
      _release((pixels as RasterSnapshot).image);

  /// 追跡中のレイヤー画像をすべて解放する(画面破棄時に呼ぶ)。
  ///
  /// ライブ・スナップショット双方が参照する画像を `_refs` で一意に把握しているため、
  /// ここで全画像を 1 回ずつ破棄すれば二重解放も取りこぼしも起きない。
  void disposeAll() {
    for (final image in _refs.keys) {
      image.dispose();
    }
    _refs.clear();
    _images.clear();
  }
}
