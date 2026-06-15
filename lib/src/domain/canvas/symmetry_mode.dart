/// 対称(シンメトリー)描画のモード(pure Dart)。[label] は UI 表示名。
///
/// 軸はキャンバス中心。[vertical] は左右(X 軸)、[horizontal] は上下(Y 軸)、
/// [quad] は上下左右の 4 分割鏡映。
enum SymmetryMode {
  none('なし'),
  vertical('左右'),
  horizontal('上下'),
  quad('4分割');

  const SymmetryMode(this.label);

  final String label;
}
