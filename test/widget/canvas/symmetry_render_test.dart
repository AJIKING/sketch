import 'dart:ui' as ui;

import 'package:flutter_test/flutter_test.dart';
import 'package:sketch/src/application/canvas_controller.dart' show Tool;
import 'package:sketch/src/domain/brush/brush_preset.dart';
import 'package:sketch/src/domain/canvas/symmetry_mode.dart';
import 'package:sketch/src/ui/canvas/painted_stroke.dart';
import 'package:sketch/src/ui/canvas/raster_painter.dart';

PaintedStroke _leftVerticalLine() {
  final s = PaintedStroke(
    tool: Tool.brush,
    brush: maruPenBrush, // 均一・不透明で読みやすい
    colorHex: '#FF0000',
    size: 6,
    opacity: 1,
    seed: 0,
  );
  // 左側(x=8)に縦線。
  for (var i = 0; i <= 12; i++) {
    s.addPoint(Offset(8, 6 + i * 2.0), i.toDouble());
  }
  return s;
}

Future<int> _alphaAt(ui.Image img, int x, int y, int w) async {
  final data = await img.toByteData();
  return data!.getUint8((y * w + x) * 4 + 3);
}

void main() {
  const w = 40, h = 40; // 中心 cx=20。x=8 の鏡映は x=32。

  testWidgets('対称なしでは反対側に線は出ない(対照)', (tester) async {
    late int left, right;
    await tester.runAsync(() async {
      final img = bakeStroke(
        existing: null,
        stroke: _leftVerticalLine(),
        width: w,
        height: h,
      );
      left = await _alphaAt(img, 8, 20, w);
      right = await _alphaAt(img, 32, 20, w);
    });
    expect(left, greaterThan(0));
    expect(right, 0);
  });

  testWidgets('左右対称で反対側にも線が焼き込まれる', (tester) async {
    late int left, right;
    await tester.runAsync(() async {
      final img = bakeStroke(
        existing: null,
        stroke: _leftVerticalLine(),
        width: w,
        height: h,
        symmetry: SymmetryMode.vertical,
      );
      left = await _alphaAt(img, 8, 20, w);
      right = await _alphaAt(img, 32, 20, w);
    });
    expect(left, greaterThan(0));
    expect(right, greaterThan(0)); // x=8 の鏡映 x=32 にも描かれる
  });

  testWidgets('4分割対称では上下左右に線が焼き込まれる', (tester) async {
    // 左上(x=8,y=8)に短い点を置き、四隅に出るか確認。
    final s = PaintedStroke(
      tool: Tool.brush,
      brush: maruPenBrush,
      colorHex: '#FF0000',
      size: 8,
      opacity: 1,
      seed: 0,
    );
    s.addPoint(const Offset(8, 8), 0);

    late int tl, tr, bl, br;
    await tester.runAsync(() async {
      final img = bakeStroke(
        existing: null,
        stroke: s,
        width: w,
        height: h,
        symmetry: SymmetryMode.quad,
      );
      tl = await _alphaAt(img, 8, 8, w);
      tr = await _alphaAt(img, 32, 8, w);
      bl = await _alphaAt(img, 8, 32, w);
      br = await _alphaAt(img, 32, 32, w);
    });
    expect(tl, greaterThan(0));
    expect(tr, greaterThan(0));
    expect(bl, greaterThan(0));
    expect(br, greaterThan(0));
  });
}
