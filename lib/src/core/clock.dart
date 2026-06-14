/// 時間源の境界(`docs/architecture.md` の差し替え境界 / ADR 0003)。
///
/// ストロークの速度計算やスケッチの保存時刻に使う。テストでは
/// 固定・手動進行の fake(`test/fixtures/fake_clock.dart`)に差し替える。
abstract interface class Clock {
  DateTime now();
}

/// 本番実装。システム時刻を返す。
class SystemClock implements Clock {
  const SystemClock();

  @override
  DateTime now() => DateTime.now();
}
