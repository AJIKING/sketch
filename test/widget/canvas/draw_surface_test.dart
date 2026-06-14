import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sketch/src/application/canvas_controller.dart';
import 'package:sketch/src/application/vector_controller.dart';
import 'package:sketch/src/domain/vector/vector_object.dart';
import 'package:sketch/src/ui/canvas/draw_surface.dart';
import 'package:sketch/src/ui/canvas/raster_layer_store.dart';

import '../../fixtures/fake_clock.dart';

Future<void> _pumpKeyed(
  WidgetTester tester,
  GlobalKey<DrawSurfaceState> key,
  CanvasController c,
  RasterLayerStore s,
) {
  return tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: Center(
          child: SizedBox(
            width: 200,
            height: 200,
            child: DrawSurface(
              key: key,
              controller: c,
              surface: s,
              clock: FakeClock(),
              transforming: ValueNotifier<bool>(false),
            ),
          ),
        ),
      ),
    ),
  );
}

Future<void> _pump(
  WidgetTester tester,
  CanvasController c,
  RasterLayerStore s,
) {
  return tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: Center(
          child: SizedBox(
            width: 200,
            height: 200,
            child: DrawSurface(
              controller: c,
              surface: s,
              clock: FakeClock(),
              transforming: ValueNotifier<bool>(false),
            ),
          ),
        ),
      ),
    ),
  );
}

