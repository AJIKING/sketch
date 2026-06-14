import 'package:flutter_test/flutter_test.dart';
import 'package:sketch/src/domain/canvas/shape_kind.dart';
import 'package:sketch/src/ui/canvas/shape_render.dart';

void main() {
  test('snap off は終点そのまま', () {
    expect(
      snapShapeEnd(
        ShapeKind.line,
        Offset.zero,
        const Offset(10, 3),
        snap: false,
      ),
      const Offset(10, 3),
    );
  });

  test('直線スナップは 45° 刻み(長さ保存)', () {
    final r = snapShapeEnd(
      ShapeKind.line,
      Offset.zero,
      const Offset(10, 9),
      snap: true,
    );
    expect(r.dx, closeTo(r.dy, 1e-6)); // 約45° → x≈y
  });

  test('四角スナップは正方形(等辺・符号保持)', () {
    expect(
      snapShapeEnd(
        ShapeKind.rectangle,
        Offset.zero,
        const Offset(10, 4),
        snap: true,
      ),
      const Offset(10, 10),
    );
    expect(
      snapShapeEnd(
        ShapeKind.ellipse,
        Offset.zero,
        const Offset(-3, -10),
        snap: true,
      ),
      const Offset(-10, -10),
    );
  });
}
