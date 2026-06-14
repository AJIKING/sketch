import 'package:flutter_test/flutter_test.dart';
import 'package:sketch/src/domain/brush/brush_preset.dart';

void main() {
  test('プロトタイプ準拠のパラメータを持つ', () {
    expect(inkBrush.flow, 1);
    expect(inkBrush.scatter, 0);
    expect(pencilBrush.scatter, 0.9);
    expect(markerBrush.flow, 0.55);
    expect(airBrush.soft, 1);
    expect(airBrush.spacing, 0.18);
  });

  test('ブラシシートの並び順は ink → pencil → marker → air', () {
    expect(brushPresets.map((b) => b.key).toList(), [
      'ink',
      'pencil',
      'marker',
      'air',
    ]);
  });

  test('isStroked は ink / marker のみ true', () {
    expect(inkBrush.isStroked, isTrue);
    expect(markerBrush.isStroked, isTrue);
    expect(pencilBrush.isStroked, isFalse);
    expect(airBrush.isStroked, isFalse);
  });

  test('brushByKey は未知の key で ink にフォールバックする', () {
    expect(brushByKey('pencil'), same(pencilBrush));
    expect(brushByKey('unknown'), same(inkBrush));
  });
}
