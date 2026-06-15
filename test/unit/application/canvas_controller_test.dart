import 'package:flutter_test/flutter_test.dart';
import 'package:sketch/src/application/canvas_controller.dart';
import 'package:sketch/src/domain/brush/brush_preset.dart';
import 'package:sketch/src/domain/canvas/layer_blend_mode.dart';
import 'package:sketch/src/domain/canvas/layer_stack.dart';
import 'package:sketch/src/domain/canvas/symmetry_mode.dart';

import '../../fixtures/fake_canvas_surface.dart';
import '../../fixtures/in_memory_palette_store.dart';

void main() {
  late FakeCanvasSurface surface;
  late CanvasController c;
  late int notifications;

  setUp(() {
    surface = FakeCanvasSurface();
    c = CanvasController(surface: surface);
    notifications = 0;
    c.addListener(() => notifications++);
  });

  test('既定値', () {
    expect(c.tool, Tool.brush);
    expect(c.brush.key, 'ink');
    expect(c.size, 14);
    expect(c.opacity, 1);
    expect(c.colorHex, '#CF4A2C'); // 朱
    expect(c.layers.length, 2);
    expect(c.canUndo, isFalse);
    expect(c.canRedo, isFalse);
  });

  group('ツール / ブラシ', () {
    test('ツール切替で通知、同じ値では通知しない', () {
      c.selectTool(Tool.erase);
      expect(c.tool, Tool.erase);
      expect(notifications, 1);
      c.selectTool(Tool.erase);
      expect(notifications, 1);
    });

    test('ブラシ選択はツールをブラシへ戻す', () {
      c.selectTool(Tool.smudge);
      c.selectBrush(pencilBrush);
      expect(c.brush.key, 'pencil');
      expect(c.tool, Tool.brush);
    });

    test('ブラシの flow/scatter/spacing を上書きできる(クランプ付き)', () {
      c.selectBrush(inkBrush);
      c.setBrushFlow(0.3);
      expect(c.brush.flow, closeTo(0.3, 1e-9));
      c.setBrushScatter(5); // クランプ上限 2
      expect(c.brush.scatter, 2);
      c.setBrushSpacing(0.01); // クランプ下限 0.05
      expect(c.brush.spacing, 0.05);
      // 他ブラシ選択で上書きはリセットされる
      c.selectBrush(inkBrush);
      expect(c.brush.flow, inkBrush.flow);
    });
  });

  test('グラデの終点透明トグル/2色目を設定できる', () {
    expect(c.gradientToTransparent, isFalse); // 既定は 2 色グラデ
    c.setGradientToTransparent(true);
    expect(c.gradientToTransparent, isTrue);
    final n = notifications;
    c.setGradientToTransparent(true); // 同値
    expect(notifications, n);
    c.setSecondColorHex('#00FF00');
    expect(c.secondColorHex, '#00FF00');
  });

  test('対称モードを切り替えると通知、同値では通知しない', () {
    expect(c.symmetry, SymmetryMode.none);
    c.setSymmetry(SymmetryMode.vertical);
    expect(c.symmetry, SymmetryMode.vertical);
    expect(notifications, 1);
    c.setSymmetry(SymmetryMode.vertical);
    expect(notifications, 1);
  });

  group('サイズ / 不透明度', () {
    test('クランプされ、無変化なら通知しない', () {
      c.setSize(200);
      expect(c.size, 80);
      c.setSize(0);
      expect(c.size, 1);
      final n = notifications;
      c.setSize(1); // 既に 1
      expect(notifications, n);
    });

    test('不透明度クランプ', () {
      c.setOpacity(2);
      expect(c.opacity, 1);
      c.setOpacity(-1);
      expect(c.opacity, 0);
    });
  });

  group('色 / 最近色', () {
    test('HEX 指定で現在色が変わる', () {
      c.setColorHex('#2C4A63'); // 藍
      expect(c.colorHex, '#2C4A63');
    });

    test('selectColor は最近色へ積む(重複は先頭・最大 8)', () {
      c.selectColor('#2C4A63');
      c.selectColor('#C69749');
      c.selectColor('#2C4A63'); // 重複 → 先頭へ
      expect(c.recent.first, '#2C4A63');
      expect(c.recent.where((x) => x == '#2C4A63'), hasLength(1));

      for (final hex in c.palette) {
        c.selectColor(hex);
      }
      expect(c.recent.length, 8);
    });
  });

  group('レイヤー', () {
    test('追加 / アクティブ切替 / 削除', () {
      c.addLayer();
      expect(c.layers.length, 3);
      expect(c.layers.activeIndex, 2);
      c.setActiveLayer(0);
      expect(c.layers.activeIndex, 0);
      expect(c.removeLayer(0), isTrue);
      expect(c.layers.length, 2);
    });

    test('最後の 1 枚は削除されず通知もしない', () {
      c.removeLayer(0);
      final n = notifications;
      expect(c.removeLayer(0), isFalse);
      expect(notifications, n);
    });

    test('ブレンド/アルファロック/クリップを切り替える', () {
      c.setLayerBlendMode(0, LayerBlendMode.multiply);
      expect(c.layers.layers[0].blendMode, LayerBlendMode.multiply);
      c.toggleLayerAlphaLock(0);
      expect(c.layers.layers[0].alphaLocked, isTrue);
      c.toggleLayerClip(0);
      expect(c.layers.layers[0].clipToLower, isTrue);
    });
  });

  group('履歴(undo/redo)', () {
    test('beginStroke→描画→undo で画素が戻り、redo でやり直す', () {
      final activeId = c.layers.active.id;
      surface.draw(activeId, 'A');
      c.beginStroke(); // 現在 'A' を記録
      surface.draw(activeId, 'B'); // 描いた
      expect(c.canUndo, isTrue);

      c.undo();
      expect(surface.state[activeId], 'A');
      expect(c.canRedo, isTrue);

      c.redo();
      expect(surface.state[activeId], 'B');
    });

    test('新しい beginStroke で redo が消える', () {
      final id = c.layers.active.id;
      c.beginStroke();
      c.undo();
      expect(c.canRedo, isTrue);
      surface.draw(id, 'x');
      c.beginStroke();
      expect(c.canRedo, isFalse);
    });

    test('clearActiveLayer は消去しつつ undo 可能', () {
      final id = c.layers.active.id;
      surface.draw(id, 'A');
      c.clearActiveLayer();
      expect(surface.state[id], 'cleared');
      expect(c.canUndo, isTrue);
      c.undo();
      expect(surface.state[id], 'A');
    });

    test('結合(構成変更)を undo/redo で構成ごと巻き戻す', () {
      c.addLayer(); // 3 枚, active=2
      final ids = c.layers.layers.map((l) => l.id).toList();
      surface.draw(ids[1], 'below');
      surface.draw(ids[2], 'above');

      // ui 相当: 結合前スナップショット → 下を合成画素へ差し替え → 構成変更。
      c.beginStructural();
      surface.draw(ids[1], 'merged');
      expect(c.mergeDown(2), isTrue);
      expect(c.layers.length, 2);
      expect(c.layers.activeIndex, 1);
      expect(surface.state[ids[1]], 'merged');

      // undo: 3 枚へ戻り、下の画素も結合前へ。
      c.undo();
      expect(c.layers.length, 3);
      expect(c.layers.activeIndex, 2);
      expect(surface.state[ids[1]], 'below');
      expect(surface.state[ids[2]], 'above');

      // redo: 再び結合状態へ。
      c.redo();
      expect(c.layers.length, 2);
      expect(surface.state[ids[1]], 'merged');
    });

    test('最下層の結合は false(履歴を積まない前提)', () {
      expect(c.mergeDown(0), isFalse);
    });

    test('空のとき undo/redo は何もしない', () {
      c.undo();
      c.redo();
      expect(c.canUndo, isFalse);
      expect(c.canRedo, isFalse);
    });

    test('beginStroke(layerId) はアクティブでなく指定レイヤーを記録する', () {
      final a = c.layers.layers[0].id;
      final b = c.layers.layers[1].id; // 既定アクティブ
      surface.draw(a, 'A0');
      surface.draw(b, 'B0');
      // アクティブは b のまま、a を対象に履歴記録(非同期で捕捉した id 相当)
      c.beginStroke(a);
      surface.draw(a, 'A1');
      c.undo();
      expect(surface.state[a], 'A0'); // a が戻る
      expect(surface.state[b], 'B0'); // b は不変
    });
  });

  group('マスク', () {
    test('drawTargetId はマスク編集中のみマスク id を返す', () {
      final activeId = c.layers.active.id;
      expect(c.drawTargetId, activeId); // 既定は本体

      c.setMaskEditing(true); // マスクが無ければ本体のまま
      expect(c.drawTargetId, activeId);

      c.setLayerMask(c.layers.activeIndex, true);
      c.setMaskEditing(true);
      expect(c.drawTargetId, maskLayerId(activeId)); // マスクへ

      c.setMaskEditing(false);
      expect(c.drawTargetId, activeId); // 終了で本体へ
    });

    test('マスク解除で編集モードも解除される', () {
      c.setLayerMask(0, true);
      c.setActiveLayer(0);
      c.setMaskEditing(true);
      expect(c.maskEditing, isTrue);
      c.setLayerMask(0, false);
      expect(c.maskEditing, isFalse);
      expect(c.layers.layers[0].hasMask, isFalse);
    });

    test('マスク追加/解除を undo/redo で構成ごと巻き戻す', () {
      final i = c.layers.activeIndex;
      final id = c.layers.active.id;

      // ui 相当: 構成スナップショット → マスク画素生成 → フラグ ON。
      c.beginStructural();
      surface.draw(maskLayerId(id), 'white');
      c.setLayerMask(i, true);
      expect(c.layers.active.hasMask, isTrue);

      // undo → マスク無し & 画素も消える(透明トークンへ)。
      c.undo();
      expect(c.layers.layers[i].hasMask, isFalse);
      expect(surface.state[maskLayerId(id)], 'empty');

      // redo → マスク復活 & 画素も戻る。
      c.redo();
      expect(c.layers.layers[i].hasMask, isTrue);
      expect(surface.state[maskLayerId(id)], 'white');
    });
  });

  group('カスタムパレット', () {
    test('現在色を保存し、重複は先頭へ寄せる', () {
      c.setColorHex('#112233');
      c.addCustomColor();
      c.setColorHex('#445566');
      c.addCustomColor();
      expect(c.customPalette, ['#445566', '#112233']);
      // 既存色を再保存 → 先頭へ移動(重複しない)
      c.addCustomColor('#112233');
      expect(c.customPalette, ['#112233', '#445566']);
    });

    test('削除できる', () {
      c.addCustomColor('#112233');
      c.addCustomColor('#445566');
      c.removeCustomColor('#112233');
      expect(c.customPalette, ['#445566']);
    });

    test('store 注入時は load で復元、変更で save される', () async {
      final store = InMemoryPaletteStore(['#AA0000', '#00BB00']);
      final cc = CanvasController(
        surface: FakeCanvasSurface(),
        paletteStore: store,
      );
      await cc.loadCustomPalette();
      expect(cc.customPalette, ['#AA0000', '#00BB00']);

      cc.addCustomColor('#0000CC');
      expect(cc.customPalette.first, '#0000CC');
      expect(store.saves, 1);

      cc.removeCustomColor('#AA0000');
      expect(store.saves, 2);
      expect(await store.load(), ['#0000CC', '#00BB00']);
    });

    test('store 無しでも add/remove は動く(非永続)', () {
      c.addCustomColor('#123456');
      expect(c.customPalette, ['#123456']);
      c.removeCustomColor('#123456');
      expect(c.customPalette, isEmpty);
    });

    test('dispose 後に load 完了が来ても通知で落ちない(回帰)', () async {
      final store = InMemoryPaletteStore(['#AABBCC']);
      final cc = CanvasController(
        surface: FakeCanvasSurface(),
        paletteStore: store,
      );
      final pending = cc.loadCustomPalette(); // await store.load() で中断
      cc.dispose(); // 完了前に破棄
      await pending; // _disposed ガードで notifyListeners を回避 → 例外なし
      expect(cc.customPalette, isEmpty); // 反映されない
    });
  });
}
