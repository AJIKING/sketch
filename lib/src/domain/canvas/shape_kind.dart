/// 図形ツールの種類(pure Dart)。[label] は UI 表示名。
enum ShapeKind {
  line('直線'),
  rectangle('四角'),
  triangle('三角'),
  ellipse('楕円');

  const ShapeKind(this.label);

  final String label;
}
