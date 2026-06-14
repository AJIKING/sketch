import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:sketch/src/domain/canvas/filters.dart';

Uint8List px(List<List<int>> pixels) {
  final b = Uint8List(pixels.length * 4);
  for (var i = 0; i < pixels.length; i++) {
    b[i * 4] = pixels[i][0];
    b[i * 4 + 1] = pixels[i][1];
    b[i * 4 + 2] = pixels[i][2];
    b[i * 4 + 3] = pixels[i][3];
  }
  return b;
}

void main() {
  test('invert は色を反転しアルファを保つ', () {
    final out = invert(
      px([
        [0, 50, 255, 200],
      ]),
    );
    expect([out[0], out[1], out[2], out[3]], [255, 205, 0, 200]);
  });

  test('grayscale は R=G=B にしアルファを保つ', () {
    final out = grayscale(
      px([
        [255, 0, 0, 128],
      ]),
    );
    expect(out[0], out[1]);
    expect(out[1], out[2]);
    expect(out[3], 128);
  });

  group('adjustBrightnessContrast', () {
    test('0/0 は変化なし', () {
      final src = px([
        [10, 128, 200, 255],
      ]);
      final out = adjustBrightnessContrast(src);
      expect(out, src);
    });

    test('明るさ +1 で白に飽和', () {
      final out = adjustBrightnessContrast(
        px([
          [10, 20, 30, 255],
        ]),
        brightness: 1,
      );
      expect([out[0], out[1], out[2]], [255, 255, 255]);
    });

    test('コントラストは 128 からの差を広げる', () {
      final out = adjustBrightnessContrast(
        px([
          [148, 0, 0, 255],
        ]),
        contrast: 1,
      );
      // (148-128)*2+128 = 168
      expect(out[0], 168);
    });
  });

  test('mosaic はブロックを平均色で塗る', () {
    // 2x1: 黒と白 → block=2 で両方が中間グレーに。
    final out = mosaic(
      px([
        [0, 0, 0, 255],
        [254, 254, 254, 255],
      ]),
      2,
      1,
      2,
    );
    expect(out[0], 127);
    expect(out[4], 127);
  });

  test('boxBlur は近傍を平均する', () {
    // 3x1: 黒 白 黒、radius 1 → 中央は (0+255+0)/3 = 85
    final out = boxBlur(
      px([
        [0, 0, 0, 255],
        [255, 255, 255, 255],
        [0, 0, 0, 255],
      ]),
      3,
      1,
      1,
    );
    expect(out[4], 85);
  });

  test('boxBlur radius 0 は変化なし', () {
    final src = px([
      [1, 2, 3, 4],
    ]);
    expect(boxBlur(src, 1, 1, 0), src);
  });
}
