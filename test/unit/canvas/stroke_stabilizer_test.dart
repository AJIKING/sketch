import 'package:flutter_test/flutter_test.dart';
import 'package:sketch/src/ui/canvas/stroke_stabilizer.dart';

void main() {
  test('strength 0 は生の点をそのまま返す', () {
    final s = StrokeStabilizer(0);
    expect(s.add(const Offset(0, 0)), const Offset(0, 0));
    expect(s.add(const Offset(10, 0)), const Offset(10, 0));
    expect(s.add(const Offset(10, 20)), const Offset(10, 20));
  });

  test('最初の点はそのまま', () {
    final s = StrokeStabilizer(0.8);
    expect(s.add(const Offset(5, 5)), const Offset(5, 5));
  });

  test('補正中は生の点より遅れて追従する', () {
    final s = StrokeStabilizer(0.8)..add(const Offset(0, 0));
    final p = s.add(const Offset(100, 0));
    // a = 1-0.8 = 0.2 → 0 + 100*0.2 = 20
    expect(p.dx, closeTo(20, 1e-9));
    expect(p.dy, 0);
    // 同じ目標を与え続けると徐々に近づく。
    final p2 = s.add(const Offset(100, 0));
    expect(p2.dx, greaterThan(p.dx));
    expect(p2.dx, lessThan(100));
  });

  test('reset で平滑状態がクリアされる', () {
    final s = StrokeStabilizer(0.8)..add(const Offset(0, 0));
    s.reset();
    expect(s.add(const Offset(50, 50)), const Offset(50, 50));
  });
}
