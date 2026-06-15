import 'package:flutter_test/flutter_test.dart';
import 'package:sketch/src/domain/canvas/shape_kind.dart';
import 'package:sketch/src/domain/vector/vector_object.dart';

void main() {
  group('VectorStroke', () {
    final stroke = VectorStroke(
      id: 's1',
      colorHex: '#112233',
      width: 6,
      points: const [VecPoint(0, 0), VecPoint(10, 0), VecPoint(10, 10)],
    );

    test('bounds は全点の外接矩形', () {
      expect(stroke.bounds, (left: 0.0, top: 0.0, right: 10.0, bottom: 10.0));
    });

    test('translate は全点を平行移動し、元は不変', () {
      final moved = stroke.translate(5, -3);
      expect(moved.points.first, const VecPoint(5, -3));
      expect(stroke.points.first, const VecPoint(0, 0)); // 不変
    });

    test('withColor / withWidth は新インスタンス', () {
      expect(stroke.withColor('#FFFFFF').colorHex, '#FFFFFF');
      expect(stroke.withWidth(20).width, 20);
      expect(stroke.colorHex, '#112233'); // 元は不変
    });

    test('hitTest は線分近傍で true、遠方で false', () {
      expect(stroke.hitTest(const VecPoint(5, 0)), isTrue); // 線上
      expect(stroke.hitTest(const VecPoint(5, 2), tolerance: 4), isTrue);
      expect(stroke.hitTest(const VecPoint(5, 40)), isFalse);
    });

    test('scaled は anchor 中心に点と線幅を比例拡縮', () {
      final s = stroke.scaled(2, const VecPoint(0, 0));
      expect(s.points.last, const VecPoint(20, 20)); // (10,10) → (20,20)
      expect(s.width, 12); // 6 * 2
    });

    test('単一点ストロークは半径内で当たる', () {
      final dot = VectorStroke(
        id: 'd',
        colorHex: '#000000',
        width: 10,
        points: const [VecPoint(0, 0)],
      );
      expect(dot.hitTest(const VecPoint(3, 0), tolerance: 0), isTrue); // r=5
      expect(dot.hitTest(const VecPoint(9, 0), tolerance: 0), isFalse);
    });
  });

  group('VectorShapeObject', () {
    test('直線は線分距離で当たり判定', () {
      final line = VectorShapeObject(
        id: 'l',
        colorHex: '#000000',
        width: 4,
        kind: ShapeKind.line,
        start: const VecPoint(0, 0),
        end: const VecPoint(10, 0),
      );
      expect(line.hitTest(const VecPoint(5, 1)), isTrue);
      expect(line.hitTest(const VecPoint(5, 50)), isFalse);
    });

    test('矩形は外接矩形内で当たる / translate / bounds', () {
      final rect = VectorShapeObject(
        id: 'r',
        colorHex: '#000000',
        width: 2,
        kind: ShapeKind.rectangle,
        start: const VecPoint(0, 0),
        end: const VecPoint(20, 10),
        filled: true,
      );
      expect(rect.hitTest(const VecPoint(10, 5)), isTrue);
      expect(rect.hitTest(const VecPoint(100, 100)), isFalse);
      final moved = rect.translate(5, 5);
      expect(moved.bounds, (left: 5.0, top: 5.0, right: 25.0, bottom: 15.0));
    });

    test('end<start でも bounds は正規化される', () {
      final tri = VectorShapeObject(
        id: 't',
        colorHex: '#000000',
        width: 2,
        kind: ShapeKind.triangle,
        start: const VecPoint(30, 30),
        end: const VecPoint(10, 10),
      );
      expect(tri.bounds, (left: 10.0, top: 10.0, right: 30.0, bottom: 30.0));
    });
  });

  group('VectorText', () {
    VectorText make() => const VectorText(
      id: 't',
      colorHex: '#112233',
      position: VecPoint(10, 20),
      text: 'Hi',
      fontSize: 24,
      boxWidth: 40,
      boxHeight: 30,
      underline: true,
    );

    test('bounds は 位置 + ボックスサイズ', () {
      expect(make().bounds, (left: 10.0, top: 20.0, right: 50.0, bottom: 50.0));
    });

    test('hitTest はボックス内で true', () {
      final t = make();
      expect(t.hitTest(const VecPoint(30, 35)), isTrue);
      expect(t.hitTest(const VecPoint(200, 200)), isFalse);
    });

    test('translate は位置を動かし装飾を保つ', () {
      final t = make().translate(5, 5);
      expect(t.position, const VecPoint(15, 25));
      expect(t.underline, isTrue);
    });

    test('withColor / copyWith / 基底 width は fontSize', () {
      expect(make().withColor('#FFFFFF').colorHex, '#FFFFFF');
      expect(make().copyWith(strikethrough: true).strikethrough, isTrue);
      expect(make().width, 24);
    });

    test('withWidth はフォントとボックスを比例して縮拡する', () {
      final t = make().withWidth(48); // 24 → 48(2 倍)
      expect(t.fontSize, 48);
      expect(t.boxWidth, 80); // 40 * 2
      expect(t.boxHeight, 60); // 30 * 2
    });

    test('scaled は位置・フォント・ボックスを anchor 中心に拡縮', () {
      final t = make().scaled(2, const VecPoint(0, 0));
      expect(t.position, const VecPoint(20, 40)); // (10,20) → (20,40)
      expect(t.fontSize, 48);
      expect(t.boxWidth, 80);
      expect(t.boxHeight, 60);
    });
  });
}
