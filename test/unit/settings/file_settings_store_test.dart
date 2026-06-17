import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:sketch/src/data/file_settings_store.dart';

void main() {
  late Directory tmp;

  setUp(() async {
    tmp = await Directory.systemTemp.createTemp('hatch_settings');
  });
  tearDown(() async {
    if (await tmp.exists()) await tmp.delete(recursive: true);
  });

  FileSettingsStore store() =>
      FileSettingsStore(resolveDir: () async => Directory('${tmp.path}/app'));

  test('未保存なら null(端末設定に追従)', () async {
    expect(await store().loadLocale(), isNull);
  });

  test('保存した言語コードが読み出せる', () async {
    await store().saveLocale('zh');
    expect(await store().loadLocale(), 'zh');
  });

  test('別インスタンスでも読める(ディスクに永続化)', () async {
    await store().saveLocale('en');
    final fresh = store();
    expect(await fresh.loadLocale(), 'en');
  });

  test('null を保存すると追従へ戻る', () async {
    final s = store();
    await s.saveLocale('ja');
    await s.saveLocale(null);
    expect(await s.loadLocale(), isNull);
  });

  test('壊れた保存は null 扱いで起動を止めない', () async {
    final dir = Directory('${tmp.path}/app')..createSync(recursive: true);
    File(
      '${dir.path}/${FileSettingsStore.fileName}',
    ).writeAsStringSync('{ broken');
    expect(await store().loadLocale(), isNull);
  });
}
