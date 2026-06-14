import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:sketch/src/data/file_gallery_store.dart';
import 'package:sketch/src/domain/gallery/sketch.dart';

void main() {
  late Directory tmp;

  setUp(() async {
    tmp = await Directory.systemTemp.createTemp('hatch_gallery');
  });
  tearDown(() async {
    if (await tmp.exists()) await tmp.delete(recursive: true);
  });

  FileGalleryStore store() => FileGalleryStore(
    resolveDir: () async => Directory('${tmp.path}/sketches'),
  );

  Sketch sketch(String id, {DateTime? at}) {
    final t = at ?? DateTime.utc(2026, 1, 1);
    return Sketch(id: id, createdAt: t, updatedAt: t);
  }

  Uint8List png(int m) => Uint8List.fromList([0x89, 0x50, m]);

  test('保存したスケッチが index と画像で読み出せる', () async {
    final s = store();
    await s.save(sketch('a'), png(1));
    expect((await s.loadIndex()).map((e) => e.id), ['a']);
    expect(await s.loadImage('a'), [0x89, 0x50, 1]);
  });

  test('別インスタンスでも読める(ディスクに永続化される)', () async {
    await store().save(sketch('a', at: DateTime.utc(2026, 5, 1)), png(7));
    final fresh = store();
    expect((await fresh.loadIndex()).single.id, 'a');
    expect(await fresh.loadImage('a'), [0x89, 0x50, 7]);
  });

  test('同じ id は上書きで重複せず、index は更新日時の新しい順', () async {
    final s = store();
    await s.save(sketch('a', at: DateTime.utc(2026, 1, 1)), png(1));
    await s.save(sketch('a', at: DateTime.utc(2026, 2, 1)), png(2));
    await s.save(sketch('b', at: DateTime.utc(2026, 3, 1)), png(3));
    expect((await s.loadIndex()).map((e) => e.id), ['b', 'a']);
    expect(await s.loadImage('a'), [0x89, 0x50, 2]);
  });

  test('削除で index と画像が消える', () async {
    final s = store();
    await s.save(sketch('a'), png(1));
    await s.delete('a');
    expect(await s.loadIndex(), isEmpty);
    expect(await s.loadImage('a'), isNull);
  });

  test('壊れた index は空扱い(起動を止めない)', () async {
    final dir = Directory('${tmp.path}/sketches')..createSync(recursive: true);
    File(
      '${dir.path}/${FileGalleryStore.indexFileName}',
    ).writeAsStringSync('{ broken json');
    expect(await store().loadIndex(), isEmpty);
  });
}
