import 'package:flutter/widgets.dart';

import '../domain/settings/settings_store.dart';

/// 表示言語の選択状態(`ChangeNotifier`)。
///
/// [locale] が `null` のときは端末設定に追従する(`MaterialApp.locale` に `null` を
/// 渡す)。選択は [SettingsStore] に永続化し、次回起動時に [load] で復元する。
/// store が無い構成(テスト等)では永続化せずメモリ上の選択のみ保持する。
class LocaleController extends ChangeNotifier {
  LocaleController({this.store});

  final SettingsStore? store;

  Locale? _locale;

  /// 現在の選択言語。`null` は端末設定に追従。
  Locale? get locale => _locale;

  /// 永続化された選択を復元する。未設定なら追従(`null`)のまま。
  Future<void> load() async {
    final code = await store?.loadLocale();
    if (code != null && code.isNotEmpty) {
      _locale = Locale(code);
      notifyListeners();
    }
  }

  /// 言語を切り替えて永続化する。`null` で端末設定に追従へ戻す。
  Future<void> setLocale(Locale? locale) async {
    if (_locale == locale) return;
    _locale = locale;
    notifyListeners();
    await store?.saveLocale(locale?.languageCode);
  }
}
