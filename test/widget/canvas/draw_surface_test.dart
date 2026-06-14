import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sketch/src/application/canvas_controller.dart';
import 'package:sketch/src/ui/canvas/draw_surface.dart';
import 'package:sketch/src/ui/canvas/raster_layer_store.dart';

import '../../fixtures/fake_clock.dart';

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
}
