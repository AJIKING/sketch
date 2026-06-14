import 'dart:typed_data';

/// RGBA ピクセルバッファに対する純 Dart 操作(ADR 0004)。
///
/// バッファは `width*height*4` の RGBA(各 0..255、行優先)。`dart:ui` に
/// 依存しないので決定的に unit テストできる。ui 層が `Image.toByteData` /
/// `decodeImageFromPixels` で橋渡しする。

/// RGBA 4 成分。
typedef Rgba = (int r, int g, int b, int a);

/// 許容値つき塗りつぶし(4 連結 flood fill)。
///
/// [seedX],[seedY] の色と各成分の差が [tolerance] 以内の連結領域を [fill] で塗る。
/// 元バッファは変更せず、新しいバッファを返す。
Uint8List floodFill(
  Uint8List src,
  int width,
  int height,
  int seedX,
  int seedY,
  Rgba fill, {
  int tolerance = 0,
}) {
  final out = Uint8List.fromList(src);
  if (seedX < 0 || seedY < 0 || seedX >= width || seedY >= height) return out;

  final si = (seedY * width + seedX) * 4;
  final sr = src[si], sg = src[si + 1], sb = src[si + 2], sa = src[si + 3];
  final (fr, fg, fb, fa) = fill;

  bool matches(int i) =>
      (src[i] - sr).abs() <= tolerance &&
      (src[i + 1] - sg).abs() <= tolerance &&
      (src[i + 2] - sb).abs() <= tolerance &&
      (src[i + 3] - sa).abs() <= tolerance;

  final visited = Uint8List(width * height);
  final stack = <int>[seedY * width + seedX];
  while (stack.isNotEmpty) {
    final p = stack.removeLast();
    if (visited[p] == 1) continue;
    visited[p] = 1;
    final i = p * 4;
    if (!matches(i)) continue;
    out[i] = fr;
    out[i + 1] = fg;
    out[i + 2] = fb;
    out[i + 3] = fa;
    final px = p % width;
    final py = p ~/ width;
    if (px > 0) stack.add(p - 1);
    if (px < width - 1) stack.add(p + 1);
    if (py > 0) stack.add(p - width);
    if (py < height - 1) stack.add(p + width);
  }
  return out;
}

/// 指定座標の色を読む(スポイト)。範囲外は透明。
Rgba samplePixel(Uint8List rgba, int width, int height, int x, int y) {
  if (x < 0 || y < 0 || x >= width || y >= height) return (0, 0, 0, 0);
  final i = (y * width + x) * 4;
  return (rgba[i], rgba[i + 1], rgba[i + 2], rgba[i + 3]);
}
