import 'dart:ui' as ui;

import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sketch/src/domain/canvas/gradient_direction.dart';
import 'package:sketch/src/ui/canvas/gradient_shader.dart';

void main() {
  const colors = [Color(0xFFFF0000), Color(0xFF0000FF)];

  test('各方向でシェーダを生成できる(例外なし)', () {
    const rect = Rect.fromLTWH(0, 0, 100, 60);
    for (final d in GradientDirection.values) {
      expect(gradientShader(d, rect, colors), isA<ui.Shader>());
    }
  });

  test('退化した矩形(幅0/高さ0/点)でも落ちない', () {
    expect(
      gradientShader(GradientDirection.horizontal, Rect.zero, colors),
      isA<ui.Shader>(),
    );
    expect(
      gradientShader(
        GradientDirection.horizontal,
        const Rect.fromLTWH(5, 5, 0, 40), // 幅0(縦ドラッグ × 横方向)
        colors,
      ),
      isA<ui.Shader>(),
    );
    expect(
      gradientShader(GradientDirection.radial, Rect.zero, colors),
      isA<ui.Shader>(), // 半径0でも最小1へ丸める
    );
  });
}
