/// グラデーションの方向(pure Dart)。テキスト・ブラシ塗り・グラデツールで共通。
///
/// 線形は [unitAxis] が返す 0..1 の相対座標(対象の矩形に対する始点・終点)で
/// 表す。ui 層が矩形へスケールして `ui.Gradient.linear` のアンカーにする。
/// [radial] は中心から外側への円形(`ui.Gradient.radial`)。
/// 表示名は UI 層([AppLocalizations] 経由・`ui/canvas/l10n_labels.dart`)で解決する。
enum GradientDirection {
  horizontal,
  vertical,
  diagonalDown,
  diagonalUp,
  radial;

  bool get isRadial => this == GradientDirection.radial;

  /// 線形グラデの始点・終点を、対象矩形に対する相対座標 (0..1) で返す。
  /// 第 1 要素が始点 (x, y)、第 2 要素が終点 (x, y)。放射は中心同士を返す。
  ((double, double), (double, double)) get unitAxis => switch (this) {
    GradientDirection.horizontal => ((0, 0.5), (1, 0.5)),
    GradientDirection.vertical => ((0.5, 0), (0.5, 1)),
    GradientDirection.diagonalDown => ((0, 0), (1, 1)),
    GradientDirection.diagonalUp => ((0, 1), (1, 0)),
    GradientDirection.radial => ((0.5, 0.5), (0.5, 0.5)),
  };
}
