import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sketch/src/application/canvas_controller.dart';
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
            child: DrawSurface(controller: c, surface: s, clock: FakeClock()),
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
}
