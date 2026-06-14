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

  test('ブラシシートの並び順', () {
    expect(brushPresets.map((b) => b.key).toList(), [
      'ink',
      'fude',
      'pencil',
      'marker',
      'air',
      'crayon',
      'chalk',
      'stipple',
    ]);
  });

  test('isStroked は線系(ink/筆/marker)のみ true', () {
    expect(inkBrush.isStroked, isTrue);
    expect(fudeBrush.isStroked, isTrue);
    expect(markerBrush.isStroked, isTrue);
    expect(pencilBrush.isStroked, isFalse);
    expect(airBrush.isStroked, isFalse);
    expect(crayonBrush.isStroked, isFalse);
  });

  test('velocity は ink/筆のみ、flat は marker のみ', () {
    expect(inkBrush.velocity, isTrue);
    expect(fudeBrush.velocity, isTrue);
    expect(markerBrush.velocity, isFalse);
    expect(markerBrush.flat, isTrue);
    expect(inkBrush.flat, isFalse);
  });

  test('brushByKey は未知の key で ink にフォールバックする', () {
    expect(brushByKey('pencil'), same(pencilBrush));
    expect(brushByKey('unknown'), same(inkBrush));
  });
}
