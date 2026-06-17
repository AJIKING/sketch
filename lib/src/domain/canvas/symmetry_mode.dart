/// 対称(シンメトリー)描画のモード(pure Dart)。
///
/// 軸はキャンバス中心。[vertical] は左右(X 軸)、[horizontal] は上下(Y 軸)、
/// [quad] は上下左右の 4 分割鏡映。表示名は UI 層([AppLocalizations] 経由・
/// `ui/canvas/l10n_labels.dart`)で解決する。
enum SymmetryMode { none, vertical, horizontal, quad }
