import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sketch/src/application/locale_controller.dart';

import '../../fixtures/in_memory_settings_store.dart';

void main() {
  test('初期状態は追従(locale=null)', () {
    final c = LocaleController(store: InMemorySettingsStore());
    expect(c.locale, isNull);
  });

  test('load は保存済みの言語コードを復元する', () async {
    final c = LocaleController(store: InMemorySettingsStore('zh'));
    await c.load();
    expect(c.locale, const Locale('zh'));
  });

  test('load は未保存なら追従のまま', () async {
    final c = LocaleController(store: InMemorySettingsStore());
    await c.load();
    expect(c.locale, isNull);
  });

  test('setLocale は選択を反映し、通知し、永続化する', () async {
    final store = InMemorySettingsStore();
    final c = LocaleController(store: store);
    var notified = 0;
    c.addListener(() => notified++);

    await c.setLocale(const Locale('en'));
    expect(c.locale, const Locale('en'));
    expect(notified, 1);
    expect(store.saves, 1);
    expect(await store.loadLocale(), 'en');
  });

  test('setLocale(null) は追従へ戻して永続化する', () async {
    final store = InMemorySettingsStore('ja');
    final c = LocaleController(store: store);
    await c.load();
    await c.setLocale(null);
    expect(c.locale, isNull);
    expect(await store.loadLocale(), isNull);
  });

  test('store 無しでも選択は保持する(非永続)', () async {
    final c = LocaleController();
    await c.setLocale(const Locale('zh'));
    expect(c.locale, const Locale('zh'));
  });
}
