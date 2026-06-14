import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import '../domain/gallery/gallery_store.dart';
import '../domain/gallery/sketch.dart';

/// `GalleryStore` のファイル実装(ADR 0001)。
///
/// 保存先ディレクトリに、合成 PNG を `<id>.png`、メタのインデックスを
/// `index_v1.json`(`Sketch` の配列)として置く。ディレクトリは [resolveDir]
/// で注入する(本番は path_provider、テストは temp dir)。
///
/// 壊れた / 読めないインデックスは例外にせず空ギャラリーとして扱い、アプリは
/// 必ず起動できるようにする。
class FileGalleryStore implements GalleryStore {
  FileGalleryStore({required this.resolveDir});

  final Future<Directory> Function() resolveDir;

  /// インデックスファイル名(スキーマバージョン付き)。
  static const String indexFileName = 'index_v1.json';

  Directory? _cached;

  Future<Directory> _dir() async {
    final dir = _cached ??= await resolveDir();
    if (!await dir.exists()) await dir.create(recursive: true);
    return dir;
  }

  File _indexFile(Directory dir) => File('${dir.path}/$indexFileName');
  File _imageFile(Directory dir, String id) => File('${dir.path}/$id.png');

  Future<Map<String, Sketch>> _readIndex(Directory dir) async {
    final file = _indexFile(dir);
    if (!await file.exists()) return {};
    try {
      final raw = jsonDecode(await file.readAsString()) as List<Object?>;
      final map = <String, Sketch>{};
      for (final entry in raw) {
        final sketch = Sketch.fromJson((entry! as Map).cast<String, Object?>());
        map[sketch.id] = sketch;
      }
      return map;
    } catch (_) {
      return {}; // 壊れた索引は空扱い
    }
  }

  Future<void> _writeIndex(Directory dir, Map<String, Sketch> map) async {
    final list = map.values.map((s) => s.toJson()).toList();
    await _indexFile(dir).writeAsString(jsonEncode(list));
  }

  @override
  Future<List<Sketch>> loadIndex() async {
    try {
      final dir = await _dir();
      final map = await _readIndex(dir);
      return map.values.toList()
        ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    } catch (_) {
      return []; // ストレージ未準備でも起動を止めない
    }
  }

  @override
  Future<void> save(Sketch sketch, Uint8List png) async {
    final dir = await _dir();
    await _imageFile(dir, sketch.id).writeAsBytes(png);
    final map = await _readIndex(dir);
    map[sketch.id] = sketch;
    await _writeIndex(dir, map);
  }

  @override
  Future<Uint8List?> loadImage(String id) async {
    final dir = await _dir();
    final file = _imageFile(dir, id);
    if (!await file.exists()) return null;
    return file.readAsBytes();
  }

  @override
  Future<void> delete(String id) async {
    final dir = await _dir();
    final image = _imageFile(dir, id);
    if (await image.exists()) await image.delete();
    final map = await _readIndex(dir);
    map.remove(id);
    await _writeIndex(dir, map);
  }
}
