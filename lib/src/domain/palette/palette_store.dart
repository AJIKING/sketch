/// ユーザー定義カラーパレットの永続化境界。
///
/// 本番はアプリ内ストレージ(`data/file_palette_store.dart`)、テストはインメモリ
/// fake(`test/fixtures/in_memory_palette_store.dart`)。保持するのは HEX 文字列の
/// 並び(新しい順)。読めない / 壊れた保存は空一覧として扱い、起動を止めない。
abstract interface class PaletteStore {
  /// 保存済みのカスタム色(HEX)を返す。無ければ空。
  Future<List<String>> load();

  /// カスタム色の並びを丸ごと保存する。
  Future<void> save(List<String> hexes);
}
