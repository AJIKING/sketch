/// 図形ツールの種類(pure Dart)。
///
/// 表示名は UI 層([AppLocalizations] 経由・`ui/canvas/l10n_labels.dart`)で解決する。
/// 識別子は enum 名(`line` / `rectangle` / `triangle` / `ellipse`)。
enum ShapeKind { line, rectangle, triangle, ellipse }
