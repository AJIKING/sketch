/// undo / redo の汎用スタック(pure Dart)。
///
/// スナップショット型 [T] は不透明に扱う(レイヤー id + 画素など、呼び出し側の
/// 都合で決める)。プロトタイプ準拠の挙動:
/// - 変更操作の直前に [record] で現在状態を積む(上限 [limit]、超過は古いものを破棄)。
/// - 新しい [record] で redo スタックをクリアする。
/// - [undo] は現在状態を redo へ退避し、直前のスナップショットを返す。
/// - [redo] はその逆。
///
/// `docs/test-plan.md`「undo/redo」/ ADR 0003。
class History<T> {
  History({this.limit = 16, this.onDrop});

  final int limit;

  /// スナップショットが恒久的に破棄される(上限超過・redo クリア・[clear])とき
  /// に呼ばれる。呼び出し側は紐づくリソース(画像など)を解放できる。undo/redo で
  /// スタック間を移動するだけの要素では呼ばれない。
  final void Function(T dropped)? onDrop;

  final List<T> _undo = [];
  final List<T> _redo = [];

  bool get canUndo => _undo.isNotEmpty;
  bool get canRedo => _redo.isNotEmpty;
  int get undoDepth => _undo.length;

  /// 次に [undo] で復元されるスナップショット(消費しない)。空なら null。
  T? get nextUndo => _undo.isEmpty ? null : _undo.last;

  /// 次に [redo] で復元されるスナップショット(消費しない)。空なら null。
  T? get nextRedo => _redo.isEmpty ? null : _redo.last;

  /// 変更の直前に現在状態を記録する。redo はクリアされる。
  void record(T snapshot) {
    _undo.add(snapshot);
    // 上限超過は必ず破棄する(removeAt を null-aware の引数に置くと onDrop 未設定時に
    // 評価されず破棄漏れになるため、常に取り出してから通知する)。
    if (_undo.length > limit) {
      final dropped = _undo.removeAt(0);
      onDrop?.call(dropped);
    }
    if (onDrop != null) {
      for (final dropped in _redo) {
        onDrop!(dropped);
      }
    }
    _redo.clear();
  }

  /// 直前の状態へ戻す。[current] は現在状態(redo に退避される)。
  /// 戻せない場合は null。
  T? undo(T current) {
    if (_undo.isEmpty) return null;
    final snapshot = _undo.removeLast();
    _redo.add(current);
    return snapshot;
  }

  /// 取り消しを取り消す。[current] は現在状態(undo に退避される)。
  /// やり直せない場合は null。
  T? redo(T current) {
    if (_redo.isEmpty) return null;
    final snapshot = _redo.removeLast();
    _undo.add(current);
    return snapshot;
  }

  void clear() {
    if (onDrop != null) {
      for (final dropped in _undo) {
        onDrop!(dropped);
      }
      for (final dropped in _redo) {
        onDrop!(dropped);
      }
    }
    _undo.clear();
    _redo.clear();
  }
}
