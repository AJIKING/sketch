/// アプリ設定の永続化境界(pure Dart)。
///
/// 本番はアプリ内ストレージ(`data/file_settings_store.dart`)、テストはインメモリ
/// fake(`test/fixtures/in_memory_settings_store.dart`)。現状は表示言語の選択のみ
/// 保持する。読めない / 壊れた保存は「未設定(`null`)」として扱い、起動を止めない。
abstract interface class SettingsStore {
  /// 保存済みの言語コード(例: `ja` / `en` / `zh`)を返す。
  /// `null` は「端末設定に追従」を表す。
  Future<String?> loadLocale();

  /// 言語コードを保存する。`null` を渡すと「端末設定に追従」へ戻す。
  Future<void> saveLocale(String? code);
}
