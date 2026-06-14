import 'package:flutter_test/flutter_test.dart';
import 'package:sketch/src/ui/canvas/viewport_transform.dart';

void expectOffset(Offset a, Offset b, {double eps = 1e-9}) {
  expect(a.dx, closeTo(b.dx, eps));
  expect(a.dy, closeTo(b.dy, eps));
}

void main() {
  group('toView / toCanvas', () {
    test('恒等変換はそのまま', () {
      const v = ViewportTransform();
      expectOffset(v.toView(const Offset(3, 4)), const Offset(3, 4));
      expectOffset(v.toCanvas(const Offset(3, 4)), const Offset(3, 4));
    });

    test('拡大と平行移動', () {
      const v = ViewportTransform(scale: 2, offset: Offset(10, 20));
      expectOffset(v.toView(const Offset(5, 5)), const Offset(20, 30));
    });

    test('toCanvas は toView の逆', () {
      const v = ViewportTransform(
        scale: 1.7,
        rotation: 0.6,
        offset: Offset(8, -3),
      );
      const p = Offset(12, 25);
      expectOffset(v.toCanvas(v.toView(p)), p, eps: 1e-6);
    });
  });

  group('fromTwoFinger', () {
    test('平行移動: 2 点が同じだけ動くと offset だけ変わる', () {
      const start = ViewportTransform();
      final v = ViewportTransform.fromTwoFinger(
        start: start,
        a0: const Offset(0, 0),
        b0: const Offset(10, 0),
        a: const Offset(5, 7),
        b: const Offset(15, 7),
      );
      expect(v.scale, closeTo(1, 1e-9));
      expect(v.rotation, closeTo(0, 1e-9));
      expectOffset(v.offset, const Offset(5, 7), eps: 1e-6);
    });

    test('ピンチ: 指間距離が倍なら scale が倍', () {
      const start = ViewportTransform();
      final v = ViewportTransform.fromTwoFinger(
        start: start,
        a0: const Offset(0, 0),
        b0: const Offset(0, 10),
        a: const Offset(0, 0),
        b: const Offset(0, 20),
      );
      expect(v.scale, closeTo(2, 1e-9));
    });

    test('回転: 90 度回すと rotation が π/2', () {
      const start = ViewportTransform();
      final v = ViewportTransform.fromTwoFinger(
        start: start,
        a0: const Offset(0, 0),
        b0: const Offset(10, 0),
        a: const Offset(0, 0),
        b: const Offset(0, 10),
      );
      expect(v.rotation, closeTo(1.5707963, 1e-6));
    });

    test('scale は 0.1..20 にクランプ', () {
      const start = ViewportTransform();
      final v = ViewportTransform.fromTwoFinger(
        start: start,
        a0: const Offset(0, 0),
        b0: const Offset(0, 1000),
        a: const Offset(0, 0),
        b: const Offset(0, 1),
      );
      expect(v.scale, closeTo(0.1, 1e-9));
    });
  });
}
