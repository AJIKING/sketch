import '../../../l10n/app_localizations.dart';

/// テキストで選べるフォント一覧(google_fonts で解決)。
///
/// オフライン完結が原則だが、本機能は google_fonts を用いるため**初回表示時のみ
/// 各フォントをネットワークから取得**し、以降は端末にキャッシュされる(キャッシュ後は
/// オフライン可)。日本語が描けるファミリを中心に十数種を用意する。
///
/// [family] が空文字のときは既定(システム)フォント。表示名は [labelKey] を
/// [fontLabel] で [AppLocalizations] へ解決する(`docs/architecture.md`「UI が表示を所有」)。
typedef TextFont = ({String family, String labelKey});

const List<TextFont> textFonts = [
  (family: '', labelKey: 'default'),
  (family: 'Noto Sans JP', labelKey: 'gothic'),
  (family: 'Noto Serif JP', labelKey: 'mincho'),
  (family: 'M PLUS Rounded 1c', labelKey: 'roundGothic'),
  (family: 'Kosugi Maru', labelKey: 'kosugiMaru'),
  (family: 'Zen Maru Gothic', labelKey: 'zenMaru'),
  (family: 'Sawarabi Mincho', labelKey: 'sawarabiMincho'),
  (family: 'Shippori Mincho', labelKey: 'shipporiMincho'),
  (family: 'Zen Kaku Gothic New', labelKey: 'zenKaku'),
  (family: 'Yusei Magic', labelKey: 'yuseiMagic'),
  (family: 'Dela Gothic One', labelKey: 'delaGothic'),
  (family: 'Kaisei Decol', labelKey: 'kaiseiDecol'),
  (family: 'RocknRoll One', labelKey: 'rocknRoll'),
  (family: 'Hachi Maru Pop', labelKey: 'hachiMaru'),
  (family: 'Reggae One', labelKey: 'reggae'),
  (family: 'Stick', labelKey: 'stick'),
  (family: 'Potta One', labelKey: 'potta'),
  (family: 'DotGothic16', labelKey: 'dot'),
];

/// フォントの [labelKey] を表示言語のラベルへ解決する。
String fontLabel(AppLocalizations l, String labelKey) => switch (labelKey) {
  'default' => l.fontDefault,
  'gothic' => l.fontGothic,
  'mincho' => l.fontMincho,
  'roundGothic' => l.fontRoundGothic,
  'kosugiMaru' => l.fontKosugiMaru,
  'zenMaru' => l.fontZenMaru,
  'sawarabiMincho' => l.fontSawarabiMincho,
  'shipporiMincho' => l.fontShipporiMincho,
  'zenKaku' => l.fontZenKaku,
  'yuseiMagic' => l.fontYuseiMagic,
  'delaGothic' => l.fontDelaGothic,
  'kaiseiDecol' => l.fontKaiseiDecol,
  'rocknRoll' => l.fontRocknRoll,
  'hachiMaru' => l.fontHachiMaru,
  'reggae' => l.fontReggae,
  'stick' => l.fontStick,
  'potta' => l.fontPotta,
  'dot' => l.fontDot,
  _ => l.fontDefault,
};
