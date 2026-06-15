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

  test('addText/updateText/deleteById', () {
    c.addText(
      position: const VecPoint(0, 0),
      text: 'A',
      fontSize: 20,
      colorHex: '#000000',
      boxWidth: 10,
      boxHeight: 12,
    );
    expect(c.selected, isA<VectorText>());
    final id = c.selectedId!;

    expect(
      c.updateText(
        id,
        text: 'B',
        fontSize: 24,
        colorHex: '#FF0000',
        boxWidth: 14,
        boxHeight: 16,
        bold: true,
        underline: true,
      ),
      isTrue,
    );
    final t = c.layer.byId(id)! as VectorText;
    expect(t.text, 'B');
    expect(t.bold, isTrue);
    expect(t.underline, isTrue);
    expect(t.colorHex, '#FF0000');

    expect(c.deleteById(id), isTrue);
    expect(c.count, 0);
    expect(c.canUndo, isTrue); // 一連の操作は undo 可能
  });

  test('addText/updateText でフォント・グラデーションを設定できる', () {
    c.addText(
      position: const VecPoint(0, 0),
      text: 'A',
      fontSize: 20,
      colorHex: '#000000',
      boxWidth: 10,
      boxHeight: 12,
      fontFamily: 'Noto Serif JP',
      gradient: true,
      secondColorHex: '#00FF00',
    );
    final id = c.selectedId!;
    final t = c.layer.byId(id)! as VectorText;
    expect(t.fontFamily, 'Noto Serif JP');
    expect(t.gradient, isTrue);
    expect(t.secondColorHex, '#00FF00');

    // フォント変更だけでも更新が走る(履歴へ積まれる)。
    expect(
      c.updateText(
        id,
        text: 'A',
        fontSize: 20,
        colorHex: '#000000',
        boxWidth: 10,
        boxHeight: 12,
        fontFamily: 'Dela Gothic One',
        gradient: true,
        secondColorHex: '#00FF00',
      ),
      isTrue,
    );
    expect((c.layer.byId(id)! as VectorText).fontFamily, 'Dela Gothic One');
  });

  test('updateText で内容が変わらなければ履歴(redo)を汚さない(回帰)', () {
    c.addText(
      position: const VecPoint(0, 0),
      text: 'A',
      fontSize: 20,
      colorHex: '#000000',
      boxWidth: 10,
      boxHeight: 12,
    );
    final id = c.selectedId!;
    c.addText(
      position: const VecPoint(5, 5),
      text: 'B',
      fontSize: 20,
      colorHex: '#000000',
      boxWidth: 10,
      boxHeight: 12,
    );
    c.undo(); // B を取り消し → redo 可能、A は残る
    expect(c.canRedo, isTrue);

    // A を同じ値で更新 → 変化なしなので push せず、redo が保たれる。
    expect(
      c.updateText(
        id,
        text: 'A',
        fontSize: 20,
        colorHex: '#000000',
        boxWidth: 10,
        boxHeight: 12,
      ),
      isTrue,
    );
    expect(c.canRedo, isTrue); // 据え置き(履歴を汚さない)
  });

  test('updateText は非テキストには効かない', () {
    c.addStroke(const [VecPoint(0, 0)], colorHex: '#000000', width: 10);
    final id = c.selectedId!;
    expect(
      c.updateText(
        id,
        text: 'x',
        fontSize: 20,
        colorHex: '#000000',
        boxWidth: 1,
        boxHeight: 1,
      ),
      isFalse,
    );
  });

  group('調整モード', () {
    test('startAdjust で選択して adjusting、endAdjust で抜ける', () {
      c.addStroke(const [VecPoint(0, 0)], colorHex: '#000000', width: 10);
      final id = c.selectedId!;
      c.clearSelection();
      c.startAdjust(id);
      expect(c.adjusting, isTrue);
      expect(c.selectedId, id);
      c.endAdjust();
      expect(c.adjusting, isFalse);
      expect(c.hasSelection, isFalse);
    });

    test('scaleSelectedBy は anchor 中心に拡縮し 1 操作で undo できる', () {
      c.addShape(
        kind: ShapeKind.rectangle,
        start: const VecPoint(0, 0),
        end: const VecPoint(10, 10),
        colorHex: '#000000',
        width: 2,
      );
      final id = c.selectedId!;
      c.beginEdit();
      c.scaleSelectedBy(2, const VecPoint(0, 0));
      c.scaleSelectedBy(1.5, const VecPoint(0, 0)); // 合計 3 倍
      expect(
        (c.layer.byId(id)! as VectorShapeObject).end,
        const VecPoint(30, 30),
      );
      c.undo(); // ドラッグ全体が 1 回で戻る
      expect(
        (c.layer.byId(id)! as VectorShapeObject).end,
        const VecPoint(10, 10),
      );
    });

    test('縮みすぎる縮小は無視する', () {
      c.addShape(
        kind: ShapeKind.rectangle,
        start: const VecPoint(0, 0),
        end: const VecPoint(8, 8),
        colorHex: '#000000',
        width: 2,
      );
      final id = c.selectedId!;
      c.beginEdit();
      c.scaleSelectedBy(0.1, const VecPoint(0, 0)); // 8*0.1=0.8 < 6 → 無視
      expect(
        (c.layer.byId(id)! as VectorShapeObject).end,
        const VecPoint(8, 8),
      );
    });
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
