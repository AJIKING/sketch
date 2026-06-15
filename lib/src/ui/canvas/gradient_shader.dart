import 'dart:ui' as ui;

import 'package:flutter/painting.dart';

import '../../domain/canvas/gradient_direction.dart';

/// [direction] と対象矩形 [bounds] から、[colors](始点→終点)のシェーダを作る。
///
/// テキスト・グラデツール・各種塗りで共通して使う(設定方式を統一するため)。
/// 線形は方向の相対軸を矩形へスケール、放射は矩形中心から最長半径の円形。
ui.Shader gradientShader(
  GradientDirection direction,
  Rect bounds,
  List<Color> colors,
) {
  if (direction.isRadial) {
    final radius = bounds.longestSide / 2;
    return ui.Gradient.radial(bounds.center, radius <= 0 ? 1 : radius, colors);
  }
  final ((ax, ay), (bx, by)) = direction.unitAxis;
  final from = Offset(
    bounds.left + ax * bounds.width,
    bounds.top + ay * bounds.height,
  );
  final to = Offset(
    bounds.left + bx * bounds.width,
    bounds.top + by * bounds.height,
  );
  return ui.Gradient.linear(from, to, colors);
}
