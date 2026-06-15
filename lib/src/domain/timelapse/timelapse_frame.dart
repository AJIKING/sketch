import 'dart:typed_data';

/// タイムラプスの 1 フレーム(RGBA 画素 + 寸法)。pure Dart。
class TimelapseFrame {
  const TimelapseFrame({
    required this.rgba,
    required this.width,
    required this.height,
  });

  final Uint8List rgba; // 長さ = width * height * 4
  final int width;
  final int height;
}
