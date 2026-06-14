import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:sketch/src/application/gallery_controller.dart';

import '../../fixtures/fake_clock.dart';
import '../../fixtures/in_memory_gallery_store.dart';

Uint8List _png(int m) => Uint8List.fromList([0x89, m]);

void main() {
  late InMemoryGalleryStore store;
  late FakeClock clock;
  late GalleryController c;

  setUp(() {
    store = InMemoryGalleryStore();
    clock = FakeClock(DateTime.utc(2026, 6, 14, 10));
    c = GalleryController(store: store, clock: clock);
  });

  test('初期状態は空', () async {
    await c.load();
    expect(c.count, 0);
    expect(c.isLoading, isFalse);
  });

  test('保存で一覧に反映され、作成日時は Clock から取る', () async {
    final s = await c.save(id: 'a', png: _png(1));
    expect(c.count, 1);
    expect(s.createdAt, DateTime.utc(2026, 6, 14, 10));
    expect(await c.image('a'), [0x89, 1]);
  });

  test('既存 id の保存は更新日時だけ進めて上書き', () async {
    await c.save(id: 'a', png: _png(1), title: '朝の習作');
    clock.advance(const Duration(hours: 2));
    final updated = await c.save(id: 'a', png: _png(2));
    expect(c.count, 1);
    expect(updated.title, '朝の習作'); // title は保たれる
    expect(updated.createdAt, DateTime.utc(2026, 6, 14, 10));
    expect(updated.updatedAt, DateTime.utc(2026, 6, 14, 12));
    expect(await c.image('a'), [0x89, 2]);
  });

  test('一覧は更新日時の新しい順', () async {
    await c.save(id: 'old', png: _png(1));
    clock.advance(const Duration(hours: 1));
    await c.save(id: 'new', png: _png(2));
    expect(c.sketches.map((s) => s.id), ['new', 'old']);
  });

  test('削除で一覧から消える', () async {
    await c.save(id: 'a', png: _png(1));
    await c.remove('a');
    expect(c.count, 0);
    expect(await c.image('a'), isNull);
  });
}
