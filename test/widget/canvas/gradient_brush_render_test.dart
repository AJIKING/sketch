import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sketch/src/application/canvas_controller.dart' show Tool;
import 'package:sketch/src/domain/brush/brush_preset.dart';
import 'package:sketch/src/ui/canvas/painted_stroke.dart';
import 'package:sketch/src/ui/canvas/stroke_render.dart';

/// 横一文字のストロークを w×h へ描き、左右端の画素を読む。
Future<({int lr, int lb, int rr, int rb})> _renderEnds(
  PaintedStroke stroke,
  int w,
  int h,
) async {
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);
  renderStroke(canvas, stroke);
  final image = await recorder.endRecording().toImage(w, h);
  final data = await image.toByteData();
  int at(int x, int y) => (y * w + x) * 4;
  final l = at(4, h ~/ 2);
  final r = at(w - 5, h ~/ 2);
  return (
    lr: data!.getUint8(l),
    lb: data.getUint8(l + 2),
    rr: data.getUint8(r),
    rb: data.getUint8(r + 2),
  );
}

void main() {
  testWidgets('グラデブラシは始点で1色目・終点で2色目に寄る', (tester) async {
    const w = 64, h = 16;
    final stroke = PaintedStroke(
      tool: Tool.brush,
      brush: maruPenBrush, // 均一・不透明で読みやすい
      colorHex: '#FF0000', // 始点=赤
      size: 10,
      opacity: 1,
      seed: 0,
      secondColorHex: '#0000FF', // 終点=青
    );
    for (var i = 0; i <= 10; i++) {
      stroke.addPoint(Offset(4 + i * 5.6, h / 2), i.toDouble());
    }

    late ({int lr, int lb, int rr, int rb}) ends;
    await tester.runAsync(() async {
      ends = await _renderEnds(stroke, w, h);
    });

    expect(ends.lr, greaterThan(ends.lb), reason: '左端は赤が優勢');
    expect(ends.rb, greaterThan(ends.rr), reason: '右端は青が優勢');
  });

  testWidgets('単色ブラシは両端とも同色(2色目なし)', (tester) async {
    const w = 64, h = 16;
    final stroke = PaintedStroke(
      tool: Tool.brush,
      brush: maruPenBrush,
      colorHex: '#FF0000',
      size: 10,
      opacity: 1,
      seed: 0,
    );
    for (var i = 0; i <= 10; i++) {
      stroke.addPoint(Offset(4 + i * 5.6, h / 2), i.toDouble());
    }

    late ({int lr, int lb, int rr, int rb}) ends;
    await tester.runAsync(() async {
      ends = await _renderEnds(stroke, w, h);
    });

    expect(ends.lr, greaterThan(200));
    expect(ends.rr, greaterThan(200)); // 右端も赤のまま
  });
}
