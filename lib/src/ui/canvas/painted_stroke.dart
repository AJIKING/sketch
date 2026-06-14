import 'dart:ui';

import '../../application/canvas_controller.dart' show Tool;
import '../../domain/brush/brush_preset.dart';

/// 1 ストロークの保持データ(retained-mode)。
///
/// 立ち上げ scope では描画をベクター(点列の再生)で保持し、レイヤーは
/// ストロークのリストとして表現する。ラスタライズは `stroke_render` が
/// `stroke_planner` を使って行う。seed はブラシの散らしを決定化する(ADR 0003)。
///
/// 各点には注入した `Clock` 由来のタイムスタンプ(ms)を添える。これにより
/// ink の速度依存の筆幅を実時間に縛られず再現できる(ADR 0003)。
class PaintedStroke {
  PaintedStroke({
    required this.tool,
    required this.brush,
    required this.colorHex,
    required this.size,
    required this.opacity,
    required this.seed,
  }) : points = <Offset>[],
       _times = <double>[];

  final Tool tool;
  final BrushPreset brush;
  final String colorHex;
  final double size;
  final double opacity;
  final int seed;
  final List<Offset> points;
  final List<double> _times;

  /// 点とそのタイムスタンプ(ms)を追加する。
  void addPoint(Offset point, double timeMs) {
    points.add(point);
    _times.add(timeMs);
  }

  /// 点 [i-1] → [i] 区間の速度(距離 / 経過 ms)。時刻が無い / dt<=0 なら 0。
  double speedAt(int i) {
    if (i <= 0 || i >= _times.length) return 0;
    final dt = _times[i] - _times[i - 1];
    if (dt <= 0) return 0;
    return (points[i] - points[i - 1]).distance / dt;
  }
}
