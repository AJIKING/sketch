import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:sketch/src/domain/gallery/sketch.dart';

import '../../fixtures/in_memory_gallery_store.dart';

Sketch _sketch(String id, {DateTime? at}) {
  final t = at ?? DateTime.utc(2026, 1, 1);
  return Sketch(id: id, createdAt: t, updatedAt: t);
}

Uint8List _png(int marker) => Uint8List.fromList([0x89, 0x50, marker]);

void main() {
  group('Sketch JSON 往復', () {
    test('toJson → fromJson で値が保たれる', () {
      final s = Sketch(
        id: 'a',
        title: '朝の習作',
        createdAt: DateTime.utc(2026, 6, 14, 9),
        updatedAt: DateTime.utc(2026, 6, 14, 10, 30),
      );
      final back = Sketch.fromJson(s.toJson());
      expect(back.id, s.id);
      expect(back.title, s.title);
      expect(back.createdAt, s.createdAt);
      expect(back.updatedAt, s.updatedAt);
    });

    test('title 無しも往復できる', () {
      final back = Sketch.fromJson(_sketch('b').toJson());
      expect(back.title, isNull);
    });
  });

  group('GalleryStore contract(InMemory)', () {
    test('保存したスケッチが index と画像で読み出せる', () async {
      final store = InMemoryGalleryStore();
      await store.save(_sketch('a'), _png(1));
      expect((await store.loadIndex()).map((s) => s.id), ['a']);
      expect(await store.loadImage('a'), [0x89, 0x50, 1]);
    });

    test('同じ id の保存は上書きで重複しない', () async {
      final store = InMemoryGalleryStore();
      await store.save(_sketch('a', at: DateTime.utc(2026, 1, 1)), _png(1));
      await store.save(_sketch('a', at: DateTime.utc(2026, 2, 1)), _png(2));
      final index = await store.loadIndex();
      expect(index, hasLength(1));
      expect(index.single.updatedAt, DateTime.utc(2026, 2, 1));
      expect(await store.loadImage('a'), [0x89, 0x50, 2]);
    });

    test('index は更新日時の新しい順', () async {
      final store = InMemoryGalleryStore();
      await store.save(_sketch('old', at: DateTime.utc(2026, 1, 1)), _png(1));
      await store.save(_sketch('new', at: DateTime.utc(2026, 3, 1)), _png(2));
      await store.save(_sketch('mid', at: DateTime.utc(2026, 2, 1)), _png(3));
      expect((await store.loadIndex()).map((s) => s.id), ['new', 'mid', 'old']);
    });

    test('削除で index と画像が消える', () async {
      final store = InMemoryGalleryStore();
      await store.save(_sketch('a'), _png(1));
      await store.delete('a');
      expect(await store.loadIndex(), isEmpty);
      expect(await store.loadImage('a'), isNull);
    });

    test('未知 id の画像読み出しは null', () async {
      expect(await InMemoryGalleryStore().loadImage('none'), isNull);
    });

    test('updateMeta はメタだけ更新し画像は保つ', () async {
      final store = InMemoryGalleryStore();
      await store.save(_sketch('a'), _png(1));
      await store.updateMeta(
        Sketch(
          id: 'a',
          title: '新しい名前',
          createdAt: DateTime.utc(2026, 1, 1),
          updatedAt: DateTime.utc(2026, 1, 1),
        ),
      );
      expect((await store.loadIndex()).single.title, '新しい名前');
      expect(await store.loadImage('a'), [0x89, 0x50, 1]); // 画像は不変
    });

    test('updateMeta は存在しない id では何もしない', () async {
      final store = InMemoryGalleryStore();
      await store.updateMeta(_sketch('ghost'));
      expect(await store.loadIndex(), isEmpty);
    });
  });
}
