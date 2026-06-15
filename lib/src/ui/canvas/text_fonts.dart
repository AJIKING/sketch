/// テキストで選べるフォント一覧(google_fonts で解決)。
///
/// オフライン完結が原則だが、本機能は google_fonts を用いるため**初回表示時のみ
/// 各フォントをネットワークから取得**し、以降は端末にキャッシュされる(キャッシュ後は
/// オフライン可)。日本語が描けるファミリを中心に十数種を用意する。
///
/// [family] が空文字のときは既定(システム)フォント。[label] は UI 表示名。
typedef TextFont = ({String family, String label});

const List<TextFont> textFonts = [
  (family: '', label: '標準'),
  (family: 'Noto Sans JP', label: 'ゴシック'),
  (family: 'Noto Serif JP', label: '明朝'),
  (family: 'M PLUS Rounded 1c', label: '丸ゴシック'),
  (family: 'Kosugi Maru', label: '小杉丸ゴ'),
  (family: 'Zen Maru Gothic', label: 'Zen 丸ゴ'),
  (family: 'Sawarabi Mincho', label: 'さわらび明朝'),
  (family: 'Shippori Mincho', label: 'しっぽり明朝'),
  (family: 'Zen Kaku Gothic New', label: 'Zen 角ゴ'),
  (family: 'Yusei Magic', label: '油性マジック'),
  (family: 'Dela Gothic One', label: 'Dela ゴ太'),
  (family: 'Kaisei Decol', label: '解星デコール'),
  (family: 'RocknRoll One', label: 'ロックロール'),
  (family: 'Hachi Maru Pop', label: 'はちまるポップ'),
  (family: 'Reggae One', label: 'レゲエ'),
  (family: 'Stick', label: 'ステッキ'),
  (family: 'Potta One', label: 'ポッタワン'),
  (family: 'DotGothic16', label: 'ドット'),
];

/// [family] の表示名(未知/空なら「標準」)。
String textFontLabel(String? family) {
  for (final f in textFonts) {
    if (f.family == (family ?? '')) return f.label;
  }
  return '標準';
}
