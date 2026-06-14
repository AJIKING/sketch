import 'package:flutter_test/flutter_test.dart';
import 'package:sketch/src/application/canvas_controller.dart';
import 'package:sketch/src/domain/brush/brush_preset.dart';
import 'package:sketch/src/domain/canvas/layer_blend_mode.dart';

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
  });
}
