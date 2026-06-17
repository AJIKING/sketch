/// レイヤーの合成モード(ibis 相当の主要セット、pure Dart)。
///
/// `dart:ui.BlendMode` への対応づけは ui 層で行い、domain は純粋に保つ。
/// 表示名は UI 層([AppLocalizations] 経由・`ui/canvas/l10n_labels.dart`)で解決する。
enum LayerBlendMode {
  normal,
  multiply,
  screen,
  overlay,
  darken,
  lighten,
  colorDodge,
  colorBurn,
  hardLight,
  softLight,
  difference,
  exclusion,
  add,
  hue,
  saturation,
  color,
  luminosity,
}
