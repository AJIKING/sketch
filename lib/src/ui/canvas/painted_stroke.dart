import 'dart:ui';

import '../../application/canvas_controller.dart' show Tool;

/// 1 ストロークの保持データ(retained-mode)。
///
/// 立ち上げ scope では描画をベクター(点列の再生)で保持し、レイヤーは
/// ストロークのリストとして表現する。ラスタライズは [canvas_painter] が
/// `stroke_planner` を使って行う。seed はブラシの散らしを決定化する(ADR 0003)。
class PaintedStroke {
  PaintedStroke({
    required this.tool,
    required this.brushKey,
    required this.colorHex,
    required this.size,
    required this.opacity,
    required this.seed,
  }) : points = <Offset>[];

  final Tool tool;
  final String brushKey;
  final String colorHex;
  final double size;
  final double opacity;
  final int seed;
  final List<Offset> points;
}
