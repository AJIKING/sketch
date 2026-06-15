/// 選択範囲の作り方(pure Dart)。[label] は UI 表示名。
enum SelectionKind {
  rectangle('矩形'),
  lasso('なげなわ'),
  magicWand('自動選択');

  const SelectionKind(this.label);

  final String label;
}
