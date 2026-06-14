import 'package:flutter_test/flutter_test.dart';
import 'package:sketch/src/application/vector_controller.dart';
import 'package:sketch/src/domain/canvas/shape_kind.dart';
import 'package:sketch/src/domain/vector/vector_object.dart';

void main() {
  late VectorController c;

  setUp(() => c = VectorController());

  test('既定は無効・空・選択なし', () {
    expect(c.enabled, isFalse);
    expect(c.count, 0);
    expect(c.hasSelection, isFalse);
    expect(c.canUndo, isFalse);
  });

  test('setEnabled(false) は選択を解除する', () {
    c.setEnabled(true);
    c.addStroke(
      const [VecPoint(0, 0), VecPoint(9, 0)],
      colorHex: '#000000',
      width: 4,
    );
    expect(c.hasSelection, isTrue);
    c.setEnabled(false);
    expect(c.hasSelection, isFalse);
  });

  test('ストローク追加で選択され、undo で消える', () {
    c.addStroke(
      const [VecPoint(0, 0), VecPoint(10, 0)],
      colorHex: '#FF0000',
      width: 6,
    );
    expect(c.count, 1);
    expect(c.selected, isA<VectorStroke>());
    expect(c.canUndo, isTrue);
    c.undo();
    expect(c.count, 0);
    c.redo();
    expect(c.count, 1);
  });

  test('図形追加', () {
    c.addShape(
      kind: ShapeKind.rectangle,
      start: const VecPoint(0, 0),
      end: const VecPoint(20, 10),
      colorHex: '#00FF00',
      width: 2,
      filled: true,
    );
    expect(c.selected, isA<VectorShapeObject>());
  });

  test('selectAt は最前面を選び、外すと null', () {
    c.addStroke(const [VecPoint(0, 0)], colorHex: '#000000', width: 10);
    expect(c.selectAt(const VecPoint(0, 0)), isTrue);
    expect(c.hasSelection, isTrue);
    expect(c.selectAt(const VecPoint(500, 500)), isFalse);
    expect(c.hasSelection, isFalse);
  });

  test('移動は beginMove→moveSelectedBy で 1 操作として undo できる', () {
    c.addStroke(const [VecPoint(0, 0)], colorHex: '#000000', width: 10);
    final id = c.selectedId;
    c.beginMove();
    c.moveSelectedBy(5, 0);
    c.moveSelectedBy(5, 0); // 合計 +10
    expect(
      (c.layer.byId(id!)! as VectorStroke).points.first,
      const VecPoint(10, 0),
    );
    c.undo(); // ドラッグ全体が 1 回で戻る
    expect(
      (c.layer.byId(id)! as VectorStroke).points.first,
      const VecPoint(0, 0),
    );
  });

  test('タップ選択だけ(移動なし)では履歴を汚さない(回帰)', () {
    c.addStroke(const [VecPoint(5, 5)], colorHex: '#000000', width: 10);
    c.selectAt(const VecPoint(5, 5));
    c.beginMove();
    c.moveSelectedBy(0, 0); // 動きゼロ
    expect(c.canUndo, isTrue); // 追加ぶんの 1 件だけ
    c.undo();
    expect(c.count, 0); // 1 回の undo でストロークが消える(no-op move が無い)
  });

  test('移動しない選択は redo スタックを壊さない(回帰)', () {
    c.addStroke(const [VecPoint(0, 0)], colorHex: '#000000', width: 10);
    c.addStroke(const [VecPoint(9, 9)], colorHex: '#000000', width: 10);
    c.undo(); // 2 本目を取り消し → redo 可能
    expect(c.canRedo, isTrue);
    c.selectAt(const VecPoint(0, 0)); // 残ったものを選択
    c.beginMove(); // 動かさない
    expect(c.canRedo, isTrue); // redo は保持される
  });

  test('削除・色変更', () {
    c.addStroke(const [VecPoint(0, 0)], colorHex: '#000000', width: 10);
    c.recolorSelected('#123456');
    expect(c.selected!.colorHex, '#123456');
    c.deleteSelected();
    expect(c.count, 0);
    expect(c.hasSelection, isFalse);
  });

  test('undo で消えた選択オブジェクトは選択解除される', () {
    c.addStroke(const [VecPoint(0, 0)], colorHex: '#000000', width: 10);
    expect(c.hasSelection, isTrue);
    c.undo(); // オブジェクトが消える
    expect(c.hasSelection, isFalse);
  });

  test('新規編集で redo が消える', () {
    c.addStroke(const [VecPoint(0, 0)], colorHex: '#000000', width: 10);
    c.undo();
    expect(c.canRedo, isTrue);
    c.addStroke(const [VecPoint(1, 1)], colorHex: '#000000', width: 10);
    expect(c.canRedo, isFalse);
  });
}
