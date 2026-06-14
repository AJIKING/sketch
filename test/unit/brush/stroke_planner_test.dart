import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:sketch/src/domain/brush/brush_preset.dart';
import 'package:sketch/src/domain/brush/stroke_planner.dart';

const _p0 = Point<double>(0, 0);

StrokePlan _plan(
  BrushPreset brush, {
  Point<double> to = const Point(0, 100),
  double speed = 0,
  double size = 10,
  double opacity = 1,
  int seed = 1,
}) {
  return planStroke(
    from: _p0,
    to: to,
    speed: speed,
    brush: brush,
    size: size,
    opacity: opacity,
    random: Random(seed),
  );
}

void main() {
  group('ink(線分・速度で細る)', () {
    test('速度 0 では筆幅 = サイズ、端は丸、平筆ではない', () {
      final plan = _plan(inkBrush, speed: 0, size: 14);
      expect(plan.dabs, isEmpty);
      expect(plan.segments, hasLength(1));
      final s = plan.segments.single;
      expect(s.width, 14); // clamp(1.15, .4, 1) = 1.0
      expect(s.round, isTrue);
      expect(s.flat, isFalse);
      expect(s.alpha, 1.0);
    });

    test('速くなるほど細り、下限 0.4×サイズでクランプ', () {
      expect(
        _plan(inkBrush, speed: 0.5, size: 10).segments.single.width,
        closeTo(10 * 0.7, 1e-9),
      ); // 1.15 - 0.45 = 0.7
      expect(
        _plan(inkBrush, speed: 5, size: 10).segments.single.width,
        closeTo(10 * 0.4, 1e-9),
      ); // クランプ下限
    });

    test('不透明度が α に乗る', () {
      expect(
        _plan(inkBrush, opacity: 0.3).segments.single.alpha,
        closeTo(0.3, 1e-9),
      );
    });
  });

  group('marker(平筆・速度非依存)', () {
    test('速度に関わらず筆幅 = サイズ、平筆・端は丸でない', () {
      final s = _plan(markerBrush, speed: 9, size: 12).segments.single;
      expect(s.width, 12);
      expect(s.flat, isTrue);
      expect(s.round, isFalse);
      expect(s.alpha, closeTo(0.55, 1e-9));
    });
  });

  group('pencil(硬い点を散らす)', () {
    test('ダブ数 = floor(dist/step)+1、soft でない', () {
      // size=10 → step = max(10*0.5, 1) = 5、dist=100 → n=20 → 21 ダブ
      final plan = _plan(pencilBrush, to: const Point(0, 100), size: 10);
      expect(plan.segments, isEmpty);
      expect(plan.dabs, hasLength(21));
      expect(plan.dabs.every((d) => !d.soft), isTrue);
    });

    test('半径は size×[0.25, 0.45]、α は flow×opacity×[0.5, 1.0]', () {
      for (final d in _plan(pencilBrush, size: 10, opacity: 1).dabs) {
        expect(d.radius, inInclusiveRange(10 * 0.25, 10 * 0.45));
        expect(d.alpha, inInclusiveRange(0.5 * 0.5, 0.5 * 1.0));
      }
    });
  });

  group('air(やわらかい霧)', () {
    test('soft・半径 = サイズ・α = flow×opacity 一定', () {
      final dabs = _plan(airBrush, size: 8, opacity: 1).dabs;
      expect(dabs, isNotEmpty);
      expect(dabs.every((d) => d.soft), isTrue);
      expect(dabs.every((d) => d.radius == 8), isTrue);
      expect(dabs.every((d) => (d.alpha - 0.18).abs() < 1e-9), isTrue);
    });
  });

  group('決定性(ADR 0003)', () {
    test('同じ seed なら同じダブ位置になる', () {
      List<Point<double>> centers(int seed) =>
          _plan(pencilBrush, seed: seed).dabs.map((d) => d.center).toList();
      final a = centers(7);
      final b = centers(7);
      expect(a.length, b.length);
      for (var i = 0; i < a.length; i++) {
        expect(a[i].x, b[i].x);
        expect(a[i].y, b[i].y);
      }
    });

    test('異なる seed では散らし位置が変わる', () {
      final a = _plan(pencilBrush, seed: 1).dabs.first.center;
      final b = _plan(pencilBrush, seed: 2).dabs.first.center;
      expect(a == b, isFalse);
    });
  });

  test('長さ 0 の区間(ストローク開始の点)でも最低 2 ダブ', () {
    final plan = _plan(pencilBrush, to: _p0);
    expect(plan.dabs, hasLength(2)); // n = max(1, 0) = 1 → i=0,1
  });
}
