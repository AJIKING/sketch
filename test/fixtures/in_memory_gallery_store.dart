import 'dart:typed_data';

import 'package:sketch/src/domain/gallery/gallery_store.dart';
import 'package:sketch/src/domain/gallery/sketch.dart';

/// `GalleryStore` のインメモリ fake(`docs/test-plan.md`)。
///
/// 実ファイル I/O に依存せず、永続化の往復を contract test で検証するための fixture。
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