void main() {
  testWidgets('描く→レイヤー画像へ焼き込み、undo/redo で戻る(ADR 0004)', (tester) async {
    final surface = RasterLayerStore();
    final controller = CanvasController(surface: surface);
    await _pump(tester, controller, surface);

    final activeId = controller.layers.active.id;
    expect(surface.imageOf(activeId), isNull);

    await tester.drag(find.byType(DrawSurface), const Offset(40, 40));
    await tester.pump();

    expect(surface.imageOf(activeId), isNotNull, reason: '確定で画像へ焼き込まれる');
    expect(controller.canUndo, isTrue);

    controller.undo();
    expect(surface.imageOf(activeId), isNull, reason: 'ストローク前(空)へ戻る');

    controller.redo();
    expect(surface.imageOf(activeId), isNotNull, reason: 'やり直しで画像が戻る');
  });

  testWidgets('描画中に外部操作が入ると進行中ストロークは破棄される(回帰)', (tester) async {
    final surface = RasterLayerStore();
    final controller = CanvasController(surface: surface);
    await _pump(tester, controller, surface);
    final id = controller.layers.active.id;

    final g = await tester.startGesture(
      tester.getCenter(find.byType(DrawSurface)),
    );
    await g.moveBy(const Offset(20, 10));
    await tester.pump();

    // 別ポインタでのツール変更・undo 等に相当(コントローラ通知)。
    controller.selectTool(Tool.erase);
    await tester.pump();

    await g.up();
    await tester.pump();

    // 進行中ストロークは無効化され、焼き込まれない。
    expect(surface.imageOf(id), isNull);
    expect(controller.canUndo, isFalse);
  });

  testWidgets('非表示レイヤーには焼き込まれない', (tester) async {
    final surface = RasterLayerStore();
    final controller = CanvasController(surface: surface);
    await _pump(tester, controller, surface);

    controller.toggleLayerVisible(controller.layers.activeIndex);
    final activeId = controller.layers.active.id;

    await tester.drag(find.byType(DrawSurface), const Offset(40, 40));
    await tester.pump();

    expect(surface.imageOf(activeId), isNull);
    expect(controller.canUndo, isFalse);
  });

  testWidgets('アルファロック中の空レイヤーには焼き込まれない(Phase1)', (tester) async {
    final surface = RasterLayerStore();
    final controller = CanvasController(surface: surface);
    await _pump(tester, controller, surface);

    controller.toggleLayerAlphaLock(controller.layers.activeIndex);
    final activeId = controller.layers.active.id;

    await tester.drag(find.byType(DrawSurface), const Offset(40, 40));
    await tester.pump();

    expect(surface.imageOf(activeId), isNull, reason: '不透明部分が無いので塗れない');
  });

  testWidgets('テキストツール: タップ→入力→焼込、undo で戻る', (tester) async {
    final surface = RasterLayerStore();
    final controller = CanvasController(surface: surface)
      ..selectTool(Tool.text);
    await _pump(tester, controller, surface);
    final id = controller.layers.active.id;

    await tester.tap(find.byType(DrawSurface));
    await tester.pumpAndSettle();
    expect(find.widgetWithText(AlertDialog, 'テキスト'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'ABC');
    await tester.tap(find.text('追加'));
    await tester.pumpAndSettle();

    expect(surface.imageOf(id), isNotNull);
    expect(controller.canUndo, isTrue);

    controller.undo();
    expect(surface.imageOf(id), isNull);
  });

  testWidgets('長押しでスポイト(どのツールでも色を吸い取る)', (tester) async {
    final surface = RasterLayerStore();
    final controller = CanvasController(surface: surface); // 既定ブラシ
    await _pump(tester, controller, surface);
    controller.setColorHex('#2C4A63'); // 紙以外に設定
    expect(controller.colorHex, '#2C4A63');

    final g = await tester.startGesture(
      tester.getCenter(find.byType(DrawSurface)),
    );
    await tester.pump(const Duration(milliseconds: 500)); // 長押しタイマー発火
    await g.up();
    await tester.pumpAndSettle();

    // 空レイヤーを吸ったので紙の色になる。
    expect(controller.colorHex, '#EFE7D6');
    // 長押しなのでストロークは焼き込まれない。
    expect(surface.imageOf(controller.layers.active.id), isNull);
  });

  testWidgets('図形ツール: ドラッグで焼き込み、undo で戻る', (tester) async {
    final surface = RasterLayerStore();
    final controller = CanvasController(surface: surface)
      ..selectTool(Tool.shape);
    await _pump(tester, controller, surface);
    final id = controller.layers.active.id;
    expect(surface.imageOf(id), isNull);

    await tester.drag(find.byType(DrawSurface), const Offset(60, 40));
    await tester.pump();

    expect(surface.imageOf(id), isNotNull);
    expect(controller.canUndo, isTrue);

    controller.undo();
    expect(surface.imageOf(id), isNull);
  });

  testWidgets('グラデーションをドラッグするとレイヤーへ焼き込まれる(Phase2)', (tester) async {
    final surface = RasterLayerStore();
    final controller = CanvasController(surface: surface)
      ..selectTool(Tool.gradient);
    await _pump(tester, controller, surface);
    final id = controller.layers.active.id;

    await tester.drag(find.byType(DrawSurface), const Offset(60, 60));
    await tester.pump();

    expect(surface.imageOf(id), isNotNull);
    expect(controller.canUndo, isTrue);
  });

  testWidgets('空レイヤーでスポイトすると紙の色になる(Phase2)', (tester) async {
    final surface = RasterLayerStore();
    final controller = CanvasController(surface: surface)
      ..selectTool(Tool.eyedropper);
    await _pump(tester, controller, surface);

    await tester.tap(find.byType(DrawSurface));
    await tester.pump();

    expect(controller.colorHex, '#EFE7D6'); // 紙の色
  });

  testWidgets('選択: 矩形で選択→範囲消去(undo可)→解除', (tester) async {
    final surface = RasterLayerStore();
    final controller = CanvasController(surface: surface);
    final key = GlobalKey<DrawSurfaceState>();
    await _pumpKeyed(tester, key, controller, surface);

    // まず描画して画像を作る。
    await tester.drag(find.byType(DrawSurface), const Offset(80, 60));
    await tester.pump();
    final id = controller.layers.active.id;
    final before = surface.imageOf(id);
    expect(before, isNotNull);

    // 選択ツールで矩形選択。
    controller.selectTool(Tool.select);
    await tester.drag(find.byType(DrawSurface), const Offset(60, 50));
    await tester.pump();
    expect(key.currentState!.hasSelection, isTrue);

    // 範囲消去 → 画像が変わり undo 可能。
    key.currentState!.clearInsideSelection();
    expect(surface.imageOf(id), isNot(same(before)));
    expect(controller.canUndo, isTrue);
    controller.undo();
    expect(surface.imageOf(id), same(before));

    key.currentState!.deselect();
    expect(key.currentState!.hasSelection, isFalse);
  });

  testWidgets('2 本指ピンチでビューが拡大する(Phase3)', (tester) async {
    final surface = RasterLayerStore();
    final controller = CanvasController(surface: surface);
    final key = GlobalKey<DrawSurfaceState>();
    await _pumpKeyed(tester, key, controller, surface);

    expect(key.currentState!.viewport.scale, 1);

    final center = tester.getCenter(find.byType(DrawSurface));
    final g1 = await tester.startGesture(
      center + const Offset(-20, 0),
      pointer: 1,
    );
    final g2 = await tester.startGesture(
      center + const Offset(20, 0),
      pointer: 2,
    );
    await g1.moveBy(const Offset(-40, 0));
    await g2.moveBy(const Offset(40, 0));
    await g1.up();
    await g2.up();
    await tester.pump();

    expect(key.currentState!.viewport.scale, greaterThan(1.5));

    key.currentState!.resetView();
    expect(key.currentState!.viewport.scale, 1);
  });

  testWidgets('保存はビューポート(ズーム)に依存しない(回帰)', (tester) async {
    final surface = RasterLayerStore();
    final controller = CanvasController(surface: surface);
    final key = GlobalKey<DrawSurfaceState>();
    await _pumpKeyed(tester, key, controller, surface);

    await tester.drag(find.byType(DrawSurface), const Offset(50, 30));
    await tester.pump();

    Uint8List? before;
    Uint8List? after;
    await tester.runAsync(() async {
      before = await key.currentState!.exportPng();
    });

    final c = tester.getCenter(find.byType(DrawSurface));
    final g1 = await tester.startGesture(c + const Offset(-20, 0), pointer: 1);
    final g2 = await tester.startGesture(c + const Offset(20, 0), pointer: 2);
    await g1.moveBy(const Offset(-50, 0));
    await g2.moveBy(const Offset(50, 0));
    await g1.up();
    await g2.up();
    await tester.pump();
    expect(key.currentState!.viewport.scale, greaterThan(1.0));

    await tester.runAsync(() async {
      after = await key.currentState!.exportPng();
    });

    expect(before, isNotNull);
    expect(after, equals(before)); // ズームしても出力は同一
  });

  Future<void> pumpVector(
    WidgetTester tester,
    CanvasController c,
    RasterLayerStore s,
    VectorController v,
  ) {
    return tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 200,
              height: 200,
              child: DrawSurface(
                controller: c,
                surface: s,
                clock: FakeClock(),
                transforming: ValueNotifier<bool>(false),
                vector: v,
              ),
            ),
          ),
        ),
      ),
    );
  }

  testWidgets('ベクターモード: ドラッグでベクターを追加し、ラスターは焼かれない', (tester) async {
    final surface = RasterLayerStore();
    final controller = CanvasController(surface: surface);
    final vector = VectorController()..setEnabled(true);
    await pumpVector(tester, controller, surface, vector);

    expect(vector.count, 0);
    await tester.drag(find.byType(DrawSurface), const Offset(60, 20));
    await tester.pump();

    expect(vector.count, 1);
    expect(vector.selected, isA<VectorStroke>());
    // ラスターレイヤーには焼き込まれない。
    expect(surface.imageOf(controller.layers.active.id), isNull);
    expect(controller.canUndo, isFalse);
  });

  testWidgets('ベクターモード: 選択ツールでオブジェクトを掴んで移動できる', (tester) async {
    final surface = RasterLayerStore();
    final controller = CanvasController(surface: surface);
    final vector = VectorController()..setEnabled(true);
    await pumpVector(tester, controller, surface, vector);

    // 中心(100,100)から描いてストロークを作る。
    await tester.drag(find.byType(DrawSurface), const Offset(40, 0));
    await tester.pump();
    final id = vector.selectedId;
    expect(id, isNotNull);

    // 選択ツールで中心(始点付近)を掴んで +30 移動。
    controller.selectTool(Tool.select);
    await tester.pump();
    await tester.drag(find.byType(DrawSurface), const Offset(30, 0));
    await tester.pump();

    expect(vector.selectedId, id); // 同じオブジェクトを選択
    final moved = vector.layer.byId(id!)! as VectorStroke;
    expect(moved.points.first.x, closeTo(130, 1)); // 100 → 130
    vector.undo(); // 移動全体が 1 回で戻る
    expect(
      (vector.layer.byId(id)! as VectorStroke).points.first.x,
      closeTo(100, 1),
    );
  });

  testWidgets('グラデブラシ: 2色目を持つストロークが焼き込まれる', (tester) async {
    final surface = RasterLayerStore();
    final controller = CanvasController(surface: surface)
      ..setColorHex('#CF4A2C')
      ..setSecondColorHex('#2C4A63')
      ..setGradientBrush(true);
    await _pump(tester, controller, surface);
    final id = controller.layers.active.id;

    await tester.drag(find.byType(DrawSurface), const Offset(60, 0));
    await tester.pump();

    expect(surface.imageOf(id), isNotNull);
    expect(controller.canUndo, isTrue);
  });

  testWidgets('2 本指ダブルタップで onToggleUi が呼ばれ、ピンチでは呼ばれない', (tester) async {
    final surface = RasterLayerStore();
    final controller = CanvasController(surface: surface);
    var toggles = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 200,
              height: 200,
              child: DrawSurface(
                controller: controller,
                surface: surface,
                clock: FakeClock(),
                transforming: ValueNotifier<bool>(false),
                onToggleUi: () => toggles++,
              ),
            ),
          ),
        ),
      ),
    );

    final center = tester.getCenter(find.byType(DrawSurface));
    Future<void> twoFingerTap(int p1, int p2) async {
      final g1 = await tester.startGesture(
        center + const Offset(-15, 0),
        pointer: p1,
      );
      final g2 = await tester.startGesture(
        center + const Offset(15, 0),
        pointer: p2,
      );
      await tester.pump();
      await g1.up();
      await g2.up();
      await tester.pump();
    }

    await twoFingerTap(1, 2);
    expect(toggles, 0, reason: '1 回タップではトグルしない');
    await twoFingerTap(3, 4);
    expect(toggles, 1, reason: 'ダブルタップでトグル');

    // 動かす(ピンチ)とタップ扱いされない。
    final g1 = await tester.startGesture(
      center + const Offset(-15, 0),
      pointer: 5,
    );
    final g2 = await tester.startGesture(
      center + const Offset(15, 0),
      pointer: 6,
    );
    await g1.moveBy(const Offset(-40, 0));
    await g2.moveBy(const Offset(40, 0));
    await g1.up();
    await g2.up();
    await tester.pump();
    expect(toggles, 1, reason: 'ピンチはダブルタップとして数えない');
  });

  testWidgets('変形モード: 移動して確定で焼き込み、undo で戻る(Phase3b)', (tester) async {
    final surface = RasterLayerStore();
    final controller = CanvasController(surface: surface);
    final key = GlobalKey<DrawSurfaceState>();
    final transforming = ValueNotifier<bool>(false);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 200,
              height: 200,
              child: DrawSurface(
                key: key,
                controller: controller,
                surface: surface,
                clock: FakeClock(),
                transforming: transforming,
              ),
            ),
          ),
        ),
      ),
    );

    await tester.drag(find.byType(DrawSurface), const Offset(40, 30));
    await tester.pump();
    final id = controller.layers.active.id;
    final before = surface.imageOf(id);
    expect(before, isNotNull);

    key.currentState!.enterTransform();
    await tester.pump();
    expect(transforming.value, isTrue);

    // 1 本指で移動(プレビュー)。確定までレイヤー画像は変わらない。
    await tester.drag(find.byType(DrawSurface), const Offset(20, 10));
    await tester.pump();
    expect(surface.imageOf(id), same(before));

    key.currentState!.confirmTransform();
    await tester.pump();
    expect(transforming.value, isFalse);
    expect(surface.imageOf(id), isNotNull);
    expect(surface.imageOf(id), isNot(same(before))); // 新しい画像へ焼込
    expect(controller.canUndo, isTrue);

    controller.undo();
    expect(surface.imageOf(id), same(before)); // 変形前へ戻る

    transforming.dispose();
  });
}
