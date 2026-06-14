import 'dart:typed_data';

import 'sketch.dart';

/// スケッチの永続化境界(ADR 0001)。
///
/// 本番実装はアプリ内ストレージ(`data/file_gallery_store.dart`)、テストは
/// インメモリ fake(`test/fixtures/in_memory_gallery_store.dart`)。
/// `loadIndex` は更新日時の新しい順で返す。
abstract interface class GalleryStore {
  /// メタ情報の一覧を更新日時の新しい順で返す。壊れた索引は空一覧として扱う。
  Future<List<Sketch>> loadIndex();

  /// メタ + PNG を保存する。同じ id があれば上書きする。
  Future<void> save(Sketch sketch, Uint8List png);

  /// id の PNG バイト列を返す。無ければ null。
  Future<Uint8List?> loadImage(String id);

  /// id のスケッチ(メタ + 画像)を削除する。
  Future<void> delete(String id);
}
