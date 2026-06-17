import 'package:sketch/src/domain/settings/settings_store.dart';

/// テスト用のインメモリ `SettingsStore`。保存回数を [saves] で観測できる。
class InMemorySettingsStore implements SettingsStore {
  InMemorySettingsStore([this._locale]);

  String? _locale;
  int saves = 0;

  @override
  Future<String?> loadLocale() async => _locale;

  @override
  Future<void> saveLocale(String? code) async {
    _locale = code;
    saves++;
  }
}
