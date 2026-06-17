import 'package:flutter_test/flutter_test.dart';
import 'package:sketch/src/domain/canvas/gradient_direction.dart';

void main() {
  test('放射状判定', () {
    expect(GradientDirection.radial.isRadial, isTrue);
    expect(GradientDirection.horizontal.isRadial, isFalse);
  });

  test('unitAxis は方向ごとの相対軸を返す', () {
    expect(GradientDirection.horizontal.unitAxis, ((0, 0.5), (1, 0.5)));
    expect(GradientDirection.vertical.unitAxis, ((0.5, 0), (0.5, 1)));
    expect(GradientDirection.diagonalDown.unitAxis, ((0, 0), (1, 1)));
    expect(GradientDirection.diagonalUp.unitAxis, ((0, 1), (1, 0)));
  });

  test('方向は 5 種(横/縦/斜め2/放射)。表示名は UI 層で解決する', () {
    // ラベルは AppLocalizations へ移行(test/widget/localization_test.dart で検証)。
    expect(GradientDirection.values.length, 5);
    expect(GradientDirection.values.map((d) => d.name), [
      'horizontal',
      'vertical',
      'diagonalDown',
      'diagonalUp',
      'radial',
    ]);
  });
}
