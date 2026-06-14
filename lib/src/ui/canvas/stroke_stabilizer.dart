import 'dart:ui';

/// 手ぶれ補正(スタビライザ)。入力点を指数平滑して滑らかな線にする。
///
/// [strength] 0..1。0 で無効(生の点)、大きいほど指に遅れて追従し滑らかになる。
/// ストロークごとに [reset] してから [add] を順に呼ぶ。
class StrokeStabilizer {
  StrokeStabilizer(this.strength);

  final double strength;
  Offset? _smoothed;

  void reset() => _smoothed = null;

  /// 生の点を与え、平滑後の点を返す。
  Offset add(Offset raw) {
    final prev = _smoothed;
    if (prev == null) {
      _smoothed = raw;
      return raw;
    }
    // strength 0 → a=1(そのまま)、strength 1 → a=0.05(強く遅延)。
    final a = (1 - strength).clamp(0.05, 1.0);
    final next = Offset(
      prev.dx + (raw.dx - prev.dx) * a,
      prev.dy + (raw.dy - prev.dy) * a,
    );
    _smoothed = next;
    return next;
  }
}
