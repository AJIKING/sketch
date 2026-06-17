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

  test('複製は画像をコピーし、新 id・コピー名で増える', () async {
    await c.save(id: 'a', png: _png(7), title: '朝の習作');
    // コピー名は UI 層がロケールに応じて渡す(ここでは日本語の文言を検証)。
    final copy = await c.duplicate('a', copyName: '朝の習作 のコピー');

    expect(copy, isNotNull);
    expect(copy!.id, isNot('a'));
    expect(copy.title, '朝の習作 のコピー');
    expect(c.count, 2);
    expect(await c.image(copy.id), [0x89, 7]); // 画像が同一
    // 元は残る。
    expect(await c.image('a'), [0x89, 7]);
  });

  test('存在しない id の複製は null', () async {
    expect(await c.duplicate('missing', copyName: 'コピー'), isNull);
    expect(c.count, 0);
  });

  test('rename はタイトルを変え、画像と並び順を保つ', () async {
    await c.save(id: 'a', png: _png(1), title: '朝の習作');
    clock.advance(const Duration(hours: 1));
    await c.save(id: 'b', png: _png(2), title: 'b');
    // 並びは新しい順で [b, a]。a をリネームしても updatedAt 据え置きで順序維持。
    final updated = await c.rename('a', '夜の習作');
    expect(updated!.title, '夜の習作');
    expect(c.sketches.map((s) => s.id), ['b', 'a']); // 順序不変
    expect(await c.image('a'), [0x89, 1]); // 画像不変
  });

  test('rename で空文字は既定名(null)に戻す', () async {
    await c.save(id: 'a', png: _png(1), title: '名前');
    final updated = await c.rename('a', '   ');
    expect(updated!.title, isNull);
  });

  test('存在しない id の rename は null', () async {
    expect(await c.rename('missing', 'x'), isNull);
  });

  test('同一時刻で連続複製しても id が衝突しない(回帰)', () async {
    await c.save(id: 'a', png: _png(1));
    final c1 = await c.duplicate('a', copyName: 'コピー'); // clock は進めない
    final c2 = await c.duplicate('a', copyName: 'コピー');
    expect(c1, isNotNull);
    expect(c2, isNotNull);
    expect(c1!.id, isNot(c2!.id)); // 衝突しない
    expect(c.count, 3); // 元 + コピー2枚
  });
}
