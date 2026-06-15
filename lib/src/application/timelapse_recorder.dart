import 'package:flutter/foundation.dart';

import '../domain/timelapse/timelapse_frame.dart';

/// タイムラプス録画の状態(ADR/タイムラプス)。
///
/// 録画 ON 中に確定(ストローク等)ごとのフレームを貯め、書き出し時にアニメ GIF
/// へ変換する。GIF エンコードは [encode](data 層の純関数)を注入して使うため、
/// application は画像ライブラリに依存しない。フレームは縮小 RGBA で持つ。
class TimelapseRecorder extends ChangeNotifier {
  TimelapseRecorder({required this.encode, this.maxFrames = 240});

  /// フレーム列 → GIF バイト列(無ければ null)。data 層の `encodeGif` を注入。
  final Uint8List? Function(List<TimelapseFrame> frames, {int frameMs}) encode;

  /// メモリ上限。超えたら間引いてタイムライン全体を保つ。
  final int maxFrames;

  bool _recording = false;
  final List<TimelapseFrame> _frames = [];

  bool get recording => _recording;
  int get frameCount => _frames.length;
  bool get hasFrames => _frames.isNotEmpty;

  void setRecording(bool value) {
    if (value == _recording) return;
    _recording = value;
    notifyListeners();
  }

  /// 録画中ならフレームを追加する。上限超過時は 1 つおきに間引く。
  void addFrame(TimelapseFrame frame) {
    if (!_recording) return;
    _frames.add(frame);
    if (_frames.length > maxFrames) {
      for (var i = _frames.length - 2; i > 0; i -= 2) {
        _frames.removeAt(i);
      }
    }
    notifyListeners();
  }

  void clear() {
    if (_frames.isEmpty) return;
    _frames.clear();
    notifyListeners();
  }

  /// 現在のフレーム列をアニメ GIF へ書き出す(無ければ null)。
  Uint8List? exportGif({int frameMs = 80}) =>
      _frames.isEmpty ? null : encode(List.of(_frames), frameMs: frameMs);
}
