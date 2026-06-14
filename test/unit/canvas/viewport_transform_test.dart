import 'dart:ui' show Size;

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

  group('fit(中央フィット)', () {
    test('同寸法なら等倍・原点(歪みなし)', () {
      final v = ViewportTransform.fit(
        const Size(100, 200),
        const Size(100, 200),
      );
      expect(v.scale, closeTo(1, 1e-9));
      expectOffset(v.offset, Offset.zero);
      expect(v.rotation, 0);
    });

    test('横長表示に縦長アートボードを収めると高さ基準で中央寄せ', () {
      // doc 100x200 を view 300x100 へ。scale = min(3, 0.5) = 0.5。
      final v = ViewportTransform.fit(
        const Size(100, 200),
        const Size(300, 100),
      );
      expect(v.scale, closeTo(0.5, 1e-9));
      // 横: (300 - 100*0.5)/2 = 125、縦: (100 - 200*0.5)/2 = 0。
      expectOffset(v.offset, const Offset(125, 0), eps: 1e-6);
      // アートボード中心(50,100)が表示の中心(150,50)へ写る。
      expectOffset(
        v.toView(const Offset(50, 100)),
        const Offset(150, 50),
        eps: 1e-6,
      );
    });

    test('縦長表示に横長アートボードを収めると幅基準で中央寄せ', () {
      // doc 200x100 を view 100x300 へ。scale = min(0.5, 3) = 0.5。
      final v = ViewportTransform.fit(
        const Size(200, 100),
        const Size(100, 300),
      );
      expect(v.scale, closeTo(0.5, 1e-9));
      expectOffset(v.offset, const Offset(0, 125), eps: 1e-6);
    });

    test('空サイズなら恒等変換(クラッシュしない)', () {
      expect(ViewportTransform.fit(Size.zero, const Size(10, 10)).scale, 1);
      expect(ViewportTransform.fit(const Size(10, 10), Size.zero).scale, 1);
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
