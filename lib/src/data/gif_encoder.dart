import 'dart:typed_data';

import 'package:image/image.dart' as img;

import '../domain/timelapse/timelapse_frame.dart';

/// タイムラプスのフレーム列をアニメ GIF へエンコードする(純 Dart)。
///
/// [frameMs] は 1 フレームの表示時間(ミリ秒)。フレームが無ければ null。
/// すべてのフレームは同じ寸法である前提(録画側で固定スケールにする)。
Uint8List? encodeGif(List<TimelapseFrame> frames, {int frameMs = 80}) {
  if (frames.isEmpty) return null;
  img.Image? root;
  for (final f in frames) {
    final frame = img.Image.fromBytes(
      width: f.width,
      height: f.height,
      bytes: f.rgba.buffer,
      numChannels: 4,
    );
    frame.frameDuration = frameMs;
    if (root == null) {
      root = frame;
    } else {
      root.addFrame(frame);
    }
  }
  return img.encodeGif(root!);
}
