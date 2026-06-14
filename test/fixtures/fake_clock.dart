import 'package:sketch/src/core/clock.dart';

/// 手動で時刻を進められる `Clock` の fake(ADR 0003 / `docs/test-plan.md`)。
///
/// ストロークの速度計算など、時間に依存するロジックを実時間なしで検証する。
class FakeClock implements Clock {
  FakeClock([DateTime? start]) : _now = start ?? DateTime.utc(2026, 1, 1);

  DateTime _now;

  @override
  DateTime now() => _now;

  /// 指定した時間だけ時刻を進める。
  void advance(Duration by) => _now = _now.add(by);

  /// 任意の時刻へ設定する。
  void set(DateTime to) => _now = to;
}
