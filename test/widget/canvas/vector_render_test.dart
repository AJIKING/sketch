import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sketch/src/domain/canvas/shape_kind.dart';
import 'package:sketch/src/domain/vector/vector_layer.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sketch/src/domain/vector/vector_object.dart';
import 'package:sketch/src/ui/canvas/vector_render.dart';

Future<ui.Image> _render(VectorLayer layer, int w, int h) async {
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);
  renderVectorLayer(canvas, layer);
  return recorder.endRecording().toImage(w, h);
}

void main() {
  testWidgets('ストロークを描くと線上の画素が着色される', (tester) async {
    const w = 40, h = 40;
    final layer = VectorLayer()
      ..add(
        VectorStroke(
          id: 's',
          colorHex: '#FF0000',
          width: 8,
          points: const [VecPoint(4, 20), VecPoint(36, 20)],
        ),
      );

    late ({int r, int a, int cornerA}) px;
    await tester.runAsync(() async {
      final image = await _render(layer, w, h);
      final data = await image.toByteData();
      int at(int x, int y) => (y * w + x) * 4;
      final mid = at(20, 20);
      final corner = at(2, 2);
      px = (
        r: data!.getUint8(mid),
        a: data.getUint8(mid + 3),
        cornerA: data.getUint8(corner + 3),
      );
    });

    expect(px.a, greaterThan(0), reason: '線上は不透明');
    expect(px.r, greaterThan(200), reason: '赤で描かれる');
    expect(px.cornerA, 0, reason: '線から離れた隅は透明');
  });

  testWidgets('塗り図形を描くと内部の画素が着色される', (tester) async {
    const w = 40, h = 40;
    final layer = VectorLayer()
      ..add(
        const VectorShapeObject(
          id: 'r',
          colorHex: '#00FF00',
          width: 2,
          kind: ShapeKind.rectangle,
          start: VecPoint(8, 8),
          end: VecPoint(32, 32),
          filled: true,
        ),
      );

    late ({int g, int a}) px;
    await tester.runAsync(() async {
      final image = await _render(layer, w, h);
      final data = await image.toByteData();
      final center = (20 * w + 20) * 4;
      px = (g: data!.getUint8(center + 1), a: data.getUint8(center + 3));
    });

    expect(px.a, greaterThan(0));
    expect(px.g, greaterThan(200));
  });

  testWidgets('テキストを描くと文字ボックス内に着色画素が出る', (tester) async {
    const w = 120, h = 48;
    final layer = VectorLayer()
      ..add(
        const VectorText(
          id: 't',
          colorHex: '#FF0000',
          position: VecPoint(4, 4),
          text: 'AB',
          fontSize: 28,
          boxWidth: 60,
          boxHeight: 34,
        ),
      );

    var found = false;
    await tester.runAsync(() async {
      final image = await _render(layer, w, h);
      final data = await image.toByteData();
      for (var y = 4; y < 40 && !found; y++) {
        for (var x = 4; x < 100; x++) {
          final i = (y * w + x) * 4;
          if (data!.getUint8(i + 3) > 0 && data.getUint8(i) > 150) {
            found = true;
            break;
          }
        }
      }
    });

    expect(found, isTrue, reason: '赤い文字の画素が描かれる');
  });

  testWidgets('2色グラデーションのテキストは左が赤・右が青に寄る', (tester) async {
    const w = 160, h = 48;
    final layer = VectorLayer()
      ..add(
        const VectorText(
          id: 't',
          colorHex: '#FF0000', // 始点=赤
          position: VecPoint(4, 4),
          text: 'MMMMMM',
          fontSize: 30,
          boxWidth: 150,
          boxHeight: 36,
          gradient: true,
          secondColorHex: '#0000FF', // 終点=青
        ),
      );

    var leftRed = false, rightBlue = false;
    await tester.runAsync(() async {
      final image = await _render(layer, w, h);
      final data = await image.toByteData();
      for (var y = 4; y < 40; y++) {
        for (var x = 4; x < w - 4; x++) {
          final i = (y * w + x) * 4;
          if (data!.getUint8(i + 3) == 0) continue; // 透明は無視
          final r = data.getUint8(i), b = data.getUint8(i + 2);
          if (x < 50 && r > b + 40) leftRed = true;
          if (x > w - 50 && b > r + 40) rightBlue = true;
        }
      }
    });

    expect(leftRed, isTrue, reason: '左側は赤寄り');
    expect(rightBlue, isTrue, reason: '右側は青寄り');
  });

  testWidgets('フォント指定でも例外なくレイアウトできる(オフライン: フォールバック)', (tester) async {
    // テストではフォントのネット取得を無効化(フォールバック描画。通信しない)。
    GoogleFonts.config.allowRuntimeFetching = false;
    addTearDown(() => GoogleFonts.config.allowRuntimeFetching = true);

    final painter = buildVectorTextPainter(
      text: 'あA',
      colorHex: '#222222',
      fontSize: 32,
      bold: false,
      underline: false,
      strikethrough: false,
      fontFamily: 'Noto Sans JP',
    );
    expect(painter.width, greaterThan(0));
    expect(painter.height, greaterThan(0));
  });
}
