import 'package:flutter_test/flutter_test.dart';
import 'package:sketch/src/domain/canvas/history.dart';

void main() {
  test('初期状態は undo も redo もできない', () {
    final h = History<String>();
    expect(h.canUndo, isFalse);
    expect(h.canRedo, isFalse);
  });

  test('record→undo で直前の状態を返し、redo 可能になる', () {
    final h = History<String>();
    h.record('a'); // 現在状態 a を記録(これから b にする想定)
    expect(h.canUndo, isTrue);
    final restored = h.undo('b'); // 現在は b
    expect(restored, 'a');
    expect(h.canUndo, isFalse);
    expect(h.canRedo, isTrue);
  });

  test('undo→redo の往復で状態が戻る', () {
    final h = History<String>();
    h.record('a');
    final back = h.undo('b'); // → 'a'、redo に b
    expect(back, 'a');
    final forward = h.redo('a'); // → 'b'、undo に a
    expect(forward, 'b');
    expect(h.canRedo, isFalse);
    expect(h.canUndo, isTrue);
  });

  test('新しい record で redo がクリアされる', () {
    final h = History<String>();
    h.record('a');
    h.undo('b'); // redo に b
    expect(h.canRedo, isTrue);
    h.record('a'); // 新しい変更
    expect(h.canRedo, isFalse);
  });

  test('上限を超えると古いスナップショットを破棄する', () {
    final h = History<int>(limit: 3);
    for (var i = 0; i < 5; i++) {
      h.record(i);
    }
    expect(h.undoDepth, 3);
    // 直近 3 件(2,3,4)だけが残る。undo を 3 回で底を打つ。
    expect(h.undo(99), 4);
    expect(h.undo(99), 3);
    expect(h.undo(99), 2);
    expect(h.canUndo, isFalse);
  });

  test('空のとき undo/redo は null を返す', () {
    final h = History<String>();
    expect(h.undo('x'), isNull);
    expect(h.redo('x'), isNull);
  });

  test('clear で両スタックが空になる', () {
    final h = History<String>()..record('a');
    h.undo('b');
    h.clear();
    expect(h.canUndo, isFalse);
    expect(h.canRedo, isFalse);
  });

  test('onDrop は恒久破棄される要素にだけ呼ばれる(上限/redoクリア/clear)', () {
    final dropped = <int>[];
    final h = History<int>(limit: 2, onDrop: dropped.add);

    h.record(1);
    h.record(2);
    h.record(3); // 上限超過 → 1 を破棄
    expect(dropped, [1]);

    h.undo(99); // 3 を返し、99 を redo へ(破棄ではない)
    dropped.clear();
    h.record(4); // redo(99)がクリアされ破棄される
    expect(dropped, [99]);

    dropped.clear();
    h.clear(); // 残り全部(undo の 2,4)を破棄
    expect(dropped, containsAll(<int>[2, 4]));
  });
}
