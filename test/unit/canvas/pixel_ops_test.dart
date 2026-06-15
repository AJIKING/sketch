import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:sketch/src/domain/canvas/pixel_ops.dart';

/// w×h の単色 RGBA バッファ。
Uint8List solid(int w, int h, Rgba c) {
  final b = Uint8List(w * h * 4);
  for (var p = 0; p < w * h; p++) {
    b[p * 4] = c.$1;
    b[p * 4 + 1] = c.$2;
    b[p * 4 + 2] = c.$3;
    b[p * 4 + 3] = c.$4;
  }
  return b;
}

Rgba at(Uint8List b, int w, int x, int y) => samplePixel(b, w, 999, x, y);

void main() {
  group('floodFill', () {
    test('連結した同色領域を塗る', () {
      final src = solid(3, 3, (255, 255, 255, 255));
      final out = floodFill(src, 3, 3, 1, 1, (255, 0, 0, 255));
      // 全面同色なので 9px すべて赤になる。
      for (var p = 0; p < 9; p++) {
        expect((out[p * 4], out[p * 4 + 3]), (255, 255));
      }
    });

    test('色の境界を越えない', () {
      // 左列 黒、右 2 列 白。seed=右上 → 白領域(6px)だけ塗る。
      final src = solid(3, 2, (255, 255, 255, 255));
      for (var y = 0; y < 2; y++) {
        final i = (y * 3 + 0) * 4;
        src[i] = 0;
        src[i + 1] = 0;
        src[i + 2] = 0;
      }
      final out = floodFill(src, 3, 2, 2, 0, (0, 0, 255, 255));
      expect(at(out, 3, 0, 0), (0, 0, 0, 255)); // 黒のまま
      expect(at(out, 3, 1, 0), (0, 0, 255, 255)); // 塗られた
      expect(at(out, 3, 2, 1), (0, 0, 255, 255));
    });

    test('tolerance で近い色も塗る', () {
      final src = solid(2, 1, (255, 255, 255, 255));
      src[4] = 250; // 右ピクセルをわずかに変える
      src[5] = 250;
      src[6] = 250;
      final strict = floodFill(src, 2, 1, 0, 0, (0, 0, 0, 255));
      expect(at(strict, 2, 1, 0), (250, 250, 250, 255)); // 厳密一致では塗られない
      final loose = floodFill(src, 2, 1, 0, 0, (0, 0, 0, 255), tolerance: 10);
      expect(at(loose, 2, 1, 0), (0, 0, 0, 255)); // 許容内で塗られる
    });

    test('範囲外 seed は元のまま', () {
      final src = solid(2, 2, (1, 2, 3, 4));
      final out = floodFill(src, 2, 2, 5, 5, (9, 9, 9, 9));
      expect(out, src);
    });
  });

  group('selectRegion', () {
    test('全面同色は全行のランを返す', () {
      final src = solid(3, 2, (255, 255, 255, 255));
      final spans = selectRegion(src, 3, 2, 1, 1);
      // 各行 1 本のラン [0,3)。
      expect(spans, [(0, 0, 3), (1, 0, 3)]);
    });

    test('色境界を越えない(白領域だけ)', () {
      // 左列 黒、右 2 列 白。seed=右上 → 各行 [1,3) のラン。
      final src = solid(3, 2, (255, 255, 255, 255));
      for (var y = 0; y < 2; y++) {
        final i = (y * 3 + 0) * 4;
        src[i] = 0;
        src[i + 1] = 0;
        src[i + 2] = 0;
      }
      final spans = selectRegion(src, 3, 2, 2, 0);
      expect(spans, [(0, 1, 3), (1, 1, 3)]);
    });

    test('行内の不連続は別ランに分かれる', () {
      // 1 行 5px: 白 黒 白 白 黒 。seed=左端 → 連結しているのは左端のみ。
      final src = solid(5, 1, (255, 255, 255, 255));
      for (final x in [1, 4]) {
        final i = x * 4;
        src[i] = src[i + 1] = src[i + 2] = 0;
      }
      // 左端 seed: 黒で分断されるので [0,1) だけ。
      expect(selectRegion(src, 5, 1, 0, 0), [(0, 0, 1)]);
      // x=2 seed: [2,4) が連結。
      expect(selectRegion(src, 5, 1, 2, 0), [(0, 2, 4)]);
    });

    test('tolerance で近い色も同領域', () {
      final src = solid(2, 1, (255, 255, 255, 255));
      src[4] = src[5] = src[6] = 250; // 右をわずかに変える
      expect(selectRegion(src, 2, 1, 0, 0), [(0, 0, 1)]); // 厳密では左のみ
      expect(selectRegion(src, 2, 1, 0, 0, tolerance: 10), [(0, 0, 2)]);
    });

    test('範囲外 seed は空', () {
      final src = solid(2, 2, (1, 2, 3, 4));
      expect(selectRegion(src, 2, 2, 9, 9), isEmpty);
    });
  });

  group('samplePixel', () {
    test('座標の色を返す', () {
      final b = solid(2, 2, (10, 20, 30, 40));
      expect(samplePixel(b, 2, 2, 1, 1), (10, 20, 30, 40));
    });

    test('範囲外は透明', () {
      final b = solid(1, 1, (10, 20, 30, 40));
      expect(samplePixel(b, 1, 1, 5, 5), (0, 0, 0, 0));
    });
  });
}
