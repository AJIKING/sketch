/// グラデーションの種類(pure Dart)。[label] は UI 表示名。
enum GradientKind {
  linear('線形'),
  radial('円形');

  const GradientKind(this.label);

  final String label;
}
