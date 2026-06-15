import 'package:flutter_test/flutter_test.dart';
import 'package:sketch/src/domain/canvas/layer_blend_mode.dart';
import 'package:sketch/src/domain/canvas/layer_stack.dart';

void main() {
  test('初期状態は 2 枚で最前面がアクティブ', () {
    final s = LayerStack.initial();
    expect(s.length, 2);
    expect(s.activeIndex, 1);
    expect(s.layers.map((l) => l.name), ['レイヤー 1', 'レイヤー 2']);
    expect(s.layers.every((l) => l.visible && l.opacity == 1), isTrue);
  });

  test('レイヤー id は一意', () {
    final s = LayerStack.initial();
    s.add();
    final ids = s.layers.map((l) => l.id).toSet();
    expect(ids, hasLength(s.length));
  });

  test('追加は最前面に積みアクティブになる', () {
    final s = LayerStack.initial();
    final added = s.add();
    expect(s.length, 3);
    expect(s.activeIndex, 2);
    expect(s.active.id, added.id);
  });

  group('削除', () {
    test('最後の 1 枚は削除できない', () {
      final s = LayerStack.initial();
      expect(s.remove(0), isTrue);
      expect(s.remove(0), isFalse);
      expect(s.length, 1);
    });

    test('アクティブより下を消すと activeIndex が前へずれる', () {
      final s = LayerStack.initial()..add(); // 3 枚, active=2
      expect(s.activeIndex, 2);
      expect(s.remove(0), isTrue); // 下を削除
      expect(s.length, 2);
      expect(s.activeIndex, 1); // 2 → 1 にずれる
    });

    test('アクティブを消すと範囲内へ補正される', () {
      final s = LayerStack.initial()..add(); // active=2(末尾)
      expect(s.remove(2), isTrue);
      expect(s.activeIndex, 1); // 末尾へ補正
    });
  });

  test('表示トグル', () {
    final s = LayerStack.initial();
    s.toggleVisible(0);
    expect(s.layers[0].visible, isFalse);
    s.toggleVisible(0);
    expect(s.layers[0].visible, isTrue);
  });

  test('アクティブ切替は範囲外を無視する', () {
    final s = LayerStack.initial();
    s.setActive(0);
    expect(s.activeIndex, 0);
    s.setActive(5);
    expect(s.activeIndex, 0);
    s.setActive(-1);
    expect(s.activeIndex, 0);
  });

  test('不透明度は 0..1 にクランプ', () {
    final s = LayerStack.initial();
    s.setOpacity(0, 1.5);
    expect(s.layers[0].opacity, 1);
    s.setOpacity(0, -0.2);
    expect(s.layers[0].opacity, 0);
  });

  test('byId はレイヤーを引き、無ければ null', () {
    final s = LayerStack.initial();
    expect(s.byId(s.layers[0].id), same(s.layers[0]));
    expect(s.byId('nope'), isNull);
  });

  test('既定の合成設定は通常・ロック無し・クリップ無し', () {
    final l = LayerStack.initial().layers[0];
    expect(l.blendMode, LayerBlendMode.normal);
    expect(l.alphaLocked, isFalse);
    expect(l.clipToLower, isFalse);
  });

  test('ブレンドモード・アルファロック・クリップを切り替える', () {
    final s = LayerStack.initial();
    s.setBlendMode(0, LayerBlendMode.multiply);
    expect(s.layers[0].blendMode, LayerBlendMode.multiply);
    s.toggleAlphaLock(0);
    expect(s.layers[0].alphaLocked, isTrue);
    s.toggleClip(0);
    expect(s.layers[0].clipToLower, isTrue);
    s.toggleAlphaLock(0);
    expect(s.layers[0].alphaLocked, isFalse);
  });

  test('move でレイヤーを前面/背面へ動かし、アクティブが追従する', () {
    final s = LayerStack.initial()..add(); // 3 枚、アクティブ=2(最前面)
    final ids = s.layers.map((l) => l.id).toList();
    expect(s.activeIndex, 2);

    // 最前面(2)を背面へ -1 → index1 へ。アクティブも 1 へ追従。
    expect(s.move(2, -1), isTrue);
    expect(s.layers.map((l) => l.id), [ids[0], ids[2], ids[1]]);
    expect(s.activeIndex, 1);

    // 範囲外は false。
    expect(s.move(0, -1), isFalse);
    expect(s.move(2, 1), isFalse);
  });

  test('move は |delta|>1 でもアクティブが正しく追従する(回帰)', () {
    final s = LayerStack.initial()
      ..add()
      ..add(); // 4 枚
    final ids = s.layers.map((l) => l.id).toList();
    s.setActive(0);
    expect(s.move(0, 2), isTrue); // index0 を +2 → index2
    expect(s.layers.map((l) => l.id), [ids[1], ids[2], ids[0], ids[3]]);
    expect(s.activeIndex, 2); // active(ids[0])は index2 へ追従
  });

  group('mergeDown', () {
    test('上を取り除きアクティブが直下へ移る', () {
      final s = LayerStack.initial()..add(); // 3 枚, active=2
      final ids = s.layers.map((l) => l.id).toList();
      expect(s.mergeDown(2), isTrue);
      expect(s.layers.map((l) => l.id), [ids[0], ids[1]]);
      expect(s.activeIndex, 1); // 直下へ
    });

    test('最下層(index<=0)や範囲外は false', () {
      final s = LayerStack.initial();
      expect(s.mergeDown(0), isFalse);
      expect(s.mergeDown(5), isFalse);
      expect(s.length, 2);
    });
  });

  group('snapshot / restore', () {
    test('構成を丸ごと巻き戻せる(メタは独立な複製)', () {
      final s = LayerStack.initial()..add(); // 3 枚
      s.setBlendMode(0, LayerBlendMode.multiply);
      s.setActive(1);
      final snap = s.snapshot();

      // 破壊的に変更。
      s.mergeDown(2);
      s.setBlendMode(0, LayerBlendMode.screen);
      s.setActive(0);
      expect(s.length, 2);

      // 復元。
      s.restore(snap);
      expect(s.length, 3);
      expect(s.activeIndex, 1);
      expect(s.layers[0].blendMode, LayerBlendMode.multiply);

      // スナップショットは独立(復元後の変更が漏れない)。
      s.setBlendMode(0, LayerBlendMode.screen);
      s.restore(snap);
      expect(s.layers[0].blendMode, LayerBlendMode.multiply);
    });
  });

  test('HSL ブレンドを含む合成モードが揃っている', () {
    expect(LayerBlendMode.values, contains(LayerBlendMode.hue));
    expect(LayerBlendMode.values, contains(LayerBlendMode.luminosity));
    expect(LayerBlendMode.values.length, greaterThanOrEqualTo(17));
  });
}
