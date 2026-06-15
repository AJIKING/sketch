import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:sketch/src/application/timelapse_recorder.dart';
import 'package:sketch/src/domain/timelapse/timelapse_frame.dart';

TimelapseFrame _f() => TimelapseFrame(rgba: Uint8List(4), width: 1, height: 1);

void main() {
  test('録画 OFF 中はフレームを貯めない', () {
    final rec = TimelapseRecorder(encode: (frames, {frameMs = 80}) => null);
    rec.addFrame(_f());
    expect(rec.frameCount, 0);
    expect(rec.hasFrames, isFalse);
  });

  test('録画 ON でフレームを貯め、上限超過で間引く', () {
    final rec = TimelapseRecorder(
      encode: (frames, {frameMs = 80}) => Uint8List.fromList([1]),
      maxFrames: 4,
    );
    rec.setRecording(true);
    for (var i = 0; i < 8; i++) {
      rec.addFrame(_f());
    }
    expect(rec.frameCount, lessThanOrEqualTo(4)); // 上限を超えない
    expect(rec.frameCount, greaterThan(0));
  });

  test('フレーム有り/無しで exportGif が切り替わる', () {
    var calls = 0;
    final rec = TimelapseRecorder(
      encode: (frames, {frameMs = 80}) {
        calls++;
        return Uint8List.fromList([1, 2, 3]);
      },
    );
    expect(rec.exportGif(), isNull); // 空 → encode 呼ばない
    expect(calls, 0);

    rec.setRecording(true);
    rec.addFrame(_f());
    expect(rec.exportGif(), isNotNull);
    expect(calls, 1);
  });

  test('clear でフレームが空になる', () {
    final rec = TimelapseRecorder(encode: (frames, {frameMs = 80}) => null);
    rec.setRecording(true);
    rec.addFrame(_f());
    rec.clear();
    expect(rec.frameCount, 0);
  });
}
