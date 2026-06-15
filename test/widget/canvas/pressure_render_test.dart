import 'package:flutter_test/flutter_test.dart';
import 'package:sketch/src/application/canvas_controller.dart' show Tool;
import 'package:sketch/src/domain/brush/brush_preset.dart';
import 'package:sketch/src/ui/canvas/painted_stroke.dart';
import 'package:sketch/src/ui/canvas/raster_painter.dart';

PaintedStroke _dot(double pressure) {
  final s = PaintedStroke(
    tool: Tool.brush,
    brush: maruPenBrush, // 均一・不透明
    colorHex: '#FF0000',
    size: 16,
    opacity: 1,
    seed: 0,
  );
  s.addPoint(const Offset(20, 20), 0, pressure: pressure);
  return s;
}

void main() {
  test('pressureAt は格納値を返し、範囲外は端の値・空は 1.0', () {
    final s = PaintedStroke(
      tool: Tool.brush,
      brush: inkBrush,
      colorHex: '#000000',
      size: 10,
      opacity: 1,
      seed: 0,
    );
    expect(s.pressureAt(0), 1.0); // 空
    s.addPoint(const Offset(0, 0), 0, pressure: 0.3);
    s.addPoint(const Offset(1, 0), 1, pressure: 0.9);
    expect(s.pressureAt(0), closeTo(0.3, 1e-9));
    expect(s.pressureAt(1), closeTo(0.9, 1e-9));
    expect(s.pressureAt(5), closeTo(0.9, 1e-9)); // 範囲外 → 末尾
  });

  testWidgets('筆圧が高いほど太く描かれる', (tester) async {
    late int hi, lo;
    await tester.runAsync(() async {
      final imgHi = bakeStroke(
        existing: null,
        stroke: _dot(1.0),
        width: 40,
        height: 40,
      );
      final imgLo = bakeStroke(
        existing: null,
        stroke: _dot(0.2),
        width: 40,
        height: 40,
      );
      // 中心(20,20)から 7px 離れた点の不透明度。
      hi = (await imgHi.toByteData())!.getUint8((20 * 40 + 27) * 4 + 3);
      lo = (await imgLo.toByteData())!.getUint8((20 * 40 + 27) * 4 + 3);
    });
    expect(hi, greaterThan(0)); // 太い → 端まで届く
    expect(lo, 0); // 細い → 届かない
  });
}
