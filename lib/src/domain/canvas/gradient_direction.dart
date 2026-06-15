/// グラデーションの方向(pure Dart)。テキスト・ブラシ塗り・グラデツールで共通。
///
/// 線形は [unitAxis] が返す 0..1 の相対座標(対象の矩形に対する始点・終点)で
/// 表す。ui 層が矩形へスケールして `ui.Gradient.linear` のアンカーにする。
/// [radial] は中心から外側への円形(`ui.Gradient.radial`)。
enum GradientDirection {
  horizontal('横'),
  vertical('縦'),
  diagonalDown('斜め ↘'),
  diagonalUp('斜め ↗'),
  radial('放射');

  const GradientDirection(this.label);

  final String label;

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
