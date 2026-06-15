/// レイヤーの合成モード(ibis 相当の主要セット、pure Dart)。
///
/// `dart:ui.BlendMode` への対応づけは ui 層で行い、domain は純粋に保つ。
/// [label] は UI 表示用の日本語名。
enum LayerBlendMode {
  normal('通常'),
  multiply('乗算'),
  screen('スクリーン'),
  overlay('オーバーレイ'),
  darken('比較(暗)'),
  lighten('比較(明)'),
  colorDodge('覆い焼き'),
  colorBurn('焼き込み'),
  hardLight('ハードライト'),
  softLight('ソフトライト'),
  difference('差の絶対値'),
  exclusion('除外'),
  add('加算発光'),
  hue('色相'),
  saturation('彩度'),
  color('カラー'),
  luminosity('輝度');

  const LayerBlendMode(this.label);

  final String label;
}
