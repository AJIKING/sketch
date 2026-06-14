import 'dart:typed_data';

/// RGBA バッファに対するフィルタ(pure Dart, ADR 0004)。
///
/// すべて元バッファを変更せず新しいバッファを返す。`dart:ui` 非依存なので
/// 決定的に unit テストできる。ui 層が `Image.toByteData` /
/// `decodeImageFromPixels` で橋渡しする。

int _clamp8(num v) => v < 0 ? 0 : (v > 255 ? 255 : v.round());

/// 色を反転(アルファは保持)。
Uint8List invert(Uint8List src) {
  final out = Uint8List(src.length);
  for (var i = 0; i < src.length; i += 4) {
    out[i] = 255 - src[i];
    out[i + 1] = 255 - src[i + 1];
    out[i + 2] = 255 - src[i + 2];
    out[i + 3] = src[i + 3];
  }
  return out;
}

/// グレースケール(輝度 0.299/0.587/0.114、アルファは保持)。
Uint8List grayscale(Uint8List src) {
  final out = Uint8List(src.length);
  for (var i = 0; i < src.length; i += 4) {
    final y = _clamp8(0.299 * src[i] + 0.587 * src[i + 1] + 0.114 * src[i + 2]);
    out[i] = y;
    out[i + 1] = y;
    out[i + 2] = y;
    out[i + 3] = src[i + 3];
  }
  return out;
}

/// 明るさ([brightness] -1..1)とコントラスト([contrast] -1..1)を調整。
Uint8List adjustBrightnessContrast(
  Uint8List src, {
  double brightness = 0,
  double contrast = 0,
}) {
  final b = brightness * 255;
  final c = 1 + contrast;
  final out = Uint8List(src.length);
  for (var i = 0; i < src.length; i += 4) {
    out[i] = _clamp8((src[i] - 128) * c + 128 + b);
    out[i + 1] = _clamp8((src[i + 1] - 128) * c + 128 + b);
    out[i + 2] = _clamp8((src[i + 2] - 128) * c + 128 + b);
    out[i + 3] = src[i + 3];
  }
  return out;
}

/// モザイク(各 [block] × [block] ブロックを平均色で塗る)。
Uint8List mosaic(Uint8List src, int width, int height, int block) {
  if (block <= 1) return Uint8List.fromList(src);
  final out = Uint8List(src.length);
  for (var by = 0; by < height; by += block) {
    for (var bx = 0; bx < width; bx += block) {
      var sr = 0, sg = 0, sb = 0, sa = 0, n = 0;
      for (var y = by; y < by + block && y < height; y++) {
        for (var x = bx; x < bx + block && x < width; x++) {
          final i = (y * width + x) * 4;
          sr += src[i];
          sg += src[i + 1];
          sb += src[i + 2];
          sa += src[i + 3];
          n++;
        }
      }
      final r = sr ~/ n, g = sg ~/ n, b = sb ~/ n, a = sa ~/ n;
      for (var y = by; y < by + block && y < height; y++) {
        for (var x = bx; x < bx + block && x < width; x++) {
          final i = (y * width + x) * 4;
          out[i] = r;
          out[i + 1] = g;
          out[i + 2] = b;
          out[i + 3] = a;
        }
      }
    }
  }
  return out;
}

/// ぼかし(box blur、半径 [radius])。水平→垂直の分離処理。
Uint8List boxBlur(Uint8List src, int width, int height, int radius) {
  if (radius <= 0) return Uint8List.fromList(src);
  final h = _blur1D(src, width, height, radius, horizontal: true);
  return _blur1D(h, width, height, radius, horizontal: false);
}

Uint8List _blur1D(
  Uint8List src,
  int width,
  int height,
  int radius, {
  required bool horizontal,
}) {
  final out = Uint8List(src.length);
  for (var y = 0; y < height; y++) {
    for (var x = 0; x < width; x++) {
      var sr = 0, sg = 0, sb = 0, sa = 0, n = 0;
      for (var d = -radius; d <= radius; d++) {
        final xx = horizontal ? x + d : x;
        final yy = horizontal ? y : y + d;
        if (xx < 0 || xx >= width || yy < 0 || yy >= height) continue;
        final i = (yy * width + xx) * 4;
        sr += src[i];
        sg += src[i + 1];
        sb += src[i + 2];
        sa += src[i + 3];
        n++;
      }
      final o = (y * width + x) * 4;
      out[o] = sr ~/ n;
      out[o + 1] = sg ~/ n;
      out[o + 2] = sb ~/ n;
      out[o + 3] = sa ~/ n;
    }
  }
  return out;
}
