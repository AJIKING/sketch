import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:sketch/src/data/gif_encoder.dart';
import 'package:sketch/src/domain/timelapse/timelapse_frame.dart';

TimelapseFrame _frame(int v) {
  final rgba = Uint8List(2 * 2 * 4);
  for (var i = 0; i < rgba.length; i += 4) {
    rgba[i] = v; // R
    rgba[i + 3] = 255; // A
  }
  return TimelapseFrame(rgba: rgba, width: 2, height: 2);
}

void main() {
  test('フレーム列からアニメ GIF を生成する(GIF ヘッダを持つ)', () {
    final gif = encodeGif([_frame(10), _frame(200)]);
    expect(gif, isNotNull);
    expect(gif!.length, greaterThan(6));
    // GIF87a / GIF89a の先頭 4 バイトは 'GIF8'。
    expect(String.fromCharCodes(gif.sublist(0, 4)), 'GIF8');
  });

  test('フレームが無ければ null', () {
    expect(encodeGif(const []), isNull);
  });
}
