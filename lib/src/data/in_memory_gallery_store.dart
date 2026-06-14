import 'dart:typed_data';

import '../domain/gallery/gallery_store.dart';
import '../domain/gallery/sketch.dart';

/// 暫定の非永続 `GalleryStore`(セッション内のみ保持)。
///
/// ADR 0001 で決めたアプリ内ファイル保存(`file_gallery_store.dart`)は
/// path_provider 導入時に実装する。それまではプロトタイプ同様、アプリを
/// 終了すると消える。永続化はこの境界の差し替えだけで導入できる。
class InMemoryGalleryStore implements GalleryStore {
  final Map<String, Sketch> _meta = {};
  final Map<String, Uint8List> _images = {};

  @override
  Future<List<Sketch>> loadIndex() async {
    final list = _meta.values.toList()
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return list;
  }

  @override
  Future<void> save(Sketch sketch, Uint8List png) async {
    _meta[sketch.id] = sketch;
    _images[sketch.id] = Uint8List.fromList(png);
  }

  @override
  Future<Uint8List?> loadImage(String id) async => _images[id];

  @override
  Future<void> delete(String id) async {
    _meta.remove(id);
    _images.remove(id);
  }
}
